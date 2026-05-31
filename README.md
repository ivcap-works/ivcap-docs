# ivcap-docs

Documentation site for the [IVCAP platform](https://develop.ivcap.net), built
with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/).

---

## Quick start

```bash
# Install Python dependencies (first time only)
make install

# Start the local dev server — no internet access required
make serve
# → http://127.0.0.1:8000/
```

To include content pulled from SDK and example repos:

```bash
make fetch   # clone & pull README / narrative docs from all registered repos
make serve   # serve with the updated content
```

---

## Directory structure

```
config/                     Registry files and JSON schemas
  sdk-registry.json         SDKs and tooling repos to pull docs from
  example-registry.json     Example / tutorial repos to pull READMEs from
  sdk-schema.json           JSON schema that validates sdk-registry.json
  example-schema.json       JSON schema that validates example-registry.json
  mkdocs-template.yml       mkdocs.yml template used by generate-nav

scripts/                    Python helper scripts
  fetch_sdk.py              Clone SDK repos and copy narrative docs
  fetch_examples.py         Clone example repos and copy READMEs
  generate_nav.py           Regenerate mkdocs.yml nav from fetched content
  validate_registry.py      Validate registry files against their schemas
  check_links.py            Check for broken links in the built site

docs/                       Hand-authored MkDocs source pages
background_docs/            Snapshots of private docs used as source material
  for_users.md              ivcap-core/FOR_USERS.md (API reference, provenance)

content/                    Generated at build time — do not commit
  sdk/<slug>/               Narrative docs pulled from each SDK repo
  examples/<slug>/          README pulled from each example repo

.github/workflows/
  build.yml                 CI: fetch → build → deploy on push to main
  notify-hub.yml            Template for SDK/example repos to trigger a rebuild
```

---

## Adding a new example repo

Example repos demonstrate *how to use* IVCAP — tutorials, templates, and
domain-specific patterns.

1. Open **`config/example-registry.json`** and add a new entry:

```json
{
  "slug": "my-example",
  "name": "Human-readable name",
  "repo": "ivcap-works/<repo-name>",
  "branch": "main",
  "capabilities": ["build-services", "artifacts"],
  "sdks": ["python-service"],
  "difficulty": "beginner",
  "pull_files": ["README.md"]
}
```

**`difficulty`** — `beginner` | `intermediate` | `advanced`

**`capabilities`** — one or more of:

| Slug | What it covers |
|---|---|
| `run-services` | Discover, submit, and monitor jobs |
| `build-services` | Write and register a containerised service |
| `artifacts` | Produce, store, and retrieve data products |
| `aspects` | Attach typed metadata; query provenance history |
| `data-fabric` | Collections, annotations, query-as-dataset |
| `workflows` | Compose multi-step pipelines |
| `queues` | Async message passing between services |
| `ai-agents` | LLM / multi-agent services (CrewAI, LlamaIndex, …) |
| `domain-bio` | Bioinformatics-specific patterns |

2. Validate and fetch:

```bash
make validate          # check registry syntax
make fetch-example EX=my-example   # pull that one repo only
```

3. Commit `config/example-registry.json`. CI will pick it up on the next push.

---

## Adding a new SDK or tooling repo

SDK repos are libraries or tools that users *install* — the Python service SDK,
Python client SDK, CLI, or a future JS/TS SDK.

1. Open **`config/sdk-registry.json`** and add a new entry:

```json
{
  "slug": "python-service",
  "name": "Python Service SDK",
  "repo": "ivcap-works/<repo-name>",
  "branch": "main",
  "github_pages_url": "https://ivcap-works.github.io/<repo-name>",
  "pull_docs": ["docs/getting-started.md", "docs/guides"],
  "capabilities": ["build-services", "artifacts"],
  "language": "python",
  "audience": "service-author"
}
```

**`audience`** — `service-author` | `app-developer` | `all`

**`language`** — `python` | `go` | `javascript` | `typescript`

**`pull_docs`** — paths inside the SDK repo to copy as narrative docs. Check the
repo's `docs/` folder before committing to confirm the paths exist.

2. Validate and fetch:

```bash
make validate
make fetch-sdk SDK=python-service   # pull that one SDK only
```

3. Commit `config/sdk-registry.json`.

---

## Updating background docs

Some source documentation lives in private repos and cannot be auto-fetched.
Snapshots are stored in **`background_docs/`** so that agents and maintainers
can use them to update the public pages.

| File | Source | Covers |
|---|---|---|
| `background_docs/for_users.md` | `ivcap-core/FOR_USERS.md` | Full API reference, auth, URNs, provenance model |

**To update an existing background doc:**

1. Copy the latest content from the private repo into the corresponding
   `background_docs/<file>.md`.
2. Keep the source-comment header at the top of the file and update the date:
   ```
   <!-- SOURCE: ivcap-works/ivcap-core — FOR_USERS.md — copied YYYY-MM-DD -->
   ```
3. Commit and ask the agent to sync the affected public pages.

**To add a new background doc:**

1. Create `background_docs/<descriptive-name>.md`.
2. Paste the private content and add a source-comment header.
3. Add a row to the table above (in this README).
4. Commit.

---

## Make targets reference

| Target | What it does |
|---|---|
| `make install` | Install all Python deps via `poetry install` |
| `make serve` | Start live-reload dev server at `http://127.0.0.1:8000/` |
| `make fetch` | Pull all SDK docs + example READMEs, regenerate nav |
| `make fetch-sdk SDK=<slug>` | Pull a single SDK only |
| `make fetch-example EX=<slug>` | Pull a single example only |
| `make validate` | Validate both registry files against their schemas |
| `make build` | Full CI build: fetch → build (strict) |
| `make deploy` | Build and deploy to the IVCAP platform |
| `make check-links` | Build then check for broken links |
| `make clean` | Remove `content/` and `site/` (keeps `mkdocs.yml`) |
| `make clean-cache` | Remove the `.cache/` git clone cache |

---

## Deploying

The site is deployed to the IVCAP platform as a static app-server artifact:

```bash
make deploy   # requires ivcap-cli to be authenticated
```

CI runs this automatically on push to `main` via `.github/workflows/build.yml`.
