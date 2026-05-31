# Running Services Locally

The fastest development loop for an IVCAP service is running it locally with
`poetry ivcap run` and testing it with `curl` — no Docker, no cloud, no waiting.
This guide covers three increasingly realistic local development modes.

---

## Prerequisites

| Tool | Purpose |
|---|---|
| Python 3.9+ | Service implementation |
| [Poetry](https://python-poetry.org/) | Dependency management and packaging |
| `poetry-plugin-ivcap` | Adds `poetry ivcap run/deploy` commands |
| Docker | Required for container-based testing only |
| `ivcap` CLI | Required for testing against a live IVCAP deployment |

Install Poetry and the plugin:

```bash
curl -sSL https://install.python-poetry.org | python3 -
poetry self add poetry-plugin-ivcap
```

---

## Mode 1: Pure Python (fastest)

Run the service directly with Python — no container, no IVCAP credentials needed.
This is the fastest way to iterate on your handler logic.

```bash
poetry ivcap run
```

The service starts at `http://localhost:8077` (or the `port` set in `pyproject.toml`):

```
Running: poetry run python my_service/service.py --port 8077
INFO (app): My Analysis Service - 0.1.0
INFO (uvicorn): Uvicorn running on http://0.0.0.0:8077
```

### Testing with curl

Create a test request file `tests/request.json`:

```json
{
  "$schema": "urn:sd:schema.my-service.request.1",
  "region": "Tasmania-North",
  "threshold": 0.05
}
```

Send it to the running service:

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    --data @tests/request.json \
    http://localhost:8077 | jq
```

A successful response:

```json
{
  "$schema": "urn:sd:schema.my-service.1",
  "summary": "Risk score for Tasmania-North: 0.72",
  "score": 0.72
}
```

### Testing with Poetry

The `poetry ivcap run` command has a built-in one-shot mode that starts the server,
sends a request, prints the response, and shuts down:

```bash
poetry ivcap job-exec tests/request.json
```

---

## Mode 2: Local Python connecting to IVCAP

If your service reads or writes artifacts, you need a real IVCAP deployment to
interact with. Set the standard environment variables and the SDK reads them
automatically:

```bash
export IVCAP_URL="https://api.example.ivcap.net"
export IVCAP_JWT="<your-jwt-token>"
export IVCAP_ACCOUNT_ID="urn:ivcap:account:<uuid>"
```

Then run the service as before:

```bash
poetry ivcap run
```

Your service handler's `ctxt.ivcap` client now talks to the real IVCAP deployment.
You can upload test artifacts, read them back, and verify the DataFabric caching
works — all without deploying the service.

!!! tip "Getting a JWT token"
    ```bash
    ivcap context login     # opens a browser for device auth
    ivcap context get       # shows current token and expiry
    ```

### Testing artifact-based services

Upload a test input:

```bash
ivcap artifact upload my-document.pdf \
    --name "test-document" \
    --mime-type application/pdf
# → ID: urn:ivcap:artifact:09e0cb8c-...
```

Update your test request to reference it:

```json
{
  "$schema": "urn:sd:schema.doc-converter.request.1",
  "document": "urn:ivcap:artifact:09e0cb8c-..."
}
```

Call the local service:

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    --data @tests/request.json \
    http://localhost:8077 | jq
```

---

## Mode 3: Docker container (pre-deploy check)

Before deploying, verify the containerised service behaves identically to the
Python version.

### Build the image locally

```bash
poetry ivcap docker-build
```

### Run the container

```bash
poetry ivcap docker-run
```

The container starts and forwards the service port to localhost. Run the same
`curl` tests from Mode 1 — they should produce identical responses.

!!! note "Port conflicts"
    Stop the Mode 1 Python server before running the container — both listen on the
    same port by default.

---

## Iterating on the code

### Hot-reload for lambda services

`poetry ivcap run` does not automatically reload when code changes. To get fast
iteration, stop and restart when you change business logic. For minor handler
tweaks, keep the structure intact and restart manually:

```bash
# Terminal 1 — start the service
poetry ivcap run

# Terminal 2 — run tests
curl -s -X POST -H "content-type: application/json" \
    --data @tests/request.json http://localhost:8077 | jq
```

### Unit tests without the server

Test handler logic directly — no server needed:

```python
# tests/test_service.py
from my_service.service import handler, Request

def test_basic():
    result = handler(Request(region="Tasmania-North", threshold=0.05))
    assert result.score >= 0.0
    assert "Tasmania-North" in result.summary
```

```bash
poetry run pytest -v
```

---

## Exploring the OpenAPI spec

Every `ivcap-ai-tool` service exposes an OpenAPI spec at `/openapi.json` and an
interactive Swagger UI at `/docs`:

```
http://localhost:8077/docs
```

This is a quick way to verify parameter names, types, descriptions, and examples
before deploying.

---

## Logging

Use `getLogger` from `ivcap_service` to write structured logs. In local mode, they
appear on stdout:

```python
from ivcap_service import getLogger

logger = getLogger("app")
logger.info(f"Processing request for region: {req.region}")
logger.warning("Threshold value is near boundary")
logger.error("Failed to fetch baseline data", exc_info=True)
```

On the platform, logs are collected by Loki and are accessible via `ivcap order logs`.

---

## Common issues

| Problem | Likely cause | Fix |
|---|---|---|
| `ModuleNotFoundError` on startup | Missing dependency | `poetry install --no-root` |
| Port `8077` already in use | Another service running | `lsof -i :8077` and kill the process |
| `401 Unauthorized` from artifact calls | Missing or expired JWT | `ivcap context login` |
| `ivcap` client not connected in `ctxt` | `IVCAP_URL` not set | Export the three env vars above |
| Request fails with validation error | Wrong field name or type | Check the model against `/docs` |

---

## Next steps

[→ Deploy](deploy.md){ .md-button .md-button--primary }
[→ Using Artifacts](use-artifacts.md){ .md-button }
