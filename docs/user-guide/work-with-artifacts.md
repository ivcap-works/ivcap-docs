# Work with artifacts

Artifacts are the outputs (and sometimes inputs) of services: datasets, tables, images, models, reports, etc.

## Inspect an artifact

```bash
ivcap artifact get <artifact-id>
```

## Download an artifact

```bash
ivcap artifact download <artifact-id> -f /path/to/file
```

## Use artifacts as inputs

Many services accept artifact parameters. In that case you pass an artifact reference in the order creation step.

> TODO: add a canonical example showing (1) running service A, (2) using its produced artifact as input for service B.
