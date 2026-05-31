# 📘 Tutorial: Building a Gene Ontology (GO) Term Mapper Tool for the IVCAP Platform

## What should it do?

Maps genes or proteins to GO terms using a local or remote database (e.g., UniProt or QuickGO), optionally builds a graph.

* Input: List of gene symbols
* Output: GO terms and categories
* Bonus: Build a GO hierarchy using networkx

## Core Workflow

* Input: List of gene/protein IDs (e.g. UniProt IDs or gene symbols)
* Query: Use QuickGO or UniProt API to fetch GO annotations
* Filter: Select GO terms by category (BP, MF, CC)
* Output: JSON of GO annotations per gene
* Optional: Visualize GO hierarchy using networkx

## Sample Questions for an Agent using this tool

These are typical user-facing queries an AI assistant might receive:

* "What are the biological functions of genes TP53, AKT1, and MCM10?"
<br>→ Agent maps the gene symbols to UniProt IDs (if needed) and calls map_go_terms.

* "List GO terms for protein Q9H0H5 involved in cellular components."
<br>→ Uses map_go_terms(ids=["Q9H0H5"], category="CC").

* "Give me all molecular functions associated with proteins P12345 and Q96GD4."

* "Which GO terms are shared between these proteins?"
<br>→ Agent may call map_go_terms and perform post-processing to find overlaps.


## 🧰 Prerequisites

Before starting, ensure you have the following installed:

- Python 3.9+
- Git (for cloning repositories)
- Docker to build the service container
- `curl` or `wget` (for downloading binaries)



The rest of the tutorial is broken up into multiple steps:

