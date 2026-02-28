# Quick Reference

Find the right service example quickly based on what you want to build.

## By Use Case

### "I want to build my first service"
→ **[Python Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** - The simplest possible service
→ **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Basic SDK usage

### "I need to build a REST API service"
→ **[FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** - REST API with FastAPI

### "I want to handle artifacts/files"
→ **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - File upload/download patterns
→ **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - Collection management

### "I need asynchronous/queue processing"
→ **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** - Queue service patterns

### "I want to work with collections"
→ **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** - Collection parameter handling
→ **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - DataFabric backend

### "I want to add AI/LLM capabilities"
→ **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** - Build reusable AI tools
→ **[Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** - Multi-agent communication

### "I need multi-agent orchestration"
→ **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** - CrewAI integration
→ **[LlamaIndex Agent Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)** - RAG and agents

### "I want to process documents for AI"
→ **[Markdown Conversion Service](https://github.com/ivcap-works/ivcap-markdown-conversion-service)** - Convert formats to markdown

---

## By Service Pattern

### Basic Service Structure
- **[Python Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** - Minimal service (best starting point)
- **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Standard service with artifacts
- **[FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** - REST API service

### Data Handling
- **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** - Collection parameters
- **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - Collection manager
- **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** - Async processing

### AI & Agent Services
- **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** - Reusable AI tool
- **[Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** - Multi-agent patterns
- **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** - Multi-agent orchestration
- **[LlamaIndex Agent Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)** - RAG workflows
- **[Markdown Conversion](https://github.com/ivcap-works/ivcap-markdown-conversion-service)** - Document processing

### Domain-Specific Examples
- **[Gene Ontology Mapper](https://github.com/ivcap-works/gene-onology-term-mapper)** - Bioinformatics tool
- **[PaddlePaddle Segmentation](https://github.com/ivcap-works/ivcap-paddle-paddle-seg)** - Deep learning service

---

## By Complexity

### Beginner (15-30 minutes each)
Perfect for learning IVCAP fundamentals:
- **[Python Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** - Simplest service
- **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Basic patterns
- **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** - Async basics

### Intermediate (1-2 hours)
For developers building real services:
- **[FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** - REST APIs
- **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** - Collection handling
- **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - Collection management
- **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** - AI tool creation

### Advanced (2-4 hours)
Complex patterns and orchestration:
- **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** - Multi-agent systems
- **[LlamaIndex Agent Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)** - RAG and agents
- **[Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** - Agent communication

---

## Decision Tree

```
Start Here
    │
    ├─ Never used IVCAP?
    │   └─> Python Lambda Example → Python Service Example
    │
    ├─ Building a REST API?
    │   └─> FastAPI Service Template
    │
    ├─ Working with files/artifacts?
    │   └─> Python Service Example → Collection Example
    │
    ├─ Need asynchronous processing?
    │   └─> Queue Example
    │
    ├─ Building AI/LLM features?
    │   └─> AI Tool Template → Agent Tutorial
    │
    ├─ Need multi-agent orchestration?
    │   └─> CrewAI Service or LlamaIndex Agent Runner
    │
    └─ Domain-specific (bioinformatics, ML)?
        └─> Gene Ontology Mapper or PaddlePaddle Segmentation
```

---

## Quick Links

**All Service Examples**: [GitHub Organization](https://github.com/ivcap-works)
**Development Tools**: [Service SDK](https://github.com/ivcap-works/ivcap-service-sdk-python) | [CLI](https://github.com/ivcap-works/ivcap-cli)
**More Help**: [Beginner Guide](beginner/index.md) | [Capability Matrix](capability-matrix.md)
