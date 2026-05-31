# Services & Jobs API

Services are registered analytic capabilities. A **job** is a single execution
of a service — created by submitting parameters to the service's jobs endpoint.

---

## Services

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/services` | List all accessible services |
| `POST` | `/1/services` | Register a new service (provider role required) |
| `GET` | `/1/services/{id}` | Get full service details |
| `PUT` | `/1/services/{id}` | Update an existing service definition |
| `DELETE` | `/1/services/{id}` | Remove a service registration |

### List services

```
GET /1/services
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |
| `filter` | string | Filter expression on name or description |

**Response `200 OK`:**

```json
{
  "services": [
    {
      "id":          "urn:ivcap:service:b14569f9-...",
      "name":        "Gradient Text Image",
      "description": "Creates an image with a customizable text.",
      "links": {
        "self":        "/1/services/urn:ivcap:service:b14569f9-...",
        "describedBy": { "href": "...", "type": "application/openapi3+json" }
      }
    }
  ],
  "links": { "self": "...", "next": "..." }
}
```

### Get service

```
GET /1/services/{id}
```

**Response `200 OK`** — full `ServiceStatusRT` object including parameters and
workflow definition.

### Register or update a service

```
POST /1/services        # create
PUT  /1/services/{id}   # update (add ?force-create=true to create-if-missing)
```

**Request body:**

```json
{
  "name": "My Analysis Service",
  "description": "Runs fire risk analysis for a given region.",
  "parameters": [
    { "name": "region",     "label": "Region Name",       "type": "string" },
    { "name": "threshold",  "label": "Rainfall threshold", "type": "float", "unit": "m" },
    { "name": "input-data", "label": "Input dataset",      "type": "artifact" }
  ],
  "workflow": {
    "type": "basic",
    "basic": {
      "image":   "my-registry.example.com/fire-risk:1.2.3",
      "command": ["/app/run"],
      "memory":  { "request": "512Mi", "limit": "2Gi" },
      "cpu":     { "request": "250m",  "limit": "2000m" }
    }
  },
  "policy": "urn:ivcap:policy:public"
}
```

**Parameter types:** `string`, `int`, `float`, `bool`, `artifact`
(an `urn:ivcap:artifact:...` reference).

**Workflow types:**

| Type | Description |
|---|---|
| `basic` | Single Docker container; uses the `basic` block for image and resources |
| `argo` | Argo Workflows definition supplied in the `argo` field |

### Delete service

```
DELETE /1/services/{id}
```

**Response `204 No Content`** on success.

### CLI equivalents

```bash
ivcap service list
ivcap service get urn:ivcap:service:<uuid>
ivcap service update --create urn:ivcap:service:<uuid> -f service.yaml
ivcap service delete urn:ivcap:service:<uuid>
```

---

## Jobs

A job is a single execution of a service. Jobs are created under a service and
their lifecycle is tracked through to completion.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/1/services/{id}/jobs` | Submit a new job |
| `GET` | `/1/services/{id}/jobs` | List jobs for a service |
| `GET` | `/1/services/{id}/jobs/{jobId}` | Get job status and metadata |
| `GET` | `/1/services/{id}/jobs/{jobId}/output` | Get the job result payload |
| `GET` | `/1/services/{id}/jobs/{jobId}/events` | Stream live job events (SSE) |

### Submit a job

```
POST /1/services/{id}/jobs
```

**Request body:**

```json
{
  "name": "my-fire-analysis-run-1",
  "parameters": [
    { "name": "region",     "value": "Tasmania-North" },
    { "name": "threshold",  "value": "0.05" },
    { "name": "input-data", "value": "urn:ivcap:artifact:<uuid>" }
  ]
}
```

**Response `201 Created`:**

```json
{
  "id":     "urn:ivcap:job:<uuid>",
  "status": "pending",
  "links":  {
    "self":   "/1/services/.../jobs/urn:ivcap:job:<uuid>",
    "events": "/1/services/.../jobs/urn:ivcap:job:<uuid>/events"
  }
}
```

### Get job status

```
GET /1/services/{id}/jobs/{jobId}
```

**Response `200 OK`:**

```json
{
  "id":        "urn:ivcap:job:<uuid>",
  "name":      "my-fire-analysis-run-1",
  "status":    "succeeded",
  "service":   "urn:ivcap:service:<uuid>",
  "submittedAt": "2025-06-01T10:00:00Z",
  "finishedAt":  "2025-06-01T10:04:23Z",
  "products": [
    { "id": "urn:ivcap:artifact:<uuid>", "name": "out.png", "mime-type": "image/png" }
  ]
}
```

### Job status values

| Status | Meaning |
|---|---|
| `pending` | Job record created; awaiting scheduling |
| `scheduled` | Execution environment is starting |
| `executing` | Service is actively running |
| `succeeded` | Service completed successfully |
| `failed` | Service reported a failure |
| `error` | Platform error (infrastructure, timeout, etc.) |

### Get job output

```
GET /1/services/{id}/jobs/{jobId}/output
```

Returns the structured result payload for services that return JSON output
directly (as opposed to producing artifacts).

### Stream job events

```
GET /1/services/{id}/jobs/{jobId}/events
```

Returns a [Server-Sent Events](events.md) stream of real-time status updates.
The stream closes when the job reaches a terminal state.

### CLI equivalents

```bash
ivcap order create urn:ivcap:service:<uuid> region="Tasmania-North" threshold=0.05
ivcap order get urn:ivcap:job:<uuid>
ivcap order list
ivcap order watch urn:ivcap:job:<uuid>
```

---

## Worked example

```bash
# 1. Find the service
ivcap service list

# 2. Upload an input artifact
ivcap artifact upload background.png --name "background" --mime-type image/png
# → urn:ivcap:artifact:6a1c3f2e-...

# 3. Submit the job
curl -X POST https://api.example.ivcap.net/1/services/urn:ivcap:service:b14569f9-.../jobs \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-text-image-run",
    "parameters": [
      { "name": "msg",     "value": "Hello IVCAP" },
      { "name": "img-art", "value": "urn:ivcap:artifact:6a1c3f2e-..." }
    ]
  }'

# 4. Poll for completion
ivcap order get urn:ivcap:job:505c8573-...

# 5. Download the result artifact
ivcap artifact download urn:ivcap:artifact:6f390b51-... -f /tmp/out.png
```
