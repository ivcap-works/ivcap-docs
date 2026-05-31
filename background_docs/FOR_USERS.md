<!-- SOURCE: ivcap-works/ivcap-core — FOR_USERS.md — copied 2026-05-30 -->
<!-- This file is a snapshot of a private document. Content is public. -->
<!-- To update: copy the latest FOR_USERS.md from ivcap-core here, then ask the agent to sync affected pages. -->

# IVCAP – API User Guide

> This document is aimed at **users and application developers** interacting with an IVCAP deployment via its public REST API. For the full internal architecture, see [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## Table of Contents

1. [What IVCAP Does for You](#1-what-ivcap-does-for-you)
2. [Key Concepts](#2-key-concepts)
3. [Getting Started](#3-getting-started)
   - 3.1 [Finding the API](#31-finding-the-api)
   - 3.2 [Authentication](#32-authentication)
   - 3.3 [The ivcap CLI](#33-the-ivcap-cli)
   - 3.4 [SDKs](#34-sdks)
4. [Typical Workflow](#4-typical-workflow)
5. [API Reference by Resource](#5-api-reference-by-resource)
   - 5.1 [Services](#51-services)
   - 5.2 [Jobs (Orders)](#52-jobs-orders)
   - 5.3 [Artifacts](#53-artifacts)
   - 5.4 [Aspects (Metadata and Provenance)](#54-aspects-metadata-and-provenance)
   - 5.5 [Queues](#55-queues)
   - 5.6 [Secrets](#56-secrets)
   - 5.7 [Packages (Docker Images)](#57-packages-docker-images)
6. [Worked Example: Running a Service](#6-worked-example-running-a-service)
7. [Uploading and Managing Artifacts](#7-uploading-and-managing-artifacts)
8. [Tracking Provenance with Aspects](#8-tracking-provenance-with-aspects)
9. [Live Job Events (Server-Sent Events)](#9-live-job-events-server-sent-events)
10. [URN Reference](#10-urn-reference)
11. [API Gateway Internals (for Integrators)](#11-api-gateway-internals-for-integrators)

---

## 1. What IVCAP Does for You

IVCAP provides a **managed, provenance-aware execution platform for analytic services**. At its core, it lets you:

| Capability | How |
|---|---|
| **Run analytic services** | POST a job to a registered service with your parameters |
| **Store and retrieve data** | Upload artifacts (any file type); download them by URN |
| **Record and query metadata** | Attach typed metadata (aspects) to any entity; query by entity, schema, or content |
| **Track provenance** | Every job, artifact, and metadata record is immutably logged with timestamps and authorship |
| **Communicate asynchronously** | Create message queues; enqueue and dequeue messages between services |
| **Manage secrets** | Store and retrieve API keys and credentials securely |

The entire platform is accessed through a single REST API endpoint — the **API Gateway**. There is no proprietary SDK required to use it.

---

## 2. Key Concepts

Before diving into the API, it helps to understand the four core entities you will work with:

| Entity | URN pattern | What it is |
|---|---|---|
| **Service** | `urn:ivcap:service:<uuid>` | A registered analytic capability with defined parameters and an execution environment |
| **Job** | `urn:ivcap:job:<uuid>` | A single execution of a service — created by submitting a request with parameters |
| **Artifact** | `urn:ivcap:artifact:<uuid>` | Any binary or structured data blob (image, CSV, model, etc.) stored in the platform |
| **Aspect** | `urn:ivcap:aspect:<uuid>` | A typed, time-stamped piece of metadata attached to any entity URN |

Everything in IVCAP — services, jobs, artifacts, even job state changes — is described by **Aspects** in the **Datafabric**, the platform's universal, append-only information store. Aspects are the metadata currency of the platform.

> **Note on terminology:** Some parts of the API (and the older CLI) refer to *orders* instead of *jobs*. These mean the same thing. The platform is converging on *job* as the canonical term.

---

## 3. Getting Started

### 3.1 Finding the API

Every IVCAP deployment serves its live OpenAPI 3 specification at:

```
GET <base-url>/1/openapi/openapi3.json
```

For example, on a local Minikube deployment:

```bash
curl -s http://ivcap.minikube/1/openapi/openapi3.yaml | head -20
```

On a cloud deployment:

```
https://api.<your-deployment>.ivcap.net/1/openapi/openapi3.json
```

Import this URL into any OpenAPI-compatible tool (Swagger UI, Insomnia, Postman, etc.) to explore the full API interactively.

### 3.2 Authentication

All API calls (except the OpenAPI spec endpoint) require a **JWT Bearer token**. Obtain one from the identity provider listed in the deployment's auth info document:

```
GET <base-url>/1/authinfo.yaml
```

This document lists the configured identity providers and their endpoints. With Auth0 (the default):

1. Complete the device-authorisation flow (the CLI does this automatically).
2. Include the obtained token in every request:

```
Authorization: Bearer <your-jwt-token>
```

Tokens have an expiry time. Refresh using the identity provider's refresh token flow, or re-authenticate.

### 3.3 The ivcap CLI

The easiest way to interact with IVCAP is the `ivcap` CLI tool, available from the [GitHub releases page](https://github.com/ivcap-works/ivcap-cli/releases/latest).

**Setup:**

```bash
# Create a context for your deployment
ivcap context create minikube http://ivcap.minikube

# Login (opens browser / QR code for device authorisation)
ivcap context login

# Verify login
ivcap context get
```

The CLI wraps the REST API and handles token refresh automatically.

### 3.4 SDKs

Language SDKs are available for:

- **Python:** [ivcap-sdk-python](https://github.com/ivcap-works/ivcap-sdk-python) — suitable for Jupyter notebooks, data pipelines, and service authors.
- **Go:** available as part of `ivcap-core` for service authors writing services in Go.

Both SDKs wrap the same REST API documented here.

---

## 4. Typical Workflow

```
1. List available services       GET /1/services
2. Inspect a service             GET /1/services/{id}
3. Upload input data (optional)  POST /1/artifacts  (then PUT blob)
4. Submit a job                  POST /1/services/{id}/jobs
5. Poll for completion           GET /1/services/{id}/jobs/{jobId}
6. Retrieve results              GET /1/services/{id}/jobs/{jobId}/output
7. Download result artifacts     GET /1/artifacts/{id}/blob
```

Steps 3 and 7 are only needed when your service takes or produces binary data. Services that produce only structured results (aspects) skip step 7.

---

## 5. API Reference by Resource

All paths are prefixed with `/1/`. Authentication via `Authorization: Bearer <token>` is required on all endpoints unless stated otherwise.

### 5.1 Services

Analytic capabilities registered on the platform.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/services` | List all accessible services (`?limit=`, `?page=`, `?filter=`) |
| `GET` | `/1/services/{id}` | Get full details of a service (parameters, workflow definition) |
| `POST` | `/1/services` | Register a new service (provider role required) |
| `PUT` | `/1/services/{id}` | Update an existing service definition |
| `DELETE` | `/1/services/{id}` | Remove a service registration |

**Service definition structure** (request body for POST/PUT):

```json
{
  "name": "My Analysis Service",
  "description": "Runs fire risk analysis for a given region.",
  "parameters": [
    { "name": "region", "label": "Region Name", "type": "string" },
    { "name": "threshold", "label": "Rainfall threshold", "type": "float", "unit": "m" },
    { "name": "input-data", "label": "Input dataset", "type": "artifact" }
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

Parameter types supported: `string`, `int`, `float`, `bool`, `artifact` (an `urn:ivcap:artifact:...` reference).

**CLI equivalents:**

```bash
ivcap service list
ivcap service get urn:ivcap:service:<uuid>
ivcap service update --create urn:ivcap:service:<uuid> -f service.yaml
```

### 5.2 Jobs (Orders)

A job is a single execution of a service.

| Method | Path | Description |
|---|---|---|
| `POST` | `/1/services/{id}/jobs` | Create and submit a job |
| `GET` | `/1/services/{id}/jobs` | List jobs for a service |
| `GET` | `/1/services/{id}/jobs/{jobId}` | Get job status and metadata |
| `GET` | `/1/services/{id}/jobs/{jobId}/output` | Get the job result payload |
| `GET` | `/1/services/{id}/jobs/{jobId}/events` | Stream live job events (SSE) |

**Submitting a job:**

```json
POST /1/services/urn:ivcap:service:<uuid>/jobs

{
  "name": "my-fire-analysis-run-1",
  "parameters": [
    { "name": "region",    "value": "Tasmania-North" },
    { "name": "threshold", "value": "0.05" },
    { "name": "input-data","value": "urn:ivcap:artifact:<uuid>" }
  ]
}
```

**Response:**

```json
{
  "id":     "urn:ivcap:job:<uuid>",
  "status": "pending",
  "links":  { "self": "/1/services/.../jobs/urn:ivcap:job:<uuid>" }
}
```

**Job status values:**

| Status | Meaning |
|---|---|
| `pending` | Job record created; awaiting scheduling |
| `scheduled` | Execution environment is starting |
| `executing` | Service is actively running |
| `succeeded` | Service completed successfully |
| `failed` | Service reported a failure |
| `error` | Platform error (infrastructure, timeout, etc.) |

**CLI equivalents:**

```bash
ivcap order create urn:ivcap:service:<uuid> region="Tasmania-North" threshold=0.05
ivcap order get urn:ivcap:job:<uuid>
ivcap order list
```

### 5.3 Artifacts

Binary or structured data blobs stored in the platform.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/artifacts` | List accessible artifacts |
| `POST` | `/1/artifacts` | Create an artifact record (returns upload URL) |
| `GET` | `/1/artifacts/{id}` | Get artifact metadata |
| `GET` | `/1/artifacts/{id}/blob` | Download artifact content |
| `PUT` | `/1/artifacts/{id}/blob` | Upload artifact content (single-shot, up to 16 MB) |
| `PATCH` | `/1/artifacts/{id}/blob` | Upload via TUS resumable protocol (up to 5 GB) |

**Uploading a file:**

```bash
# Step 1: Create the artifact record
curl -X POST https://api.example.ivcap.net/1/artifacts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-dataset.csv", "mime-type": "text/csv"}'
# → returns { "id": "urn:ivcap:artifact:<uuid>", ... }

# Step 2: Upload the content
curl -X PUT https://api.example.ivcap.net/1/artifacts/urn:ivcap:artifact:<uuid>/blob \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: text/csv" \
  --data-binary @my-dataset.csv
```

**CLI equivalents:**

```bash
ivcap artifact upload my-dataset.csv --name "my-dataset" --mime-type text/csv
ivcap artifact list
ivcap artifact get urn:ivcap:artifact:<uuid>
ivcap artifact download urn:ivcap:artifact:<uuid> -f output.csv
```

### 5.4 Aspects (Metadata and Provenance)

Aspects are typed, time-stamped metadata records attached to any entity URN.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/aspects` | Search aspects (`?entity=`, `?schema=`, `?at-time=`, `?filter=`) |
| `GET` | `/1/aspects/{id}` | Get a specific aspect by its URN |
| `POST` | `/1/aspects` | Create (assert) a new aspect |
| `PUT` | `/1/aspects/{id}` | Update an aspect (retracts old, creates new) |
| `DELETE` | `/1/aspects/{id}` | Retract an aspect (`validTo = now`) |

**Creating an aspect:**

```json
POST /1/aspects

{
  "entity": "urn:ivcap:artifact:<uuid>",
  "schema": "urn:ivcap:schema:my-domain:classification.1",
  "content": {
    "class": "fire-risk",
    "confidence": 0.92,
    "model-version": "v3.1"
  }
}
```

**Querying aspects:**

```bash
# All current aspects on an artifact
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>

# Aspects of a specific type on any entity
GET /1/aspects?schema=urn:ivcap:schema:my-domain:classification.1

# Historical query: what was known about this artifact at a point in time?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&at-time=2025-06-01T00:00:00Z
```

**Important:** Aspects are append-only. The platform never deletes history. Every change is recorded as a new aspect with a timestamp. This is the foundation of IVCAP's provenance model.

**CLI equivalents:**

```bash
ivcap aspect list --entity urn:ivcap:artifact:<uuid>
ivcap aspect get urn:ivcap:aspect:<uuid>
```

### 5.5 Queues

Message queues for asynchronous communication between services or pipeline stages.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/queues` | List queues |
| `POST` | `/1/queues` | Create a queue |
| `GET` | `/1/queues/{id}` | Get queue details |
| `POST` | `/1/queues/{id}/messages` | Enqueue a message |
| `GET` | `/1/queues/{id}/messages` | Dequeue message(s) |
| `DELETE` | `/1/queues/{id}` | Delete a queue |

Queues are useful for pipeline patterns where one service produces work items that another service consumes asynchronously.

### 5.6 Secrets

Manage secrets (API keys, credentials) that service containers can securely retrieve at runtime.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/secrets` | List secret names (values never returned via API) |
| `PUT` | `/1/secrets/{name}` | Create or update a secret value |
| `DELETE` | `/1/secrets/{name}` | Remove a secret |

**CLI equivalents:**

```bash
ivcap secret set MY_API_KEY -f ./api-key.txt
ivcap secret list
```

Secrets are injected into service containers via the sidecar's `secret_proxy` — service code retrieves them at runtime using the service SDK, not via the public API.

### 5.7 Packages (Docker Images)

Manage Docker container images in the platform's account-scoped registry.

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/packages/list` | List available images for your account |
| `DELETE` | `/1/packages/remove?tag={tag}` | Remove an image by tag |

Images are pushed to the registry via standard `docker push` using appropriate registry credentials — the API is for listing and cleanup only.

---

## 6. Worked Example: Running a Service

This example uses the `ivcap` CLI but every step maps directly to a REST API call.

**Step 1: Find the service**

```bash
$ ivcap service list
+----+---------------------+-----------------------------------+
| ID | NAME                | ACCOUNT                           |
+----+---------------------+-----------------------------------+
| @1 | Gradient Text Image | urn:ivcap:account:45a06508-...    |
+----+---------------------+-----------------------------------+

$ ivcap service get @1
          ID  urn:ivcap:service:b14569f9-...
        Name  Gradient Text Image
 Description  Creates an image with a customizable text.
  Parameters  ┌──────────┬──────────────────────┬──────────┐
              │ NAME     │ DESCRIPTION          │ TYPE     │
              ├──────────┼──────────────────────┼──────────┤
              │ msg      │ Message to display   │ string   │
              ├──────────┼──────────────────────┼──────────┤
              │ img-art  │ Background image     │ artifact │
              └──────────┴──────────────────────┴──────────┘
```

**Step 2: Upload an input artifact (if needed)**

```bash
$ ivcap artifact upload background.png --name "background" --mime-type image/png
ID: urn:ivcap:artifact:6a1c3f2e-...
```

**Step 3: Submit the job**

```bash
$ ivcap order create @1 \
    msg="Hello IVCAP" \
    img-art=urn:ivcap:artifact:6a1c3f2e-...

Order 'urn:ivcap:job:505c8573-...' with status 'pending' submitted.
```

Equivalent REST call:

```bash
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
```

**Step 4: Poll for completion**

```bash
$ ivcap order get urn:ivcap:job:505c8573-...
       ID  urn:ivcap:job:505c8573-...
     Name  my-text-image-run
   Status  succeeded
  Service  Gradient Text Image
 Products  ┌────┬──────────┬───────────┐
           │ @1 │ out.png  │ image/png │
           └────┴──────────┴───────────┘
 Metadata  ┌────┬─────────────────────────────────────────────┐
           │ @2 │ urn:ivcap:schema:order-finished.1           │
           │ @3 │ urn:ivcap:schema:order-placed.1             │
           │ @4 │ urn:ivcap:schema:order-produced-artifact.1  │
           └────┴─────────────────────────────────────────────┘
```

**Step 5: Download the result**

```bash
$ ivcap artifact download urn:ivcap:artifact:6f390b51-... -f /tmp/out.png
... downloading file 100% [==============================]

$ file /tmp/out.png
/tmp/out.png: PNG image data, 1024 x 512, 8-bit/color RGB, non-interlaced
```

---

## 7. Uploading and Managing Artifacts

Artifacts support two upload modes:

**Single-shot (≤ 16 MB):**

```bash
POST /1/artifacts          # create the record → returns { "id": "urn:ivcap:artifact:..." }
PUT  /1/artifacts/{id}/blob  # upload bytes
```

**Resumable / large files (≤ 5 GB) — TUS protocol:**

```bash
POST   /1/artifacts             # create the record
PATCH  /1/artifacts/{id}/blob   # TUS upload (supports pause/resume)
```

The `ivcap` CLI handles both modes transparently.

**Attaching custom metadata to an artifact:**

After upload, add any number of typed aspects to describe your artifact:

```json
POST /1/aspects
{
  "entity": "urn:ivcap:artifact:<uuid>",
  "schema": "urn:ivcap:schema:remote-sensing:scene.1",
  "content": {
    "sensor": "Sentinel-2",
    "acquisition-date": "2025-04-15",
    "cloud-cover-pct": 3.2
  }
}
```

These aspects make the artifact discoverable via `GET /1/aspects?schema=urn:ivcap:schema:remote-sensing:scene.1`.

---

## 8. Tracking Provenance with Aspects

IVCAP automatically records provenance aspects for every significant event:

| When | Schema recorded | Content |
|---|---|---|
| Job submitted | `urn:ivcap:schema:order-placed.1` | Service, parameters, submitter |
| Job started | `urn:ivcap:schema.job.2` | Status `executing`, timestamp |
| Artifact consumed | `urn:ivcap:schema:artifact-usedBy-order.1` | Artifact URN → Job URN |
| Artifact produced | `urn:ivcap:schema:order-produced-artifact.1` | Job URN → Artifact URN |
| Job completed | `urn:ivcap:schema:order-finished.1` | Final status, timestamp |

You can query the full provenance chain for any artifact:

```bash
# What jobs produced this artifact?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&schema=urn:ivcap:schema:artifact-usedBy-order.1

# What did this job produce?
GET /1/aspects?entity=urn:ivcap:job:<uuid>&schema=urn:ivcap:schema:order-produced-artifact.1
```

Because aspects are **never deleted** (only retracted with a `validTo` timestamp), you can query the state of any entity at any point in the past:

```bash
GET /1/aspects?entity=urn:ivcap:job:<uuid>&at-time=2025-06-01T12:00:00Z
```

---

## 9. Live Job Events (Server-Sent Events)

To stream real-time updates while a job is running:

```bash
curl -N -H "Authorization: Bearer <token>" \
  https://api.example.ivcap.net/1/services/<svcId>/jobs/<jobId>/events
```

Events are emitted as [CloudEvents](https://cloudevents.io/) JSON over Server-Sent Events (SSE):

```
event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"executing","timestamp":"..."}

event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"succeeded","timestamp":"..."}
```

The SSE stream closes when the job reaches a terminal state (`succeeded`, `failed`, or `error`).

---

## 10. URN Reference

All IVCAP identifiers are **URNs** of the form `urn:ivcap:<type>:<uuid>`. They are stable, globally unique, and can be used across API calls and deployments.

| What | URN pattern | Example |
|---|---|---|
| Service | `urn:ivcap:service:<uuid>` | `urn:ivcap:service:b14569f9-81bc-5ac2-af1a-9b05ee987c1b` |
| Job / Order | `urn:ivcap:job:<uuid>` | `urn:ivcap:job:505c8573-3c1a-4f2d-9e7b-1a2b3c4d5e6f` |
| Artifact | `urn:ivcap:artifact:<uuid>` | `urn:ivcap:artifact:6f390b51-0001-4a2b-9c3d-5e6f7a8b9c0d` |
| Aspect | `urn:ivcap:aspect:<uuid>` | `urn:ivcap:aspect:1a2b3c4d-...` |
| Schema | `urn:ivcap:schema.<name>.<v>` | `urn:ivcap:schema:order-placed.1` |
| Account | `urn:ivcap:account:<uuid>` | `urn:ivcap:account:45a06508-...` |
| Queue | `urn:ivcap:queue:<uuid>` | `urn:ivcap:queue:7f8a9b0c-...` |

The `ivcap` CLI accepts short-form references like `@1`, `@2`, etc. in commands as convenience aliases for recently seen URNs.

---

## 11. API Gateway Internals (for Integrators)

This section is for teams building integrations that talk directly to the REST API rather than through the CLI.

**Base URL structure:**

```
<scheme>://<host>/1/<resource>
```

The `/1/` prefix indicates API version 1. All public resources are under this prefix.

**Content negotiation:**

- Request bodies: `application/json`
- Response bodies: `application/json` (or `application/vnd.api+json` for list responses following JSON:API conventions)
- Artifact blob downloads: content-type matches the artifact's registered MIME type

**Pagination:**

List endpoints (`GET /1/services`, `GET /1/artifacts`, `GET /1/aspects`, etc.) support:

- `?limit=N` — maximum number of results per page (default varies by resource)
- `?page=<cursor>` — opaque cursor returned in `links.next` of the previous response

**Filtering:**

- `?filter=<expression>` — filter expression on resource fields
- `?schema=<urn>` — filter aspects by schema URN (aspects endpoint)
- `?entity=<urn>` — filter aspects by entity URN (aspects endpoint)
- `?at-time=<ISO8601>` — historical query for aspects valid at a given timestamp

**Error responses:**

All errors follow a consistent structure:

```json
{
  "id":      "urn:ivcap:error:...",
  "status":  404,
  "code":    "not-found",
  "detail":  "No service with ID urn:ivcap:service:xxx",
  "links":   { "about": "..." }
}
```

**The live API specification** at `GET /1/openapi/openapi3.json` is always authoritative and generated directly from the service code. When in doubt, consult it.
