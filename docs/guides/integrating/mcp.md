# Using IVCAP via MCP

The `ivcap` CLI includes a built-in **Model Context Protocol (MCP) server**.
This lets any MCP-compatible AI assistant — Claude, GPT-4o, Gemini, Cursor,
Cline, and others — connect directly to your IVCAP deployment and control it
as a set of tools.

---

## What the MCP server exposes

Once running, the MCP server exposes IVCAP's core capabilities as tools:

| MCP tool | What it does |
|---|---|
| `list_services` | List all services available in the current context |
| `get_service` | Get details and parameter schema for a specific service |
| `submit_job` | Submit a new job to a service with given parameters |
| `get_job` | Get the status and output of a job |
| `list_jobs` | List recent jobs (optionally filtered by service) |
| `upload_artifact` | Upload a file and get back its artifact URN |
| `download_artifact` | Download an artifact by URN |
| `list_artifacts` | List accessible artifacts |
| `query_aspects` | Query aspects by entity, schema, or content filter |
| `get_aspect` | Get a specific aspect by URN |

---

## Starting the MCP server

First, ensure you are authenticated:

```bash
ivcap context login   # if not already logged in
```

Then start the MCP server:

```bash
ivcap mcp serve
```

By default the server listens on `stdio` (standard input/output), which is the
transport expected by most MCP clients. To use a network transport instead:

```bash
ivcap mcp serve --transport sse --port 3001
```

---

## Connecting Claude Desktop

Add IVCAP to your Claude Desktop configuration
(`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "ivcap": {
      "command": "ivcap",
      "args": ["mcp", "serve"],
      "env": {
        "IVCAP_CONTEXT": "my-deployment"
      }
    }
  }
}
```

Replace `my-deployment` with the name of the context you created with
`ivcap context create`. Restart Claude Desktop after saving the file.

---

## Connecting Cline (VS Code)

In VS Code with the Cline extension, add to your MCP server configuration:

```json
{
  "ivcap": {
    "command": "ivcap",
    "args": ["mcp", "serve"]
  }
}
```

The active `ivcap` context (set with `ivcap context use <name>`) is used
automatically.

---

## Example: submitting a job via Claude

Once connected, you can ask the AI assistant in plain language:

> "List the available services on IVCAP, then submit a job to the fire-risk
> analysis service with region = 'Tasmania-North' and threshold = 0.05"

The assistant will call `list_services`, inspect the service parameters,
then call `submit_job`. You can then ask it to monitor the job and download
the result artifact.

---

## Example: querying provenance via Claude

> "Show me all the jobs that used artifact urn:ivcap:artifact:6f390b51-... as
> an input, and what they produced."

The assistant will call `query_aspects` with the appropriate filters and
return a provenance graph in natural language.

---

## Security

The MCP server inherits the authenticated identity of the `ivcap` CLI context.
It can only access resources that your account has permission to access.

!!! warning "Do not expose the MCP server publicly"
    The `stdio` transport is local-only. If you use `--transport sse`,
    ensure the port is firewalled or protected by an authentication proxy.
    The server does not implement its own authentication layer.

---

## See also

- [Authentication](authentication.md) — how IVCAP authenticates requests
- [Agentic Patterns](../../concepts/agentic-patterns.md) — building services that themselves act as agents
- [CLI Reference](../../reference/cli.md) — full `ivcap mcp` command reference
