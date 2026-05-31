# Service Basics

Every IVCAP service follows the same structure: a typed request model in, typed result
model out. This guide covers the core concepts you need before writing your first service.

---

## Choosing an execution mode

Before writing a line of code, decide whether your service should be **lambda** or **batch**.
This is the most important architectural decision.

### Lambda

A **lambda** service runs as a persistent web server. IVCAP sends each job to it as an
HTTP POST. Multiple jobs can run **simultaneously** inside the same process.

**Choose lambda when:**

- Each job is **stateless** — it doesn't depend on previous jobs
- Jobs are **short-lived** (milliseconds to a few seconds)
- You want **high throughput** and parallel execution
- You are wrapping an **external API call** (e.g. QuickGO, an LLM)
- You are building a **tool that agents will call repeatedly**

```toml
# pyproject.toml
[tool.poetry-plugin-ivcap]
service-type = "lambda"
port = 8077
```

### Batch

A **batch** service runs as a one-shot program. IVCAP starts a **fresh container** for
each job, runs it to completion, then shuts it down.

**Choose batch when:**

- The job is **long-running** (minutes to hours)
- The job uses **significant resources** — GPU, large RAM, many cores
- You are wrapping a **CLI tool** not designed for concurrency
- The job is a **multi-step pipeline** (use Argo workflow type)

```toml
# pyproject.toml
[tool.poetry-plugin-ivcap]
service-type = "batch"
```

### Comparison

| | Lambda | Batch |
|---|---|---|
| **Execution model** | Persistent server, parallel requests | One container per job |
| **Concurrency** | High — many jobs at once | One job at a time |
| **Job duration** | Short (ms – seconds) | Long (seconds – hours) |
| **State between jobs** | Shared (be careful!) | None — fresh each time |
| **Best for** | API wrappers, AI tools, lookups | ML training, pipelines, CLI wrappers |

---

## Project structure

The recommended layout for a new service:

```
my_service/
├── pyproject.toml          ← Poetry config + ivcap plugin settings
├── Dockerfile              ← Container definition
├── my_service/
│   ├── __init__.py
│   ├── service.py          ← IVCAP wrapper (request/response models + handler)
│   └── core.py             ← Pure domain logic (no IVCAP imports)
└── tests/
    └── request.json        ← Test request for local testing
```

!!! tip "Keep core logic separate"
    Put your domain logic in `core.py` with no IVCAP imports. This makes it easy to
    test independently before introducing the service wrapper. The GO Term Mapper
    tutorial follows this pattern exactly.

---

## Setting up a project

```bash
# Install Poetry and the IVCAP plugin
curl -sSL https://install.python-poetry.org | python3 -
poetry self add poetry-plugin-ivcap

# Create a new project
poetry new my_service --flat
cd my_service

# Add core dependencies
poetry add pydantic ivcap-ai-tool
poetry install --no-root
```

Configure the IVCAP plugin at the bottom of `pyproject.toml`:

```toml
[tool.poetry-plugin-ivcap]
service-file = "my_service/service.py"
service-type = "lambda"
port = 8077
```

---

## Defining request and result models

