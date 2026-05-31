# Choosing Your Starting Point

A guide to help you find the best example repository to start your IVCAP service development based on your goals and experience level.

## Quick Decision Guide

### First Time with IVCAP?
→ Start with **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)**

This is the absolute minimum service (just 10-15 lines) showing:
- Basic service structure
- Request/response handling
- Minimal dependencies
- Clean entry point

**Time to understand**: 15 minutes

---

## What Do You Want to Build?

### Basic Services & Learning

**Just Starting:**
- **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** - Simplest possible service
- **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Standard service with artifacts

**Need REST APIs:**
- **[FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** - Build HTTP APIs

**Working with Data:**
- **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** - Artifact handling
- **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** - Collection parameters
- **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** - Collection management

**Async Processing:**
- **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** - Queue service patterns

---

### AI & Machine Learning Services

**Build AI Tools:**
- **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** - Reusable AI tools for agent frameworks

**Multi-Agent Systems:**
- **[Agent Calling Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** - Agent communication patterns
- **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** - CrewAI orchestration
- **[LlamaIndex Agent Runner](https://github.com/ivcap-works/ivcap-llama-index-agent-runner)** - RAG and agents

**Learn**: LLM integration, agent coordination, tool creation

---

### Document Processing

**Convert Documents:**
- **[Markdown Conversion Service](https://github.com/ivcap-works/ivcap-markdown-conversion-service)** - Convert formats to markdown

**Learn**: Document handling, format conversion, AI preprocessing

---

### Domain-Specific Services

**Bioinformatics:**
- **[Gene Ontology Term Mapper](https://github.com/ivcap-works/gene-onology-term-mapper)** - GO term analysis

**Deep Learning:**
- **[PaddlePaddle Segmentation](https://github.com/ivcap-works/ivcap-paddle-paddle-seg)** - DL framework integration

---

## Learning Paths by Role

### Path 1: Complete Beginner (2 hours)
**Goal**: Understand IVCAP fundamentals and build your first service

1. **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** (15 min) - Minimal structure
2. **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** (30 min) - Artifact handling
3. **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** (25 min) - Collections
4. Choose a domain-specific example (30 min)
5. Build your first service (30 min)

**Total time**: ~2 hours to confidence

---

### Path 2: REST API Developer (1 hour)
**Goal**: Build HTTP API services on IVCAP

1. **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** (quick review, 10 min)
2. **[FastAPI Service Template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)** (30 min) - REST patterns
3. Adapt to your API needs (20 min)

**Total time**: ~1 hour

---

### Path 3: AI/ML Developer (2 hours)
**Goal**: Build intelligent services with LLMs and agents

1. **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** (quick review, 10 min)
2. **[AI Tool Template](https://github.com/ivcap-works/ivcap-python-ai-tool-template)** (30 min) - AI tool basics
3. **[Agent Tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial)** (30 min) - Multi-agent patterns
4. **[CrewAI Service](https://github.com/ivcap-works/ivcap-crewai-service)** (40 min) - Advanced orchestration
5. Build your AI service (30 min)

**Total time**: ~2 hours

---

### Path 4: Data Engineer (1.5 hours)
**Goal**: Handle complex data workflows

1. **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** (quick review, 10 min)
2. **[Python Service Example](https://github.com/ivcap-works/ivcap-python-service-example)** (20 min) - Artifacts
3. **[Queue Example](https://github.com/ivcap-works/ivcap-python-queue-example)** (20 min) - Async processing
4. **[Collection Example](https://github.com/ivcap-works/ivcap-python-service-example-collection)** (20 min) - Collections
5. **[DataFabric Example](https://github.com/ivcap-works/ivcap-datafabric-example)** (30 min) - Collection management

**Total time**: ~1.5 hours

---

### Path 5: Domain Specialist (1 hour)
**Goal**: Adapt IVCAP to your specific domain

1. **[Lambda Example](https://github.com/ivcap-works/ivcap-python-lambda-example)** (quick review, 10 min)
2. Browse domain-specific examples (20 min)
   - Bioinformatics: [Gene Ontology Mapper](https://github.com/ivcap-works/gene-onology-term-mapper)
   - Deep Learning: [PaddlePaddle Seg](https://github.com/ivcap-works/ivcap-paddle-paddle-seg)
3. Adapt patterns to your needs (30 min)

**Total time**: ~1 hour

---

## Tips for Success

- **Start Simple**: Begin with simple-python even if experienced
- **Copy and Adapt**: Find closest example and modify it
- **Test Locally**: Use IVCAP CLI before deploying
- **Read Multiple Examples**: Learn patterns from 2-3 similar services

---

## Resources

- [All Examples](../examples/index.md)
- [Quick Reference](../examples/quick-reference.md)
- [Capability Matrix](../examples/capability-matrix.md)
- [GitHub Organization](https://github.com/ivcap-works)
- [Python SDK](https://github.com/ivcap-works/ivcap-service-sdk-python)
