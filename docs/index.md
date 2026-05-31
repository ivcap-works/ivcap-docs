---
template: home.html
title: IVCAP Documentation
---

# IVCAP

**IVCAP** is a managed platform for running, building, and orchestrating
analytic services and AI agents. Services are containerised, composable, and
provenance-aware — every result is traceable back to its inputs, parameters,
and execution history.

---

## What would you like to do?

<div class="grid cards" markdown>

- :material-play-circle: **Run an analysis**

    Submit a job to an existing service, download the results, and trace the
    full provenance chain.

    [→ Run your first analysis](getting-started/run-analysis.md)

- :material-code-braces: **Build a service**

    Wrap your code as a containerised IVCAP service using the Python SDK.
    Lambda or batch — your choice.

    [→ Build your first service](getting-started/build-service.md)

- :material-robot: **Build an AI agent**

    Create agentic services that call LLMs, orchestrate other services, and
    record structured outputs as provenance aspects.

    [→ Build your first agent](getting-started/build-agent.md)

- :material-api: **Integrate IVCAP**

    Call IVCAP from your own app via the Python client SDK, REST API,
    or the CLI's built-in **MCP server**.

    [→ Integration options](guides/integrating/index.md)

</div>

---

## Key concepts in 60 seconds

| Concept | What it is |
|---|---|
| **Service** | A registered analytic capability with typed parameters and a Docker execution environment |
| **Job** | A single execution of a service (also called *order* in the CLI) |
| **Artifact** | Any binary or structured data blob — images, CSVs, models, JSON results |
| **Aspect** | A typed, append-only metadata record attached to any entity; the foundation of provenance |
| **Data Fabric** | The platform's universal, queryable information store — everything is an Aspect |

[Read the full Concepts guide →](concepts/index.md)

---

## Using IVCAP as an AI agent

The `ivcap` CLI includes a built-in **MCP server**. Any MCP-compatible AI
assistant (Claude, GPT-4o, Gemini, …) can connect to it and directly:

- list available services
- submit and monitor jobs
- upload and download artifacts
- query provenance history

```bash
ivcap mcp serve   # start the MCP server; point your AI tool at it
```

[→ Using IVCAP via MCP](guides/integrating/mcp.md)

---

## Not sure where to start?

- New to IVCAP? → [Platform concepts](concepts/index.md)
- Want to see examples first? → [Examples gallery](examples/index.md)
- Looking up a specific API resource? → [API Reference](reference/api/index.md)
- Managing an IVCAP deployment? → [Operator Manual](operators/index.md)
