# Work with Artifacts

An **artifact** is any binary or structured data stored in IVCAP — CSV files, images,
trained models, shapefiles, or any other file format. Artifacts are first-class entities:
every upload, download, and usage by a job is automatically tracked with full provenance.

```
urn:ivcap:artifact:<uuid>
```

---

## Setup

```python
from ivcap_client.ivcap import IVCAP

ivcap = IVCAP()   # reads IVCAP_URL, IVCAP_JWT, IVCAP_ACCOUNT_ID from environment
```

---

## Upload input data

If a service requires an `artifact`-type parameter, upload the data first to get a URN,
then pass that URN when submitting the job.

### Upload from a file

=== "CLI"

    ```bash
    ivcap artifact upload my-dataset.csv \
        --name "my-dataset" \
        --mime-type text/csv
    ```

    ```
    Uploading my-dataset.csv ...
       100% [==============================]
    ID: urn:ivcap:artifact:6a1c3f2e-0012-4b7a-9c3d-5e6f7a8b9c0d
    ```

=== "Python"

    ```python
    artifact = ivcap.upload_artifact(
        name="my-dataset",
        file_path="/path/to/my-dataset.csv",
    )
    print(f"Artifact URN: {artifact.id}")
    print(f"Name: {artifact.name}, Size: {artifact.size}, Type: {artifact.mime_type}")
    ```

    The SDK auto-detects the MIME type from the file extension. To override it:

    ```python
    artifact = ivcap.upload_artifact(
        name="sensor-data",
        file_path="/path/to/data.csv",
        policy="urn:ivcap:policy:ivcap.open.artifact",
    )
    ```

### Upload a pandas DataFrame

Serialise the DataFrame to CSV in memory and upload using `io_stream`:

```python
import io
import pandas as pd
from ivcap_client.ivcap import IVCAP

ivcap = IVCAP()

# ── 1. Prepare data ───────────────────────────────────────────────────────────
df = pd.DataFrame({
    "site_id":     ["S01", "S02", "S03", "S04"],
    "latitude":    [-42.88, -43.10, -41.75, -42.50],
    "longitude":   [147.32, 146.95, 148.12, 147.80],
    "temperature": [22.1, 19.4, 25.8, 21.3],    # °C
    "humidity":    [0.61, 0.78, 0.45, 0.55],
    "rainfall_mm": [12.4, 18.9, 5.2, 9.7],
})

# Serialise to CSV bytes (portable, non-Python-specific format)
buf = io.BytesIO()
df.to_csv(buf, index=False)
csv_bytes = buf.getvalue()

# ── 2. Upload to IVCAP ────────────────────────────────────────────────────────
artifact = ivcap.upload_artifact(
    name="sensor-readings-june-2025",
    io_stream=io.BytesIO(csv_bytes),
    content_type="text/csv",
    content_size=len(csv_bytes),
)
print(f"Artifact URN: {artifact.id}")
```

### Upload a NumPy array

Use `numpy.savetxt` to produce portable CSV from a NumPy array:

```python
import io
import numpy as np
from ivcap_client.ivcap import IVCAP

ivcap = IVCAP()

# ── 1. Prepare a NumPy array ──────────────────────────────────────────────────
# Columns: site_id, temperature (°C), humidity (0–1), rainfall (mm)
data = np.array([
    [1, 22.1, 0.61, 12.4],
    [2, 19.4, 0.78, 18.9],
    [3, 25.8, 0.45,  5.2],
    [4, 21.3, 0.55,  9.7],
])
buf = io.BytesIO()
np.savetxt(buf, data, delimiter=",",
           header="site_id,temperature,humidity,rainfall_mm",
           comments="", fmt="%.4f")
csv_bytes = buf.getvalue()

# ── 2. Upload to IVCAP ────────────────────────────────────────────────────────
artifact = ivcap.upload_artifact(
    name="numpy-sensor-readings",
    io_stream=io.BytesIO(csv_bytes),
    content_type="text/csv",
    content_size=len(csv_bytes),
)
print(f"Uploaded: {artifact.id}")
```

### Common MIME types

| File type | `content_type` |
|---|---|
| CSV | `text/csv` |
| JSON | `application/json` |
| PNG | `image/png` |
| TIFF / GeoTIFF | `image/tiff` |
| NetCDF | `application/x-netcdf` |
| Shapefile (ZIP) | `application/zip` |
| Parquet | `application/vnd.apache.parquet` |

