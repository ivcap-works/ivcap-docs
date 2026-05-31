# Deploy and Register a Service

Deploying an IVCAP service means: build a Docker image, push it to the platform's
container registry, and register the service definition so it appears in the catalogue.
The `poetry ivcap deploy` command does all three in one step.

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Docker | any recent | Build and push container images |
| Git | any | Commit hash is used as the service version |
| `ivcap` CLI | latest | Authenticated context for deployment |
| `poetry-plugin-ivcap` | latest | `poetry ivcap deploy` command |

Verify your CLI is authenticated:

```bash
ivcap context get
```

If it shows a valid context and account, you're ready.

---

## Step 1: Write a Dockerfile

Add a `Dockerfile` to your project root. Choose the Python base image that matches
your project:

| Python version | Base image |
|---|---|
| 3.10 | `python:3.10-slim-bullseye` |
| 3.11 | `python:3.11-slim-bookworm` |
| 3.12 | `python:3.12-slim-bookworm` |

Check your version:

```bash
poetry run python --version
```

A minimal `Dockerfile`:

```dockerfile
FROM python:3.12-slim-bookworm

RUN pip install poetry

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false \
 && poetry install --no-root --only main

COPY . .

# IVCAP injects the commit hash at build time
ARG VERSION=dev
ENV VERSION=$VERSION
ENV PORT=80

ENTRYPOINT ["python", "/app/my_service/service.py"]
```

!!! important
    The `ENTRYPOINT` must match the `service-file` path in `pyproject.toml`.

---

## Step 2: Commit your code

IVCAP uses the Git commit hash as the service version. Every deployed service is
permanently linked to the exact commit that produced it — this is what makes
services reproducible and auditable.

```bash
git add .
git commit -m "feat: initial release of my-analysis-service"
git rev-parse --short HEAD
# → e3f1a9c
```

!!! warning "Always commit before deploying"
    The `poetry ivcap deploy` command reads the current HEAD commit hash. Uncommitted
    changes won't be included in the deployed image.

---

## Step 3: Deploy

```bash
poetry ivcap deploy
```

This single command:

1. **Cross-compiles** a Docker image for the platform target (`linux/amd64` even on Apple Silicon)
2. **Pushes** the image to the IVCAP container registry
3. **Registers** the service definition on the platform
4. **Registers** the service as a discoverable AI tool

Expected output:

```
Building image for linux/amd64...
Pushing my-analysis-service:e3f1a9c to registry.example.ivcap.net/...
INFO: service definition successfully uploaded - urn:ivcap:aspect:...
INFO: tool description successfully uploaded - urn:ivcap:aspect:...

Service ID: urn:ivcap:service:b14569f9-81bc-5ac2-af1a-9b05ee987c1b
```

Save the service ID — you'll use it to submit jobs.

---

## Step 4: Verify the deployment

```bash
# List services — yours should appear
ivcap service list

# Inspect its parameters
ivcap service get urn:ivcap:service:<your-service-id>
```

Expected output:

```
        Name  My Analysis Service
 Description  Analyse a region and return a risk score.
          ID  urn:ivcap:service:<uuid>
      Status  active

  Parameters  ┌────────────┬──────────────────────────┬──────────┬──────────┐
              │ NAME       │ DESCRIPTION              │ TYPE     │ OPTIONAL │
              ├────────────┼──────────────────────────┼──────────┼──────────┤
              │ region     │ Region name to analyse   │ string   │ no       │
              │ threshold  │ Detection threshold (0-1)│ float    │ yes      │
              └────────────┴──────────────────────────┴──────────┴──────────┘
```

---

## Step 5: Submit a test job

```bash
# Using the CLI
ivcap order create urn:ivcap:service:<uuid> \
    region="Tasmania-North" \
    threshold=0.05 \
    --watch
```

Or with the Poetry plugin's `job-exec` shorthand (reads from a JSON file):

```bash
poetry ivcap job-exec tests/request.json -- --timeout 0
```

---

## Updating an existing service

Deploy again after a new commit. The platform registers a new version of the service
while keeping the old version available for jobs already using it:

```bash
git add .
git commit -m "fix: improve scoring algorithm"
poetry ivcap deploy
```

Each deployment produces a new service URN. Users and integrations can pin to a
specific version by URN, or always use the latest by name.

---

## Service definition (under the hood)

`poetry ivcap deploy` generates and uploads a service definition aspect. For reference,
the structure it produces looks like:

```json
{
  "name": "My Analysis Service",
  "description": "Analyse a region and return a risk score.",
  "parameters": [
    { "name": "region",    "label": "Region name",   "type": "string" },
    { "name": "threshold", "label": "Threshold (0-1)", "type": "float" }
  ],
  "workflow": {
    "type": "basic",
    "basic": {
      "image": "registry.example.ivcap.net/account/<uuid>/my-analysis-service:e3f1a9c",
      "command": ["python", "/app/my_service/service.py"],
      "memory": { "request": "256Mi", "limit": "1Gi" },
      "cpu":    { "request": "100m",  "limit": "1000m" }
    }
  },
  "policy": "urn:ivcap:policy:ivcap.base.service"
}
```

To customise resource limits, add to your `pyproject.toml`:

```toml
[tool.poetry-plugin-ivcap]
service-file = "my_service/service.py"
service-type = "lambda"
port = 8077
memory-request = "512Mi"
memory-limit   = "4Gi"
cpu-request    = "250m"
cpu-limit      = "2000m"
```

---

## Manual registration (advanced)

If you're not using the Poetry plugin, you can register a service directly with the CLI:

```bash
ivcap service update --create urn:ivcap:service:<uuid> -f service.yaml
```

Where `service.yaml` contains the service definition JSON above. The `--create` flag
creates the service if it doesn't exist yet.

---

## Troubleshooting deployments

| Symptom | Likely cause | Fix |
|---|---|---|
| `registry auth failed` | Not logged in to CLI | `ivcap context login` |
| Image build fails | Missing system dependency in Dockerfile | Add `apt-get install` for the missing lib |
| Service shows `inactive` status | Container fails to start | Check service logs: `ivcap order logs <job-id>` |
| Parameters don't match expected | Pydantic model mismatch | Compare `ivcap service get` output with your model |
| Old service version still running | Platform cached the previous deployment | Wait for running jobs to finish; new jobs use new version |

---

## Next steps

[→ Call LLMs](call-llms.md){ .md-button .md-button--primary }
[→ Call Other Services](call-other-services.md){ .md-button }
[→ Use Queues](use-queues.md){ .md-button }
