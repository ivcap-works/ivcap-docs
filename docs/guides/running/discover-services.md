# Discover Services

Before you can run an analysis, you need to find the right service and understand what
parameters it expects. This guide covers every way to browse and inspect the IVCAP service
catalogue.

---

## Setup

All examples assume the following environment variables are set (the Python SDK reads them automatically):

```bash
export IVCAP_URL="https://api.example.ivcap.net"
export IVCAP_JWT="<your-jwt-token>"
export IVCAP_ACCOUNT_ID="urn:ivcap:account:<uuid>"
```

=== "Python"

    Install the client SDK:

    ```bash
    pip install ivcap-client-sdk-python
    ```

    Create the client — it picks up credentials from environment variables automatically:

    ```python
    from ivcap_client.ivcap import IVCAP

    ivcap = IVCAP()
    # or supply credentials explicitly:
    # ivcap = IVCAP(url="https://api.example.ivcap.net", token="<jwt>", account_id="urn:...")
    ```

---

## List all available services

=== "CLI"

    ```bash
    ivcap service list
    ```

    ```
    +----+----------------------------------+-------------------------------------------+
    | ID | NAME                             | DESCRIPTION                               |
    +----+----------------------------------+-------------------------------------------+
    | @1 | Gene Ontology (GO) Term Mapper   | Maps UniProt IDs to GO terms via QuickGO  |
    | @2 | Gradient Text Image              | Creates an image with customizable text   |
    | @3 | Fire Risk Analysis               | Runs fire risk analysis for a given region|
    +----+----------------------------------+-------------------------------------------+
    ```

    !!! note "Short-form aliases (`@1`, `@2`, …)"
        The CLI assigns short aliases like `@1` to recently seen URNs within your session.
        Use `--no-history` to work with raw URNs directly.

=== "Python"

    `list_services()` returns a lazy iterator — pages are fetched on demand:

    ```python
    for i, svc in enumerate(ivcap.list_services(limit=50)):
        print(f"====== {i}")
        print(svc)
        for name, param in svc.parameters.items():
            print(f"  .. {name}: {param}")
    ```

=== "REST"

    ```bash
    GET /1/services?limit=50
    ```

---

## Filter the catalogue

=== "CLI"

    ```bash
    ivcap service list --filter "name~='fire'"
    ivcap service list --filter "name=='Fire Risk Analysis'"
    ```

=== "Python"

    OData-style filter expressions are supported (`~=` for contains-like matching):

    ```python
    for svc in ivcap.list_services(filter="name~='fire'", limit=20):
        print(svc.id, svc.name)
    ```

=== "REST"

    ```bash
    GET /1/services?filter=name~%3D'fire'
    ```

---

## Inspect a service

Get full parameter details for a specific service:

=== "CLI"

    ```bash
    ivcap service get urn:ivcap:service:<uuid>
    ```

    ```
            Name  Fire Risk Analysis
     Description  Runs fire risk analysis for a given region.
              ID  urn:ivcap:service:ac158a1f-... (@1)
          Status  active

      Parameters  ┌────────────┬──────────────────────┬──────────┬──────────────┐
                  │ NAME       │ DESCRIPTION          │ TYPE     │ OPTIONAL     │
                  ├────────────┼──────────────────────┼──────────┼──────────────┤
                  │ region     │ Region name          │ string   │ no           │
                  │ threshold  │ Rainfall threshold   │ float    │ no           │
                  │ input-data │ Input dataset        │ artifact │ yes          │
                  └────────────┴──────────────────────┴──────────┴──────────────┘
    ```

=== "Python"

    Fetch by URN or by name:

    ```python
    # By URN
    svc = ivcap.get_service("urn:ivcap:service:ac158a1f-dfb4-5dac-bf2e-9bf15e0f2cc7")

    # By name (raises AmbiguousRequest if multiple matches)
    svc = ivcap.get_service_by_name("Fire Risk Analysis")

    print(f"Name:        {svc.name}")
    print(f"Description: {svc.description}")
    print(f"Status:      {svc.status}")
    print("\nParameters:")
    for name, param in svc.parameters.items():
        print(f"  {name:20s}  {param}")
    ```

    To see what the job request model looks like:

    ```python
    Model = svc.request_model
    print(Model.__doc__)      # lists fields and types
    ```

=== "REST"

    ```bash
    GET /1/services/urn:ivcap:service:<uuid>
    ```

---

## Understanding parameter types

| Type | How to provide it | Python example |
|---|---|---|
| `string` | Text value | `Model(region="Tasmania-North")` |
| `int` | Integer | `Model(count=10)` |
| `float` | Decimal | `Model(threshold=0.05)` |
| `bool` | True/False | `Model(dry_run=True)` |
| `artifact` | An artifact URN | `Model(input_data="urn:ivcap:artifact:...")` |

!!! note
    Parameter names with hyphens (e.g. `input-data`) are accessible as underscored
    Python attributes in the request model (e.g. `input_data`).

---

## Tips for finding the right service

- Use `get_service_by_name()` if you know the exact name.
- Use `list_services(filter=...)` to search by keyword.
- Inspect `svc.parameters` to understand required inputs before submitting.

---

## Next steps

[→ Submit and Monitor Jobs](submit-jobs.md){ .md-button .md-button--primary }
