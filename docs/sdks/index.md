# SDKs & Tools

IVCAP provides three SDKs and a CLI that cover every stage of working with the platform — from interactive exploration to building and deploying production services.

---

## IVCAP CLI

The command-line interface for interacting with an IVCAP deployment.  Use it to discover services, submit jobs, upload/download artifacts, query provenance, and more.  It also exposes a built-in **MCP server** so any MCP-compatible AI assistant can control IVCAP directly.

- [Install the CLI](../getting-started/install.md)
- [CLI Reference](../reference/cli.md)
- [Full API Reference ↗](https://github.com/ivcap-works/ivcap-cli){ target="_blank" }

---

## Python Client SDK

A Python library for calling IVCAP from notebooks, scripts, or external applications.  Wraps the REST API with idiomatic Python objects and async support.

- [Guide: Python Client SDK](../guides/integrating/python-client-sdk.md)
- [Full API Reference ↗](https://ivcap-works.github.io/ivcap-client-sdk-python/){ target="_blank" }

---

## Python Service SDK

A Python framework for *building* IVCAP services — handling parameter parsing, artifact I/O, provenance recording, and service registration so you can focus on your analysis logic.

- [Guide: Build your first service](../getting-started/build-service.md)
- [Full API Reference ↗](https://ivcap-works.github.io/ivcap-service-sdk-python){ target="_blank" }
