# IVCAP Docs — Maintenance Guide

This document is for whoever is maintaining this documentation site — whether
that is a human engineer or an AI agent. It explains the site's objectives,
the audience it serves, the concepts it covers, the writing style it follows,
and how to use the various repos and registries to keep it accurate and current.

---

## Table of Contents

1. [Site Objectives](#1-site-objectives)
2. [Intended Audiences](#2-intended-audiences)
3. [Core IVCAP Concepts](#3-core-ivcap-concepts)
4. [Writing Style Guide](#4-writing-style-guide)
5. [Information Architecture](#5-information-architecture)
6. [Working with Example Repos](#6-working-with-example-repos)
7. [Working with SDK Repos](#7-working-with-sdk-repos)
8. [Working with Background Docs](#8-working-with-background-docs)
9. [Keeping the API Section Accurate](#9-keeping-the-api-section-accurate)
10. [Common Maintenance Tasks](#10-common-maintenance-tasks)
11. [Agent-Specific Instructions](#11-agent-specific-instructions)
12. [Agent-Friendly Site Strategy](#12-agent-friendly-site-strategy)

---

## 1. Site Objectives

The IVCAP documentation site has four primary objectives:

### 1.1 Be the single front door for all IVCAP users and developers

A user or developer encountering IVCAP for the first time should be able to
arrive here and — within five minutes — understand what the platform does and
take their first concrete action (run a service, or start building one). The
site should reduce time-to-first-success, not comprehensively describe every
internal detail.

### 1.2 Surface example repos as navigable documentation

The `ivcap-works` GitHub organisation hosts over a dozen example and template
repos. Currently these are raw GitHub links. The site's job is to pull their
README content and present it as browsable, searchable documentation pages —
keeping users on the site rather than bouncing them out to GitHub.

### 1.3 Keep the API reference accurate as the platform evolves

The platform's API is documented in `background_docs/FOR_USERS.md` as well as `background_docs/openapi3.json`.
The public site's API section (`docs/API/`) must reflect that source of truth.

### 1.4 Reflect the correct terminology as the platform matures

The platform is migrating from the word *order* to *job* as the canonical term
for a service execution. The docs must handle this transition carefully — using
"job" in API contexts, "order" in CLI contexts (where the literal command is
`ivcap order ...`), and explaining the equivalence in the glossary.

---

## 2. Intended Audiences

The site serves three distinct audiences. Each has a different entry point and
different success criteria.

### 2.1 Users (scientists, analysts, data engineers)

*They want to run existing services — not build new ones.*

They arrive via the **Getting Started** and **User Guide** sections. Their
success is:
- Finding a service that does what they need
- Submitting a job with their data
- Downloading the result

They think in terms of data files, results, and reproducibility. They may not
know Python or Docker. They use the CLI or a Jupyter notebook with the Python
client SDK.

**Key pages for this audience:**
- `docs/getting-started/quick-start.md`
- `docs/user-guide/discover-services.md`
- `docs/user-guide/run-and-monitor-orders.md`
- `docs/user-guide/work-with-artifacts.md`

### 2.2 Service Authors (software engineers, researchers building tools)

*They want to wrap their code as an IVCAP service.*

They arrive via the **Developer Guide**. Their success is:
- Understanding the service model (lambda vs batch)
- Writing a containerised service using the Python service SDK
- Registering and testing it locally
- Deploying it to a shared IVCAP instance

They know Python and Docker. They want code examples, not prose.

**Key pages for this audience:**
- `docs/getting-started/choosing-starting-point.md`
- `docs/developer-guide/develop-services.md`
- `docs/developer-guide/deploy-services.md`
- `docs/examples/` (especially beginner examples)

### 2.3 Application Developers (engineers integrating IVCAP into other systems)

*They want to call IVCAP from their own code — not build services inside it.*

They arrive via the **API** section or the **Developer Guide → SDK** page.
Their success is:
- Understanding the REST API structure (resources, authentication, pagination)
- Making their first authenticated API call
- Using the Python client SDK or Go client from their own application

They are comfortable with REST APIs and want accurate reference material.

**Key pages for this audience:**
- `docs/API/` (all pages)
- `docs/developer-guide/sdk.md`
- `docs/developer-guide/integration-options.md`

---

## 3. Core IVCAP Concepts

Understanding these concepts is required before editing any page. Every doc
page should use this vocabulary consistently.

### Service

A registered analytic capability. Has a name, a set of typed parameters, and
an execution environment (a Docker image). Users submit jobs to services.
Services are identified by URNs (`urn:ivcap:service:<uuid>`).

There are two service execution modes:
- **Lambda (request/response):** Short-lived; result is returned synchronously
  or via a short poll. Analogous to a function call.
- **Batch (async):** Long-running; result appears as output artifacts once the
  job completes. Analogous to a pipeline stage.

### Job (Order)

A single execution of a service, created by submitting parameters to a service
endpoint. Identified by `urn:ivcap:job:<uuid>`.

> **Terminology note:** Older parts of the CLI and some internal schemas use
> *order* instead of *job*. They mean the same thing. The platform is converging
> on *job* as the canonical term. In docs: use "job" when describing the API
> resource; use "order" when showing literal CLI commands (`ivcap order create …`).

Job status values (in lifecycle order):
`pending` → `scheduled` → `executing` → `succeeded` | `failed` | `error`

### Artifact

Any binary or structured data blob stored in the platform — images, CSVs,
models, JSON results, etc. Identified by `urn:ivcap:artifact:<uuid>`. Supports
two upload modes: single-shot (≤ 16 MB via PUT) and resumable TUS protocol
(≤ 5 GB via PATCH).

Artifacts have typed metadata attached as Aspects (see below). They are the
primary currency of data exchange between services and users.

### Aspect

A typed, time-stamped, append-only metadata record attached to any entity URN
(service, job, artifact, or another aspect). Identified by
`urn:ivcap:aspect:<uuid>`. Aspects are the *metadata currency* of the platform.

Key properties:
- **Append-only:** aspects are never deleted; they can be *retracted* (given a
  `validTo` timestamp) but the historical record is always preserved.
- **Point-in-time queries:** any entity's state at any past moment can be
  reconstructed by querying aspects `?at-time=<ISO8601>`.
- **Typed by schema URN:** every aspect declares its schema as
  `urn:ivcap:schema:<name>.<version>`.
- **Provenance:** the platform automatically records aspects for every job
  lifecycle event, artifact creation, and artifact consumption. This creates an
  immutable audit trail.

Aspects underpin discoverability, provenance tracking, and the Data Fabric.
They deserve their own capability page — they are not merely a metadata
footnote.

### Data Fabric (Datafabric)

The platform's universal, append-only information store. Every Aspect lives in
the Data Fabric. It supports collections, annotations, datasets, and
point-in-time queries. The Data Fabric is what makes IVCAP's provenance model
work at scale.

### Queue

An async message queue for communication between services or pipeline stages.
One service enqueues work items; another dequeues and processes them. Useful
for fan-out patterns and long-running pipelines.

### URN

All IVCAP identifiers are URNs of the form `urn:ivcap:<type>:<uuid>`. They are
stable, globally unique, and version-independent. Common URN types: `service`,
`job`, `artifact`, `aspect`, `schema`, `account`, `queue`, `policy`.

The CLI accepts short aliases (`@1`, `@2`, …) as convenience references to
recently seen URNs within a session.

---

## 4. Writing Style Guide

### Voice and tone

- **Second person, active voice.** Write "you submit a job" not "a job is
  submitted". Write "run `ivcap service list`" not "the user should run …".
- **Practical over theoretical.** Every concept explanation should be followed
  immediately by a concrete CLI command or code snippet.
- **Terse prose, rich examples.** Prefer short paragraphs. Let the code block
  carry the weight.
- **No marketing language.** Avoid "powerful", "seamless", "cutting-edge".
  Describe what the thing *does*, not how impressive it is.

### Terminology rules

| Use | Instead of | Notes |
|---|---|---|
| job | order | In API context; REST resource is `/jobs` |
| artifact | file, data, output | IVCAP's term for stored data blobs |
| aspect | metadata | When referring to the typed, append-only records |
| service | tool, function | The IVCAP term for a registered capability |
| submit a job | run a service, execute | The action a user takes |
| Data Fabric | Datafabric, data fabric | Mixed case as shown; avoid capitalising "data fabric" in prose |

### Code blocks

- Always specify the language for syntax highlighting: ` ```bash `, ` ```json `,
  ` ```python `.
- In CLI examples, use `$` as the prompt; omit the prompt on output-only lines.
- Prefer `ivcap` CLI examples for user-facing actions; use `curl` examples for
  the equivalent REST call when showing both is useful.
- Replace real UUIDs with `<uuid>` placeholders.

### Admonitions

Use Material's admonition boxes sparingly:

```markdown
!!! note
    Use for important clarifications that aren't warnings.

!!! tip
    Use for time-saving shortcuts a reader might miss.

!!! warning
    Use only for things that could cause data loss or authentication failure.
```

Do not use admonitions for every paragraph — they lose impact.

### Links

- **Internal links:** use relative paths (`../API/artifact.md`).
- **External API reference:** link to the SDK's GitHub Pages site; do not
  duplicate auto-generated API reference content here.
- **Example repos:** link to the example page within this site (once generated)
  rather than directly to GitHub.

### Page structure

Every page should follow this rough structure:
1. **H1 title** — matches the nav label exactly
2. **One-sentence summary** — what this page helps you do
3. **Prerequisites** (if any) — what the reader needs installed/done first
4. **Main content** — concept explanation + code examples, interleaved
5. **See also** — 2–4 links to related pages

---

## 5. Information Architecture

The site uses a Diátaxis-inspired structure with audience-routed Guides.
The top-level tabs (enabled via `navigation.tabs`) are:

```
Home                     → what is IVCAP; 4-path chooser; MCP quick note

Concepts                 → the "why" and "what" — explains the platform once
  How IVCAP Works (index)
  Services and Jobs
  Artifacts
  Aspects and Provenance
  The Data Fabric
  Queues
  Agentic Patterns       ← services calling services; LLM sidecar; MCP

Get Started              → one tutorial per audience (short, hand-held)
  Install the CLI
  Run Your First Analysis  (5 min, CLI)
  Build Your First Service (15 min, Python SDK)
  Build Your First AI Agent (20 min)

Guides                   → task-oriented how-to, grouped by audience
  Running Analyses       → for scientists / analysts / data engineers
    Discover Services
    Submit and Monitor Jobs
    Work with Artifacts
    Query Provenance
    Troubleshooting
  Building Services      → for software engineers / service authors
    Service Basics
    Using Artifacts
    Using Queues
    Calling Other Services
    Calling LLMs
    Deploy and Register
    Running Locally
  Building AI Agents     → for AI engineers building agentic services
    Agent Patterns
    Multi-Agent Orchestration
    CrewAI on IVCAP
    LlamaIndex on IVCAP
  Integrating IVCAP      → for application developers
    Authentication
    Python Client SDK
    REST API Primer
    Using IVCAP via MCP  ← CLI MCP server; Claude Desktop; Cline config

Reference                → look-up material; no explanation
  Glossary
  URN Reference
  CLI Reference
  REST API →
    Services / Orders / Artifacts / Aspects / Queues /
    Secrets / Packages / Sessions / Live Events / Search

Examples                 → generated from example-registry.json
  Examples gallery (index)
  Capability Matrix

Operators                → deploy and manage IVCAP itself
  Architecture / Installation / Security
```

**Key design decisions:**

- **Concepts live in their own tab**, separate from Guides. A reader understands
  the platform model once (Concepts), then applies it in task-oriented steps (Guides).
- **Agents are a top-level audience** in the Guides tab — not a footnote.
- **MCP is a first-class integration path** — covered in Concepts (agentic-patterns),
  Guides (integrating/mcp), and Reference (cli).
- **The API Reference tab is gone** — REST API lives under Reference alongside
  the Glossary, URNs, and CLI, keeping it as look-up material, not a guide.
- **Operator Manual is reinstated** as its own tab (was commented out before).

---

## 6. Working with Example Repos

### What example repos are

Repos in the `ivcap-works` organisation that demonstrate a pattern or provide
a template for building IVCAP services. Each repo has a README; the site pulls
that README and presents it as a documentation page.

### Registry file

All example repos are listed in **`config/example-registry.json`**. Each entry
specifies:

| Field | Description |
|---|---|
| `slug` | Short identifier used as the page filename (`docs/examples/<slug>.md`) |
| `name` | Human-readable name shown in the nav and page title |
| `repo` | `ivcap-works/<repo-name>` — the GitHub repo to clone |
| `branch` | Branch to pull from (almost always `main`) |
| `capabilities` | Which capability slugs this example demonstrates |
| `sdks` | Which SDK slugs the example uses |
| `difficulty` | `beginner` \| `intermediate` \| `advanced` |
| `pull_files` | Files to pull from the repo (usually `["README.md"]`) |

### Adding a new example

1. Add an entry to `config/example-registry.json` (see README.md for the template).
2. Run `make validate` to check the entry is schema-valid.
3. Run `make fetch-example EX=<slug>` to pull its README.
4. Check `content/examples/<slug>/` — confirm the README is meaningful and has
   enough context to be useful without the full GitHub repo.
5. If the README is too sparse, consider linking to the repo instead and
   writing a brief hand-authored stub in `docs/examples/<slug>.md`.
6. Commit `config/example-registry.json` and any hand-authored stubs.

### Updating fetched example content

Example READMEs are re-pulled every time `make fetch` or `make build` runs.
You do not need to manually update fetched content — just ensure `make fetch`
runs in CI (which `build.yml` does nightly).

### notify-hub.yml

The file at `.github/workflows/notify-hub.yml` is a *template* intended for
copy-paste into each example repo. When an example repo pushes to `main`, it
dispatches a repository dispatch event to `ivcap-docs`, triggering a rebuild.
This keeps the docs at most one build cycle stale after an example is updated.

---

## 7. Working with SDK Repos

### What SDK repos are

Repos in `ivcap-works` that provide libraries or tools users install — not
examples. The Python service SDK, Python client SDK, and CLI are the current
entries. A JS/TS SDK is planned.

The distinction between **service SDK** and **client SDK** matters:
- A **service SDK** is used *inside* a containerised service to fetch inputs,
  deliver outputs, and self-describe its parameters.
- A **client SDK** is used *from outside* — notebooks, pipelines, apps — to
  discover services, submit jobs, and manage artifacts.

### Registry file

All SDK repos are listed in **`config/sdk-registry.json`**. Key fields:

| Field | Description |
|---|---|
| `slug` | Identifier used in nav and page names |
| `github_pages_url` | Where the auto-generated API reference lives |
| `pull_docs` | Paths inside the repo's `docs/` folder to pull as narrative docs |
| `audience` | `service-author` \| `app-developer` \| `all` |

### pull_docs paths

Before adding a new SDK to the registry, clone the repo and inspect its `docs/`
folder. The `pull_docs` paths must exist in the repo exactly as written. If
the repo has no `docs/` folder yet, set `pull_docs: []` as a placeholder and
add a hand-authored stub page linking to the repo.

### Narrative docs vs API reference

The site pulls **narrative docs** (getting-started guides, concept explanations,
code walkthroughs) from the SDK repos. It does **not** duplicate the
auto-generated API reference (pydoc, godoc). Instead, each SDK page links out
to the SDK's GitHub Pages site for the full reference. This avoids stale
duplicated content.

### Adding a new SDK

1. Add an entry to `config/sdk-registry.json` (see README.md for the template).
2. Run `make validate` to check the entry.
3. Inspect the repo's `docs/` folder; adjust `pull_docs` if needed.
4. Run `make fetch-sdk SDK=<slug>`.
5. Review `content/sdk/<slug>/` — check that pulled content reads well in
   context (the pulled markdown may use repo-relative links that need fixing).
6. Create `docs/developer-guide/sdk-<slug>.md` as the overview page
   (what the SDK is for, install instructions, link to GitHub Pages reference).
7. Update `docs/developer-guide/sdk.md` to include the new SDK in the
   comparison table.
8. Add the new page to `mkdocs.yml` nav.

---

## 8. Working with Background Docs

### What background docs are

Some source documentation lives in **private** `ivcap-works` repos and cannot
be auto-fetched at CI build time. However, the content itself is public
knowledge — only the repo access is restricted.

The `background_docs/` folder in this repo contains snapshots of those private
documents. A human maintainer copies the latest content in; the AI agent reads
from there and updates the corresponding public pages.

### Current background docs

| File | Source | Last updated | Covers |
|---|---|---|---|
| `background_docs/for_users.md` | `ivcap-core/FOR_USERS.md` | 2026-05-30 | Full API reference, auth, URNs, provenance model |

### Source-comment header

Every background doc must start with a source comment:

```markdown
<!-- SOURCE: ivcap-works/ivcap-core — FOR_USERS.md — copied YYYY-MM-DD -->
<!-- This file is a snapshot of a private document. Content is public. -->
```

Update the date whenever you update the content. This lets maintainers quickly
see how stale each snapshot is.

### Updating a background doc

1. Open the source file in its private repo.
2. Copy the full content into `background_docs/<file>.md`.
3. Update the date in the source-comment header.
4. Commit the updated file.
5. Ask the agent to identify which public pages are affected and update them
   (see §11 below, or the [Agent Instructions in IVCAP-PLAN.md](_next_phase/IVCAP-PLAN.md#agent-instructions)).

### Section-to-page mapping for `background_docs/for_users.md`

When `for_users.md` changes, use this table to identify which public pages to update:

| Section in for_users.md | Public page to update |
|---|---|
| §1 What IVCAP Does for You | `docs/getting-started/platform-overview.md` |
| §2 Key Concepts | `docs/getting-started/platform-overview.md`, `docs/glossary.md` |
| §3.2 Authentication | `docs/API/sessions.md` |
| §3.3 CLI | `docs/user-guide/cli-basics.md` |
| §3.4 SDKs | `docs/developer-guide/sdk.md` |
| §4 Typical Workflow | `docs/getting-started/quick-start.md` |
| §5.1 Services | `docs/API/service.md` |
| §5.2 Jobs (Orders) | `docs/API/orders.md` |
| §5.3 Artifacts | `docs/API/artifact.md` |
| §5.4 Aspects | `docs/API/aspects.md` |
| §5.5 Queues | `docs/API/queues.md` |
| §5.6 Secrets | `docs/API/secrets.md` |
| §5.7 Packages | `docs/API/packages.md` |
| §8 Provenance | `docs/user-guide/datafabric/index.md`, `docs/API/aspects.md` |
| §9 SSE Events | `docs/API/events.md` |
| §10 URN Reference | `docs/reference/urns.md` |

---

## 9. Keeping the API Section Accurate

### Current state (as of May 2026)

The `docs/API/` section has coverage for services, jobs/orders, artifacts, and
sessions/auth. The following are **missing and high priority**:

| Resource | Target file | Source section in for_users.md |
|---|---|---|
| Aspects | `docs/API/aspects.md` | §5.4 and §8 (provenance) |
| Queues | `docs/API/queues.md` | §5.5 |
| Secrets | `docs/API/secrets.md` | §5.6 |
| Packages | `docs/API/packages.md` | §5.7 |
| Live Events (SSE) | `docs/API/events.md` | §9 |
| URN Reference | `docs/reference/urns.md` | §10 |

### How to write a new API page

1. Read the relevant section in `background_docs/for_users.md`.
2. Do **not** copy it verbatim — adapt it to match the site's writing style
   (second person, code-first, brief prose).
3. Structure:
   - **H1:** resource name (e.g., "Aspects")
   - **One-line summary**
   - **Endpoint table:** METHOD | Path | Description
   - **Key concepts** (a short paragraph on what makes this resource special)
   - **Example request / response** (with `curl` and CLI equivalent)
   - **See also** links
4. Add the new file to `mkdocs.yml` nav under `API`.
5. Check that `mkdocs build` succeeds after adding the page.

### Terminology alignment

When an API page uses the word "order" it should always be in the context of the
CLI command (`ivcap order create …`). The REST API resource is `/jobs`. Add a
note at the top of `docs/API/orders.md`:

```markdown
!!! note "Jobs vs Orders"
    The REST API uses the term **job** for a service execution
    (`/1/services/{id}/jobs`). The `ivcap` CLI uses **order**
    (`ivcap order create`). They mean the same thing. This page covers both.
```

---

## 10. Common Maintenance Tasks

### A new example repo has been added to `ivcap-works`

1. Add it to `config/example-registry.json`.
2. `make validate && make fetch-example EX=<slug>`
3. Review the generated page in `content/examples/<slug>/`.
4. If the README is thin, write a hand-authored stub in `docs/examples/<slug>.md`.
5. Ensure `docs/examples/index.md` includes the new example in the right category.
6. Update `docs/examples/capability-matrix.md` to mark the new example's capabilities.
7. Commit.

### A new SDK has shipped

1. Add it to `config/sdk-registry.json`.
2. Inspect the repo's `docs/` folder; set `pull_docs` paths accordingly.
3. `make validate && make fetch-sdk SDK=<slug>`
4. Create `docs/developer-guide/sdk-<slug>.md`.
5. Update `docs/developer-guide/sdk.md` (comparison table).
6. Add the new page to `mkdocs.yml` nav.
7. Commit.

### `for_users.md` has been updated in `ivcap-core`

1. Copy the new content into `background_docs/for_users.md`.
2. Update the date in the source-comment header.
3. Use `git diff background_docs/for_users.md` to identify what changed.
4. Map changed sections to public pages using the table in §8.
5. Update each affected page (adapt prose; don't mechanically copy).
6. Check the glossary for any new terms.
7. `mkdocs build` to confirm no errors.
8. Commit.

### A page has a broken link

```bash
make build          # builds the site
make check-links    # runs check_links.py against the built site
```

Fix any broken internal links by updating the markdown source. For broken
external links (e.g., to a GitHub repo that moved), update the link.

### Deploying a new version

```bash
make deploy   # builds, packages, uploads artifact, updates app-server aspect
```

Requires `ivcap` CLI to be authenticated. In CI this happens automatically on
push to `main`.

---

## 11. Agent-Specific Instructions

This section is addressed to an AI agent (e.g., Cline/Claude) asked to maintain
or update the documentation site.

### Before you start any task

1. Read this file (`MAINTENANCE.md`) in full — it's your primary context.
2. Read `README.md` for the quick-reference make commands.
3. Read `_next_phase/IVCAP-PLAN.md` for the broader strategic plan and the
   detailed agent instructions for each trigger type.
4. Check `background_docs/for_users.md` — this is your authoritative source
   for API details. The date in its source-comment header tells you how
   current it is.

### Files to read before editing any page

| Task | Read first |
|---|---|
| Editing an API page | `background_docs/for_users.md` §5.x for that resource |
| Editing platform-overview or quick-start | `background_docs/for_users.md` §1–4 |
| Adding an example page | `config/example-registry.json`, then the repo's README |
| Editing the SDK page | `config/sdk-registry.json`, then pulled `content/sdk/<slug>/` |
| Editing the glossary | `background_docs/for_users.md` §2 and §10 |

### Files you must not overwrite or delete

| File | Why |
|---|---|
| `mkdocs.yml` | Committed nav config; only overwrite via `generate-nav` after a `fetch` |
| `background_docs/*.md` | Source-of-truth snapshots; only humans update these |
| `config/*.json` | Registry files; only humans add/remove repos |
| `config/*.schema.json` | Schema files; only change if the registry format changes |
| `pyproject.toml`, `poetry.lock` | Dependency pins; only update with `poetry add` |

### Verifying your work

Always run `mkdocs build` after any edit. The build must complete with zero
errors. Warnings about pages not in the nav are acceptable if those pages are
intentionally excluded (operator manual, roadmap). Warnings about broken links
or missing files are not acceptable.

```bash
poetry run mkdocs build   # or: make build (which also runs fetch)
```

### Writing quality checklist

Before committing any page edits, verify:
- [ ] Written in second person ("you"), active voice
- [ ] Every concept is followed by a code example
- [ ] `job` used for the REST resource; `order` only in literal CLI examples
- [ ] No marketing language ("powerful", "seamless")
- [ ] Internal links use relative paths and point to files that exist
- [ ] New terms added to `docs/glossary.md` if it exists
- [ ] `mkdocs build` passes

---

## 12. Agent-Friendly Site Strategy

This section documents the deliberate choices made to ensure the documentation
site is efficiently consumable by AI agents (coding assistants, LLM-powered
tools, RAG pipelines) as well as human readers.

### Problem statement

Standard MkDocs HTML output carries 80–90% overhead from CSS, JS, and navigation
chrome that agents must strip before they can parse content. This wastes tokens
and increases latency for any agent querying the docs. The goal is to serve
clean, structured content that agents can consume directly — without altering
the experience for human readers.

### Chosen strategy: `mkdocs-llmstxt-md` (source-first approach)

We use the **`mkdocs-llmstxt-md`** plugin (v0.2+). This plugin was chosen over
the alternative `mkdocs-llmstxt` (HTML-parsing approach) because:

- It works directly with the raw markdown source files — no HTML round-trip.
- The site's content is entirely source-first (no injected HTML-only content),
  so the simpler approach is the correct choice.
- It produces all three agent-facing artefacts in one pass with zero impact on
  the human-facing HTML output.

### What the plugin produces

| Artefact | URL | Purpose |
|---|---|---|
| Raw markdown | `/<page>.md` | Agents request the `.md` URL to get clean markdown instead of HTML |
| Index file | `/llms.txt` | Structured index (analogous to `robots.txt`) listing all sections and pages with links to their `.md` URLs. Used actively by AI coding assistants (Cursor, Claude Code). |
| Full dump | `/llms-full.txt` | All documentation concatenated into a single LLM-friendly file. Data shows agents visit this at >2× the rate of `llms.txt`. |

### Configuration (in `mkdocs.yml`)

```yaml
plugins:
  - search
  - llmstxt-md:
      enable_markdown_urls: true   # serve .md alongside HTML
      enable_llms_txt: true        # generate /llms.txt
      enable_llms_full: true       # generate /llms-full.txt
      markdown_description: >-
        IVCAP is a managed, provenance-aware platform for running, building,
        and orchestrating analytic services and AI agents. ...
      sections:
        Concepts:          [concepts/*.md]
        "Get Started":     [getting-started/*.md]
        ...
```

The `sections` map mirrors the site nav, so agents see the same information
hierarchy as human readers.

### Agent entry points

Once deployed, agents can use:

- **`https://docs.ivcap.net/llms.txt`** — start here; contains the project
  description and links to every section's markdown pages.
- **`https://docs.ivcap.net/llms-full.txt`** — the entire documentation in one
  file; ideal for RAG ingestion or one-shot context loading.
- **Any page as markdown** — append `.md` to any page URL, e.g.:
  `https://docs.ivcap.net/concepts/services-and-jobs.md`

### Usage by agent type (as of early 2026)

| Agent type | Uses `llms.txt`? | Uses `llms-full.txt`? | Uses `.md` URLs? |
|---|---|---|---|
| AI coding assistants (Cursor, Claude Code) | ✅ Yes — actively during inference | ✅ If indexed | ✅ When fetching specific pages |
| General chatbots (ChatGPT, Claude, Perplexity) | ❌ Not during inference | ❌ | ✅ If given a direct URL |
| RAG pipelines / custom crawlers | ✅ As a sitemap | ✅ Preferred | ✅ Preferred |

### Dependency

The plugin is declared in `pyproject.toml` and installed via Poetry:

```bash
poetry add mkdocs-llmstxt-md
```

It is automatically active during `mkdocs build` and `make deploy`. No
additional CI steps are required.

---

*Last updated: May 2026*
