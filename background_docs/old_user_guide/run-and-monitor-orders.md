# Run & monitor orders

An **order** is a request to execute a service with specific parameters.

## Create an order

```bash
ivcap order create \
  -n "my analysis" \
  <service-urn-or-alias> \
  param1=value1 \
  param2=value2
```

## Monitor progress

```bash
ivcap order get <order-id>
```

Orders typically transition through states such as `pending` → `executing` → (`succeeded` | `failed`).

## Get produced artifacts (products)

When an order succeeds, it lists produced artifacts (“products”). Use those artifact IDs in the artifact commands.

## Next

- **[Work with artifacts](work-with-artifacts.md)**
