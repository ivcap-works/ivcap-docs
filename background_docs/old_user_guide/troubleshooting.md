# Troubleshooting

## Authentication issues

Symptoms:

- CLI commands fail with `401` / `403`
- login flow never completes

Checklist:

1. Confirm you’re using the correct context (deployment URL)
2. Re-run login
3. Check whether your token expired

> TODO: add deployment-specific guidance (ID provider URLs, expected scopes/roles).

## Orders failing

> TODO: add guidance for inspecting logs/events, typical failure modes, and when to contact a service provider.
