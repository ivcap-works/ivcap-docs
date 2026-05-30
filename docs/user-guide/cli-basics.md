# CLI basics

The fastest way to interact with an IVCAP deployment is via **`ivcap-cli`**.

This page is intentionally *task-oriented* (not a full command reference).

## Install

See **[Get started → Installing CLI](../getting-started/installing-cli.md)**.

## Configure a context

Create a context per deployment (dev/staging/prod), then select it.

> TODO: confirm the current CLI command names (`ivcap context ...` vs `ivcap config create-context ...`) and standardise across docs.

## Login

Most interactions require an auth token.

The Quick Start uses:

```bash
ivcap context login
```

## Useful commands

- List services: `ivcap service list`
- Inspect a service: `ivcap service get <id>`
- Create order: `ivcap order create ...`
- Check order: `ivcap order get <id>`
- Inspect artifact: `ivcap artifact get <id>`
- Download artifact: `ivcap artifact download <id> -f <path>`

## Troubleshooting

If auth fails, start at **[Troubleshooting](troubleshooting.md)**.
