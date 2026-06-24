# SDKs & Tools

IVCAP provides five SDKs and a CLI that cover every stage of working with the platform — from interactive exploration to building and deploying production services.

---

## IVCAP CLI

The command-line interface for interacting with an IVCAP deployment.  Use it to discover services, submit jobs, upload/download artifacts, query provenance, and more.  It also exposes a built-in **MCP server** so any MCP-compatible AI assistant can control IVCAP directly.

- [Install the CLI](../getting-started/install.md)
- [CLI Reference](../reference/cli.md)
- [Full API Reference ↗](https://github.com/ivcap-works/ivcap-cli){ target="_blank" }

---

## Python Client SDK (`ivcap-client`)

A Python library for calling IVCAP from notebooks, scripts, or external applications.  Wraps the REST API with idiomatic Python objects and async support.  Auto-detects platform vs local mode from environment variables — no code changes needed when switching between development and production.

- [Guide: Python Client SDK](../guides/integrating/python-client-sdk.md)
- [Full API Reference ↗](https://ivcap-works.github.io/ivcap-client-sdk-python/){ target="_blank" }

---

## JavaScript/TypeScript Client SDK

A TypeScript/JavaScript library for calling IVCAP from web applications, Node.js scripts, or any JS/TS environment.  Wraps the REST API with idiomatic typed objects and async/await support.

- [Full API Reference ↗](https://ivcap-works.github.io/ivcap-client-sdk-js/){ target="_blank" }

---

## Python Service SDK (`ivcap-service`)

The core Python SDK for *building* IVCAP **batch** services — long-running, queue-based workers that the platform launches as a fresh container per job.  Handles artifact I/O, provenance recording, progress reporting, and structured logging so you can focus on your analysis logic.

- [Guide: Build your first service](../getting-started/build-service.md)
- [Full API Reference ↗](https://ivcap-works.github.io/ivcap-service-sdk-python){ target="_blank" }

---

## Python Lambda SDK (`ivcap-lambda`)

A Python framework for building **lambda** (request/response) services — persistent HTTP servers where the platform routes each job as a `POST` request.  Ideal for short-lived, stateless operations such as API wrappers, lookups, and AI agent tools.

!!! note "Renamed from `ivcap-ai-tool`"
    This package was previously published as `ivcap-ai-tool`. The module and decorator
    have been renamed to `ivcap_lambda`. The old names remain available as deprecated
    aliases for backwards compatibility.

- [Guide: Service Basics](../guides/building/service-basics.md)
- [PyPI ↗](https://pypi.org/project/ivcap-lambda/){ target="_blank" }
