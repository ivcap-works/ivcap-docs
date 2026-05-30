# Platform overview

This page provides a **platform-level overview** of IVCAP. It is based on the platform overview material (Jan 2024).

## What are we trying to do?

Enable researchers to tackle **100x more ambitious challenges** by enabling **collaboration across science domains and organisations**.

IVCAP is a platform for rapid deployment of services for:

- Science
- Analytics
- Information management
- Collaboration

## The mental model

IVCAP revolves around a small set of concepts:

- **Service** – packaged compute/analysis capability (often containerised)
- **Order** – a request to execute a service with parameters
- **Workflow** – one or more connected tasks (often executed by a workflow engine)
- **Artifact** – a produced data product (dataset, table, image, model, report, …)
- **Data Fabric** – the layer for organising, tagging, querying and reusing data

Typical flow:

1. Discover a service
2. Submit an order
3. Monitor execution
4. Retrieve artifacts
5. Reuse artifacts as input into another order/workflow

## Foundations

### 1) Composable workflows

IVCAP supports packaging and deploying services from different teams and composing them into workflows.

*What’s usually covered here (to be expanded):*

- Service/task boundaries and reproducibility
- Service modes (single task vs multi-step workflows)
- Chaining services with artifacts

### 2) Data Fabric

The Data Fabric provides a structured way to organise and relate:

- records and collections (e.g. field trips, cameras)
- annotations and datasets
- models and model inference results
- observations/sightings

It aims to make data **discoverable**, **reusable**, and **governable** across teams.

### 3) Dataset as query

In IVCAP, a dataset can be defined by a *query* (intent) rather than only by a fixed file list.

Example intent (from the overview material):

> “A random sample of max N images taken by camera C in geo-area G.”

This enables repeatable dataset definitions, sampling, and re-materialisation as data grows.

## Supported stages of the investigative lifecycle

IVCAP is intended to support every stage and role involved in an investigation, such as:

- Field collection
- Data cleaning
- Annotation
- AI-assisted analysis
- Research synthesis

## High-level architecture (conceptual)

An IVCAP deployment typically includes:

- **API gateway + IVCAP API** (OpenAPI)
- **Workflow engine** (e.g. Argo) and **order dispatcher**
- **Data Fabric service** (incl. query/datalog engine)
- **Storage / artifact store**
- **Policy agent** (OPA) for access control decisions
- Clients: **ivcap-cli**, web app, client SDKs

## Where to go next

- If you want to *use* services: start at **[User Guide](../user-guide/index.md)**
- If you want to *build* services: start at **[Developer Guide](../developer-guide/README.md)**

---

### TODO (for follow-up instructions)

- Add a diagram-based walkthrough (reuse existing architecture SVGs in `docs/assets/` / `core-docs/images/svg/`)
- Add a glossary page and link terms throughout
- Add concrete examples of “dataset as query” (syntax/API/CLI)
