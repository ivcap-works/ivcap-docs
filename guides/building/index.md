# Building Services

This section is for **service authors** — developers who package and deploy analytic
capabilities on IVCAP so that analysts, agents, and pipelines can run them as jobs.

---

## What is an IVCAP service?

An IVCAP service is a **containerised HTTP endpoint** that:

1. Accepts a structured JSON request (described by a typed schema)
2. Does its work — calling APIs, running models, processing data
3. Returns a structured JSON result, optionally uploading output to the artifact store

Services are registered on the platform with a name, description, and parameter schema.
Once registered, anyone with access can discover and run them as jobs.

---

## How services are built

The standard toolchain is **Python + [Poetry](https://python-poetry.org/) + the `ivcap-ai-tool` package**:

| Component | Purpose |
|---|---|
| [`ivcap-ai-tool`](https://pypi.org/project/ivcap-ai-tool/) | HTTP wrapper, schema generation, AI tool exposure |
| [`ivcap-service`](https://pypi.org/project/ivcap-service/) | Core SDK — artifacts, aspects, sidecar access |
| [`poetry-plugin-ivcap`](https://github.com/ivcap-works/poetry-plugin-ivcap) | `poetry ivcap run/deploy` commands |
| Docker | Containerises the service for deployment |
| `ivcap` CLI | Registers the service and pushes images |

You don't have to use this stack — any HTTP server packaged in a container can be registered
as a service. But the `ivcap-ai-tool` stack automates schema generation, deployment, and
AI tool registration in a single `poetry ivcap deploy`.

---

## The development workflow

```
Write code  →  Test locally  →  Containerise  →  Deploy
                   ↑                                 |
               (iterate)                             ↓
                                          Service visible to users
```

1. **Write** your service logic as a Python function with typed Pydantic models
2. **Test** it locally with `poetry ivcap run` and `curl`
3. **Containerise** with `poetry ivcap docker-build`
4. **Deploy** with `poetry ivcap deploy` — this builds the image, pushes it, and registers the service

---

## Guides in this section

| Guide | What it covers |
|---|---|
| [Service Basics](service-basics.md) | Lambda vs batch, project structure, request/response models, parameters |
| [Using Artifacts](use-artifacts.md) | Reading and writing artifacts; DataFabric caching |
| [Run Locally](run-locally.md) | Fast local development loop; testing against a live IVCAP deployment |
| [Deploy](deploy.md) | Containerising, versioning, and registering a service on the platform |
| [Call LLMs](call-llms.md) | Using the sidecar LLM client — credential-free, provenance-recorded |
| [Call Other Services](call-other-services.md) | Submitting sub-jobs from within a service |
| [Use Queues](use-queues.md) | Async pipelines: fan-out, standing orders, producer/consumer patterns |

---

## Quick start

If you haven't built a service before, start with the step-by-step tutorial:

[→ Build Your First Service](../../getting-started/build-service.md){ .md-button .md-button--primary }

Or jump straight to the hands-on tutorial with full source code:

[→ GO Term Mapper Tutorial](../../examples/go-term-mapper-tutorial.md){ .md-button }
