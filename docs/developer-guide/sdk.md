# Python SDKs

IVCAP provides three Python packages that cover every stage of working with the
platform. Choose the right one for your task:

| Package | Install | Use when |
|---|---|---|
| [`ivcap-service`](https://pypi.org/project/ivcap-service/) | `pip install ivcap-service` | Building **batch** services — long-running jobs, artifact I/O, progress reporting |
| [`ivcap-lambda`](https://pypi.org/project/ivcap-lambda/) | `pip install ivcap-lambda` | Building **lambda** services — short-lived HTTP tools, AI agent tools |
| [`ivcap-client`](https://pypi.org/project/ivcap-client/) | `pip install ivcap-client` | Calling IVCAP **from outside** — notebooks, scripts, agents, pipelines |

---

## `ivcap-service` — Batch Service SDK

**GitHub:** [ivcap-works/ivcap-service-sdk-python](https://github.com/ivcap-works/ivcap-service-sdk-python)
**API reference:** [ivcap-works.github.io/ivcap-service-sdk-python](https://ivcap-works.github.io/ivcap-service-sdk-python)

Use `ivcap-service` to build **batch** services: long-running, queue-based workers
that the platform launches as a fresh container per job. The SDK handles job
lifecycle, artifact upload/download, provenance recording, and structured logging.

```python
from pydantic import BaseModel, Field
from ivcap_service import (
    Service, ServiceContact, ServiceLicense,
    JobContext, start_batch_service, getLogger, logging_init, with_schema,
)

logging_init()
logger = getLogger("app")

service = Service(
    name="My Batch Service",
    contact=ServiceContact(name="Your Name", email="you@example.com"),
    license=ServiceLicense(name="MIT", url="https://opensource.org/license/MIT"),
)

@with_schema("urn:sd:schema:my_service.request.1")
class Request(BaseModel):
    input_data: str = Field(description="The data to process")

@with_schema("urn:sd:schema:my_service.1")
class Result(BaseModel):
    output_data: str = Field(description="The processed result")

def process_job(req: Request, ctxt: JobContext) -> Result:
    """Process a batch job."""
    with ctxt.report.step("processing", msg="Starting work") as step:
        result = req.input_data.upper()
        step.finished(msg="Processing complete")
    return Result(output_data=result)

if __name__ == "__main__":
    start_batch_service(service, process_job)
```

**Key differences from lambda services:**

- `start_batch_service(service, handler)` — the entry point; takes both the service
  description and a handler function
- `JobContext` — provides `.report` for progress steps, `.ivcap` for artifact access
- `@with_schema(urn)` — attaches a URN to the Pydantic model for the service registry
- `ServiceContact` / `ServiceLicense` — typed classes (not plain dicts)

---

## `ivcap-lambda` — Lambda Service SDK

**GitHub:** [ivcap-works/ivcap-python-ai-tool-template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)
**PyPI:** [pypi.org/project/ivcap-lambda](https://pypi.org/project/ivcap-lambda/)

!!! note "Renamed from `ivcap-ai-tool`"
    This package was previously published as `ivcap-ai-tool`. The module name has
    changed to `ivcap_lambda` and the decorator to `@ivcap_lambda`. The old names
    are retained as deprecated aliases — existing code will still run but will emit
    deprecation warnings. Update your imports when convenient.

Use `ivcap-lambda` to build **lambda** services: persistent HTTP servers where the
platform routes each job as a `POST` request. Lambda services are ideal for
stateless, short-lived operations — API wrappers, lookups, AI tools.

```python
from pydantic import BaseModel, Field
from ivcap_service import Service, ServiceContact, getLogger
from ivcap_lambda import ivcap_lambda, start_lambda_server, ToolOptions, logging_init

logging_init()
logger = getLogger("app")

service = Service(
    name="My Lambda Service",
    contact=ServiceContact(name="Your Name", email="you@example.com"),
)

class Request(BaseModel):
    number: int = Field(description="The number to check")

class Result(BaseModel):
    is_prime: bool = Field(description="True if number is prime")

@ivcap_lambda("/", opts=ToolOptions(tags=["Math"]))
def check_prime(req: Request) -> Result:
    """Check whether a number is prime.

    Returns true if the provided number is a prime number, false otherwise.
    """
    n = req.number
    is_prime = n > 1 and all(n % i != 0 for i in range(2, int(n**0.5) + 1))
    return Result(is_prime=is_prime)

if __name__ == "__main__":
    start_lambda_server(service)
```

**Key exports:**

| Name | Purpose |
|---|---|
| `@ivcap_lambda(path, opts)` | Decorator — registers the function as the HTTP handler and AI tool |
| `start_lambda_server(service)` | Start the FastAPI server |
| `ToolOptions(tags, ...)` | Configure tool metadata (tags shown in service catalogue) |
| `logging_init()` | Set up structured logging compatible with the platform |
| `ExecutionContext` | Optional second parameter for accessing job ID and platform APIs |

---

## `ivcap-client` — Python Client SDK

**GitHub:** [ivcap-works/ivcap-client-sdk-python](https://github.com/ivcap-works/ivcap-client-sdk-python)
**API reference:** [ivcap-works.github.io/ivcap-client-sdk-python](https://ivcap-works.github.io/ivcap-client-sdk-python/)

Use `ivcap-client` to call IVCAP from **outside** the platform — notebooks, data
pipelines, external applications, and AI agents. It wraps the REST API with
idiomatic Python objects and full async support.

The SDK auto-detects three operating modes from environment variables:

| Mode | ENV vars | When to use |
|---|---|---|
| **Platform (external)** | `IVCAP_URL` + `IVCAP_JWT` | Scripts, notebooks, agents accessing a live deployment |
| **Platform (in-container)** | `IVCAP_BASE_URL` (injected by platform) | Service code running inside an IVCAP job container |
| **Local** | *(none set)* | Developing and testing locally — no platform needed |

```python
from ivcap_client.ivcap import IVCAP
import time

# Reads IVCAP_URL and IVCAP_JWT from environment or .env file
ivcap = IVCAP()

# Find a service and submit a job
service = ivcap.get_service_by_name("hello-world-python")
job = service.request_job({"msg": "Hello, IVCAP!"})

# Poll until done
while not job.finished:
    time.sleep(5)
    job.refresh()

print(job.status(), job.result)
```

**Getting a JWT token:**

```bash
ivcap context get access-token
```

For the complete guide including artifact management, async API, and Datafabric
access see [Guides → Integrating → Python Client SDK](../guides/integrating/python-client-sdk.md).

---

## Choosing the right package

```
Are you calling IVCAP from a notebook / script / external app?
  → ivcap-client

Are you building a service that runs INSIDE IVCAP?
  → Is each job short-lived (< 30 s) and stateless?
       → ivcap-lambda   (persistent HTTP server, AI tool capable)
  → Is each job long-running or resource-intensive?
       → ivcap-service  (batch mode, one container per job)
```

!!! note "Both service types use `ivcap-service`"
    `ivcap-service` provides the shared core — `Service`, `ServiceContact`,
    `JobContext`, `getLogger` — used by **both** lambda and batch services.
    `ivcap-lambda` adds the HTTP layer on top for lambda-mode services.

---

## See also

- [Build Your First Service](../getting-started/build-service.md)
- [Build Your First AI Agent](../getting-started/build-agent.md)
- [SDK Resources](sdk-resources.md) — links to full API references and examples
