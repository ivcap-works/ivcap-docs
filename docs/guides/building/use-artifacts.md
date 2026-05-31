# Using Artifacts in a Service

IVCAP's **artifact store** is a managed blob store — a place to keep files of any
type (PDFs, images, CSVs, model weights, generated reports) alongside metadata and
provenance information.

Services interact with artifacts by **URN**, not by file content. A request passes in
`"urn:ivcap:artifact:09e0cb8c-..."`, the service downloads the content, processes it,
uploads the result, and returns the new URN.

---

## Key concepts

| Concept | What it means |
|---|---|
| **Artifact URN** | Stable identifier like `urn:ivcap:artifact:<uuid>` — works across services and jobs |
| **MIME type** | Declared at upload time; tells consumers how to parse the content |
| **Policy** | Controls who can read/write the artifact and for how long |
| **Aspect** | Typed metadata attached to an artifact URN in the DataFabric |

---

## Accessing the IVCAP client

Inside a service handler, access the IVCAP client via `ctxt.ivcap`:

```python
from ivcap_service import JobContext

def handler(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap
    ...
```

The client is pre-configured with the service's credentials — no environment variables
or tokens needed in your code.

---

## Reading an input artifact

### Pattern 1: Input by reference

Services receive artifact URNs as parameters. Declare them as `str` in your Request model:

```python
from pydantic import BaseModel, Field
from typing import Optional

class Request(BaseModel):
    document: str = Field(description="IVCAP URN of the document to process")
    policy: Optional[str] = Field(
        "urn:ivcap:policy:ivcap.base.artifact",
        description="Policy for any artifacts this service creates"
    )
```

### Fetching and streaming the content

```python
def handler(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap

    # Fetch artifact metadata (does NOT download the content yet)
    artifact = ivcap.get_artifact(req.document)

    # Stream the content lazily — memory-efficient for large files
    content_stream = artifact.as_file()

    # artifact.mime_type tells you the file format
    print(f"Processing {artifact.name} ({artifact.mime_type})")

    # Read the content
    data = content_stream.read()
    ...
```

`get_artifact()` returns metadata (name, MIME type, size, policy) without downloading
the content. Call `.as_file()` to get a file-like stream — content flows through as
consumed, without loading it all into memory at once.

---

## Writing an output artifact

### Pattern 2: Output as artifact

Upload results to the artifact store and return the URN in your result. This keeps
responses small even when the output is a large file.

```python
import io

def handler(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap

    # ... do your processing ...
    output_content = b"<processed content>"

    # Upload the result
    output_stream = io.BytesIO(output_content)
    artifact = ivcap.upload_artifact(
        name="result.csv",
        io_stream=output_stream,
        content_type="text/csv",
        content_size=len(output_content),
        policy=req.policy,           # pass through the caller's policy preference
    )

    return Result(output_urn=artifact.urn)
```

| `upload_artifact` parameter | Purpose |
|---|---|
| `name` | Human-readable name visible in the artifact list |
| `io_stream` | Any file-like or byte-stream object |
| `content_type` | MIME type of the uploaded content |
| `content_size` | Byte length — used to show progress during upload |
| `policy` | Access and retention policy URN |

---

## Attaching metadata to an artifact

After uploading, attach typed metadata (aspects) to the artifact URN. This makes it
discoverable via the DataFabric — other services and users can query `list_aspects()`
to find artifacts matching specific criteria without knowing their URNs in advance.

```python
ivcap.add_aspect(
    entity=artifact.urn,
    schema="urn:ivcap:schema:my-domain:analysis-result.1",
    content={
        "region": req.region,
        "score": 0.82,
        "model-version": "v3.1",
    }
)
```

---

## DataFabric caching with `$id`

A powerful pattern: attach a job's result to its *input* artifact, not the job. This
lets subsequent jobs find the cached result by looking up aspects on the input URN,
avoiding redundant reprocessing.

