# Calling Other Services

An IVCAP service can submit jobs to any other registered service using the platform's
internal API via the **sidecar**. This is the foundation of agentic and pipeline patterns:
services that autonomously orchestrate other services.

---

## When to use this pattern

| Pattern | Description |
|---|---|
| **Pipeline** | Service A processes data, passes results to Service B, then to C |
| **Fan-out / fan-in** | A coordinator submits N parallel sub-jobs and collects results |
| **Recursive decomposition** | A service breaks a large task into smaller sub-tasks |
| **Conditional routing** | An orchestrator routes work to different services based on data |

Use direct function calls (calling Python code inline) instead when the sub-task is not
a separately registered service — only use sub-jobs for work that benefits from
independent tracking, versioning, and provenance.

---

## Accessing the sidecar client

Inside a handler with `ctxt: JobContext`, the IVCAP client (`ctxt.ivcap`) is connected
to the sidecar and can submit jobs on behalf of the running service:

```python
from ivcap_service import JobContext

def orchestrate(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap
    ...
```

---

## Submitting a sub-job

### Step 1: Look up the service

```python
# By URN (stable, recommended for production)
svc = ivcap.get_service("urn:ivcap:service:<uuid>")

# By name (convenient for development)
svc = ivcap.get_service_by_name("Fire Risk Analysis")
```

### Step 2: Build the request model

```python
Model = svc.request_model
request = Model(
    region="Tasmania-North",
    threshold=0.05,
    input_data=req.input_artifact,   # pass through an artifact URN
)
```

### Step 3: Submit and wait

```python
import time
from ivcap_client import JobStatus

# Submit the sub-job
job = svc.request_job(request)
print(f"Sub-job submitted: {job.id}")

# Poll until done
while not job.finished:
    time.sleep(5)
    job.refresh()

if job.status() != JobStatus.SUCCEEDED:
    raise RuntimeError(f"Sub-job failed: {job.id} — status: {job.status()}")

# Access the result
result = job.result
print(result)
```

---

## Complete orchestrator example

A service that runs two analyses in sequence and synthesises the results:

```python
import time
from typing import ClassVar, Optional
from pydantic import BaseModel, Field
from ivcap_service import getLogger, Service, JobContext
from ivcap_ai_tool import start_tool_server, ToolOptions, ivcap_ai_tool, logging_init
from ivcap_client import JobStatus

logging_init()
logger = getLogger("app")

service = Service(name="Risk Synthesiser")

class Request(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.risk-synthesiser.request.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    region: str = Field(description="Region to analyse")
    input_data: str = Field(alias="input-data", description="IVCAP artifact URN")

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.risk-synthesiser.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    fire_score: float
    flood_score: float
    combined_risk: str

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Orchestration"]))
def synthesise(req: Request, ctxt: JobContext) -> Result:
    """Run fire and flood risk analyses and synthesise results.

    Orchestrates two downstream services and combines their outputs.
    """
    ivcap = ctxt.ivcap

    # Look up both services
    fire_svc  = ivcap.get_service_by_name("Fire Risk Analysis")
    flood_svc = ivcap.get_service_by_name("Flood Risk Analysis")

    # Submit fire risk job
    FireModel = fire_svc.request_model
    fire_job = fire_svc.request_job(FireModel(
        region=req.region,
        threshold=0.05,
        input_data=req.input_data,
    ))
    logger.info(f"Fire risk job: {fire_job.id}")

    # Submit flood risk job
    FloodModel = flood_svc.request_model
    flood_job = flood_svc.request_job(FloodModel(
        region=req.region,
        input_data=req.input_data,
    ))
    logger.info(f"Flood risk job: {flood_job.id}")

    # Wait for both to complete
    for job in [fire_job, flood_job]:
        while not job.finished:
            time.sleep(5)
            job.refresh()
        if job.status() != JobStatus.SUCCEEDED:
            raise RuntimeError(f"Sub-job {job.id} failed with status {job.status()}")

    fire_result  = fire_job.result
    flood_result = flood_job.result

    fire_score  = fire_result["score"]
    flood_score = flood_result["score"]

    combined = "high" if max(fire_score, flood_score) > 0.7 else "moderate"

    return Result(
        fire_score=fire_score,
        flood_score=flood_score,
        combined_risk=combined,
    )


if __name__ == "__main__":
    start_tool_server(service)
```

