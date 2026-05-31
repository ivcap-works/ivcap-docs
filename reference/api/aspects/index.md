# Aspects API

Aspects are **typed, time-stamped, append-only metadata records** attached to
any entity URN — services, jobs, artifacts, or other aspects. They are the
metadata currency of the platform and the foundation of
[provenance tracking](../../concepts/aspects-and-provenance.md).

Key properties:

- Aspects are **never deleted** — only *retracted* (given a `validTo` timestamp).
- Every change is recorded as a new aspect, creating an immutable audit trail.
- Point-in-time queries let you reconstruct the state of any entity at any
  moment in the past.

The `/1/metadata` path is an alias for `/1/aspects` and accepts the same
parameters.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/aspects` | Search aspects by entity, schema, or content |
| `GET` | `/1/aspects/{id}` | Get a specific aspect by URN |
| `POST` | `/1/aspects` | Create (assert) a new aspect |
| `PUT` | `/1/aspects/{id}` | Update an aspect (retracts old, asserts new) |
| `DELETE` | `/1/aspects/{id}` | Retract an aspect (`validTo = now`) |

---

## Search aspects

```
GET /1/aspects
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `entity` | string | Filter by entity URN |
| `schema` | string | Filter by schema URN |
| `at-time` | ISO 8601 datetime | Return aspects valid at this point in time |
| `filter` | string | Additional filter expression on content fields |
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |

**Examples:**

```bash
# All current aspects on an artifact
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>

# All aspects of a given schema across all entities
GET /1/aspects?schema=urn:ivcap:schema:remote-sensing:scene.1

# Historical: what was known about this artifact on 1 June 2025?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&at-time=2025-06-01T00:00:00Z
```

**Response `200 OK`:**

```json
{
  "aspects": [
    {
      "id":        "urn:ivcap:aspect:<uuid>",
      "entity":    "urn:ivcap:artifact:<uuid>",
      "schema":    "urn:ivcap:schema:remote-sensing:scene.1",
      "assertedAt": "2025-06-01T10:05:00Z",
      "validTo":   null,
      "content": {
        "sensor":           "Sentinel-2",
        "acquisition-date": "2025-04-15",
        "cloud-cover-pct":  3.2
      },
      "links": { "self": "..." }
    }
  ],
  "links": { "self": "...", "next": "..." }
}
```

---

## Get aspect

```
GET /1/aspects/{id}
```

Returns the full aspect record including content.

---

## Create an aspect

```
POST /1/aspects
```

**Request body:**

```json
{
  "entity":  "urn:ivcap:artifact:<uuid>",
  "schema":  "urn:ivcap:schema:my-domain:classification.1",
  "content": {
    "class":         "fire-risk",
    "confidence":    0.92,
    "model-version": "v3.1"
  }
}
```

The `$schema` field in `content` is optional — if omitted, the server injects
it from the `schema` parameter.

**Response `201 Created`** — returns the new aspect record with its assigned
`urn:ivcap:aspect:<uuid>`.

---

## Update an aspect

```
PUT /1/aspects/{id}
```

Updating an aspect is a two-step atomic operation:

1. The existing aspect is **retracted** (`validTo` is set to `now`).
2. A new aspect is **asserted** with the updated content.

This preserves the full history — the previous value is always queryable via
`?at-time=`.

---

## Retract an aspect

```
DELETE /1/aspects/{id}
```

Sets `validTo = now` on the aspect. The record is not deleted and remains
queryable via `?at-time=`.

---

## Platform provenance aspects

IVCAP automatically records provenance aspects for every significant event:

| Schema URN | Recorded when |
|---|---|
| `urn:ivcap:schema:job-placed.1` | Job submitted (service, parameters, submitter) |
| `urn:ivcap:schema:job.2` | Job status change (executing) |
| `urn:ivcap:schema:artifact-usedBy-order.1` | Artifact consumed by a job |
| `urn:ivcap:schema:order-produced-artifact.1` | Artifact produced by a job |
| `urn:ivcap:schema:job-finished.1` | Job reached terminal state |

**Querying the provenance chain:**

```bash
# What jobs produced this artifact?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&schema=urn:ivcap:schema:artifact-usedBy-order.1

# What artifacts did this job produce?
GET /1/aspects?entity=urn:ivcap:job:<uuid>&schema=urn:ivcap:schema:order-produced-artifact.1

# Full history of a job at a specific point in time
GET /1/aspects?entity=urn:ivcap:job:<uuid>&at-time=2025-06-01T12:00:00Z
```

---

## CLI equivalents

```bash
ivcap aspect list --entity urn:ivcap:artifact:<uuid>
ivcap aspect list --schema urn:ivcap:schema:my-domain:classification.1
ivcap aspect list --entity urn:ivcap:artifact:<uuid> --at-time 2025-06-01T00:00:00Z
ivcap aspect get urn:ivcap:aspect:<uuid>
```
