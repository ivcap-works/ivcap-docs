# Tutorial: Working with Artifacts and the DataFabric

This tutorial builds on the [GO Term Mapper tutorial](go-term-mapper-tutorial.md) and introduces two
new IVCAP concepts: **artifacts** and the **DataFabric**.

The complete source code is available at
[github.com/ivcap-works/ivcap-markdown-conversion-service](https://github.com/ivcap-works/ivcap-markdown-conversion-service).

---

## What Are Artifacts?

IVCAP's **artifact store** is essentially a managed blob store — a place to keep files of any type (PDFs,
images, CSVs, model weights, generated reports, etc.) alongside metadata. Unlike passing raw file
content through service requests, artifacts are:

- **Referenced by URN** — a stable identifier like `urn:ivcap:artifact:09e0cb8c-...` that works
  across services, jobs, and users
- **Typed** — each artifact has a MIME type so consumers know how to handle it
- **Policy-controlled** — access and retention are governed by named policies
- **Provenance-tracked** — IVCAP records which job produced each artifact, from which inputs

A typical artifact workflow looks like this:

```
User uploads PDF ──► artifact URN ──► Service A downloads it
                                          └──► processes it
                                          └──► uploads result as new artifact
                                               └──► artifact URN returned to user
```

---

## What Is the DataFabric?

The **DataFabric** is IVCAP's metadata layer. Alongside storing artifact content, IVCAP lets you
attach **aspects** to any entity (an artifact, an order, or any URN you define). An aspect is a
typed JSON document — a piece of structured metadata — associated with that entity.

This enables powerful patterns:

- **Caching**: Attach the result of an expensive computation as an aspect on the *input* URN. Next
  time that same input arrives, look up the aspect first — if it exists, return it immediately
  without reprocessing
- **Lineage**: Link an output artifact back to its source input via aspects
- **Discovery**: Query aspects by schema to find all processed versions of a document, or all
  annotations for a gene, without knowing the specific job IDs

```
                   DataFabric
                  ┌──────────────────────────────────────┐
  PDF artifact ───┤ aspect: markdown_urn = urn:ivcap:...  │
  (source URN)    │ schema: markdown-conversion.1         │
                  └──────────────────────────────────────┘
```

---

## What We're Building

A document conversion service that:

