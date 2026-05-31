# Service Modes: Lambda vs Batch

Before building an IVCAP service, the most important architectural decision is choosing the right **execution mode**. IVCAP supports two fundamentally different modes, and the right choice depends on the nature of your workload.

---

## Lambda Mode

A **lambda** service runs as a persistent web server that handles incoming requests as HTTP `POST` calls. Multiple requests can be processed **simultaneously** — the service is always listening and can serve many clients at once.

**Choose lambda when:**

- Each request is **stateless** — it doesn't depend on what previous requests did
- Requests are **short-lived** (milliseconds to a few seconds)
- You want **high throughput** — many requests handled in parallel
- Your service wraps an external API call (e.g. fetching data from QuickGO, calling an LLM)
- You are building an **AI tool** that agents will call repeatedly

**How it works:**

```
  Request A ──┐
  Request B ──┤──► [Lambda Service] ──► Response A
  Request C ──┘                    └──► Response B
                                   └──► Response C
```

The service process stays alive between requests. All requests share the same process, so **any global or in-memory state is shared** — this is usually fine as long as requests don't mutate shared state.

**Configured in `pyproject.toml` as:**
```toml
[tool.poetry-plugin-ivcap]
service-type = "lambda"
port = 8077
```

**Example:** The [Gene Ontology Term Mapper](https://github.com/ivcap-works/gene-onology-term-mapper) is a lambda service — each request independently queries the QuickGO API and returns results. Requests for `P12345` and `Q9H0H5` can run fully in parallel.

---

## Batch Mode

A **batch** service processes one request at a time. IVCAP starts a **fresh container instance** for each job, runs it to completion, and then shuts it down. There is no persistent server; the service runs as a one-shot program.

**Choose batch when:**

- The job is **long-running** (minutes to hours)
- The job consumes **significant resources** (GPU, large memory, many CPU cores)
- You cannot avoid **global state** — e.g. loading a large model into memory that would be corrupted by concurrent access
- You are wrapping a **CLI tool** that was not designed for concurrent use
- The workload is a **pipeline** — a sequence of steps that must complete before results are available

**How it works:**

```
  Job A submitted ──► [Container starts] ──► [Runs to completion] ──► [Container exits]
  Job B submitted ──►                        [Waits, or runs in a separate container]
```

Each job gets its own clean environment. There is no shared state between jobs by design.

**Configured in `pyproject.toml` as:**
```toml
[tool.poetry-plugin-ivcap]
service-type = "batch"
```

**Example:** A genome assembly pipeline that loads a reference genome into memory, processes a FASTQ file, and writes results to disk would be a batch service — it's long-running, resource-intensive, and the tools involved (e.g. BWA, GATK) aren't designed for concurrent execution within a single process.

---

## Comparison

| | Lambda | Batch |
|---|---|---|
| **Execution model** | Persistent server, many requests in parallel | One container per job, runs once |
| **Concurrency** | High — requests handled simultaneously | Low — one job at a time per container |
| **Request duration** | Short (ms – seconds) | Long (seconds – hours) |
| **State between requests** | Shared (be careful!) | None — fresh environment each time |
| **Resource usage** | Light | Can be heavy (GPU, large RAM) |
| **Startup overhead** | None (server already running) | Container start per job |
| **Best for** | API wrappers, AI tools, data lookups | ML training, pipelines, CLI tool wrappers |
| **`service-type` value** | `"lambda"` | `"batch"` |

---

## When You're Unsure

If your service:

- **Calls an external API** and returns the result → **Lambda**
- **Runs a local computation** in under a few seconds → **Lambda**
- **Loads a large model or dataset** at startup → **Batch** (or Lambda if you can load it once at server start and share it safely)
- **Wraps a CLI tool** not designed for parallelism → **Batch**
- **Runs for more than ~30 seconds** → **Batch**

The [Gene Ontology Term Mapper tutorial](go-term-mapper-tutorial.md) walks through building a lambda service end-to-end — a good starting point for most new services.
