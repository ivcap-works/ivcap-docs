# Services and Jobs

In IVCAP, a **Service** is a registered analytic capability and a **Job** is a single
execution of that service. Together they form the primary unit of work on the platform.

---

## Services

A service describes *what* can be run: its name, parameters, execution environment, and
access policy. Services are registered by providers and are immutable once published —
updates result in a new version of the service definition.

### Service definition

```json
{
  "name": "Fire Risk Analysis",
  "description": "Runs fire risk analysis for a given region.",
  "parameters": [
    { "name": "region",     "label": "Region name",       "type": "string"   },
    { "name": "threshold",  "label": "Rainfall threshold", "type": "float",
      "unit": "m" },
    { "name": "input-data", "label": "Input dataset",      "type": "artifact" }
  ],
  "workflow": {
    "type": "basic",
    "basic": {
      "image": "my-registry.example.com/fire-risk:1.2.3",
      "command": ["/app/run"],
      "memory": { "request": "512Mi", "limit": "2Gi" },
      "cpu":    { "request": "250m",  "limit": "2000m" }
    }
  },
  "policy": "urn:ivcap:policy:public"
}
```

### Parameter types

| Type | Description |
|---|---|
| `string` | Plain text |
| `int` | Integer number |
| `float` | Floating-point number (optional `unit`) |
| `bool` | Boolean flag |
| `artifact` | Reference to an IVCAP artifact URN |

### Execution models

IVCAP supports pluggable execution models via the `workflow.type` field:

| Type | Description |
|---|---|
| `basic` | Single container, executed via the Argo workflow engine. The most common model. |
| `argo` | Full Argo workflow YAML, for multi-step pipelines with explicit DAG control. |
| `app-server` | Hosts a static web application served from an artifact (e.g. a React app). |

### Listing and inspecting services

=== "CLI"

    ```bash
    # List all accessible services
    ivcap service list

    # Inspect a specific service
    ivcap service get urn:ivcap:service:<uuid>
    ```

=== "REST"

    ```bash
    GET /1/services
    GET /1/services/urn:ivcap:service:<uuid>
    ```

---

## Jobs

A **job** is created by submitting a request to a service with a set of parameters. Each
job gets its own URN and is independently tracked through its lifecycle.

> **Note on terminology:** Older parts of the API and CLI use the word *order* instead of
> *job*. They mean the same thing. The platform is converging on *job* as the canonical term.

### Submitting a job

=== "CLI"

    ```bash
    ivcap order create urn:ivcap:service:<uuid> \
        region="Tasmania-North" \
        threshold=0.05 \
        input-data=urn:ivcap:artifact:<uuid>
    ```

=== "REST"

    ```json
    POST /1/services/urn:ivcap:service:<uuid>/jobs

    {
      "name": "my-fire-analysis-run-1",
      "parameters": [
        { "name": "region",     "value": "Tasmania-North" },
        { "name": "threshold",  "value": "0.05" },
        { "name": "input-data", "value": "urn:ivcap:artifact:<uuid>" }
      ]
    }
    ```

The platform returns immediately with the job URN and initial status:

```json
{
  "id":     "urn:ivcap:job:<uuid>",
  "status": "pending",
  "links":  { "self": "/1/services/.../jobs/urn:ivcap:job:<uuid>" }
}
```

### Job lifecycle

```mermaid
stateDiagram-v2
    [*] --> pending
    pending --> scheduled : platform schedules execution
    scheduled --> executing : container starts
    executing --> succeeded : service exits 0
    executing --> failed : service exits non-zero
    executing --> error : platform / infrastructure fault
    succeeded --> [*]
    failed --> [*]
    error --> [*]
```

| Status | Meaning |
|---|---|
| `pending` | Job record created; awaiting scheduling |
| `scheduled` | Execution environment is starting |
| `executing` | Service container is actively running |
| `succeeded` | Service completed successfully |
| `failed` | Service reported a failure (non-zero exit) |
| `error` | Platform error — infrastructure fault, timeout, or resource exhaustion |

### Polling and streaming

=== "CLI (poll)"

    ```bash
    ivcap order get urn:ivcap:job:<uuid>
    ```

=== "REST (poll)"

    ```bash
    GET /1/services/<svcId>/jobs/<jobId>
    ```

=== "REST (live stream)"

    ```bash
    # Server-Sent Events — stream closes when job reaches a terminal state
    curl -N -H "Authorization: Bearer <token>" \
      https://api.example.ivcap.net/1/services/<svcId>/jobs/<jobId>/events
    ```

Events are emitted as [CloudEvents](https://cloudevents.io/) JSON:

```
event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"executing","timestamp":"..."}

event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"succeeded","timestamp":"..."}
```

### Retrieving results

Once a job has `succeeded`, retrieve its output artifacts:

=== "CLI"

    ```bash
    # List what the job produced
    ivcap order get urn:ivcap:job:<uuid>

    # Download a specific result artifact
    ivcap artifact download urn:ivcap:artifact:<uuid> -f result.png
    ```

=== "REST"

    ```bash
    GET /1/services/<svcId>/jobs/<jobId>/output
    GET /1/artifacts/<artifactId>/blob
    ```

---

## Worked example

```bash
# 1 – Find a service
$ ivcap service list
+----+---------------------+
| @1 | Gradient Text Image |
+----+---------------------+

# 2 – Upload an input
$ ivcap artifact upload background.png --name "background" --mime-type image/png
ID: urn:ivcap:artifact:6a1c3f2e-...

# 3 – Submit the job
$ ivcap order create @1 msg="Hello IVCAP" img-art=urn:ivcap:artifact:6a1c3f2e-...
Order 'urn:ivcap:job:505c8573-...' with status 'pending' submitted.

# 4 – Wait for completion
$ ivcap order get urn:ivcap:job:505c8573-...
  Status  succeeded
Products  @1 │ out.png │ image/png

# 5 – Download the result
$ ivcap artifact download urn:ivcap:artifact:6f390b51-... -f /tmp/out.png
```

---

## Related concepts

- [Artifacts](artifacts.md) — how input and output data is stored and referenced
- [Aspects and Provenance](aspects-and-provenance.md) — how every job event is automatically recorded
- [Queues](queues.md) — for pipeline patterns where jobs produce work for downstream consumers
- [Agentic Patterns](agentic-patterns.md) — services that autonomously submit sub-jobs
