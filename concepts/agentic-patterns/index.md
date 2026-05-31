# Agentic Patterns

IVCAP is designed from the ground up to support agentic workloads. Services can
autonomously call other services, access the Data Fabric, call LLMs, and produce
structured outputs — all without requiring pre-authorisation or orchestration
from outside the platform.

---

## Services calling other services

Any IVCAP service can submit a job to any other registered service using the
platform's internal API, accessible through the **sidecar**. This means you
can build:

- **Pipelines** — service A calls service B with its output, which calls service C
- **Fan-out / fan-in** — a coordinator service spawns N parallel jobs and waits for results
- **Recursive decomposition** — a service breaks a large task into smaller subtasks
  and submits them as new jobs

```python
from ivcap_sdk import get_service_client

client = get_service_client()   # sidecar-provided client

# Submit a sub-job to another service
sub_job = client.submit_job(
    service_id="urn:ivcap:service:<uuid>",
    parameters={"input": artifact_urn, "threshold": 0.5}
)

# Wait for it (or poll later)
result = client.wait_for_job(sub_job.id)
```

Because jobs are first-class IVCAP entities, every sub-job is automatically
recorded with full provenance — input parameters, parent job, outputs, and timing.

---

## LLM integration via the sidecar

The IVCAP sidecar includes an integrated LLM client. Services access it through
a standard OpenAI-compatible interface, without managing API keys directly —
secrets are injected by the platform.

```python
from ivcap_sdk import get_llm_client

llm = get_llm_client()   # uses the sidecar; no API key required in code

response = llm.chat.completions.create(
    model="gpt-4o",      # or any model configured on the deployment
    messages=[
        {"role": "system", "content": "You are a data analyst."},
        {"role": "user",   "content": f"Summarise this dataset: {data}"}
    ]
)

summary = response.choices[0].message.content
```

LLM calls made through the sidecar are:
- **Credential-free in service code** — secrets are managed by the platform
- **Provenance-recorded** — every LLM call can be traced via aspects
- **Model-agnostic** — the deployment admin configures which model provider(s) are available

---

## Multi-agent orchestration frameworks

IVCAP services can host any Python-based agent framework. The pattern is:

1. Wrap the framework's orchestration loop as an IVCAP service
2. Each "agent" in the framework becomes a function that may call the sidecar
   (to submit sub-jobs, read/write artifacts, query aspects)
3. The service records its final output as an artifact and/or aspect

### CrewAI on IVCAP

```python
from crewai import Agent, Task, Crew
from ivcap_sdk import get_llm_client, save_artifact

llm = get_llm_client()

researcher = Agent(role="Researcher", llm=llm, ...)
analyst    = Agent(role="Analyst",    llm=llm, ...)

crew = Crew(agents=[researcher, analyst], tasks=[...])
result = crew.kickoff()

# Save the final report as an IVCAP artifact
save_artifact(result.raw, mime_type="text/markdown", name="crew-report.md")
```

See [CrewAI on IVCAP](../guides/agents/crewai.md) for the full example.

### Using IVCAP from external agent environments

IVCAP services and capabilities can also be used from *outside* the platform — in
Claude Desktop, Jupyter Notebooks, or any agent framework — via the built-in MCP
server or the Python client. This lets you prototype and explore interactively,
then promote the logic to a deployed service when you are ready.

See [Using IVCAP from External Agents](../guides/agents/using-ivcap-externally.md)
for configuration details for each environment.

---

## Using IVCAP as an agent tool (MCP)

From the *outside* — not inside a service — any MCP-compatible AI assistant
can control IVCAP directly via the CLI's built-in MCP server:

```bash
ivcap mcp serve   # exposes IVCAP as an MCP tool set
```

This lets Claude, GPT-4o, Gemini, or any compatible tool:
- discover and inspect services
- submit and monitor jobs
- upload inputs, download results
- query aspects and provenance

See [Using IVCAP via MCP](../guides/integrating/mcp.md) for configuration details.

---

## Design principles for agentic services

When building a service that acts as an agent or orchestrator, follow these
principles:

**Record intermediate state as aspects.** Don't discard reasoning steps — store
them as aspects on the job URN. This makes the agent's decision process auditable.

```python
from ivcap_sdk import add_aspect

add_aspect(
    entity=current_job_urn,
    schema="urn:ivcap:schema:agent-step.1",
    content={"step": "literature-search", "query": query, "hits": len(results)}
)
```

**Use artifacts for large inputs/outputs.** Pass artifact URNs between sub-jobs,
not raw data blobs in parameters. This keeps provenance chains intact.

**Prefer sub-jobs over in-process computation for reproducible steps.** If a
step is reusable, register it as its own service. The sub-job is then
independently reproducible and testable.

**Name your jobs.** Include a meaningful `name` when submitting sub-jobs —
it makes the provenance graph readable.