### Step 1: Set `$id` in your Result model

```python
from typing import ClassVar
from pydantic import BaseModel, Field, ConfigDict

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.my-service.1"
    jschema: str = Field(SCHEMA, alias="$schema")

    # Setting $id attaches this result to the INPUT entity, not the job
    id: str = Field(..., alias="$id")
    output_urn: str = Field(description="URN of the result artifact")

    model_config = ConfigDict(populate_by_name=True)
```

### Step 2: Check the cache before doing work

```python
def handler(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap

    # Look up any previous result for this exact input
    cached = list(ivcap.list_aspects(
        entity=req.document,
        schema=Result.SCHEMA,
        limit=1,
    ))
    if cached:
        # Return immediately — no re-download, no re-processing
        return Result(**cached[0].content)

    # Not cached — do the work
    artifact = ivcap.get_artifact(req.document)
    output = process(artifact.as_file(), artifact.mime_type)
    output_artifact = ivcap.upload_artifact(
        name="result.md",
        io_stream=io.BytesIO(output.encode()),
        content_type="text/markdown",
        content_size=len(output),
        policy=req.policy,
    )

    # Return result attached to the SOURCE document URN
    return Result(id=req.document, output_urn=output_artifact.urn)
```

The next time any job sends the same input URN, Step 2's cache lookup will find the
cached result and return instantly.

---

## Complete example

A document conversion service using all three patterns (input by reference, output as
artifact, DataFabric caching):

```python
import io
from typing import ClassVar, Optional
from pydantic import BaseModel, Field, ConfigDict
from ivcap_service import getLogger, Service, JobContext
from ivcap_ai_tool import start_tool_server, ToolOptions, ivcap_ai_tool, logging_init

logging_init()
logger = getLogger("app")

service = Service(name="Document Converter")

class Request(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.doc-converter.request.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    document: str = Field(description="IVCAP URN of the document to convert")
    policy: Optional[str] = Field("urn:ivcap:policy:ivcap.base.artifact")

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.doc-converter.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    id: str = Field(..., alias="$id")           # attach to input document
    output_urn: str
    model_config = ConfigDict(populate_by_name=True)

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Conversion"]))
def convert(req: Request, ctxt: JobContext) -> Result:
    """Convert a document artifact to plain text."""
    ivcap = ctxt.ivcap

    # 1. Cache check
    cached = list(ivcap.list_aspects(entity=req.document, schema=Result.SCHEMA, limit=1))
    if cached:
        logger.info("Cache hit")
        return Result(**cached[0].content)

    # 2. Download
    doc = ivcap.get_artifact(req.document)
    content = do_conversion(doc.as_file(), doc.mime_type)

    # 3. Upload result
    out_bytes = content.encode("utf-8")
    out_art = ivcap.upload_artifact(
        name=f"{doc.name}.txt",
        io_stream=io.BytesIO(out_bytes),
        content_type="text/plain",
        content_size=len(out_bytes),
        policy=req.policy,
    )
    logger.info(f"Uploaded result: {out_art.urn}")

    # 4. Return — result attached to source document in DataFabric
    return Result(id=req.document, output_urn=out_art.urn)

if __name__ == "__main__":
    start_tool_server(service)
```

---

## Pattern summary

| Pattern | Use it when | Key API |
|---|---|---|
| **Input by reference** | Service receives a file | `ivcap.get_artifact(urn)` then `.as_file()` |
| **Output as artifact** | Service produces a file | `ivcap.upload_artifact(...)` |
| **DataFabric caching** | Service does expensive idempotent work | `$id` field + `list_aspects()` lookup |

---

## Next steps

[→ Run Locally](run-locally.md){ .md-button .md-button--primary }
[→ Deploy](deploy.md){ .md-button }

For the full working example with step-by-step explanation, see:

[→ Artifact Tutorial](../../examples/artifact-tutorial.md){ .md-button }
