# CLI Reference

The `ivcap` CLI is the primary command-line interface for IVCAP. It wraps the
REST API, handles token refresh automatically, and provides short-form `@N`
aliases for recently seen URNs.

**Installation:** see [Install the CLI](../getting-started/install.md).

---

## Global flags

These flags apply to every command:

| Flag | Description |
|---|---|
| `--context <name>` | Use a named context instead of the current default |
| `--output <format>` | Output format: `table` (default), `json`, `yaml` |
| `--timeout <duration>` | HTTP request timeout (default: `30s`) |
| `--no-color` | Disable colour output |
| `-v`, `--verbose` | Increase log verbosity |
| `--help` | Show help for any command |

---

## context — manage deployment contexts

A *context* is a named configuration pointing at a specific IVCAP deployment.
Contexts are stored in `~/.ivcap/config.yaml`.

```bash
ivcap context create <name> <base-url>   # create a new context
ivcap context use <name>                 # set the active context
ivcap context login                      # authenticate (device flow / browser)
ivcap context logout                     # clear saved tokens
ivcap context get                        # show the current context and identity
ivcap context list                       # list all configured contexts
ivcap context delete <name>              # remove a context
```

**Example:**

```bash
ivcap context create prod https://api.prod.ivcap.net
ivcap context use prod
ivcap context login
ivcap context get
```

---

## service — list and inspect services

```bash
ivcap service list                            # list accessible services
ivcap service get <urn|@N>                    # show full service details
ivcap service update --create <urn> -f <file> # register or update a service
ivcap service delete <urn|@N>                 # remove a service
```

**Options for `service list`:**

| Flag | Description |
|---|---|
| `--limit <n>` | Maximum results to return |
| `--filter <expr>` | Filter expression on service name or description |

**Example:**

```bash
$ ivcap service list
+----+---------------------+
| ID | NAME                |
+----+---------------------+
| @1 | Gradient Text Image |
| @2 | Fire Risk Analysis  |
+----+---------------------+

$ ivcap service get @1
```

---

## job — submit and monitor jobs

Jobs are submitted to a service with named parameters. The CLI currently uses
the `order` command group (a legacy alias), but arguments map directly to jobs.

```bash
ivcap order create <service-urn|@N> [param=value ...]   # submit a job
ivcap order get <job-urn|@N>                            # get job status
ivcap order list                                        # list recent jobs
ivcap order watch <job-urn|@N>                          # stream live events until done
```

**Options for `order create`:**

| Flag | Description |
|---|---|
| `--name <str>` | Human-readable name for the job |
| `-f <file>` | Read parameters from a YAML/JSON file |
| `--wait` | Block until the job reaches a terminal state |

**Example:**

```bash
$ ivcap order create @1 msg="Hello IVCAP" img-art=urn:ivcap:artifact:6a1c3f2e-...
Order 'urn:ivcap:job:505c8573-...' with status 'pending' submitted.

$ ivcap order get urn:ivcap:job:505c8573-...
       ID  urn:ivcap:job:505c8573-...
   Status  succeeded
  Service  Gradient Text Image
 Products  @1  out.png  image/png
```

**Job status values:**

| Status | Meaning |
|---|---|
| `pending` | Job record created; awaiting scheduling |
| `scheduled` | Execution environment is starting |
| `executing` | Service is actively running |
| `succeeded` | Service completed successfully |
| `failed` | Service reported a failure |
| `error` | Platform error (infrastructure, timeout, etc.) |

---

## artifact — upload, download, and manage data

```bash
ivcap artifact upload <file> [flags]          # upload a file as an artifact
ivcap artifact download <urn|@N> -f <file>    # download artifact content
ivcap artifact list                           # list accessible artifacts
ivcap artifact get <urn|@N>                   # show artifact metadata
```

**Options for `artifact upload`:**

| Flag | Description |
|---|---|
| `--name <str>` | Display name for the artifact |
| `--mime-type <type>` | MIME type (auto-detected if omitted) |
| `--policy <urn>` | Access policy URN |
| `--collection <urn>` | Assign to a collection |

