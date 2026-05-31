# CrewAI on IVCAP

[CrewAI](https://docs.crewai.com/) is a Python framework for orchestrating teams of
role-playing AI agents that collaborate on multi-step tasks. IVCAP supports CrewAI in
two distinct ways:

| Path | What you do | Best for |
|---|---|---|
| **Build your own CrewAI service** | Write Python that defines a `Crew`, wrap it as an IVCAP service | Custom agent logic; using IVCAP services as crew tools |
| **Use the IVCAP CrewAI runner** | Write a crew definition (YAML/JSON), submit it as a job | Running standard crews without deploying your own container |

Both paths produce provenance-tracked, reproducible executions with output stored
as IVCAP artifacts.

---

## Path 1: Build your own CrewAI service

### When to use this path

- You need custom logic in your crew (beyond what YAML can express)
- You want CrewAI agents to use **other IVCAP services** as tools
- You want the crew result to feed into subsequent IVCAP services
- You want full control over how the crew is constructed and kicked off

### How it works

You write a standard IVCAP service — a Python function decorated with
`@ivcap_ai_tool` — whose body creates and runs a CrewAI `Crew`. The crew's LLM
calls go through the IVCAP sidecar (no API key in your code), and any IVCAP service
can be wrapped as a CrewAI tool.

### Minimal example

```bash
poetry add crewai ivcap-ai-tool ivcap-service
```

```python
from crewai import Agent, Task, Crew, LLM
from crewai.tools import BaseTool
from pydantic import BaseModel, Field
from typing import ClassVar, Optional
import time

from ivcap_service import getLogger, Service, JobContext, get_llm_client
from ivcap_ai_tool import start_tool_server, ivcap_ai_tool, ToolOptions, logging_init

logging_init()
logger = getLogger("app")

service = Service(
    name="Research Crew",
    description="A CrewAI crew that researches a topic and produces a structured report.",
)


# ── Request / Result schemas ────────────────────────────────────────────────

class Request(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.research-crew.request.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    topic: str = Field(description="Topic to research")
    pdf_to_md_service: Optional[str] = Field(
        None, description="URN of PDF-to-Markdown service (used if source is a PDF artifact)"
    )
    source_artifact: Optional[str] = Field(
        None, description="Optional IVCAP artifact URN to use as source material"
    )

class Result(BaseModel):
    SCHEMA: ClassVar[str] = "urn:sd:schema.research-crew.1"
    jschema: str = Field(SCHEMA, alias="$schema")
    report: str = Field(description="Final research report")
    report_artifact: str = Field(description="URN of the stored report artifact")


# ── IVCAP service as a CrewAI tool ─────────────────────────────────────────

class PDFToMarkdownTool(BaseTool):
    """Converts a PDF artifact to Markdown using the IVCAP PDF-to-Markdown service."""

    name: str = "pdf_to_markdown"
    description: str = "Convert a PDF artifact (by URN) to Markdown text"
    ivcap: object  # injected at construction

    def _run(self, artifact_urn: str) -> str:
        svc = self.ivcap.get_service_by_name("PDF to Markdown")
        job = svc.request_job(svc.request_model(document=artifact_urn))
        while not job.finished:
            time.sleep(3)
            job.refresh()
        if not job.succeeded:
            raise RuntimeError(f"PDF conversion failed: {job.error}")
        # Download and return the Markdown text
        md_artifact = self.ivcap.get_artifact(job.result["markdown_artifact"])
        return md_artifact.as_file().read().decode("utf-8")


# ── CrewAI service handler ──────────────────────────────────────────────────

@ivcap_ai_tool("/", opts=ToolOptions(tags=["CrewAI", "Research"]))
def run_research_crew(req: Request, ctxt: JobContext) -> Result:
    """Run a CrewAI research crew on a given topic."""
    import io
    ivcap = ctxt.ivcap

    # The sidecar LLM client is OpenAI-compatible — pass it to CrewAI
    llm_client = get_llm_client()
    crew_llm = LLM(model="gpt-4o", client=llm_client)

    # Optionally build tools from IVCAP services
    tools = []
    if req.pdf_to_md_service:
        tools.append(PDFToMarkdownTool(ivcap=ivcap))

    # Define the crew
    researcher = Agent(
        role="Researcher",
        goal=f"Thoroughly research the topic: {req.topic}",
        backstory="You are a rigorous scientific researcher who finds and synthesises evidence.",
        llm=crew_llm,
        tools=tools,
        verbose=True,
    )

    writer = Agent(
        role="Technical Writer",
        goal="Produce a clear, well-structured report from the research findings",
        backstory="You are an expert science communicator who writes for informed audiences.",
        llm=crew_llm,
        verbose=True,
    )

    research_task = Task(
        description=f"Research the topic '{req.topic}'. "
                    + (f"Use the source material at {req.source_artifact}." if req.source_artifact else ""),
        expected_output="A comprehensive set of research notes with key findings and references.",
        agent=researcher,
    )

    writing_task = Task(
        description="Write a 500–800 word report based on the research notes.",
        expected_output="A well-structured Markdown report with an introduction, body, and conclusion.",
        agent=writer,
        context=[research_task],
    )

    crew = Crew(
        agents=[researcher, writer],
        tasks=[research_task, writing_task],
        verbose=True,
    )

    # Run the crew
    crew_result = crew.kickoff()
    report_text = crew_result.raw

    # Store the report as an IVCAP artifact
    report_bytes = report_text.encode("utf-8")
    report_art = ivcap.upload_artifact(
        name=f"research-report-{req.topic[:30]}.md",
        io_stream=io.BytesIO(report_bytes),
        content_type="text/markdown",
        content_size=len(report_bytes),
    )
    logger.info(f"Report stored: {report_art.urn}")

    return Result(report=report_text, report_artifact=report_art.urn)


if __name__ == "__main__":
    start_tool_server(service)
```

### Using IVCAP services as CrewAI tools

Any IVCAP service can be wrapped as a `BaseTool` subclass and given to a CrewAI agent.
The pattern is:

1. Subclass `crewai.tools.BaseTool`
2. Store the IVCAP client (`ctxt.ivcap`) as a field
3. In `_run()`, look up the IVCAP service, submit a job, and return the result as text

This lets CrewAI agents call domain-specific IVCAP services (data processors, analysers,
converters) as naturally as they call any other tool.

!!! note "PDF to Markdown"
    IVCAP includes a built-in `PDF to Markdown` service that converts PDF documents to
    clean Markdown. This is particularly useful as a tool for research agents that need
    to process scientific papers or reports. Wrap it as a `BaseTool` as shown above and
    pass it to agents that need document access.

### Agents calling agents via CrewAI tools

Just as individual IVCAP services can call other services as sub-jobs
(see [Multi-Agent Orchestration](multi-agent.md)), a CrewAI tool can submit a job to
another IVCAP agent service — including another deployed crew:

```python
class FactCheckerTool(BaseTool):
    name: str = "fact_checker"
    description: str = "Verify a list of references using the fact-checker agent"
    ivcap: object
    fact_checker_urn: str

    def _run(self, references: list[str]) -> str:
        agent = self.ivcap.get_agent(self.fact_checker_urn)
        job = agent.exec_agent(agent.request_model(references=references))
        if not job.succeeded:
            return f"Fact checking failed: {job.error}"
        return str(job.result["results"])
```

---

## Path 2: Use the IVCAP CrewAI runner

### When to use this path

- You want to run a standard crew without writing deployment boilerplate
- You are experimenting with crew designs and want fast iteration
- You want to run crews from outside IVCAP (via MCP, Jupyter, or the CLI)

### How it works

IVCAP hosts a pre-deployed **CrewAI runner service**. You define your crew in a YAML
configuration file (or inline JSON), upload it as an artifact, and submit a job to the
runner. The runner executes the crew, records provenance, and stores the output.

You focus on *what* the crew should do; IVCAP handles *how* it runs.

### Crew definition format

```yaml
# my_crew.yaml
crew:
  name: "Literature Review Crew"
  llm: gpt-4o          # model to use (configured on the IVCAP deployment)
  verbose: true

agents:
  - id: researcher
    role: "Literature Researcher"
    goal: "Find and summarise recent research on {topic}"
    backstory: "You are a rigorous academic researcher with broad scientific knowledge."

  - id: synthesiser
    role: "Knowledge Synthesiser"
    goal: "Produce a structured literature review from the research findings"
    backstory: "You distil complex research into clear, concise summaries for practitioners."

tasks:
  - id: research
    agent: researcher
    description: "Research recent developments on the topic: {topic}"
    expected_output: "A list of key findings with sources."

  - id: synthesis
    agent: synthesiser
    description: "Synthesise the research findings into a literature review."
    expected_output: "A structured 500-word literature review in Markdown."
    context: [research]
```

### Submitting the crew job

Upload the crew definition and submit it:

```bash
# Upload the crew definition
ivcap artifact upload my_crew.yaml
# → urn:ivcap:artifact:a1b2c3...

# Submit the job to the CrewAI runner
ivcap job create \
  --service urn:ivcap:service:crewai-runner \
  --param crew-definition=urn:ivcap:artifact:a1b2c3... \
  --param topic="Advances in battery energy storage" \
  --param output-policy=urn:ivcap:policy:ivcap.base.artifact
```

Or via the Python client:

```python
from ivcap_client.ivcap import IVCAP
import time

ivcap = IVCAP()

# Upload the crew definition
crew_art = ivcap.upload_artifact(name="my_crew", file_path="my_crew.yaml")
print(f"Crew definition: {crew_art.id}")

# Look up and run the CrewAI runner service
runner = ivcap.get_service_by_name("CrewAI Runner")
job = runner.request_job({
    "crew_definition": crew_art.id,
    "topic": "Advances in battery energy storage",
})

# Wait for result
while not job.finished:
    time.sleep(5)
    job.refresh()

print(job.result["report"])
```

### Passing tools to the runner

The CrewAI runner supports a curated set of built-in tools that can be enabled in
the crew definition:

```yaml
agents:
  - id: researcher
    role: "Researcher"
    goal: "Research {topic}"
    tools:
      - pdf_to_markdown   # converts PDF artifacts to text
      - web_search        # web search (if configured on the deployment)
```

To use a custom IVCAP service as a tool, provide its URN:

```yaml
agents:
  - id: analyst
    role: "Analyst"
    tools:
      - type: ivcap_service
        urn: "urn:ivcap:service:your-analysis-service"
        description: "Run domain-specific analysis on a dataset"
```

---

## Comparing the two paths

| | Build your own | Use the runner |
|---|---|---|
| **Control** | Full — custom Python logic | Limited to what the YAML schema supports |
| **IVCAP service tools** | Any service, fully customisable | Curated set + URN-addressed services |
| **Deployment** | You build and deploy a container | No deployment needed |
| **Iteration speed** | Slower (build, push, deploy) | Fast (edit YAML, submit job) |
| **Provenance** | Full, via IVCAP job tracking | Full, via IVCAP job tracking |
| **Best for** | Production, complex custom logic | Exploration, standard patterns |

---

## Local development (Path 1)

For developing a custom CrewAI service locally:

```bash
# Set up your environment
poetry add crewai ivcap-ai-tool ivcap-service
export OPENAI_API_KEY="sk-..."   # used instead of the sidecar locally

# Run the service locally
poetry ivcap run

# Test with curl
curl -s -X POST -H "content-type: application/json" \
  --data '{"$schema": "urn:sd:schema.research-crew.request.1", "topic": "ocean acidification"}' \
  http://localhost:8077 | jq '.report'
```

---

## Deploying a custom CrewAI service

```bash
git add . && git commit -m "research crew v1"
poetry ivcap deploy
```

```bash
# Run on IVCAP
ivcap job create \
  --service urn:ivcap:service:<your-crew-service-urn> \
  --param topic="ocean acidification"
```

---

## Next steps

[→ Using IVCAP from External Agents](using-ivcap-externally.md){ .md-button .md-button--primary }
[→ Multi-Agent Orchestration](multi-agent.md){ .md-button }
[→ Agent Patterns](agent-patterns.md){ .md-button }
