# Tutorial: Building a GO Term Mapper Service

This tutorial walks through building a real IVCAP service from scratch — a **Gene Ontology (GO) Term Mapper** that maps protein IDs to their GO annotations using the [QuickGO](https://www.ebi.ac.uk/QuickGO/) REST API.

The complete source code is available at [github.com/ivcap-works/gene-onology-term-mapper](https://github.com/ivcap-works/gene-onology-term-mapper).

---

## What We're Building

A service that takes a list of [UniProt](https://www.uniprot.org/) protein IDs and returns their [Gene Ontology](https://geneontology.org/) annotations, optionally filtered by GO category.

**Input:** A list of UniProt IDs (e.g. `["P12345", "Q9H0H5"]`) and an optional category filter (`BP`, `MF`, or `CC`)

**Output:** A JSON map of protein ID → list of GO annotations

**Why lambda mode?** Each request independently queries the QuickGO API and returns results. Requests are stateless, short-lived, and can run fully in parallel — a perfect fit for [lambda mode](service-modes.md#lambda-mode). See [Service Modes](service-modes.md) for when to choose lambda vs batch.

---

## Prerequisites

- Python 3.9+
- Git
- Docker (for containerising and deploying)
- `curl` or `wget` (for testing)

---

## Step 1: Install Poetry and the IVCAP Plugin

[Poetry](https://python-poetry.org/) manages Python dependencies and packaging. The IVCAP Poetry plugin adds commands for building, running, and deploying services.

```bash
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
poetry --version
```

Add the IVCAP plugin:

```bash
poetry self add poetry-plugin-ivcap
poetry ivcap version
```

---

## Step 2: Install the `ivcap` CLI

The `ivcap` CLI is used to interact with an IVCAP deployment — listing services, submitting jobs, and downloading results.

**macOS/Linux (Homebrew):**
```bash
brew tap ivcap-works/ivcap
brew install ivcap
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://github.com/ivcap-works/ivcap-cli/releases/latest/download/ivcap-Windows-amd64.exe -OutFile ivcap.exe
Move-Item ivcap.exe 'C:\Program Files\ivcap\ivcap.exe'
```

Verify and configure:

```bash
ivcap --help
ivcap context create sd-dev https://develop.ivcap.net
ivcap context login
```

---

## Step 3: Create the Project with Poetry

```bash
poetry new my_app --flat
cd my_app
```

This gives you:

```
my_app/
├── pyproject.toml
├── README.rst
├── my_app/
│   └── __init__.py
└── tests/
    └── __init__.py
```

!!! important
    Open `pyproject.toml` and change `requires-python = ">=3.xx"` to `requires-python = ">=3.xx,<4.0"` (where `xx` is your Python minor version). This is required for dependency resolution in the next step.

---

## Step 4: Add Dependencies

```bash
poetry add httpx pydantic ivcap-ai-tool
poetry install --no-root
```

- **`httpx`** — async HTTP client for calling the QuickGO API
- **`pydantic`** — data validation and schema definition
- **`ivcap-ai-tool`** — IVCAP SDK for building lambda services that work as AI tools

---

## Step 5: Implement the Core Functionality

Create `my_app/go_term_fetcher.py`. This file contains the pure domain logic — no IVCAP-specific code yet. This separation makes it easy to test independently.

### Data model and constants

```python
import httpx
from typing import List, Dict, Optional
from pydantic import BaseModel

GO_CATEGORIES = {
    "BP": "biological_process",
    "MF": "molecular_function",
    "CC": "cellular_component",
}

class Annotation(BaseModel):
    id: Optional[str] = None
    geneProductId: Optional[str] = None
    qualifier: Optional[str] = None
    goId: Optional[str] = None
    goAspect: Optional[str] = None
    goEvidence: Optional[str] = None
    goName: Optional[str] = None
    assignedBy: Optional[str] = None
    symbol: Optional[str] = None
    synonyms: Optional[str] = None
    name: Optional[str] = None
    reference: Optional[str] = None
```

### Fetching and filtering annotations

```python
async def fetch_go_terms(uniprot_id: str) -> List[Annotation]:
    """Fetch GO annotations for a UniProt ID from the QuickGO service."""
    url = "https://www.ebi.ac.uk/QuickGO/services/annotation/search"
    params = {
        "geneProductId": f"UniProtKB:{uniprot_id}",
        "limit": 100
    }
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()
        return [Annotation(**d) for d in data["results"]]

def filter_by_category(go_terms: List[Annotation], category: str) -> List[Annotation]:
    """Filter annotations by GO category (BP, MF, or CC)."""
    if category not in GO_CATEGORIES:
        return go_terms
    return [t for t in go_terms if t.goAspect == GO_CATEGORIES[category]]
```

### Test it standalone

Add this at the bottom of `go_term_fetcher.py` to verify it works before adding any IVCAP wrapping:

```python
if __name__ == "__main__":
    import asyncio, json
    from fastapi.encoders import jsonable_encoder

    async def main():
        terms = await fetch_go_terms("P12345")
        print(json.dumps([jsonable_encoder(t) for t in terms[:3]], indent=2))

    asyncio.run(main())
```

```bash
poetry run python my_app/go_term_fetcher.py
```

You should see the first three GO annotations for `P12345`:

```json
[
  {
    "id": "UniProtKB:P12345!306410571",
    "geneProductId": "UniProtKB:P12345",
    "qualifier": "enables",
    "goId": "GO:0003824",
    "goAspect": "molecular_function",
    "goEvidence": "IEA",
    "assignedBy": "InterPro",
    "symbol": "GOT2",
    "reference": "GO_REF:0000002"
  },
  ...
]
```

---

## Step 6: Implement the IVCAP Service Wrapper

Now we wrap the core logic in an IVCAP lambda service. Create `my_app/service.py`.

This service is stateless and spends most of its time waiting on network I/O — making it an ideal lambda service that can handle many requests in parallel.

### Tell IVCAP it's a lambda service

Add this to the end of `pyproject.toml`:

```toml
[tool.poetry-plugin-ivcap]
service-file = "my_app/service.py"
service-type = "lambda"
port = 8077
```

### Imports and logging

```python
import os
from typing import List, Dict, Optional
import asyncio
from pydantic import BaseModel, ConfigDict, Field
from ivcap_service import getLogger, Service
from ivcap_ai_tool import start_tool_server, logging_init, ToolOptions, ivcap_ai_tool

from go_term_fetcher import Annotation, fetch_go_terms, filter_by_category

logging_init()
logger = getLogger("app")
```

### Service metadata

```python
service = Service(
    name="Gene Ontology (GO) Term Mapper",
    contact={
        "name": "Mary Doe",
        "email": "mary.doe@acme.au",
    },
)
```

### Request and Result models

Pydantic models define the schema of incoming requests and outgoing results. The `Field(description=...)` annotations are used by IVCAP to generate documentation and by AI agents to understand how to use the tool.

```python
class Request(BaseModel):
    jschema: str = Field("urn:sd:schema.gene-ontology-term-mapper.request.1", alias="$schema")
    ids: List[str] = Field(description="List of UniProt IDs")
    category: Optional[str] = Field(None, description="GO category: BP, MF, or CC")

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "$schema": "urn:sd:schema.gene-ontology-term-mapper.request.1",
            "ids": ["P12345", "Q9H0H5"],
            "category": "BP"
        }
    })

class Result(BaseModel):
    jschema: str = Field("urn:sd:schema.gene-ontology-term-mapper.1", alias="$schema")
    results: Dict[str, List[Annotation]] = Field(
        description="GO annotations per UniProt ID"
    )
```

### The service handler

The `@ivcap_ai_tool` decorator registers this function as the HTTP handler and also exposes it as a callable AI tool. The docstring becomes the tool's description for agent frameworks.

```python
@ivcap_ai_tool("/", opts=ToolOptions(tags=["GO Term Mapper"]))
async def map_go_terms(req: Request) -> Result:
    """Maps protein or gene identifiers (UniProt IDs) to their GO annotations
    using the QuickGO REST API. Optionally filters by GO category.

    GO categories:
    * BP — Biological Process
    * MF — Molecular Function
    * CC — Cellular Component

    Typical use cases:
    * Enriching gene/protein datasets with functional annotations
    * Supporting biological data exploration
    * Downstream graph or network construction
    """
    results = {}

    async def fetch_and_filter(uid):
        terms = await fetch_go_terms(uid)
        filtered = filter_by_category(terms, req.category) if req.category else terms
        results[uid] = filtered

    await asyncio.gather(*(fetch_and_filter(i) for i in req.ids))
    return Result(results=results)
```

!!! note "Concurrency"
    `asyncio.gather` fetches all requested UniProt IDs **in parallel**. This is one of the key advantages of lambda mode — a single request can fan out many async sub-calls simultaneously.

### Server entry point

```python
if __name__ == "__main__":
    start_tool_server(service)
```

---

## Step 7: Run and Test Locally

Start the service in one terminal:

```bash
poetry ivcap run
```

```
Running: poetry run python my_app/service.py --port 8077
INFO (app): Gene Ontology (GO) Term Mapper - 0.1.0|...
INFO (uvicorn): Uvicorn running on http://0.0.0.0:8077
```

Create a test request file `two_bp.json`:

```json
{
  "$schema": "urn:sd:schema.gene-ontology-term-mapper.request.1",
  "ids": ["P12345", "Q9H0H5"],
  "category": "BP"
}
```

In a second terminal, call it with `curl`:

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    -H "timeout: 60" \
    --data @two_bp.json \
    http://localhost:8077 | jq
```

You should see a JSON response with `"goAspect": "biological_process"` annotations for each ID.

---

## Step 8: Deploy to IVCAP

Deployment has four sub-steps: build a Docker container, commit the code, publish the container, and register the service.

### Choose your base image

Check your Python version:

```bash
poetry run python --version
```

| Python version | Base image |
|---|---|
| 3.10 | `python:3.10-slim-bullseye` |
| 3.11 | `python:3.11-slim-bookworm` |
| 3.12 | `python:3.12-slim-bookworm` |

### Create the Dockerfile

```dockerfile
FROM python:3.12-slim-bookworm
RUN pip install poetry

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false && poetry install --no-root

COPY . .

ARG VERSION=???
ENV VERSION=$VERSION
ENV PORT=80

ENTRYPOINT ["python", "/app/my_app/service.py"]
```

Replace `python:3.12-slim-bookworm` with the version matching your project.

### Build and test the container locally

```bash
poetry ivcap docker-build
poetry ivcap docker-run
```

The same `curl` test from Step 7 should work against the running container. Stop the local Python server first to free the port.

### Commit the code

IVCAP uses the Git commit hash as the service version, ensuring every deployed service is traceable to an exact point in the source history.

```bash
git init
git add .
git commit -m "initial implementation of go term mapper"
git rev-parse --short HEAD
```

### Publish and register

```bash
poetry ivcap deploy
```

This builds a container for the target platform (cross-compiling if needed, e.g. Apple Silicon → `linux/amd64`), pushes it to the IVCAP container registry, and registers the service and tool definitions.

```
INFO: service definition successfully uploaded - urn:ivcap:aspect:...
INFO: tool description successfully uploaded - urn:ivcap:aspect:...
```

---

## Step 9: Test on IVCAP

Submit the same test request to the deployed service:

```bash
poetry ivcap job-exec two_bp.json
```

```json
{
  "$schema": "urn:sd:schema.gene-ontology-term-mapper.1",
  "results": {
    "P12345": [
      {
        "goAspect": "biological_process",
        "goId": "GO:0006103",
        "goEvidence": "ISS",
        "assignedBy": "UniProt",
        ...
      }
    ],
    ...
  }
}
```

---

## Summary

You've built and deployed a fully functional IVCAP lambda service. Here's what each step accomplished:

| Step | What it did |
|---|---|
| 1–2 | Installed Poetry, the IVCAP plugin, and the CLI |
| 3–4 | Created the project structure and added dependencies |
| 5 | Implemented the core logic, independently testable |
| 6 | Wrapped the logic in an IVCAP lambda service with typed request/response schemas |
| 7 | Tested locally with `curl` |
| 8 | Packaged as Docker, committed to Git, deployed to IVCAP |
| 9 | Verified the deployed service produces correct results |

**Key patterns to carry forward:**

- **Separate core logic from the IVCAP wrapper** — `go_term_fetcher.py` works standalone; `service.py` wraps it
- **Use Pydantic models** for all request/response types — IVCAP uses them for schema generation and agent integration
- **Write rich docstrings** on your handler functions — they become the AI tool description
- **Use `asyncio.gather`** to fan out parallel calls within a single lambda request

## What's Next

- Read about [Service Modes](service-modes.md) to understand when to use batch instead
- Browse the [Service Examples](index.md) for more patterns
- See the [Quick Reference](quick-reference.md) to find examples matching your use case
