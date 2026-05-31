# Build Your First Service

This tutorial gives you a high-level picture of what it takes to build and deploy
an IVCAP service. We use the **Gene Ontology (GO) Term Mapper** as the worked
example — a real service that maps UniProt protein IDs to GO annotations using the
[QuickGO](https://www.ebi.ac.uk/QuickGO/) API.

The full, step-by-step tutorial (including all source code) lives in the example
repository:

**[github.com/ivcap-works/gene-onology-term-mapper](https://github.com/ivcap-works/gene-onology-term-mapper)**

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| Python 3.9+ | Service implementation |
| [Poetry](https://python-poetry.org/) | Dependency and packaging management |
| Docker | Build and test the service container |
| `ivcap` CLI (installed & authenticated) | Push the image and register the service |
| Git | Version the code (IVCAP uses the commit hash as the service version) |

---

## What an IVCAP service looks like

An IVCAP service is a **containerised HTTP endpoint** that:

1. Accepts a structured JSON request (described by a schema)
2. Does its work (calling APIs, running models, processing data, …)
3. Returns a structured JSON result

The [`ivcap-ai-tool`](https://pypi.org/project/ivcap-ai-tool/) Python package
provides the service wrapper that handles the HTTP layer, schema validation, and
automatic registration with the platform.

---

## The five key steps

### 1 — Implement the core logic

Write the domain function independently of IVCAP. For the GO Term Mapper this is
a simple async function that calls the QuickGO REST API and returns typed
[Pydantic](https://docs.pydantic.dev/) objects:

```python
async def fetch_go_terms(uniprot_id: str) -> List[Annotation]:
    """Fetch GO annotations for a UniProt ID from QuickGO."""
    ...
```

Having the core logic separate from the service wrapper makes it easy to test
locally with plain Python before introducing any IVCAP concepts.

### 2 — Wrap it as an IVCAP service

Use `ivcap-ai-tool` to declare the service, its input/output schemas, and its
entrypoint. A minimal wrapper looks like this:

```python
from ivcap_ai_tool import service, run

@service(schema="urn:sd:schema.gene-ontology-term-mapper.request.1")
async def map_go_terms(ids: List[str], category: str = "") -> GOTermResult:
    results = {}
    for uid in ids:
        terms = await fetch_go_terms(uid)
        results[uid] = filter_by_category(terms, category)
    return GOTermResult(results=results)

if __name__ == "__main__":
    run(map_go_terms)
```

### 3 — Test locally

Run the service directly with Poetry:

```bash
poetry ivcap run
```

Then call it with `curl`:

```bash
curl -X POST http://localhost:8077 \
     -H "content-type: application/json" \
     --data '{"ids": ["P12345"], "category": "BP"}' | jq
```

### 4 — Containerise

Add a `Dockerfile` and build the image:

```bash
poetry ivcap docker-build
poetry ivcap docker-run   # verify the container behaves identically
```

### 5 — Deploy to IVCAP

Commit your code (the commit hash becomes the service version), then publish:

```bash
git add . && git commit -m "initial release"
poetry ivcap deploy
```

This single command:

- Builds a platform-native Docker image
- Pushes it to the IVCAP package registry
- Registers the service definition on the platform
- Registers the service as a discoverable tool

After a successful deploy you can submit jobs immediately:

```bash
ivcap job create urn:ivcap:service:<your-service-id> \
    -f go_request.json --watch
```

---

## Full tutorial

The steps above are intentionally brief. For complete source code, detailed
explanations of each file, and troubleshooting tips, follow the full tutorial in
the example repository:

[→ Full tutorial on GitHub](https://github.com/ivcap-works/gene-onology-term-mapper){ .md-button .md-button--primary }

---

## Next steps

- Explore the **Guides → Building Services** section for deeper topics such as
  working with artifacts, calling other services, and setting up queues.
- Read [SDK Resources](../developer-guide/sdk-resources.md) for links to the
  Python SDK reference and additional examples.
- Build an **AI agent** that orchestrates multiple services:

[→ Build Your First AI Agent](build-agent.md){ .md-button }