---

## Parallel fan-out

To run N sub-jobs in parallel, submit them all first, then wait for all:

```python
import time
from ivcap_client import JobStatus

def run_parallel(regions: list[str], svc, ivcap) -> list[dict]:
    Model = svc.request_model

    # Submit all jobs
    jobs = []
    for region in regions:
        job = svc.request_job(Model(region=region))
        logger.info(f"Submitted {region}: {job.id}")
        jobs.append((region, job))

    # Wait for all
    results = {}
    for region, job in jobs:
        while not job.finished:
            time.sleep(5)
            job.refresh()
        if job.status() != JobStatus.SUCCEEDED:
            logger.warning(f"Job for {region} failed: {job.status()}")
            results[region] = None
        else:
            results[region] = job.result

    return results
```

!!! tip "Fan-out with queues"
    For very large fan-outs (hundreds or thousands of sub-jobs), use a **queue** instead
    of submitting all jobs directly. A coordinator enqueues work items; worker services
    dequeue and process them. See [Using Queues](use-queues.md).

---

## Passing artifacts between services

Pass artifact URNs in sub-job parameters — never raw file content. This keeps
provenance intact and allows artifact reuse:

```python
# First service produces an artifact
prep_result = prep_job.result
intermediate_urn = prep_result["output_artifact"]   # e.g. "urn:ivcap:artifact:..."

# Second service receives the artifact URN as a parameter
Model = analysis_svc.request_model
analysis_job = analysis_svc.request_job(Model(
    input_data=intermediate_urn,
    region=req.region,
))
```

---

## Async variant

For `async` handlers, use the async request API:

```python
import asyncio
from ivcap_client import JobStatus

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Orchestration"]))
async def orchestrate_async(req: Request, ctxt: JobContext) -> Result:
    ivcap = ctxt.ivcap

    svc = ivcap.get_service("urn:ivcap:service:<uuid>")
    req_model = await svc.request_model_async()
    job = await svc.request_job_async(req_model(region=req.region))
    result = await job.result_async()

    return Result(output=result["summary"])
```

---

## Provenance of sub-jobs

Every sub-job is a first-class IVCAP job with its own URN, provenance aspects, and
lifecycle. When a parent job submits a sub-job:

- The sub-job is recorded with its own `urn:ivcap:job:<uuid>`
- The parent job URN is linked to the sub-job via a provenance aspect
- Input and output artifacts are linked for the full lineage chain

This means you can query the DataFabric to reconstruct the complete execution graph
of a multi-step analysis — which sub-jobs ran, in what order, with what inputs,
producing which outputs.

```bash
# See all aspects (including sub-job links) for a parent job
ivcap aspect list --entity urn:ivcap:job:<parent-uuid>
```

---

## Design principles

**Name your sub-jobs.** Include a `name` when submitting — it makes the provenance
graph readable:

```python
job = svc.request_job(Model(region=region), name=f"fire-risk-{region}")
```

**Prefer sub-jobs for reusable steps.** If a processing step is useful on its own,
register it as a separate service. Sub-jobs are independently testable, versioned,
and cacheable.

**Handle failures explicitly.** Check each sub-job's status before using its results.
Log failures with the sub-job URN so they can be investigated:

```python
if job.status() != JobStatus.SUCCEEDED:
    logger.error(f"Sub-job failed: {job.id} (status: {job.status()})")
    raise RuntimeError("Sub-job did not succeed")
```

---

## Next steps

[→ Use Queues](use-queues.md){ .md-button .md-button--primary }
[→ Call LLMs](call-llms.md){ .md-button }