IVCAP uses [Pydantic](https://docs.pydantic.dev/) models to define input and output
schemas. These models serve triple duty: runtime validation, schema generation for the
service registry, and documentation for AI agents.

```python
from pydantic import BaseModel, Field, ConfigDict
from typing import ClassVar, Optional, List

class Request(BaseModel):
    # $schema identifies this request type in the DataFabric
    SCHEMA: ClassVar[str] = "urn:sd:schema.my-service.request.1"
    jschema: str = Field(SCHEMA, alias="$schema")

    # Service-specific parameters
    region: str = Field(description="Region name to analyse")
    threshold: float = Field(0.05, description="Detection threshold (0–1)")
    input_data: Optional[str] = Field(
        None,
        alias="input-data",
        description="IVCAP artifact URN of input dataset"
    )

    # Example shown in the service catalogue and to AI agents
    model_config = ConfigDict(json_schema_extra={"example": {
        "$schema": "urn:sd:schema.my-service.request.1",
        "region": "Tasmania-North",
        "threshold": 0.05,
    }})


class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.my-service.1"
    jschema: str = Field(SCHEMA, alias="$schema")

    summary: str = Field(description="Plain-language summary of the result")
    score: float = Field(description="Overall risk score (0–1)")
    output_artifact: Optional[str] = Field(
        None,
        description="URN of the detailed result artifact"
    )
```

---

## Parameter types

| Type | Python type | Service registry type |
|---|---|---|
| Text | `str` | `string` |
| Integer | `int` | `int` |
| Decimal | `float` | `float` |
| Boolean | `bool` | `bool` |
| Artifact reference | `str` (an artifact URN) | `artifact` |

!!! note "Artifact parameters"
    Parameters that reference artifacts should be declared as `str` in Python.
    Add `description="IVCAP artifact URN of ..."` so the service catalogue and
    agents understand what kind of input is expected.

---

## Writing the handler

Wrap your function with `@ivcap_ai_tool`. The decorator registers it as both the
HTTP handler and an AI-callable tool. Write a rich docstring — it becomes the
tool description shown in the service catalogue and used by AI agents.

```python
from ivcap_service import getLogger, Service, JobContext
from ivcap_ai_tool import start_tool_server, ToolOptions, ivcap_ai_tool, logging_init

logging_init()
logger = getLogger("app")

service = Service(
    name="My Analysis Service",
    contact={"name": "Jane Smith", "email": "jane.smith@example.com"},
    license={"name": "MIT", "url": "https://opensource.org/license/MIT"},
)

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Analysis"]))
def analyse(req: Request, ctxt: JobContext) -> Result:
    """Analyse a region and return a risk score.

    Accepts a region name and optional input dataset and returns a
    plain-language summary and a numeric risk score between 0 and 1.

    Typical use cases:
    - Automated risk screening for a list of regions
    - Input to a downstream decision service
    """
    logger.info(f"Analysing region: {req.region}")

    score = run_analysis(req.region, req.threshold)  # your domain logic

    return Result(
        summary=f"Risk score for {req.region}: {score:.2f}",
        score=score,
    )


if __name__ == "__main__":
    start_tool_server(service)
```

### Async handlers

Lambda services benefit from `async` handlers when making multiple I/O calls:

```python
import asyncio

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Analysis"]))
async def analyse(req: Request) -> Result:
    # Fan out multiple async calls simultaneously
    results = await asyncio.gather(
        fetch_region_data(req.region),
        fetch_baseline(req.region),
    )
    score = compute_score(results[0], results[1])
    return Result(summary=f"Score: {score:.2f}", score=score)
```

---

## The `JobContext`

For handlers that need to interact with IVCAP (reading artifacts, querying aspects,
submitting sub-jobs), add a `ctxt: JobContext` parameter:

```python
from ivcap_service import JobContext

def handler(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap          # pre-configured IVCAP client
    job_urn = ctxt.job_id       # URN of the current job
    ...
```

`ctxt.ivcap` provides `get_artifact()`, `upload_artifact()`, `list_aspects()`, and more.
See [Using Artifacts](use-artifacts.md) and [Call Other Services](call-other-services.md).

---

## Testing the handler standalone

Before running the full server, unit-test the handler directly:

```python
# tests/test_service.py
from my_service.service import analyse, Request

def test_basic_request():
    result = analyse(Request(region="Tasmania-North", threshold=0.05))
    assert 0.0 <= result.score <= 1.0
    assert "Tasmania-North" in result.summary
```

```bash
poetry run pytest
```

---

## Next steps

[→ Run Locally](run-locally.md){ .md-button .md-button--primary }
[→ Using Artifacts](use-artifacts.md){ .md-button }
[→ Deploy](deploy.md){ .md-button }
