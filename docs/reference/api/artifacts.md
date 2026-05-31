# Artifacts API

Artifacts are binary or structured data blobs stored in the platform — images,
CSV files, JSON results, trained models, NetCDF datasets, and so on. Each
artifact is identified by a `urn:ivcap:artifact:<uuid>` and is **immutable
once its content is uploaded**; subsequent versions are new artifacts.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/artifacts` | List accessible artifacts |
| `POST` | `/1/artifacts` | Create an artifact record |
| `GET` | `/1/artifacts/{id}` | Get artifact metadata |
| `GET` | `/1/artifacts/{id}/blob` | Download artifact content |
| `PUT` | `/1/artifacts/{id}/blob` | Upload content (single-shot, ≤ 16 MB) |
| `PATCH` | `/1/artifacts/{id}/blob` | Upload via TUS resumable protocol (≤ 5 GB) |

---

## List artifacts

```
GET /1/artifacts
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |
| `filter` | string | Filter expression on artifact name or status |

**Response `200 OK`:**

```json
{
  "artifacts": [
    {
      "id":     "urn:ivcap:artifact:6f390b51-...",
      "name":   "my-dataset.csv",
      "status": "ready",
      "links":  { "self": "...", "describedBy": { "href": "...", "type": "..." } }
    }
  ],
  "links": { "self": "...", "next": "..." }
}
```

**Artifact status values:**

| Status | Meaning |
|---|---|
| `pending` | Record created; awaiting content upload |
| `building` | Content is being processed or indexed |
| `ready` | Content is available for download |
| `error` | Upload or processing failed |

---

## Create an artifact record

```
POST /1/artifacts
```

**Request body:**

```json
{
  "name":      "my-dataset.csv",
  "mime-type": "text/csv",
  "policy":    "urn:ivcap:policy:public"
}
```

**Response `201 Created`** — returns the artifact metadata including its `id`
and upload instructions.

```json
{
  "id":     "urn:ivcap:artifact:<uuid>",
  "status": "pending",
  "links": {
    "self":   "/1/artifacts/urn:ivcap:artifact:<uuid>",
    "upload": "/1/artifacts/urn:ivcap:artifact:<uuid>/blob"
  }
}
```

---

## Get artifact metadata

```
GET /1/artifacts/{id}
```

**Response `200 OK`** — `ArtifactStatusRT` object:

```json
{
  "id":        "urn:ivcap:artifact:<uuid>",
  "name":      "my-dataset.csv",
  "mime-type": "text/csv",
  "size":      2376,
  "status":    "ready",
  "account":   { "id": "urn:ivcap:account:<uuid>", "links": { ... } },
  "links":     { "self": "...", "data": "..." }
}
```

---

## Upload artifact content

### Single-shot upload (≤ 16 MB)

```
PUT /1/artifacts/{id}/blob
```

**Request headers:**

| Header | Description |
|---|---|
| `Content-Type` | MIME type of the content (e.g. `text/csv`, `image/png`) |
| `Content-Length` | Size of the content in bytes |

**Response `204 No Content`** on success.

### Resumable upload — TUS protocol (≤ 5 GB)

```
PATCH /1/artifacts/{id}/blob
```

IVCAP supports the [TUS resumable upload protocol](https://tus.io) for large
files. TUS allows uploads to be paused and resumed without re-sending data.

**Required TUS headers:**

| Header | Example value | Description |
|---|---|---|
| `Tus-Resumable` | `1.0.0` | TUS protocol version |
| `Upload-Offset` | `0` | Byte offset to resume from |
| `Content-Type` | `application/offset+octet-stream` | Required by TUS |
| `Content-Length` | `2376` | Number of bytes in this chunk |

The `ivcap` CLI and Python SDK handle TUS transparently — use them for files
over 16 MB.

---

## Download artifact content

```
GET /1/artifacts/{id}/blob
```

Returns the raw artifact bytes with the artifact's registered `Content-Type`.
Supports HTTP range requests for partial downloads.

---

## Full example: upload and use an artifact

```bash
# Step 1: Create the artifact record
curl -X POST https://api.example.ivcap.net/1/artifacts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-dataset.csv", "mime-type": "text/csv"}'
# → { "id": "urn:ivcap:artifact:<uuid>", "status": "pending", ... }

# Step 2: Upload the content
curl -X PUT https://api.example.ivcap.net/1/artifacts/urn:ivcap:artifact:<uuid>/blob \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: text/csv" \
  --data-binary @my-dataset.csv

# Step 3: Use as a job parameter
# { "name": "input-data", "value": "urn:ivcap:artifact:<uuid>" }
```

**CLI equivalent:**

```bash
ivcap artifact upload my-dataset.csv --name "my-dataset" --mime-type text/csv
ivcap artifact list
ivcap artifact get urn:ivcap:artifact:<uuid>
ivcap artifact download urn:ivcap:artifact:<uuid> -f output.csv
```

---

## Attaching metadata to an artifact

After upload you can add any number of typed [Aspects](aspects.md) to describe
your artifact and make it discoverable by schema:

```json
POST /1/aspects

{
  "entity": "urn:ivcap:artifact:<uuid>",
  "schema": "urn:ivcap:schema:remote-sensing:scene.1",
  "content": {
    "sensor":            "Sentinel-2",
    "acquisition-date":  "2025-04-15",
    "cloud-cover-pct":   3.2
  }
}
```

Query by schema to find all matching artifacts:

```
GET /1/aspects?schema=urn:ivcap:schema:remote-sensing:scene.1
```
