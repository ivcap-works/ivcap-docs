# Building AI Agents with IVCAP

IVCAP supports AI agent workloads in two complementary ways:

| Approach | What it means |
|---|---|
| **Agents on IVCAP** | You build an agent as an IVCAP service — it runs on the platform, has full access to the sidecar (LLMs, other services, the Data Fabric), and produces provenance-tracked results |
| **Agents using IVCAP** | You run an agent *outside* IVCAP (in Claude, Cursor, Jupyter, or your own code) and give it IVCAP capabilities via the built-in MCP server or Python client |

Both approaches use the same underlying IVCAP capabilities. The choice depends on where you want your agent to run and how you want to manage it.

---

## Agents *on* IVCAP — building internal agents

When you build an agent as an IVCAP service, it runs inside the platform just like any other service. This gives you:

- **Managed LLM access** — call any configured model through the sidecar without API keys in your code
- **Service-to-service orchestration** — your agent can call other IVCAP services as sub-jobs
- **Agents as tools** — any IVCAP service can be treated as a tool by another service; agents can call other agents
- **Automatic provenance** — every LLM call, sub-job, and artifact is recorded
- **Independent scaling** — each agent in a multi-agent system runs in its own container

The simplest form is a plain Python function that calls an LLM:

```python
from ivcap_service import get_llm_client, JobContext
from ivcap_ai_tool import ivcap_ai_tool, ToolOptions

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Agent"]))
def analyse(req: Request, ctxt: JobContext) -> Result:
    llm = get_llm_client()   # sidecar-managed, no API key in code
    response = llm.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": req.query}]
    )
    return Result(answer=response.choices[0].message.content)
```

### Agents calling other agents

A service can call any other deployed IVCAP service by its URN — including other agent services. The calling service does not need to know anything about the callee's implementation, only its schema:

```python
# Resolve an agent service by its URN
agent = ctxt.ivcap.get_agent(request.fact_checker.agent_id)

# Introspect its schema and build a typed request
req = agent.request_model(references=references)

# Submit as a sub-job and wait for the result
job = agent.exec_agent(req)
result = job.result["results"]
```

This means an agent service can act as a **tool** for another agent. You compose complex behaviour by wiring together focused, independently deployable agents — each testable on its own, each with its own resource allocation, each tracked with full provenance.

See [Agent Patterns](agent-patterns.md) for the common design patterns, and [Multi-Agent Orchestration](multi-agent.md) for a worked example.

### Framework-based agents: CrewAI

You can run CrewAI crews as IVCAP services. There are two paths:

1. **Build your own CrewAI service** — write Python code that defines a `Crew`, wrap it as an IVCAP service, and give each CrewAI agent tools that call other IVCAP services.
2. **Use the IVCAP CrewAI runner** — submit a crew definition (YAML) to the pre-deployed CrewAI service; the platform handles execution. You only need to define *what* the crew should do, not *how* to run it.

See [CrewAI on IVCAP](crewai.md) for the full guide.

---

## Agents *using* IVCAP — external agents and MCP

You do not need to deploy a service to use IVCAP as part of an agent workflow. The `ivcap` CLI includes a built-in **Model Context Protocol (MCP) server** that exposes the full IVCAP API as tools to any MCP-compatible client.

```bash
ivcap mcp serve   # exposes IVCAP as an MCP tool set on stdio
```

This enables scenarios where the agent reasoning happens *outside* IVCAP — in Claude Desktop, an LLM Studio session, a Jupyter Notebook, or your own code — while IVCAP acts as the execution and data backend:

```
Your AI assistant / agent framework
          │  (MCP tool calls)
          ▼
  IVCAP MCP server (ivcap mcp serve)
          │
          ▼
  IVCAP platform — services, jobs, artifacts, Data Fabric
```

With this setup, an AI agent can:

- **Discover and inspect services** — list what's available, read parameter schemas
- **Submit and monitor jobs** — run any registered IVCAP service on your behalf
- **Upload inputs, download results** — manage artifacts without writing code
- **Query provenance** — ask questions about what ran, when, and what it produced

### Supported client environments

| Environment | How to connect |
|---|---|
| **Claude Desktop** | Add `ivcap` to `claude_desktop_config.json` as an MCP server |
| **LLM Studio** (e.g. LM Studio, Jan) | Configure IVCAP as an MCP tool server in the model settings |
| **Cursor / Cline** | Add to MCP server configuration in VS Code settings |
| **Jupyter Notebooks** | Use `jupyter-ai` (MCP support) or the `mcp` Python client |
| **Custom agents** | Use the MCP Python SDK or the IVCAP Python client directly |

See [Using IVCAP from External Agents](using-ivcap-externally.md) for configuration details for each environment.

---

## Choosing your approach

| You want to… | Best approach |
|---|---|
| Build a reusable, versioned agent that runs on-platform | Internal agent service |
| Compose multiple agents with provenance tracking | Multi-agent service composition |
| Orchestrate a crew of LLM-backed workers | CrewAI on IVCAP |
| Use IVCAP from Claude or another AI assistant | MCP server |
| Explore IVCAP capabilities interactively | Jupyter Notebook + MCP or Python client |
| Add IVCAP to an existing agent framework | MCP server or Python client SDK |

The two approaches are not mutually exclusive. A common pattern is to build your core analysis logic as IVCAP services and then control them from an external AI assistant or Jupyter notebook during research and exploration.

---

## What's in this section

| Guide | What it covers |
|---|---|
| [Agent Patterns](agent-patterns.md) | Design patterns for IVCAP-native agents: LLM wrappers, tool-calling, fan-out, agents-as-tools |
| [Multi-Agent Orchestration](multi-agent.md) | Composing multiple agent services; full worked example |
| [CrewAI on IVCAP](crewai.md) | Running CrewAI crews as services, or using the CrewAI runner |
| [Using IVCAP from External Agents](using-ivcap-externally.md) | MCP server, Claude, Jupyter, custom frameworks |

---

## See also

- [Calling LLMs via the Sidecar](../building/call-llms.md) — how services access LLMs without API keys
- [Calling Other Services](../building/call-other-services.md) — the sub-job API used by orchestrator services
- [Agentic Patterns concept page](../../concepts/agentic-patterns.md) — the design principles behind IVCAP's agent model
