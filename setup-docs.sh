#!/bin/bash

cd /Users/ott030/src/IVCAP/ivcap-docs

# Create directories
echo "Creating directories..."
mkdir -p docs/examples/beginner

# Create examples/index.md
echo "Creating examples/index.md..."
cat > docs/examples/index.md << 'EOF'
# Service Examples

Browse 25+ working IVCAP service examples organized by experience level, domain, and capability.

## Quick Navigation

- **[Quick Reference](quick-reference.md)** - Find services by use case
- **[Capability Matrix](capability-matrix.md)** - Compare services side-by-side
- **[Beginner Guide](beginner/index.md)** - Step-by-step learning path

---

## Service Categories

### Beginner Examples (3 services)
Perfect for getting started with IVCAP:
- **simple-python** - The simplest possible service
- **python-example** - Basic artifact handling
- **batch-tester** - Testing platform features

### Bioinformatics (10 services)
Sequence analysis, annotation, and genomics:
- **seqkit, seqtk** - Sequence manipulation
- **prokka, orffinder** - Genome annotation
- **baseine, alphagenome** - Protein/gene analysis
- **unique-gene-finder** - Comparative genomics
- **gene-ontology-term-mapper** - Functional annotation

### AI & Machine Learning (9 services)
Chatbots, research agents, and LLM integration:
- **chat-service** - Simple chatbot
- **genewhisperer, deepresearch** - Research agents
- **icrew, meta-agent** - Multi-agent systems
- **python-code-service** - Code generation

### Document Processing (2 services)
Document conversion and parsing:
- **markitdown** - Universal document converter
- **document-parsing** - Document to markdown

### Workflows (2 services)
Multi-step pipelines and orchestration:
- **icrew** - Multi-agent CrewAI workflows
- **nextflow-runner** - Nextflow pipeline execution

---

## Resources