**Example:**

```bash
$ ivcap artifact upload background.png --name "background" --mime-type image/png
ID: urn:ivcap:artifact:6a1c3f2e-...

$ ivcap artifact download urn:ivcap:artifact:6f390b51-... -f /tmp/result.png
```

---

## aspect — read and manage metadata

```bash
ivcap aspect list [flags]           # search aspects
ivcap aspect get <urn|@N>           # get a specific aspect by URN
```

**Options for `aspect list`:**

| Flag | Description |
|---|---|
| `--entity <urn>` | Filter by entity URN |
| `--schema <urn>` | Filter by schema URN |
| `--at-time <ISO8601>` | Historical query — aspects valid at this timestamp |
| `--limit <n>` | Maximum results to return |

**Example:**

```bash
$ ivcap aspect list --entity urn:ivcap:artifact:6f390b51-...
$ ivcap aspect list --schema urn:ivcap:schema:remote-sensing:scene.1
```

---

## queue — manage message queues

```bash
ivcap queue list                          # list queues
ivcap queue create --name <str>           # create a queue
ivcap queue get <urn|@N>                  # get queue details
ivcap queue delete <urn|@N>              # delete a queue
ivcap queue enqueue <urn|@N> -f <file>   # enqueue a message from a file
ivcap queue dequeue <urn|@N>             # dequeue one or more messages
```

---

## secret — manage credentials

```bash
ivcap secret list                            # list secret names (values hidden)
ivcap secret set <name> -f <file>            # create or update a secret from file
ivcap secret delete <name>                   # remove a secret
```

**Example:**

```bash
$ ivcap secret set MY_API_KEY -f ./api-key.txt
$ ivcap secret list
```

---

## package — manage container images

```bash
ivcap package list          # list images in the account's registry
ivcap package remove <tag>  # remove an image by tag
```

Images are pushed via standard `docker push` using registry credentials —
the `package` commands are for listing and cleanup only.

---

## mcp — built-in MCP server

The `ivcap` CLI includes a built-in
[Model Context Protocol](https://modelcontextprotocol.io/) server that exposes
IVCAP's capabilities as MCP tools, allowing any MCP-compatible AI assistant
to list services, submit jobs, and manage artifacts directly.

```bash
ivcap mcp serve                      # start the MCP server (stdio transport)
ivcap mcp serve --http --port 8080   # HTTP transport (SSE)
```

When running as an MCP server, the following tools are exposed:

| MCP tool | Description |
|---|---|
| `ivcap_service_list` | List available services |
| `ivcap_service_get` | Get service details |
| `ivcap_job_create` | Submit a job to a service |
| `ivcap_job_get` | Get job status and results |
| `ivcap_job_list` | List recent jobs |
| `ivcap_artifact_upload` | Upload a file as an artifact |
| `ivcap_artifact_download` | Download an artifact |
| `ivcap_artifact_list` | List artifacts |
| `ivcap_artifact_get` | Get artifact metadata |
| `ivcap_aspect_list` | Search aspects |
| `ivcap_aspect_get` | Get a specific aspect |

See [Using IVCAP via MCP](../guides/integrating/mcp.md) for integration
instructions.

---

## version — show version info

```bash
ivcap version    # print CLI version and build info
```

---

## Configuration file

The CLI stores all contexts in `~/.ivcap/config.yaml`. You can edit this file
directly, but it is safer to use `ivcap context` commands.

```yaml
current-context: prod
contexts:
  - name: prod
    url: https://api.prod.ivcap.net
    token: eyJhbGci...
  - name: local
    url: http://ivcap.minikube
```

---

## OpenAPI specification

Every IVCAP deployment serves its live OpenAPI 3 specification at:

```
GET <base-url>/1/openapi/openapi3.json
```

Import into Swagger UI, Insomnia, or Postman for interactive exploration.