- [Step 1: Install Poetry and IVCAP plugin](#step1)
- [Step 2: Install `ivcap` CLI Tool](#step2)
- [Step 3: Create Your Project Structure with Poetry](#step3)
- [Step 4: Add and install Dependencies](#step4)
- [Step 5: Implement the Core Functionality](#step5)
- [Step 6: Implement the IVCAP Service Wrapper](#step6)
- [Step 7: Run and test locally](#step7)
- [Step 8: Deploying to IVCAP](#step8)
- [Step 9: Testing the service on IVCAP](#step9)

Let's begin!

---

## Step 1: Install Poetry and IVCAP plugin <a name="step1"></a>

Poetry is a modern dependency and packaging manager for Python.

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

After installation, make sure Poetry is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Confirm installation:

```bash
poetry --version
```

Add the ICAP plugin to poetry:

```bash
poetry self add poetry-plugin-ivcap
```

Add confirm the installation of the plugin:

```bash
poetry ivcap version
```
---
## Step 2: Install `ivcap` CLI Tool <a name="step2"></a>

The application relies on the `ivcap` CLI. Install and build instructions can be found on [github](https://github.com/ivcap-works/ivcap-cli). A list of pre-built binaries can be found [here](https://github.com/ivcap-works/ivcap-cli/releases/latest).

### For macOS/Linux

If you use [homebrew](https://brew.sh/), you can install it by:

```
brew tap ivcap-works/ivcap
brew install ivcap
```

### For Windows (PowerShell):

```powershell
Invoke-WebRequest -Uri https://github.com/ivcap-works/ivcap-cli/releases/latest/download/ivcap-Windows-amd64.exe -OutFile ivcap.exe
Move-Item ivcap.exe 'C:\Program Files\ivcap\ivcap.exe'
# Add C:\Program Files\ivcap to your PATH if necessary
```

Verify installation:

```bash
ivcap --help
```

To configure it for a specific IVCAP deployment, follow [these instructions](https://github.com/ivcap-works/ivcap-cli?tab=readme-ov-file#configure-context-for-a-specific-deployment). For instance, to connect to the SD dev deployment, you can use (`sd-dev` is  a local alias, pick whatever makes it easy for you to remember, in case you work across multiple platofrm instancies):

```bash
ivcap context create sd-dev https://develop.ivcap.net
```

After setting up a specific context, please log in before proceeding. The ivcap poetry plugin is using the cli tool to communicate with the selected platform.

```bash
ivcap context login
```

If you have trouble logging in, see these [more detailed descriptions](https://github.com/ivcap-works/ivcap-cli?tab=readme-ov-file#configure-context-for-a-specific-deployment). For problems creating the initial accounts, please refer
to the individual platforms' support channels.

---

## Step 3: Create Your Project Structure with Poetry <a name="step3"></a>

```bash
poetry new my_app --flat
cd my_app
```

This creates:

```
my_app/
├── pyproject.toml
├── README.rst
├── my_app/
│   └── __init__.py
└── tests/
    └── __init__.py
```

> **Important:** Please open `pyproject.toml` in an editor and change the line `requires-python = ">=3.xx"` to `requires-python = ">=3.xx,<4.0"` where `xx` is your current python version (eg. 9, 10, 11, 12, ...). This is needed for version compatibility checks when adding dependencies in the next step.
---

## Step 4: Add and install Dependencies <a name="step4"></a>

```bash
poetry add httpx pydantic ivcap-ai-tool
```

> **Note:** If this results in errors like _"The current project's supported Python range (>=3.12) is not compatible with ..."_ make sure you have edited the `pyproject.toml` as instructed above.

To install the packages, run:

```bash
poetry install --no-root
```

---

## Step 5: Implement the Core Functionality <a name="step5"></a>

The base functionality will be provided by a function `fetch_go_terms(uniprot_id: str) -> List[Annotation]`
which takes a protein ID as argument and returns a list of annotations. It uses the
[Gene Ontology and GO Annotations (QuickGO)](https://www.ebi.ac.uk/QuickGO/) service to retrieve the
annotations.

Let's open a new file `my_app/go_term_fetcher.py` and add the following:

```python
async def fetch_go_terms(uniprot_id: str) -> List[Annotation]:
    """Fetch the annotations for 'uniprot_id' from the QuickGO service."""
    url = f"https://www.ebi.ac.uk/QuickGO/services/annotation/search"
    params = {
        "geneProductId": f"UniProtKB:{uniprot_id}",
        "limit": 100
    }
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()
        results = [Annotation(**d) for d in data["results"]]
        return results

def filter_by_category(go_terms: List[Annotation], category: str) -> List[Annotation]:
    """If 'category' is in GO_CATEGORIES, filter the go_terms by that category."""
    if category not in GO_CATEGORIES:
        return go_terms
    return [t for t in go_terms if t.goAspect == GO_CATEGORIES[category]]
```

We also need to import some libraries as well as define the _shape_ of the
returned annotations using the [Pydantic](https://docs.pydantic.dev/latest/) library. Add the following to the top of `go_term_fetcher.py`:

```python
import httpx
from typing import List, Dict, Optional
from pydantic import BaseModel

GO_CATEGORIES = {
    "BP": "biological_process",
    "MF": "molecular_function",
    "CC": "cellular_component",
}

class Annotation(BaseModel):
    id: Optional[str] = None
    geneProductId: Optional[str] = None
    qualifier: Optional[str] = None
    goId: Optional[str] = None
    goAspect: Optional[str] = None
    goEvidence: Optional[str] = None
    goName: Optional[str] = None
    assignedBy: Optional[str] = None
    symbol: Optional[str] = None
    synonyms: Optional[str] = None
    name: Optional[str] = None
    reference: Optional[str] = None
```

To test our progress so far, we add some code to verify that this is working to the end
of `go_term_fetcher.py`:

```python
if __name__ == "__main__":
    import asyncio
    import json
    from fastapi.encoders import jsonable_encoder

    async def main():
        terms = await fetch_go_terms("P12345")
        print(json.dumps([jsonable_encoder(term) for term in terms[:3]], indent=2))
    asyncio.run(main())
```

And now, let's test it by executing `poetry run python my_app/go_term_fetcher.py`:

```bash
poetry run python my_app/go_term_fetcher.py
```

You should see something like:

```bash
% poetry run python my_app/go_term_fetcher.py
[
  {
    "id": "UniProtKB:P12345!306410571",
    "geneProductId": "UniProtKB:P12345",
    "qualifier": "enables",
    "goId": "GO:0003824",
    "goAspect": "molecular_function",
    "goEvidence": "IEA",
    "goName": null,
    "assignedBy": "InterPro",
    "symbol": "GOT2",
    "synonyms": null,
    "name": null,
    "reference": "GO_REF:0000002"
  },
  {
    "id": "UniProtKB:P12345!306410572",
    "geneProductId": "UniProtKB:P12345",
    "qualifier": "enables",
    "goId": "GO:0004069",
    "goAspect": "molecular_function",
    "goEvidence": "ISS",
    "goName": null,
    "assignedBy": "UniProt",
    "symbol": "GOT2",
    "synonyms": null,
    "name": null,
    "reference": "GO_REF:0000024"
  },
  {
    "id": "UniProtKB:P12345!306410573",
    "geneProductId": "UniProtKB:P12345",
    "qualifier": "enables",
    "goId": "GO:0004069",
    "goAspect": "molecular_function",
    "goEvidence": "IEA",
    "goName": null,
    "assignedBy": "UniProt",
    "symbol": "GOT2",
    "synonyms": null,
    "name": null,
    "reference": "GO_REF:0000120"
  }
]
```

---

## Step 6: Implement the IVCAP Service Wrapper <a name="step6"></a>

Our tool is stateless as well as requires little computational resources. In fact, most of the run time
will be spent to wait for the reply from the remote _QuickGO_ service. In short it can easily process many requests in
parallel and is an excellent candidate for a FaaS type service. In practical terms, we will implement a web service
which will receive requests as `POST` events and return the result in JOSN format.

Therefore, our plan is as follows:

* Add a `tool.poetry-plugin-ivcap` section to `pyproject.toml`
* Create a new file `my_app/service.py`
* Describe the service (`Service(...)`)
* Define the Request as well as Result [Pydantic](https://docs.pydantic.dev/latest/) models
* Implement the IVCAP service wrapper around the previously defined `fetch_go_terms` function
* Add code to start the server


In `pyproject.toml`, add the following to the end of the file:

```toml
[tool.poetry-plugin-ivcap]
service-file = "my_app/service.py"
service-type = "lambda"
port = 8077
```

Now, let's open a new file `my_app/service.py` and add the following sections to that file:

### Headers and logging setup

```python
import os
from typing import List, Dict, Optional
import asyncio
from pydantic import BaseModel, ConfigDict, Field
from ivcap_service import getLogger, Service
from ivcap_ai_tool import start_tool_server, logging_init, ToolOptions, ivcap_ai_tool

from go_term_fetcher import Annotation, fetch_go_terms, filter_by_category

logging_init()
logger = getLogger("app")
```

### Service description

```python
service = Service(
    name="Gene Ontology (GO) Term Mapper",
    contact={
        "name": "Mary Doe",
        "email": "mary.doe@acme.au",
    },
)
```

### Request and Result model

We already have implemented our function, but need more formally define the _shape_ or _schema_ of the incoming request
as well as the reply. For that, we will add the two models `Request` and `Result`
using the additional functionality from the [Pydantic](https://docs.pydantic.dev/latest/) library to
make them more self-descriptive:


```python
class Request(BaseModel):
    jschema: str = Field("urn:sd:schema.gene-ontology-term-mapper.request.1", alias="$schema")
    ids: List[str] = Field(description="List of UniProt IDs")
    category: Optional[str] = Field(None, description="GO category: BP, MF, or CC")

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "$schema": "urn:sd:schema.gene-ontology-term-mapper.request.1",
            "ids": [ "P12345", "Q9H0H5" ],
            "category": "BP"
        }
    })

class Result(BaseModel):
    jschema: str = Field("urn:sd:schema.gene-ontology-term-mapper.1", alias="$schema")
    results: Dict[str, List[Annotation]] = Field(description="contains a list of annotations for every UniProt ID")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "$schema": "urn:sd:schema.gene-ontology-term-mapper.1",
                "results": {
                    "P12345": [{
                        "id": "UniProtKB:P12345!296618610",
                        "geneProductId": "UniProtKB:P12345",
                        "qualifier": "involved_in",
                        "goId": "GO:0006103",
                        "goAspect": "biological_process",
                        "goEvidence": "ISS",
                        "assignedBy": "UniProt",
                        "symbol": "GOT2",
                        "reference": "GO_REF:0000024"
                    }]
                }
            }
        },
    )
```

### The service wrapper

We now implement the "wrapper" function which takes the above `Request` instance, calls the previously defined
`fetch_go_terms` function for each of the requested UniProt IDs and assembles the result. Please note that we
are adding a quite extensive 'doc_string' to the function. The IVCAP SDK will use this as the tool description
accessible to the various agent frameworks.

```python
@ivcap_ai_tool("/", opts=ToolOptions(tags=["GO Term Mapper"]))
async def map_go_terms(
    req: Request
) -> Result:
    """This function maps a set of protein or gene identifiers (typically UniProt IDs)
    to their corresponding Gene Ontology (GO) annotations using the QuickGO REST API.
    It can filter results by specific GO categories and is optimized for
    multi-ID batch processing.

    Supported high-level are:
    * GO categories are Biological Process (BP)
    * Molecular Function (MF)
    * Cellular Component (CC)

    Typical use-cases for this function are:
    * Enriching gene or protein datasets with structured functional annotations
    * Supporting biological data exploration or hypothesis generation
    * Downstream graph or network construction for biological analysis
"""
    results = {}

    async def fetch_and_filter(uid):
        terms = await fetch_go_terms(uid)
        filtered = filter_by_category(terms, req.category) if req.category else terms
        results[uid] = filtered

    await asyncio.gather(*(fetch_and_filter(i) for i in req.ids))
    return Result(results=results)
```

### Code to start the server

```python
if __name__ == "__main__":
    start_tool_server(service)
```

---

## Step 7: Run and test locally <a name="step7"></a>

In one terminal window, start the service:

```bash
poetry ivcap run
```

which should look like:

```bash
% poetry ivcap run
Running: poetry run python my_app/service.py --port 8077
2025-06-02T09:54:13+1000 INFO (app): Gene Ontology (GO) Term Mapper - 0.1.0|9083543|2025-06-02T09:54:12+10:00 - v0.7.6
2025-06-02T09:54:13+1000 INFO (uvicorn): Started server process [22445]
2025-06-02T09:54:13+1000 INFO (uvicorn): Waiting for application startup.
2025-06-02T09:54:13+1000 INFO (uvicorn): Application startup complete.
2025-06-02T09:54:13+1000 INFO (uvicorn): Uvicorn running on http://0.0.0.0:8077 (Press CTRL+C to quit)
```

To test the service, we need to first define a request. For that, open a new file `two_bp.json` and add the following:

```json
{
  "$schema": "urn:sd:schema.gene-ontology-term-mapper.request.1",
  "ids": [
    "P12345",
    "Q9H0H5"
  ],
  "category": "BP"
}
```

In a different terminal window, use `curl` (or `wget`) to directly call the service:

```bash
curl -X POST \
    -H "content-type: application/json" \
    -H "timeout: 60" \
    --data @two_bp.json \
    http://localhost:8077
```

Adding a json formatter, like `jq` should give us a nicely formatter reply:

```bash
% curl -X POST \
    -H "content-type: application/json" \
    -H "timeout: 60" \
    --data @tests/two_bp.json \
    http://localhost:8077 | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10031  100  9907  100   124   4968     62  0:00:02  0:00:01  0:00:01  5028
{
  "$schema": "urn:sd:schema.gene-ontology-term-mapper.1",
  "results": {
    "P12345": [
      {
        "id": "UniProtKB:P12345!306410578",
        "geneProductId": "UniProtKB:P12345",
        "qualifier": "involved_in",
        "goId": "GO:0006103",
        "goAspect": "biological_process",
        "goEvidence": "ISS",
        "goName": null,
        "assignedBy": "UniProt",
        "symbol": "GOT2",
        "synonyms": null,
        "name": null,
        "reference": "GO_REF:0000024"
      },
      ...
```

---

## Step 8: Deploying to IVCAP <a name="step8"></a>

To deploy a service or tool to IVCAP, we need to do the following:

* Build and test the service as a Docker container
* Create a `git commit` of progress so far
* Publish the service container
* Register the service
* Register the service as a tool

### Build and test the service as a Docker container

To package the code we have developed so far into a docker container, we first need to
create a Dockerfile.

The first line in the Dockerfile references an image with a specific version of python already installed.

Please check the version of python referenced in the `pyproject.toml` file with:

```bash
poetry run python --version
```
Depending on the major (3) and minor (e.g. 10, 11, 12) pick the appropriate base image:

| Python Version | Base Image Tag                |
|----------------|-------------------------------|
| **3.10**       | `python:3.10-slim-bullseye`   |
| **3.11**       | `python:3.11-slim-bookworm`   |
| **3.12**       | `python:3.12-slim-bookworm`   |

Now open a file named `Dockerfile` and add the following, replacing `#BASE_IMAGE#` with the respective version from the above table:

```dockerfile
FROM #BASE_IMAGE#
RUN pip install poetry

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false && poetry install --no-root

COPY . .

# VERSION INFORMATION
ARG VERSION ???
ENV VERSION=$VERSION
ENV PORT=80

# Command to run
ENTRYPOINT ["python",  "/app/service.py"]
```

To test our setup, we will first build the docker image locally:

```bash
poetry ivcap docker-build
```

You should see something like:
```bash
% poetry ivcap docker-build
INFO: docker buildx build -t gene_onology_term_mapper_arm64:9a9a7cc --platform linux/arm64 --build-arg VERSION=0.1.0|9a9a7cc|2025-05-29T08:48:39+10:00 --build-arg BUILD_PLATFORM=linux/arm64 -f /Dockerfile --load .
[+] Building 43.3s (1/10)
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 441B
 => [internal] load metadata for docker.io/library/python:3.10-slim-buster
 ...
 INFO: Docker build completed successfully
```

You can now test the docker image.

> **Note:** Before proceeding make sure that the above test with the
"plain" python files has been terminated and the associated port freed.

```bash
poetry ivcap docker-run
```

This should create a service listening on the same port as in the above "Run and test locally" step. The same 'curl' (or 'wget') tests should succeed and return the same results.

After verifying that the docker container build successfully, we can now deploy it:

### Create a `git commit` of progress so far

IVCAP only accespt versioned services identifying a specific implementation of a service. Any invocation of a service will also create a proveneance record not only of what service has been used to produce a particular result, but also
its version as well as any other relevant properties.

As `git` has been widely adopted to mainain similar versin control of software, we have been adopting the `commit` hash of the current source code as the version for the respective docker container.

Therefore, we need to turn this directory into a git repository, add all the created code so far and "commit" all that to create our initial commit hash.

```bash
git init
git add .
git commit -m "initial implementation of my_app"
```

To verify that we indeed have a commit hash, run the following:

```bash
git rev-parse --short HEAD
```

You should see something like:
```bash
% git rev-parse --short HEAD
635d141
```

### Publish the service container

Now we should have everything in place to publish the previoulsy build and tested docker container. Please note, that if
the architecture of your local machine uses a different CPU architecture from the one
used for the target platform, the following command will first build a new container for the target platform.
This is likely the case if your development machine is using an ARM CPU (like Apple Silicon).

```
poetry ivcap deploy
```


You should see something similar to:
```bash
$ poetry ivcap deploy
INFO: docker buildx build -t gene_onology_term_mapper_amd64:9a9a7cc --platform linux/amd64 --build-arg VERSION=0.2.0|b4dbd44|2025-05-28T16:27:56+10:00 --build-arg BUILD_PLATFORM=linux/amd64 -f Dockerfile --load .
[+] Building 0.9s (14/14) FINISHED
=> [internal] load build definition from Dockerfile
...
INFO: Docker build completed successfully
...
INFO: Image size 287.9 MB
Running: ivcap package push --force --local gene_onology_term_mapper_amd64:9a9a7cc
 Pushing gene_onology_term_mapper_amd64:9a9a7cc from local, may take multiple minutes depending on the size of the image ...
...
 45a06508-5c3a-4678-8e6d-e6399bf27538/gene_onology_term_mapper_amd64:9a9a7cc pushed
INFO: package push completed successfully
...
INFO: service definition successfully uploaded - urn:ivcap:aspect:1c1c1714-1456-4e44-9433-f1a24099673d
...
INFO: tool description successfully uploaded - urn:ivcap:aspect:1632a3df-c79e-43c3-be75-06ff3a6138d2

```

---

## Step 9: Testing the service on IVCAP <a name="step9"></a>

To test the service we have deployed in the previous step we can follow the same sequence as in
[Step 7: Run and test locally](#step7). We can use the same test request `two_bp.json`.

```bash
poetry ivcap job-exec two_bp.json
```

Running this, we should see something like:
```
% poetry ivcap job-exec two_bp.json
Creating job 'https://develop.ivcap.net/1/services2/urn:ivcap:service:ac158a1f-dfb4-5dac-bf2e-9bf15e0f2cc7/jobs'
{
  "$schema": "urn:sd:schema.gene-ontology-term-mapper.1",
  "results": {
    "P12345": [
      {
        "assignedBy": "UniProt",
        "geneProductId": "UniProtKB:P12345",
        "goAspect": "biological_process",
        "goEvidence": "ISS",
        "goId": "GO:0006103",
        "goName": null,
        "id": "UniProtKB:P12345!306410578",
        ...
```
---

## 🏁 Conclusion

You’ve built a fully functional IVCAP service which can also be used as an AI tool using:

- Poetry for dependency and packaging
- `ivcap` CLI for interacting with an IVCAP deployment
- calls to external services, such as QuickGO