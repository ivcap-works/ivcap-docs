# Glossary

Definitions for every IVCAP term. Terms are listed alphabetically.

---

**Artifact**
: Any binary or structured data blob stored in IVCAP — images, CSV files,
  JSON results, trained models, etc. Identified by `urn:ivcap:artifact:<uuid>`.
  Artifacts are immutable once uploaded; subsequent versions are new artifacts.
  See [Artifacts](../concepts/artifacts.md).

**Aspect**
: A typed, time-stamped, append-only metadata record attached to any entity
  URN (service, job, artifact, or another aspect). Identified by
  `urn:ivcap:aspect:<uuid>`. Aspects are the metadata currency of the platform
  and the foundation of provenance tracking. They are never deleted — only
  *retracted* (given a `validTo` timestamp). See [Aspects and Provenance](../concepts/aspects-and-provenance.md).

**Batch service**
: A service that runs asynchronously and produces output artifacts once complete.
  Suitable for long-running analyses. Contrast with [lambda service](#lambda-service).

**Context** (CLI)
: A named CLI configuration pointing at a specific IVCAP deployment, stored in
  `~/.ivcap/config.yaml`. Created with `ivcap context create <name> <base-url>`.

**Data Fabric**
: IVCAP's universal, append-only information store. Everything — service
  registrations, job events, artifact metadata, user-defined annotations — is
  recorded as Aspects in the Data Fabric. Supports point-in-time queries and
  cross-entity search. See [The Data Fabric](../concepts/data-fabric.md).

**Datafabric**
: Alternative spelling of [Data Fabric](#data-fabric). The two spellings are
  used interchangeably in platform code and documentation.

**Job**
: A single execution of a service, created by submitting parameters to a
  service endpoint. Identified by `urn:ivcap:job:<uuid>`. Lifecycle:
  `pending` → `scheduled` → `executing` → `succeeded | failed | error`.
  Also called *order* in the CLI and older API paths (they mean the same thing).
  See [Services and Jobs](../concepts/services-and-jobs.md).

**Lambda service**
: A service that returns results synchronously or via a short poll — analogous
  to a function call. Suitable for fast, stateless operations. Contrast with
  [batch service](#batch-service).

**MCP server**
: Model Context Protocol server. The `ivcap` CLI includes a built-in MCP server
  (`ivcap mcp serve`) that exposes IVCAP's capabilities as MCP tools, allowing
  any MCP-compatible AI assistant to list services, submit jobs, and manage
  artifacts directly. See [Using IVCAP via MCP](../guides/integrating/mcp.md).

**Metadata**
: In IVCAP, metadata is recorded as [Aspects](#aspect) in the Data Fabric.
  The `/1/metadata` API path is an alias for the aspects endpoint.

**Order** (CLI legacy)
: The legacy CLI term for a [job](#job). The `ivcap order` command group
  submits and monitors service executions. The REST API exposes jobs under
  `/1/services/{id}/jobs`; the older `/1/orders` path is retained for backward
  compatibility. The canonical term throughout the documentation is **job**.

**Package**
: A Docker container image stored in the platform's account-scoped registry.
  Used as the execution environment for a service. See [Packages API](../reference/api/packages.md).

**Policy**
: An access control rule attached to an entity (service, artifact, aspect, etc.).
  Identified by `urn:ivcap:policy:<name>`. Example: `urn:ivcap:policy:public`.

**Project**
: A logical grouping of resources (services, artifacts, aspects) within an
  account, used for access control and billing. Corresponds to the
  `/1/project` API resource.

**Provenance**
: The immutable record of how every result was produced — which service ran,
  with which inputs and parameters, at what time, and who submitted it.
  Recorded automatically as Aspects. See [Aspects and Provenance](../concepts/aspects-and-provenance.md).

**Queue**
: An async message queue for communication between services or pipeline stages.
  One service enqueues work items; another dequeues and processes them.
  Identified by `urn:ivcap:queue:<uuid>`. See [Queues](../concepts/queues.md).

**Schema**
: A URN that identifies the type of an [Aspect](#aspect).
  Format: `urn:ivcap:schema:<domain>:<name>.<version>`.
  Example: `urn:ivcap:schema:order-placed.1`.
  Platform schemas (job lifecycle events, artifact provenance) are defined by
  IVCAP; user-defined schemas can be registered for custom metadata.

**Secret**
: An API key or credential stored securely in IVCAP and injected into service
  containers at runtime. Values are never returned via the API.
  See [Secrets API](../reference/api/secrets.md).

**Service**
: A registered analytic capability with a name, typed parameters, and a Docker
  execution environment. Identified by `urn:ivcap:service:<uuid>`. Users submit
  [jobs](#job) to services. See [Services and Jobs](../concepts/services-and-jobs.md).

**Sidecar**
: A process that runs alongside a service container in the same Pod. The IVCAP
  sidecar provides the service with access to artifacts, aspects, secrets,
  queues, and — for AI services — an integrated LLM client. Services communicate
  with the sidecar via a local HTTP endpoint.

**SSE (Server-Sent Events)**
: A streaming protocol used by IVCAP to push live job status updates to clients.
  Subscribe at `GET /1/services/{serviceId}/jobs/{jobId}/events`.
  See [Live Events](../reference/api/events.md).

**TUS**
: An open protocol for resumable file uploads over HTTP. IVCAP supports TUS
  for uploading large artifacts (up to 5 GB) via `PATCH /1/artifacts/{id}/blob`.

**URN (Uniform Resource Name)**
: The identifier format used for all IVCAP entities.
  Pattern: `urn:ivcap:<type>:<uuid>`.
  Types: `service`, `job`, `artifact`, `aspect`, `schema`, `account`,
  `queue`, `policy`, `project`.
  The CLI accepts short aliases (`@1`, `@2`, …) as convenience references.
  See [URN Reference](urns.md).

**Workflow**
: A composed pipeline of services where the output of one service feeds the
  input of the next. Can be expressed as a sequence of job submissions, or
  using a workflow-engine service that orchestrates multiple steps internally.
