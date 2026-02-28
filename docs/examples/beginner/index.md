# Beginner Examples

Start your IVCAP service development journey with these simple, well-documented examples. Follow this structured learning path to master IVCAP service creation from the ground up.

## Recommended Learning Path

### Step 1: Lambda Example (15 minutes)
**Repository**: [ivcap-python-lambda-example](https://github.com/ivcap-works/ivcap-python-lambda-example)

The absolute simplest IVCAP service - perfect for understanding the basic structure with minimal code.

**What You'll Learn:**
- Minimal service structure (just 10-15 lines!)
- Request/response handling basics
- Service registration fundamentals
- How IVCAP invokes your service

**Key Concepts:**
- Service entry point
- Request parameters
- Return values
- Deployment basics

**Time**: 15 minutes

---

### Step 2: Python Service Example (30 minutes)
**Repository**: [ivcap-python-service-example](https://github.com/ivcap-works/ivcap-python-service-example)

Build on the lambda example by introducing IVCAP's artifact system for handling files.

**What You'll Learn:**
- Downloading input artifacts
- Processing files within your service
- Publishing output artifacts
- Using the JobContext object
- Parameter validation with Pydantic

**Key Concepts:**
- Artifact management
- File I/O patterns
- Output publishing
- Context usage

**Time**: 30 minutes

---

### Step 3: FastAPI Service Template (20 minutes)
**Repository**: [ivcap-python-fastapi-service-template](https://github.com/ivcap-works/ivcap-python-fastapi-service-template)

Learn how to build REST API services on IVCAP using FastAPI.

**What You'll Learn:**
- Building REST endpoints
- HTTP request handling
- FastAPI integration
- API-style service patterns

**Key Concepts:**
- REST API design
- Endpoint routing
- Request/response models
- HTTP methods

**Time**: 20 minutes

---

### Step 4: Queue Example (20 minutes)
**Repository**: [ivcap-python-queue-example](https://github.com/ivcap-works/ivcap-python-queue-example)

Understand asynchronous processing patterns using IVCAP queues.

**What You'll Learn:**
- Queue service basics
- Asynchronous job patterns
- Message passing
- Long-running tasks

**Key Concepts:**
- Async processing
- Queue integration
- Job management
- Event-driven patterns

**Time**: 20 minutes

---

### Step 5: Collection Example (25 minutes)
**Repository**: [ivcap-python-service-example-collection](https://github.com/ivcap-works/ivcap-python-service-example-collection)

Work with IVCAP collections - groups of related artifacts.

**What You'll Learn:**
- Collection parameter handling
- Iterating over collection items
- Processing multiple artifacts
- Collection metadata

**Key Concepts:**
- Collection parameters
- Batch processing
- Multi-artifact handling
- Metadata access

**Time**: 25 minutes

---

### Step 6: DataFabric Example (30 minutes)
**Repository**: [ivcap-datafabric-example](https://github.com/ivcap-works/ivcap-datafabric-example)

Build a collection manager using IVCAP's DataFabric backend.

**What You'll Learn:**
- DataFabric integration
- Collection management
- Backend storage patterns
- Advanced collection operations

**Key Concepts:**
- DataFabric API
- Collection CRUD operations
- Storage backends
- Collection architecture

**Time**: 30 minutes

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
