# Examples

Working examples from the `ivcap-works` GitHub organisation, pulled and
presented here for easy browsing. All examples include a README, source code,
and instructions for deploying to IVCAP.

---

## By difficulty

### Beginner — single concept, < 50 lines of service code

| Example | Capabilities | SDK |
|---|---|---|
| [Lambda Service Example](https://github.com/ivcap-works/ivcap-python-lambda-example) | build-services | Python service |
| [Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example) | build-services, artifacts | Python service |
| [FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template) | build-services | Python service |

### Intermediate — two or more concepts

| Example | Capabilities | SDK |
|---|---|---|
| [Queue / Async Example](https://github.com/ivcap-works/ivcap-python-queue-example) | build-services, queues | Python service |
| [Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection) | build-services, data-fabric | Python service |
| [DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example) | data-fabric, aspects | Python service |
| [AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template) | ai-agents, build-services | Python service |
| [Markdown Conversion Service](https://github.com/ivcap-works/ivcap-markdown-conversion-service) | ai-agents, artifacts | Python service |
| [Gene Ontology Term Mapper](https://github.com/ivcap-works/gene-onology-term-mapper) | domain-bio, build-services | Python service |

### Advanced — multiple concepts, domain knowledge required

| Example | Capabilities | SDK |
|---|---|---|
| [CrewAI Multi-Agent Service](https://github.com/ivcap-works/ivcap-crewai-service) | ai-agents, build-services | Python service |
| [LlamaIndex Agent Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner) | ai-agents | Python service |
| [Agent Calling Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial) | ai-agents, workflows | Python service |

---

## By capability

See the [Capability Matrix](capability-matrix.md) for a complete cross-reference
of which examples demonstrate which platform capabilities.

---

## In-depth tutorials

These tutorials walk through real IVCAP services step by step:

- **[Gene Ontology Term Mapper](go-term-mapper-tutorial.md)** — bioinformatics service with domain-specific output
- **[Working with Artifacts](../guides/building/use-artifacts.md)** — artifact upload, download, and provenance
- **[Agent Calling Agent](../guides/agents/multi-agent.md)** — services that autonomously orchestrate other services

---

!!! tip "Add an example"
    To add a new example to this page, edit `config/example-registry.json` and
    run `make fetch-examples`. See the project [README](https://github.com/ivcap-works/ivcap-docs#readme) for details.
