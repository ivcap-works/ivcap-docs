# Artifacts

An **artifact** is any binary or structured data blob stored in IVCAP — images, CSV files,
trained models, JSON documents, shapefiles, or any other file type. Every artifact gets a
stable, globally unique URN and is tracked with full provenance.

```
urn:ivcap:artifact:<uuid>
```

Artifacts are first-class entities in the [Data Fabric](data-fabric.md). Beyond the raw
bytes, every upload, download, and usage by a job is **also** automatically recorded as a
typed [Aspect](aspects-and-provenance.md) — a time-stamped metadata record — giving every
artifact a complete, queryable audit trail without any extra work from the caller.

---

## Uploading artifacts

IVCAP supports two upload modes depending on file size.

### Single-shot upload (≤ 16 MB)

```bash
# Step 1: create the artifact record
curl -X POST https://api.example.ivcap.net/1/artifacts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-dataset.csv", "mime-type": "text/csv"}'
# → { "id": "urn:ivcap:artifact:<uuid>", ... }

# Step 2: upload the content
curl -X PUT https://api.example.ivcap.net/1/artifacts/urn:ivcap:artifact:<uuid>/blob \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: text/csv" \
  --data-binary @my-dataset.csv
```

### Resumable upload — TUS protocol (up to 5 GB)

For large files use `PATCH` after creating the record. The [TUS protocol](https://tus.io/)
allows uploads to be paused and resumed without restarting from the beginning.

```bash
POST   /1/artifacts             # create the record
PATCH  /1/artifacts/{id}/blob   # TUS upload (pause/resume supported)
```

The `ivcap` CLI handles both modes transparently — it automatically chooses TUS for files
above the single-shot threshold.

### CLI shortcut

```bash
ivcap artifact upload my-dataset.csv \
    --name "my-dataset" \
    --mime-type text/csv
# → ID: urn:ivcap:artifact:<uuid>
```

---

## Listing and downloading artifacts

=== "CLI"

    ```bash
    # List all accessible artifacts
    ivcap artifact list

    # Get metadata for a specific artifact
    ivcap artifact get urn:ivcap:artifact:<uuid>

    # Download artifact content to a file
    ivcap artifact download urn:ivcap:artifact:<uuid> -f output.csv
    ```

=== "REST"

    ```bash
    GET /1/artifacts                          # list
    GET /1/artifacts/urn:ivcap:artifact:<uuid>       # metadata
    GET /1/artifacts/urn:ivcap:artifact:<uuid>/blob  # content
    ```

---

## Attaching metadata to an artifact

After uploading, you can attach any number of typed [Aspects](aspects-and-provenance.md)
to describe your artifact. This makes it discoverable by schema or content:

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

Query artifacts by this metadata:

```bash
GET /1/aspects?schema=urn:ivcap:schema:remote-sensing:scene.1
```

---

## Artifacts as job parameters

Artifacts are passed *by reference* between jobs — you pass the URN, not the raw bytes.
This keeps provenance chains intact and avoids copying large datasets:

```json
{
  "name": "input-data",
  "value": "urn:ivcap:artifact:6a1c3f2e-..."
}
```

Inside a running service container, the sidecar's **data proxy** resolves the URN to a
local file path. The service code reads it as a regular file without needing to handle
authentication or download logic itself.

---

## Artifact lifecycle and provenance

IVCAP automatically records provenance aspects for every artifact event:

| Event | Schema recorded | Content |
|---|---|---|
| Artifact uploaded | `urn:ivcap:schema:artifact-created.1` | Name, MIME type, size, uploader |
| Artifact used by a job | `urn:ivcap:schema:artifact-usedBy-order.1` | Artifact URN → Job URN |
| Artifact produced by a job | `urn:ivcap:schema:order-produced-artifact.1` | Job URN → Artifact URN |

Query the full lineage of any artifact:

```bash
# Which jobs consumed this artifact?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&schema=urn:ivcap:schema:artifact-usedBy-order.1

# Which job produced this artifact?
GET /1/aspects?entity=urn:ivcap:artifact:<uuid>&schema=urn:ivcap:schema:order-produced-artifact.1
```

---

## API reference summary

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/artifacts` | List accessible artifacts |
| `POST` | `/1/artifacts` | Create an artifact record |
| `GET` | `/1/artifacts/{id}` | Get artifact metadata |
| `GET` | `/1/artifacts/{id}/blob` | Download content |
| `PUT` | `/1/artifacts/{id}/blob` | Upload content (single-shot, ≤ 16 MB) |
| `PATCH` | `/1/artifacts/{id}/blob` | Upload via TUS (resumable, ≤ 5 GB) |

---

## Related concepts

- [Aspects and Provenance](aspects-and-provenance.md) — how artifact metadata and lineage is stored
- [Services and Jobs](services-and-jobs.md) — how artifacts flow through job inputs and outputs
- [The Data Fabric](data-fabric.md) — the unified store where artifacts and their metadata live
