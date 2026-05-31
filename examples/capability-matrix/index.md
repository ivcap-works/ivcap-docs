# Capability Matrix

Compare IVCAP service examples side-by-side to find the right template for your needs.

## Service Example Comparison

| Service Example | REST API | Artifacts | Queue/Async | Collections | LLM/AI | Multi-Agent | Documents | Domain |
|-----------------|----------|-----------|-------------|-------------|---------|-------------|-----------|--------|
| [Lambda](https://github.com/ivcap-works/ivcap-python-lambda-example) | - | - | - | - | - | - | - | Basic |
| [Service Example](https://github.com/ivcap-works/ivcap-python-service-example) | - | ✓ | - | - | - | - | - | Basic |
| [FastAPI Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template) | ✓ | - | - | - | - | - | - | Basic |
| [Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example) | - | - | ✓ | - | - | - | - | Basic |
| [Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection) | - | ✓ | - | ✓ | - | - | - | Basic |
| [DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example) | - | ✓ | - | ✓ | - | - | - | Basic |
| [AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template) | - | - | - | - | ✓ | - | - | AI/ML |
| [Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial) | - | - | - | - | ✓ | ✓ | - | AI/ML |
| [CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service) | - | - | - | - | ✓ | ✓ | - | AI/ML |
| [LlamaIndex Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner) | - | - | - | - | ✓ | ✓ | - | AI/ML |
| [Markdown Conversion](https://github.com/ivcap-works/ivcap-markdown-conversion-service) | - | ✓ | - | - | - | - | ✓ | Documents |
| [Gene Ontology](https://github.com/ivcap-works/gene-onology-term-mapper) | - | ✓ | - | - | - | - | - | Bioinformatics |
| [PaddlePaddle Seg](https://github.com/ivcap-works/ivcap-paddle-paddle-seg) | - | ✓ | - | - | - | - | - | Deep Learning |

---

## Capability Categories

### Basic Service Examples (Start Here)
These examples teach fundamental IVCAP service patterns:

- **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** - Simplest possible service (10 lines)
- **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Standard service with artifact handling
- **[FastAPI Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** - REST API service pattern

### Data Handling Examples
Learn how to work with IVCAP's data features:

- **[Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Artifact upload/download
- **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** - Collection parameters
- **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - Collection management
- **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** - Asynchronous processing

### AI & Agent Examples
Build services with AI and multi-agent capabilities:

- **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** - Create reusable AI tools
- **[Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** - Multi-agent communication
- **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** - CrewAI orchestration
- **[LlamaIndex Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)** - RAG and agent workflows

### Document Processing Examples
Handle various document formats:

- **[Markdown Conversion](https://github.com/ivcap-works/ivcap-markdown-conversion-service)** - Convert formats to markdown for AI

### Domain-Specific Examples
Specialized use cases:

- **[Gene Ontology Mapper](https://github.com/ivcap-works/gene-onology-term-mapper)** - Bioinformatics analysis
- **[PaddlePaddle Segmentation](https://github.com/ivcap-works/ivcap-paddle-paddle-seg)** - Deep learning framework

---

## Legend

### Capability Definitions

- **REST API** - Exposes HTTP endpoints via FastAPI
- **Artifacts** - Downloads/uploads files from IVCAP storage
- **Queue/Async** - Uses IVCAP queue service for async processing
- **Collections** - Works with IVCAP collection parameters
- **LLM/AI** - Integrates language models or AI APIs
- **Multi-Agent** - Coordinates multiple AI agents
- **Documents** - Processes document files (PDF, Word, markdown, etc.)
- **Domain** - Category: Basic, AI/ML, Documents, Bioinformatics, Deep Learning

### Symbols

- **✓** = Feature demonstrated in this example
- **-** = Feature not used in this example

---

## Choosing the Right Example

### By Learning Goal

**"I'm new to IVCAP"**
→ Start with [Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example), then [Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)

**"I need to handle files"**
→ Use [Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example) for artifacts, [Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection) for collections

**"I'm building a REST API"**
→ Check out [FastAPI Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)

**"I need asynchronous processing"**
→ See [Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)

**"I want to add AI capabilities"**
→ Explore [AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template) and [Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)

**"I need multi-agent orchestration"**
→ Study [CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service) or [LlamaIndex Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)

---

## More Resources

- **[Quick Reference](quick-reference.md)** - Find examples by use case
- **[Beginner Guide](beginner/index.md)** - Step-by-step learning path
- **[Service SDK](https://github.com/ivcap-works/ivcap-service-sdk-python)** - SDK documentation
- **[All Examples](https://github.com/ivcap-works)** - Browse all repositories
