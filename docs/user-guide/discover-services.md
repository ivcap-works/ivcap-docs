# Discover services

IVCAP deployments expose a catalogue of **services**.

## List services

```bash
ivcap service list
```

Use filters to narrow down results.

> TODO: add canonical filter examples once confirmed (e.g. by name, provider/account, tags).

## Inspect service parameters

```bash
ivcap service get <service-id>
```

Look for:

- required vs optional parameters
- artifact parameters (inputs coming from prior outputs)
- default values

## Next

- **[Run & monitor orders](run-and-monitor-orders.md)**
