# Tutorial: Services Calling Other Services

This tutorial introduces one of IVCAP's most powerful architectural patterns: **composing services
by having one service call another**. Rather than building one monolithic service that does
everything, you break the work into focused, independently deployable services — each of which can
be tested, scaled, and resourced on its own terms.

The complete source code is at
[github.com/ivcap-works/agent-calling-agent-tutorial](https://github.com/ivcap-works/agent-calling-agent-tutorial).

This tutorial builds on the concepts introduced in the
[GO Term Mapper tutorial](go-term-mapper-tutorial.md). Familiarity with artifacts is not required
but the [Artifacts tutorial](artifact-tutorial.md) is a useful companion.

---

## Why Compose Services?

A single service that does everything is tempting but creates real problems at scale:

**Resource mismatch.** One part of your pipeline might need a GPU and 32 GB of RAM. Another part
is pure CPU logic that runs in 256 MB. Packing them together means paying for the GPU even when
only the lightweight part is running.

**Testing friction.** A complex monolithic service is hard to unit-test. Smaller services with
clean interfaces can each be tested independently with simple JSON requests.

**Reuse.** A fact-checker, a document converter, or a gene annotation lookup is useful to many
different callers. Deployed as its own service, any other service — or a human user — can invoke
it directly.

**Independent deployment.** You can update, scale, or replace one service without touching the
others. A faster model comes out? Swap the fact-checker alone.

IVCAP makes service-to-service calls a first-class pattern. A service receives the **URN of another
deployed service** as a parameter in its request, looks it up via the IVCAP client, introspects its
request schema, and calls it — all with typed, validated models on both sides.

---

## What We're Building

Two independent services that work together:

```
User
 │
 ▼
Report Writer  ──── calls ────►  Fact Checker
 │ 1. Ask LLM to write report         │ 1. For each reference, ask LLM
 │ 2. Extract references from text    │    to assess credibility
 │ 3. Submit references to            │ 2. Return list of assessments
 │    Fact Checker as a sub-job       │
 │ 4. Merge assessments into          │
 │    final response                  │
 ▼
ReportResponse (topic, content, references + assessments)
```

The **Fact Checker** is a self-contained lambda service. It takes a list of reference strings and
returns an LLM assessment of each one's credibility and relevance. It has no knowledge of the
Report Writer.

The **Report Writer** is also a lambda service. It writes a report on a topic, extracts the
references from the text, and delegates their verification to whichever Fact Checker service URN
was passed in the request. It has no knowledge of the Fact Checker's implementation — only its
schema.

---

## The Fact Checker Service

### Source: `fact_checker/fact_checker.py`

```python
from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List
import os
from dotenv import load_dotenv
from openai import OpenAI

from ivcap_service import getLogger, Service
from ivcap_ai_tool import start_tool_server, ivcap_ai_tool, ToolOptions, logging_init

load_dotenv()
logging_init()
logger = getLogger("app")

service = Service(
    name="Simplistic AI Fact Checker Agent",
    description="Assesses the credibility and relevance of a list of references.",
    contact={"name": "Max Ott", "email": "max.ott@data61.csiro.au"},
    license={"name": "MIT", "url": "https://opensource.org/license/MIT"},
)

class FactCheckInput(BaseModel):
    jschema: str = Field("urn:sd:schema:a2a-tutorial.fact-checker.request.1", alias="$schema")
    references: List[str] = Field(..., description="List of references to be checked")
    model: Optional[str] = Field("gpt-4.1", description="Model to use for fact checking")
    temperature: Optional[float] = Field(0.3, description="Temperature parameter for model")

    model_config = ConfigDict(json_schema_extra={"example": {
        "$schema": "urn:sd:schema:a2a-tutorial.fact-checker.request.1",
        "references": [
            "[1] NASA Solar System Exploration - https://solarsystem.nasa.gov/..."
        ]
    }})

class ReferenceAssessment(BaseModel):
    reference: str = Field(..., description="The original reference text")
    assessment: str = Field(..., description="LLM assessment of credibility and relevance")

class FactCheckOutput(BaseModel):
    jschema: str = Field("urn:sd:schema:a2a-tutorial.fact-checker.1", alias="$schema")
    results: List[ReferenceAssessment]


@ivcap_ai_tool("/", opts=ToolOptions(tags=["Fact Checker"], service_id="/"))
async def verify_references(input: FactCheckInput) -> FactCheckOutput:
    """Verify and assess the quality of a list of references.
    Returns an LLM assessment of each reference's credibility and relevance."""
    verified_refs = []
    client = get_client()
    for ref in input.references:
        response = client.chat.completions.create(
            model=input.model,
            messages=[
                {"role": "system", "content": "You are a critical academic reviewer."},
                {"role": "user",   "content": f"Assess the credibility and relevance of this reference: {ref}"}
            ],
            temperature=input.temperature,
        )
        assessment = response.choices[0].message.content
        verified_refs.append(ReferenceAssessment(reference=ref, assessment=assessment))
    return FactCheckOutput(results=verified_refs)

def get_client():
    """Return an OpenAI client, optionally routing through a LiteLLM proxy."""
    litellm_proxy = os.environ.get("LITELLM_PROXY")
    if litellm_proxy:
        base_url = litellm_proxy.rstrip("/") + "/v1"
        return OpenAI(api_key="sk-xxx", base_url=base_url)  # dummy key for proxy
    return OpenAI()

if __name__ == "__main__":
    start_tool_server(service)
```

### Key points

The Fact Checker is a **completely standalone service**. It knows nothing about the Report Writer.
Its only job is: take a list of reference strings, call an LLM for each one, return the
assessments. It can be called by any other service, by a human user directly, or by an AI agent.

Notice `service_id="/"` in the `ToolOptions` — this publishes the service's schema under its own
root path, which is what allows other services to introspect its request model (see the Report
Writer section below).

The `get_client()` helper supports both a direct OpenAI connection and a
[LiteLLM](https://docs.litellm.ai/) proxy, controlled by the `LITELLM_PROXY` environment
variable. This lets you swap underlying models without changing service code.

---

## The Report Writer Service

### Source: `report_writer/report_writer.py`

```python
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional
import os
from dotenv import load_dotenv
from openai import OpenAI

from ivcap_service import getLogger, Service, JobContext
from ivcap_ai_tool import start_tool_server, ivcap_ai_tool, ToolOptions, logging_init

load_dotenv()
logging_init()
logger = getLogger("app")

service = Service(
    name="Simplistic AI Report Writer w/ Fact Checker",
    description="Writes a report on a topic and uses a separate fact checking agent to validate references.",
    contact={"name": "Max Ott", "email": "max.ott@data61.csiro.au"},
    license={"name": "MIT", "url": "https://opensource.org/license/MIT"},
)

class FactChecker(BaseModel):
    agent_id: str = Field(..., description="URN of the deployed fact checker service")
    model: Optional[str] = Field("gpt-4.1", description="Model for the fact checker")
    temperature: Optional[float] = Field(0.3, description="Temperature for fact checker model")

class ReportRequest(BaseModel):
    jschema: str = Field("urn:sd:schema:a2a-tutorial.report-writer.request.1", alias="$schema")
    topic: str = Field(..., description="The topic to write about")
    fact_checker: Optional[FactChecker] = Field(None, description="Fact checker agent to use")
    model: Optional[str] = Field("gpt-4.1", description="Model for the report writer")
    temperature: Optional[float] = Field(0.7, description="Temperature for report writer model")

    model_config = ConfigDict(json_schema_extra={"example": {
        "$schema": "urn:sd:schema:a2a-tutorial.report-writer.request.1",
        "topic": "The Solar System",
        "fact_checker": {
            "agent_id": "urn:ivcap:service:1c107789-c5f4-51c4-b086-8a09e0fb39c0"
        }
    }})

class ReferenceAssessment(BaseModel):
    reference: str = Field(..., description="The original reference text")
    assessment: Optional[str] = Field(None, description="LLM assessment of credibility")

class ReportResponse(BaseModel):
    jschema: str = Field("urn:sd:schema:a2a-tutorial.report-writer.1", alias="$schema")
    topic: str
    content: str
    references: List[ReferenceAssessment]


@ivcap_ai_tool("/", opts=ToolOptions(tags=["Report Writer"]))
def generate_report(request: ReportRequest, ctxt: JobContext) -> ReportResponse:
    """Write a report on a topic and fact-check its references using a separate agent."""
    logger.debug(f"Generating report for topic: {request.topic}")
    report_text = generate_initial_report(request)
    references = check_references(report_text, request, ctxt)
    return ReportResponse(topic=request.topic, content=report_text, references=references)


def generate_initial_report(request: ReportRequest) -> str:
    """Ask the LLM to write a report with at least two formatted references."""
    client = get_client()
    response = client.chat.completions.create(
        model=request.model,
        messages=[
            {"role": "system", "content": "You are a science writer."},
            {"role": "user", "content": f"""
Write a concise summary about "{request.topic}".
Include at least 2 well-formatted references at the end, like:
[1] Author/Source - URL
[2] Author/Source - URL
"""},
        ],
        temperature=request.temperature,
    )
    return response.choices[0].message.content


def check_references(report_text: str, request: ReportRequest, ctxt: JobContext):
    """Extract references from the report and delegate verification to the fact checker."""

    # Parse references: lines starting with '['
    references = [
        line.strip()
        for line in report_text.splitlines()
        if line.strip().startswith("[")
    ]

    # If no fact checker was provided, return references without assessments
    if not request.fact_checker:
        return [{"reference": r} for r in references]

    # Look up the fact checker service by its URN
    agent = ctxt.ivcap.get_agent(request.fact_checker.agent_id)

    # Introspect its schema and build a typed request
    req_model = agent.request_model
    req = req_model(
        references=references,
        model=request.fact_checker.model,
        temperature=request.fact_checker.temperature,
    )

    # Submit a sub-job and wait for the result
    job = agent.exec_agent(req)
    if not job.succeeded:
        raise RuntimeError(f"Fact checking job failed: {job.error}")

    return job.result["results"]


def get_client():
    litellm_proxy = os.environ.get("LITELLM_PROXY")
    if litellm_proxy:
        base_url = litellm_proxy.rstrip("/") + "/v1"
        return OpenAI(api_key="sk-xxx", base_url=base_url)
    return OpenAI()

if __name__ == "__main__":
    start_tool_server(service)
```

---

## Walking Through the Service-to-Service Call

The key mechanism is in `check_references`. Let's look at it step by step:

### Step 1 — The caller receives the callee's URN in its own request

```python
class FactChecker(BaseModel):
    agent_id: str = Field(..., description="URN of the deployed fact checker service")
```

The Report Writer does not have the Fact Checker's URN hardcoded. It receives it as part of
the incoming `ReportRequest`. This means:

- The same Report Writer can use **any** deployed fact-checker service — a fast one, an accurate
  one, a domain-specific one
- The Fact Checker can be **updated or replaced** without touching the Report Writer code
- The Fact Checker URN is just data — it can come from a user, an AI agent, or a configuration file

### Step 2 — Look up the agent by URN

```python
agent = ctxt.ivcap.get_agent(request.fact_checker.agent_id)
```

`get_agent()` takes a service URN and returns an agent handle. It fetches the service's registered
metadata from IVCAP, including its **request schema**. No hardcoded knowledge of the Fact Checker
is needed at this point.

### Step 3 — Introspect the schema and build a typed request

```python
req_model = agent.request_model
req = req_model(
    references=references,
    model=request.fact_checker.model,
    temperature=request.fact_checker.temperature,
)
```

`agent.request_model` returns the Pydantic model class derived from the Fact Checker's published
schema. Instantiating it gives you full validation — if the schema has changed in a way that's
incompatible with the fields you're setting, you find out immediately, before submitting the job.

### Step 4 — Submit as a sub-job and wait

```python
job = agent.exec_agent(req)
if not job.succeeded:
    raise RuntimeError(f"Fact checking job failed: {job.error}")
result = job.result["results"]
```

`exec_agent()` submits a job to the Fact Checker service on IVCAP and **blocks until it completes**.
The parent job (Report Writer) holds its HTTP connection open while IVCAP executes the child job.
The result comes back as a dict that maps to the Fact Checker's `FactCheckOutput` schema.

---

## Project Structure

Each service is its own Poetry project with independent dependencies, `Dockerfile`, and deployment
configuration:

```
agent-calling-agent-tutorial/
├── fact_checker/
│   ├── pyproject.toml
│   ├── Dockerfile
│   ├── fact_checker.py
│   └── tests/
│       └── refs.json          ← test request for local curl testing
└── report_writer/
    ├── pyproject.toml
    ├── Dockerfile
    ├── report_writer.py
    └── tests/
        └── solar.json         ← test request for local curl testing
```

Each service declares its own dependencies:

```bash
# Fact Checker
cd fact_checker
poetry add openai python-dotenv ivcap-ai-tool
```

```bash
# Report Writer
cd report_writer
poetry add openai python-dotenv ivcap-ai-tool
```

Each has its own `pyproject.toml` configuration:

```toml
# fact_checker/pyproject.toml
[tool.poetry-plugin-ivcap]
service-file = "fact_checker.py"
service-type = "lambda"
port = 8077

# report_writer/pyproject.toml
[tool.poetry-plugin-ivcap]
service-file = "report_writer.py"
service-type = "lambda"
port = 8078     ← different port so both can run locally at the same time
```

---

## Testing Locally

### 1. Set up your API key

Both services use OpenAI (or a LiteLLM proxy). Create a `.env` file in each service directory:

```bash
# fact_checker/.env and report_writer/.env
OPENAI_API_KEY=sk-...
# Or, to route through a LiteLLM proxy:
# LITELLM_PROXY=http://localhost:4000
```

### 2. Start the Fact Checker

```bash
cd fact_checker
poetry install --no-root
poetry ivcap run
```

```
INFO (app): Simplistic AI Fact Checker Agent - 0.1.0|...
INFO (uvicorn): Uvicorn running on http://0.0.0.0:8077
```

### 3. Test the Fact Checker directly

Create `fact_checker/tests/refs.json`:

```json
{
  "$schema": "urn:sd:schema:a2a-tutorial.fact-checker.request.1",
  "references": [
    "[1] NASA Solar System Exploration - https://solarsystem.nasa.gov/solar-system/our-solar-system/overview/",
    "[2] European Space Agency (ESA) - https://www.esa.int/Science_Exploration/Space_Science/Solar_System"
  ]
}
```

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    --data @fact_checker/tests/refs.json \
    http://localhost:8077 | jq '.results[0]'
```

You should see an assessment of the first reference's credibility and relevance.

### 4. Start the Report Writer

In a separate terminal:

```bash
cd report_writer
poetry install --no-root
poetry ivcap run
```

```
INFO (app): Simplistic AI Report Writer w/ Fact Checker - 0.1.0|...
INFO (uvicorn): Uvicorn running on http://0.0.0.0:8078
```

### 5. Test the Report Writer locally (without fact checking)

When running locally, the Fact Checker isn't a deployed IVCAP service yet — it has no URN. You can
test the Report Writer alone by omitting `fact_checker` from the request:

```json
{
  "$schema": "urn:sd:schema:a2a-tutorial.report-writer.request.1",
  "topic": "The Solar System"
}
```

```bash
curl -s -X POST \
    -H "content-type: application/json" \
    --data @report_writer/tests/solar.json \
    http://localhost:8078 | jq '.content'
```

The response will contain the report text with references, but no assessments.

---

## Deploying Both Services

Deploy the Fact Checker first, since the Report Writer needs its URN:

```bash
cd fact_checker
git add . && git commit -m "fact checker service"
poetry ivcap deploy
```

Note the service URN from the output:
```
INFO: service definition successfully uploaded - urn:ivcap:service:1c107789-...
```

Then deploy the Report Writer:

```bash
cd report_writer
git add . && git commit -m "report writer service"
poetry ivcap deploy
```

---

## Testing on IVCAP

Now create a full test request that wires the two services together. In
`report_writer/tests/solar.json`, set the `fact_checker.agent_id` to the URN you noted above:

```json
{
  "$schema": "urn:sd:schema:a2a-tutorial.report-writer.request.1",
  "topic": "The Solar System",
  "fact_checker": {
    "agent_id": "urn:ivcap:service:1c107789-c5f4-51c4-b086-8a09e0fb39c0"
  }
}
```

```bash
cd report_writer
poetry ivcap job-exec tests/solar.json
```

The result includes the full report with each reference assessed:

```yaml
topic: The Solar System
content: >-
  The Solar System consists of the Sun and all objects bound to it by gravity ...

  References:
  [1] NASA Solar System Exploration - https://solarsystem.nasa.gov/...
  [2] European Space Agency (ESA) - https://www.esa.int/...

references:
  - reference: "[1] NASA Solar System Exploration - ..."
    assessment: >-
      This reference is highly credible. NASA is a leading authority in space
      science. The referenced page is directly relevant to the topic ...
  - reference: "[2] European Space Agency (ESA) - ..."
    assessment: >-
      ESA is a reputable intergovernmental organisation. This source is both
      credible and relevant for research on the solar system ...
```

---

## The Composition Pattern in Summary

The five-line core of this pattern is worth memorising:

```python
# 1. Receive the callee's URN as a parameter in the request
agent_urn = request.fact_checker.agent_id

# 2. Look up the agent by URN via the IVCAP client
agent = ctxt.ivcap.get_agent(agent_urn)

# 3. Introspect schema, build a typed request
req = agent.request_model(references=references, ...)

# 4. Submit as a sub-job and wait
job = agent.exec_agent(req)

# 5. Use the result
return job.result["results"]
```

---

## Design Considerations

### Make the callee optional
The Report Writer's `fact_checker` field is `Optional`. When it's absent, the service still
produces a report — just without assessments. This makes the service useful standalone and lets
you add the fact-checking step incrementally.

```python
if not request.fact_checker:
    return [{"reference": r} for r in references]
```

### Independent deployability enables independent resourcing
The Fact Checker can be deployed with different resource limits than the Report Writer. A
fact-checker that calls an LLM API needs network bandwidth and latency tolerance but very little
memory. A service that runs a local embedding model needs significant RAM. With separate
deployments, each gets exactly what it needs.

### Schema introspection provides loose coupling
The Report Writer never imports `FactCheckInput`. It discovers the schema at runtime via
`agent.request_model`. This means:

- You can deploy a completely different fact-checker implementation as long as it accepts
  `references`, `model`, and `temperature`
- Version mismatches surface as validation errors at call time, not at import time
- The two services can be developed and deployed by different teams

### Services vs AI agents
This tutorial uses the word "agent" in the IVCAP sense: any deployed service that can be looked
up by URN and called with a typed request. The same pattern applies whether the callee uses an
LLM, runs a bioinformatics tool, or processes documents. The caller doesn't need to know.

---

## What's Next

- Read [Service Modes](service-modes.md) to understand lambda vs batch — relevant if your
  sub-service is long-running
- See the [Artifacts tutorial](artifact-tutorial.md) if your composed services need to pass large
  files between them (use artifact URNs rather than embedding content in requests)
- Browse the [Service Examples](index.md) for more patterns