- [GitHub Organization](https://github.com/ivcap-works) - All IVCAP repositories
- [Python SDK](https://github.com/ivcap-works/ivcap-service-sdk-python) - Service development
- [CLI Tool](https://github.com/ivcap-works/ivcap-cli) - Command-line interface
- [Developer Guide](../developer-guide/README.md) - Comprehensive development docs
EOF

# Create examples/quick-reference.md
echo "Creating examples/quick-reference.md..."
cat > docs/examples/quick-reference.md << 'EOF'
# Quick Reference

Find the right service quickly based on what you want to build.

## By Use Case

### "I want to build my first service"
→ **[simple-python](https://github.com/ivcap-works/ivcap-service-simple-python)** - Start here

### "I need to wrap a CLI tool"
→ **[prokka-service](https://github.com/ivcap-works/ivcap-prokka-service)** or **[seqkit-service](https://github.com/ivcap-works/ivcap-seqkit-service)**

### "I want to add AI/LLM capabilities"
→ **[chat-service](https://github.com/ivcap-works/ivcap-chat-service)** (simple) or **[genewhisperer](https://github.com/ivcap-works/ivcap-genewhisperer)** (advanced)

### "I need to process documents"
→ **[markitdown-service](https://github.com/ivcap-works/ivcap-markitdown-service)**

### "I want multi-agent workflows"
→ **[icrew](https://github.com/ivcap-works/ivcap-icrew)** - CrewAI integration

---

## By Domain

### Bioinformatics
- **Sequence Analysis**: [seqkit](https://github.com/ivcap-works/ivcap-seqkit-service), [seqtk](https://github.com/ivcap-works/ivcap-seqtk-service)
- **Genome Annotation**: [prokka](https://github.com/ivcap-works/ivcap-prokka-service), [orffinder](https://github.com/ivcap-works/ivcap-orffinder-service)
- **Protein Analysis**: [baseine](https://github.com/ivcap-works/ivcap-baseine), [alphagenome](https://github.com/ivcap-works/ivcap-alphagenome-service)
- **Comparative Genomics**: [unique-gene-finder](https://github.com/ivcap-works/ivcap-unique-gene-finder)

### AI & Machine Learning
- **Chatbots**: [chat-service](https://github.com/ivcap-works/ivcap-chat-service)
- **Research Agents**: [genewhisperer](https://github.com/ivcap-works/ivcap-genewhisperer), [deepresearch](https://github.com/ivcap-works/ivcap-deepresearch-service)
- **Code Generation**: [python-code-service](https://github.com/ivcap-works/ivcap-python-code-service)
- **Orchestration**: [icrew](https://github.com/ivcap-works/ivcap-icrew), [meta-agent](https://github.com/ivcap-works/ivcap-meta-agent)

### Document Processing
- [markitdown-service](https://github.com/ivcap-works/ivcap-markitdown-service) - Multiple format support
- [document-parsing-service](https://github.com/ivcap-works/ivcap-document-parsing-service)

---

## By Complexity

**Beginner**: simple-python, python-example, batch-tester

**Intermediate**: Tool wrappers (prokka, seqkit), Document processing, Simple LLM

**Advanced**: Multi-agent systems (icrew, genewhisperer), Meta-agents, Complex pipelines

---

## All Repositories

Browse all services: [https://github.com/ivcap-works](https://github.com/ivcap-works)
EOF

# Create examples/capability-matrix.md
echo "Creating examples/capability-matrix.md..."
cat > docs/examples/capability-matrix.md << 'EOF'
# Capability Matrix

Compare services side-by-side to find the right example for your needs.

## Feature Comparison Table

| Service | Artifacts | External Tools | LLM/AI | Multi-Agent | Documents | Bioinformatics |
|---------|-----------|----------------|---------|-------------|-----------|----------------|
| simple-python | ✓ | - | - | - | - | - |
| python-example | ✓ | - | - | - | - | - |
| batch-tester | ✓ | - | - | - | - | - |
| markitdown | ✓ | ✓ | - | - | ✓ | - |
| prokka | ✓ | ✓ | - | - | - | ✓ |
| seqkit | ✓ | ✓ | - | - | - | ✓ |
| orffinder | ✓ | ✓ | - | - | - | ✓ |
| chat-service | - | - | ✓ | - | - | - |
| genewhisperer | ✓ | - | ✓ | ✓ | - | ✓ |
| deepresearch | - | - | ✓ | ✓ | - | - |
| icrew | - | - | ✓ | ✓ | - | - |
| meta-agent | ✓ | - | ✓ | ✓ | - | - |

---

## Categories

### Beginner-Friendly
- **simple-python** - Absolute minimum service
- **python-example** - Basic artifact handling
- **batch-tester** - Platform testing

### Bioinformatics
- **seqkit** - Sequence manipulation
- **prokka** - Genome annotation
- **orffinder** - ORF finding
- **unique-gene-finder** - Comparative genomics
- **baseine** - Protein modeling
- **alphagenome** - Gene expression prediction

### AI & Machine Learning
- **chat-service** - Simple chatbot
- **genewhisperer** - Biological research agent
- **deepresearch** - General research agent
- **python-code** - Code generation
- **meta-agent** - Service orchestration
- **icrew** - CrewAI workflows

### Document Processing
- **markitdown** - Universal document converter
- **document-parsing** - Document to markdown parser

### Workflows
- **icrew** - Multi-agent CrewAI workflows
- **nextflow-runner** - Nextflow pipeline execution

---

## Legend

- **✓** = Feature implemented
- **-** = Feature not used
- **Artifacts** = Works with IVCAP artifacts (file upload/download)
- **External Tools** = Integrates external CLI tools or binaries
- **LLM/AI** = Uses language models or AI capabilities
- **Multi-Agent** = Coordinates multiple agents
- **Documents** = Processes documents (PDF, Word, etc.)
- **Bioinformatics** = Bioinformatics domain

---

## Finding More Information

Each service has detailed documentation in its GitHub repository:
[https://github.com/ivcap-works](https://github.com/ivcap-works)
EOF

# Create examples/beginner/index.md
echo "Creating examples/beginner/index.md..."
cat > docs/examples/beginner/index.md << 'EOF'
# Beginner Examples

Start your IVCAP service development journey with these simple, well-documented examples.

## Recommended Learning Path

### 1. Simple Python Service
**Repository**: [ivcap-service-simple-python](https://github.com/ivcap-works/ivcap-service-simple-python)

The absolute simplest IVCAP service - perfect for understanding the basic structure.

**What You'll Learn:**
- Basic service structure
- Request/response handling
- Minimal dependencies
- Service registration

**Time**: 15 minutes

---

### 2. Basic Artifact Handling
**Repository**: [ivcap-python-service-example](https://github.com/ivcap-works/ivcap-python-service-example)

Introduces IVCAP's artifact system for handling files.

**What You'll Learn:**
- Downloading input artifacts
- Processing files
- Publishing output artifacts
- Using JobContext

**Time**: 30 minutes

---

### 3. Batch Processing
**Repository**: [ivcap-batch-tester](https://github.com/ivcap-works/ivcap-batch-tester)

Understand how batch jobs work on IVCAP.

**What You'll Learn:**
- Long-running jobs
- Resource management
- Error handling
- Testing platform limits

**Time**: 20 minutes

---

## Common Patterns

All beginner examples demonstrate these fundamental patterns:

### Service Structure
```python
from ivcap_sdk_service import JobContext, deliver

def run(request: Request, ctxt: JobContext) -> Result:
    # Your service logic here
    return Result(...)
```

### Request Validation
```python
from pydantic import BaseModel

class Request(BaseModel):
    parameter: str
    optional_param: Optional[int] = None
```

---

## Next Steps

Once comfortable with these basics:

1. **Choose Your Domain**
   - Bioinformatics
   - AI/ML  
   - Document Processing
   - Workflows

2. **Learn Advanced Patterns**
   - Tool wrapping
   - LLM integration
   - Multi-agent systems

3. **Build Your Service**
   - Start from similar example
   - Adapt to your needs
   - Test locally
   - Deploy to platform

---

## Resources

- [Developer Guide](../../developer-guide/README.md)
- [Python SDK](https://github.com/ivcap-works/ivcap-service-sdk-python)
- [CLI Tool](https://github.com/ivcap-works/ivcap-cli)
- [All Examples](../index.md)
EOF

# Create getting-started/choosing-starting-point.md
echo "Creating getting-started/choosing-starting-point.md..."
cat > docs/getting-started/choosing-starting-point.md << 'EOF'
# Choosing Your Starting Point

A guide to help you find the best example repository to start your IVCAP service development.

## Quick Decision Guide

### First Time with IVCAP?
→ Start with **[ivcap-service-simple-python](https://github.com/ivcap-works/ivcap-service-simple-python)**

This is the absolute minimum service showing:
- Basic service structure
- Request/response handling
- Minimal dependencies

**Time to understand**: 15 minutes

---

## What Do You Want to Build?

### Wrap an Existing CLI Tool
**Best Examples:**
- **[prokka-service](https://github.com/ivcap-works/ivcap-prokka-service)** - Full-featured CLI wrapper
- **[seqkit-service](https://github.com/ivcap-works/ivcap-seqkit-service)** - Tool with multiple subcommands

**Learn**: Tool installation, parameter passing, output parsing

---

### Build an AI/ML Service
**For Chatbots:**
- **[chat-service](https://github.com/ivcap-works/ivcap-chat-service)** - Simple chatbot with memory

**For Research:**
- **[deepresearch-service](https://github.com/ivcap-works/ivcap-deepresearch-service)** - General research
- **[genewhisperer](https://github.com/ivcap-works/ivcap-genewhisperer)** - Domain-specific biology

**For Code Generation:**
- **[python-code-service](https://github.com/ivcap-works/ivcap-python-code-service)**

---

### Process Documents
**Best Examples:**
- **[markitdown-service](https://github.com/ivcap-works/ivcap-markitdown-service)** - Multiple format support
- **[document-parsing-service](https://github.com/ivcap-works/ivcap-document-parsing-service)** - Focused parsing

---

### Create Multi-Agent Workflows
**Best Examples:**
- **[icrew](https://github.com/ivcap-works/ivcap-icrew)** - CrewAI integration
- **[meta-agent](https://github.com/ivcap-works/ivcap-meta-agent)** - Custom orchestration

---

## Learning Paths

### Path 1: Complete Beginner
1. simple-python (15 min)
2. python-example (30 min)
3. Choose domain-specific example
4. Build your service

**Total time**: ~2 hours to confidence

### Path 2: Tool Wrapper Developer
1. simple-python (quick review)
2. prokka or seqkit (study patterns)
3. Adapt to your tool

**Total time**: ~1 hour

### Path 3: AI/ML Developer
1. simple-python (review)
2. chat-service (simple example)
3. genewhisperer (advanced patterns)
4. Build your AI service

**Total time**: ~2 hours

### Path 4: Bioinformatics Researcher
1. simple-python (review)
2. Browse bioinformatics examples
3. Pick closest match
4. Adapt to your workflow

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
EOF

echo ""
echo "✅ All files created successfully!"
echo ""
echo "Files created:"
ls -lh docs/examples/*.md
ls -lh docs/examples/beginner/*.md
ls -lh docs/getting-started/choosing-starting-point.md
echo ""
echo "Now run:"
echo "  mkdocs build --clean"
echo "  mkdocs serve"
echo ""
echo "Then open: http://127.0.0.1:8000"