### Check for deduplication

Before re-uploading, check if an identical file was already uploaded:

```python
existing = ivcap.artifact_for_file("/path/to/file.csv")
if existing:
    print(f"Already uploaded: {existing.id}")
    artifact = existing
else:
    artifact = ivcap.upload_artifact(name="my-data", file_path="/path/to/file.csv")
    print(f"Uploaded: {artifact.id}")
```

---

## List your artifacts

=== "CLI"

    ```bash
    ivcap artifact list --limit 20
    ```

=== "Python"

    ```python
    for artifact in ivcap.list_artifacts(limit=20):
        print(artifact)
    ```

---

## Use an artifact as a job input

Pass the artifact URN as an `artifact`-type parameter value:

=== "CLI"

    ```bash
    ivcap order create urn:ivcap:service:<uuid> \
        region="Tasmania-North" \
        input-data=urn:ivcap:artifact:6a1c3f2e-...
    ```

=== "Python"

    ```python
    import time
    from ivcap_client import JobStatus

    svc = ivcap.get_service_by_name("Fire Risk Analysis")
    Model = svc.request_model

    job = svc.request_job(Model(
        region="Tasmania-North",
        threshold=0.05,
        input_data=artifact.id,          # ← pass the artifact URN
    ))

    while not job.finished:
        time.sleep(5)
        job.refresh()
    print(f"Done: {job.status()}")
    ```

!!! note "How the platform resolves artifact URNs"
    When the service container starts, IVCAP's sidecar data-proxy resolves the artifact
    URN to a local file path. The service reads it as a regular file — no auth or
    download logic required inside the service code.

---

## Chain jobs: one job's output as another job's input

```python
import time
from ivcap_client.ivcap import IVCAP
from ivcap_client import JobStatus

ivcap = IVCAP()

def run_and_wait(svc_name, **params):
    """Submit a job and block until terminal state."""
    svc = ivcap.get_service_by_name(svc_name)
    Model = svc.request_model
    job = svc.request_job(Model(**params))
    print(f"Submitted {job.id}")
    while not job.finished:
        time.sleep(5)
        job.refresh()
    if job.status() != JobStatus.SUCCEEDED:
        raise RuntimeError(f"Job {job.id} failed: {job.status()}")
    return job

# Step 1 — upload sensor CSV and pre-process it
artifact = ivcap.upload_artifact(
    name="sensor-readings",
    io_stream=io.BytesIO(csv_bytes),
    content_type="text/csv",
    content_size=len(csv_bytes),
)

job_a = run_and_wait("Sensor Pre-Processor", input_data=artifact.id)
print(f"Intermediate result: {job_a.result}")

# Step 2 — pass the first job's output artifact into the next job
preprocessed_id = job_a.result["artifact_id"]
job_b = run_and_wait("Fire Risk Analysis", input_data=preprocessed_id, threshold=0.05)
print(f"Pipeline complete: {job_b.result}")
```

---

## Attach custom metadata to an artifact

```python
ivcap.add_aspect(
    entity=artifact.id,
    schema="urn:ivcap:schema:remote-sensing:scene.1",
    aspect={
        "sensor":           "Sentinel-2",
        "acquisition-date": "2025-04-15",
        "cloud-cover-pct":  3.2,
    },
)
```

Query artifacts by this metadata later:

```python
for m in ivcap.list_aspects(
    schema="urn:ivcap:schema:remote-sensing:scene.1",
    filter="cloud-cover-pct < 10",
    include_content=True,
    limit=50,
):
    print(m.entity, m.aspect)
```

---

## REST API reference summary

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/artifacts` | List accessible artifacts |
| `POST` | `/1/artifacts` | Register an artifact record |
| `GET` | `/1/artifacts/{id}` | Get artifact metadata |
| `GET` | `/1/artifacts/{id}/blob` | Download artifact content |
| `PUT` | `/1/artifacts/{id}/blob` | Upload content (single-shot, ≤ 16 MB) |
| `PATCH` | `/1/artifacts/{id}/blob` | Upload via TUS protocol (resumable, ≤ 5 GB) |

---

## Next steps

[→ Query Provenance](query-provenance.md){ .md-button .md-button--primary }
[→ Troubleshooting](troubleshooting.md){ .md-button }
