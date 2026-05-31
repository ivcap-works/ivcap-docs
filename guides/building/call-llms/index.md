# Calling LLMs via the Sidecar

IVCAP services can call LLMs without managing API keys in their code. The platform
**sidecar** injects credentials at runtime and exposes an OpenAI-compatible interface
that any Python service can use.

---

## How it works

Every service container runs alongside a **sidecar** process managed by IVCAP. The sidecar:

- Holds API keys and secrets injected by the platform (never exposed to service code)
- Exposes a local HTTP endpoint that implements the OpenAI API
- Routes calls to whichever LLM provider(s) the deployment has configured
- Records each LLM call as a provenance aspect on the job

Your service calls the sidecar at `http://localhost:<sidecar-port>` — identical to
calling OpenAI directly, but with no credentials in your code.

```
Service container
┌─────────────────────────────────────────────────┐
│  your code  →  sidecar (localhost)  →  LLM API  │
│                    │                             │
│               injects secrets                    │
│               records provenance                 │
└─────────────────────────────────────────────────┘
```

---

## Getting the LLM client

Use `get_llm_client()` from the service SDK. In local development (without a sidecar),
you can fall back to a direct API key:

```python
from ivcap_service import get_llm_client

# In production: connects to the sidecar automatically
# In local dev: falls back to OPENAI_API_KEY environment variable
llm = get_llm_client()
```

The client returned is a standard [OpenAI Python SDK](https://github.com/openai/openai-python)
client, so any code written against the OpenAI SDK works unchanged.

---

## Basic chat completion

```python
from ivcap_service import get_llm_client, getLogger

logger = getLogger("app")

def summarise_text(text: str) -> str:
    llm = get_llm_client()

    response = llm.chat.completions.create(
        model="gpt-4o",   # or any model configured for the deployment
        messages=[
            {
                "role": "system",
                "content": "You are a scientific analyst. Be concise and precise."
            },
            {
                "role": "user",
                "content": f"Summarise the following dataset findings:\n\n{text}"
            }
        ],
        max_tokens=512,
        temperature=0.2,
    )

    summary = response.choices[0].message.content
    logger.info(f"LLM generated {len(summary)} chars")
    return summary
```

---

## Using LLMs in a service handler

A complete lambda service that summarises an uploaded artifact:

```python
import io
from typing import ClassVar, Optional
from pydantic import BaseModel, Field, ConfigDict
from ivcap_service import getLogger, Service, JobContext, get_llm_client
from ivcap_ai_tool import start_tool_server, ToolOptions, ivcap_ai_tool, logging_init

logging_init()
logger = getLogger("app")

service = Service(
    name="Dataset Summariser",
    contact={"name": "Jane Smith", "email": "jane.smith@example.com"},
)

class Request(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.summariser.request.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    document: str = Field(description="IVCAP artifact URN of the document to summarise")
    model: Optional[str] = Field("gpt-4o", description="LLM model to use")
    policy: Optional[str] = Field("urn:ivcap:policy:ivcap.base.artifact")
    model_config = ConfigDict(populate_by_name=True)

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.summariser.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    summary: str = Field(description="Plain-language summary")
    summary_artifact: str = Field(description="URN of the stored summary artifact")

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Analysis", "LLM"]))
def summarise(req: Request, ctxt: JobContext) -> Result:
    """Summarise a document artifact using an LLM.

    Downloads the specified artifact, passes its content to the configured
    LLM model, and returns the summary both inline and as a stored artifact.
    """
    ivcap = ctxt.ivcap
    llm = get_llm_client()

    # Download the document
    doc = ivcap.get_artifact(req.document)
    text = doc.as_file().read().decode("utf-8", errors="replace")
    logger.info(f"Loaded document: {doc.name} ({len(text)} chars)")

    # Call the LLM
    response = llm.chat.completions.create(
        model=req.model,
        messages=[
            {"role": "system", "content": "Summarise the document concisely."},
            {"role": "user",   "content": text[:32000]},  # respect context window
        ],
        max_tokens=1024,
        temperature=0.1,
    )
    summary = response.choices[0].message.content
    logger.info(f"Summary generated ({len(summary)} chars)")

    # Store the summary as an artifact
    summary_bytes = summary.encode("utf-8")
    summary_art = ivcap.upload_artifact(
        name=f"{doc.name}-summary.txt",
        io_stream=io.BytesIO(summary_bytes),
        content_type="text/plain",
        content_size=len(summary_bytes),
        policy=req.policy,
    )

    return Result(summary=summary, summary_artifact=summary_art.urn)


if __name__ == "__main__":
    start_tool_server(service)
```

---

## Async LLM calls

For lambda services handling many concurrent requests, use the async client:

```python
from ivcap_service import get_async_llm_client

@ivcap_ai_tool("/", opts=ToolOptions(tags=["Analysis"]))
async def analyse(req: Request) -> Result:
    llm = get_async_llm_client()

    response = await llm.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "user", "content": req.query}
        ]
    )
    return Result(answer=response.choices[0].message.content)
```

---

## Tool calling (function calling)

The sidecar LLM client supports OpenAI-style tool/function calling. This enables
services that let the LLM decide which IVCAP services to invoke:

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "run_fire_risk_analysis",
            "description": "Run fire risk analysis for a region",
            "parameters": {
                "type": "object",
                "properties": {
                    "region": {
                        "type": "string",
                        "description": "Region name"
                    },
                    "threshold": {
                        "type": "number",
                        "description": "Detection threshold (0–1)"
                    }
                },
                "required": ["region"]
            }
        }
    }
]

response = llm.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Assess risk for Tasmania-North"}],
    tools=tools,
    tool_choice="auto",
)

# If the model chose to call a tool:
if response.choices[0].finish_reason == "tool_calls":
    tool_call = response.choices[0].message.tool_calls[0]
    import json
    args = json.loads(tool_call.function.arguments)
    # → submit a sub-job to the fire risk service with args["region"], args["threshold"]
```

---

## Streaming responses

For long-form generation, stream the response to reduce time-to-first-token:

```python
with llm.chat.completions.stream(
    model="gpt-4o",
    messages=[{"role": "user", "content": req.prompt}],
) as stream:
    chunks = []
    for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        chunks.append(delta)

full_text = "".join(chunks)
```

---

## Local development

In local development (`poetry ivcap run`), there is no sidecar. `get_llm_client()`
falls back to using the `OPENAI_API_KEY` environment variable:

```bash
export OPENAI_API_KEY="sk-..."
poetry ivcap run
```

To test against a different model provider locally, set the base URL:

```bash
export IVCAP_LLM_BASE_URL="https://api.anthropic.com/v1"
export IVCAP_LLM_API_KEY="sk-ant-..."
```

---

## Design tips

**Respect context window limits.** Truncate large inputs before sending to the LLM.
A common pattern is to limit to `text[:32000]` for safety, or use a tokeniser.

**Keep prompts in your code, not in parameters.** System prompts are part of your
service's behaviour — treat them like code, version them in Git.

**Record intermediate reasoning as aspects.** If your service uses chain-of-thought
or multi-step prompting, save reasoning steps as aspects on the job URN for auditability.

**Use low temperature for analytical tasks.** Set `temperature=0.0`–`0.2` for
deterministic, factual analysis; higher values for creative or exploratory tasks.

---

## Next steps

[→ Call Other Services](call-other-services.md){ .md-button .md-button--primary }
[→ Use Queues](use-queues.md){ .md-button }