1. Receives the URN of a document stored in IVCAP artifact storage
2. Checks the DataFabric to see if this document has been converted before (cache hit → return immediately)
3. Downloads the source document
4. Converts it to Markdown using [MarkItDown](https://github.com/microsoft/markitdown)
5. Uploads the result as a new artifact
6. Returns the markdown artifact's URN, attaching it to the source document in the DataFabric as a cache entry

**Why lambda mode?** The service is stateless and spends most of its time on I/O (downloads, uploads, conversion).
It's a natural fit for [lambda mode](service-modes.md#lambda-mode).

---

## The Full Implementation

The entire service fits in a single file, `conversion_service.py`. Here it is in full, then we'll walk
through each part:

```python
import io
from markitdown import MarkItDown, StreamInfo
from pydantic import BaseModel, Field, ConfigDict
from typing import ClassVar, Optional

from ivcap_service import getLogger, Service, JobContext
from ivcap_ai_tool import start_tool_server, ToolOptions, ivcap_ai_tool, logging_init

logging_init()
logger = getLogger("app")

service = Service(
    name="Conversion to Markdown Service",
    contact={"name": "Max Ott", "email": "max.ott@data61.csiro.au"},
    license={"name": "MIT", "url": "https://opensource.org/license/MIT"},
)

class Request(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.markdown-conversion.request.2"
    jschema: str = Field(SCHEMA, alias="$schema")
    document: str = Field(description="IVCAP URN of the file to parse")
    policy: Optional[str] = Field(
        "urn:ivcap:policy:ivcap.base.artifact",
        description="Policy for the created markdown artifact"
    )
    model_config = ConfigDict(json_schema_extra={"example": {
        "$schema": "urn:sd:schema.markdown-conversion.request.2",
        "document": "urn:ivcap:artifact:09e0cb8c-...",
    }})

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.markdown-conversion.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    id: str = Field(..., alias="$id")
    markdown_urn: str = Field(description="URN of the markdown version of the document")
    policy: Optional[str] = Field(None, alias="$policy")
    model_config = ConfigDict(populate_by_name=True)


@ivcap_ai_tool("/", opts=ToolOptions(tags=["Markdown Conversion"]))
def conversion_service(req: Request, ctxt: JobContext) -> Result:
    """Parse an uploaded document into markdown.

    Fetches a document artifact from IVCAP storage, converts it to Markdown
    using MarkItDown, and uploads the result back to IVCAP storage.

    Steps:
    1. Check DataFabric for a cached conversion of this document
    2. Download the source document from IVCAP artifact storage
    3. Convert to Markdown using MarkItDown
    4. Upload the markdown as a new artifact
    5. Return the markdown artifact URN (stored as aspect on the source document)
    """

    ivcap = ctxt.ivcap

    # 1. Check for a cached conversion
    cl = list(ivcap.list_aspects(entity=req.document, schema=Result.SCHEMA, limit=1))
    cached = cl[0] if cl else None
    if cached:
        logger.info(f"Cache hit: {cached.content['markdown_urn']}")
        return Result(**cached.content)

    # 2. Download the source document
    logger.info(f"Converting document: {req.document}")
    doc = ivcap.get_artifact(req.document)

    # 3. Convert to markdown
    converter = MarkItDown(enable_plugins=True)
    cres = converter.convert(doc.as_file(), stream_info=StreamInfo(mimetype=doc.mime_type))
    if not cres:
        raise ValueError(f"Failed to convert '{req.document}' to markdown")
    md = cres.markdown

    # 4. Upload the markdown as a new artifact
    ms = io.BytesIO(md.encode("utf-8"))
    cart = ivcap.upload_artifact(
        name=f"{doc.name}.md",
        io_stream=ms,
        content_type="text/markdown",
        content_size=len(md),
        policy=req.policy,
    )
    logger.info(f"Uploaded markdown artifact: {cart.urn}")

    # 5. Return result — IVCAP will attach this as an aspect on req.document
    return Result(id=req.document, markdown_urn=cart.urn, policy=req.policy)


if __name__ == "__main__":
    start_tool_server(service)
```

---

## Walking Through Each Step

### The Request and Result Models

```python
class Request(BaseModel):
    document: str = Field(description="IVCAP URN of the file to parse")
    policy: Optional[str] = Field("urn:ivcap:policy:ivcap.base.artifact", ...)
```

The request takes just two fields: the URN of the artifact to convert, and an optional
storage policy. Notice there is **no file content** in the request — only a pointer. This is the
key artifact pattern: services receive URNs, not bytes.

```python
class Result(BaseModel):
    id: str = Field(..., alias="$id")          # ← the source document URN
    markdown_urn: str = Field(...)              # ← the new artifact URN
```

The `$id` field is a special IVCAP convention. Normally a job's result aspect is attached to
the *job* record itself. By including `$id` set to the **source document URN**, the result is
instead attached to the source document. This is what enables the cache lookup in Step 1 — the
DataFabric now knows "this document has a markdown conversion at this URN".

---

### Step 1: Cache Lookup via the DataFabric

```python
ivcap = ctxt.ivcap
cl = list(ivcap.list_aspects(entity=req.document, schema=Result.SCHEMA, limit=1))
cached = cl[0] if cl else None
if cached:
    return Result(**cached.content)
```

`ctxt` is the `JobContext` passed into every service handler. It carries a pre-configured
[IVCAP client](https://ivcap-works.github.io/ivcap-client-sdk-python/) instance via `ctxt.ivcap`.

`list_aspects(entity=..., schema=...)` queries the DataFabric for any aspects of a given schema
attached to the given entity URN. If a previous job already converted this document, its result
aspect will be there and we can return it immediately — no re-download, no re-conversion.

This is a general-purpose caching pattern applicable to any expensive or idempotent computation.

---

### Step 2: Downloading an Artifact

```python
doc = ivcap.get_artifact(req.document)
doc_f = doc.as_file()
```

`get_artifact()` fetches the artifact metadata (name, MIME type, size, policy). It does **not**
immediately download the content. The content is streamed lazily via `doc.as_file()`, which
returns a file-like object. This is memory-efficient for large files — the content flows through
as it is consumed, without loading it all into memory at once.

`doc.mime_type` is preserved from the original upload and passed to the converter so it knows
how to handle the file format.

---

### Step 3: Converting the Document

```python
converter = MarkItDown(enable_plugins=True)
cres = converter.convert(doc.as_file(), stream_info=StreamInfo(mimetype=doc.mime_type))
md = cres.markdown
```

[MarkItDown](https://github.com/microsoft/markitdown) is a Microsoft library that converts
PDFs, Word documents, PowerPoint, Excel, HTML, images, and more to Markdown. Passing
`stream_info=StreamInfo(mimetype=...)` lets MarkItDown choose the right parser without needing
a file extension.

---

### Step 4: Uploading the Result as an Artifact

```python
ms = io.BytesIO(md.encode("utf-8"))
cart = ivcap.upload_artifact(
    name=f"{doc.name}.md",
    io_stream=ms,
    content_type="text/markdown",
    content_size=len(md),
    policy=req.policy,
)
```

`upload_artifact()` streams the content to IVCAP artifact storage and returns an artifact
record `cart` containing the assigned URN (`cart.urn`). The `policy` parameter controls who
can access this artifact and for how long.

Key fields:

| Parameter | Purpose |
|---|---|
| `name` | Human-readable name, visible in the artifact list |
| `io_stream` | Any file-like or byte-stream object |
| `content_type` | MIME type of the uploaded content |
| `content_size` | Byte length — used to show progress during upload |
| `policy` | Access and retention policy URN |

---

### Step 5: Returning the Result

```python
return Result(id=req.document, markdown_urn=cart.urn, policy=req.policy)
```

Returning a `Result` with `id` (aliased as `$id`) set to the source document URN causes IVCAP
to attach this result as an aspect on the *source document* in the DataFabric — not just on the
job. The next time any service receives `req.document`, Step 1's cache lookup will find it.

---

## Artifact Patterns Summary

This service demonstrates three fundamental artifact patterns you'll use in most data-intensive
IVCAP services:

### Pattern 1: Input by reference
Services receive artifact URNs, not raw content. This keeps requests small and allows the same
artifact to be reused across many jobs without re-uploading.

```python
# In your Request model:
document: str = Field(description="IVCAP URN of the input artifact")

# In your handler:
doc = ctxt.ivcap.get_artifact(req.document)
content = doc.as_file()   # streamed, not loaded all at once
```

### Pattern 2: Output as artifact
Produce output by uploading to the artifact store and returning the URN. Results can be large
files — images, datasets, reports — without bloating the service response.

```python
cart = ctxt.ivcap.upload_artifact(
    name="result.md",
    io_stream=io.BytesIO(content.encode()),
    content_type="text/markdown",
    content_size=len(content),
    policy=req.policy,
)
return Result(output_urn=cart.urn)
```

### Pattern 3: DataFabric caching via `$id`
Attach results to input entities so they can be retrieved by later jobs without reprocessing.

```python
class Result(BaseModel):
    id: str = Field(..., alias="$id")    # attach result to this entity in the DataFabric
    output_urn: str

# Lookup:
cached = list(ctxt.ivcap.list_aspects(entity=input_urn, schema=Result.SCHEMA, limit=1))
if cached:
    return Result(**cached[0].content)
```

---

## Project Setup

Dependencies for this service:

```bash
poetry add markitdown ivcap-ai-tool
poetry install --no-root
```

The `pyproject.toml` configuration (lambda mode, because conversion is stateless and fast):

```toml
[tool.poetry-plugin-ivcap]
service-file = "conversion_service.py"
service-type = "lambda"
port = 8077
```

---

## Testing Locally

Before testing locally you need an artifact already uploaded to IVCAP. Upload a PDF:

```bash
ivcap artifact upload --name "my-document.pdf" --content-type "application/pdf" my-document.pdf
```

Note the returned URN (e.g. `urn:ivcap:artifact:09e0cb8c-...`). Create a request file
`tests/request.json`:

```json
{
  "$schema": "urn:sd:schema.markdown-conversion.request.2",
  "document": "urn:ivcap:artifact:09e0cb8c-..."
}
```

Start the service:

```bash
poetry ivcap run
```

Call it:

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    --data @tests/request.json \
    http://localhost:8077 | jq
```

A successful response looks like:

```json
{
  "$schema": "urn:sd:schema.markdown-conversion.1",
  "$id": "urn:ivcap:artifact:09e0cb8c-...",
  "markdown_urn": "urn:ivcap:artifact:ea6e74d0-...",
  "$policy": "urn:ivcap:policy:ivcap.base.artifact"
}
```

Call it a second time with the same request — the response will be identical but return
**instantly**, served from the DataFabric cache.

---

## Deploying

```bash
git add . && git commit -m "markdown conversion service"
poetry ivcap deploy
```

Then test on the platform:

```bash
poetry ivcap job-exec tests/request.json -- --timeout 0
```

---

## Summary

| Concept | What it is | API |
|---|---|---|
| **Artifact** | A managed blob — file content + metadata + URN | `get_artifact()`, `upload_artifact()` |
| **Artifact URN** | Stable identifier passed between services | `doc.urn`, `cart.urn` |
| **`as_file()`** | Streamed file handle — memory-efficient for large files | `doc.as_file()` |
| **Aspect** | Typed JSON metadata attached to any entity URN | `list_aspects()` |
| **`$id` in Result** | Attach result to the *input* entity, not the job | `Field(..., alias="$id")` |
| **Cache pattern** | Look up aspects before doing expensive work | `list_aspects(entity=input_urn, schema=...)` |

## What's Next

- Read [Service Modes](service-modes.md) to understand when to use batch instead of lambda
- Browse the [GO Term Mapper tutorial](go-term-mapper-tutorial.md) for an introduction to
  building lambda services without artifact handling
- See the [Service Examples overview](index.md) for the full catalogue
