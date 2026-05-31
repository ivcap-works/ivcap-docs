# URN Reference

All IVCAP identifiers are **URNs (Uniform Resource Names)** of the form:

```
urn:ivcap:<type>:<identifier>
```

URNs are stable, globally unique, and can be used across API calls, CLI
commands, and deployments.

---

## Entity URN patterns

| Entity | Pattern | Example |
|---|---|---|
| Service | `urn:ivcap:service:<uuid>` | `urn:ivcap:service:b14569f9-81bc-5ac2-af1a-9b05ee987c1b` |
| Job | `urn:ivcap:job:<uuid>` | `urn:ivcap:job:505c8573-3c1a-4f2d-9e7b-1a2b3c4d5e6f` |
| Artifact | `urn:ivcap:artifact:<uuid>` | `urn:ivcap:artifact:6f390b51-0001-4a2b-9c3d-5e6f7a8b9c0d` |
| Aspect | `urn:ivcap:aspect:<uuid>` | `urn:ivcap:aspect:1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d` |
| Schema | `urn:ivcap:schema:<domain>:<name>.<version>` | `urn:ivcap:schema:job-placed.1` |
| Account | `urn:ivcap:account:<uuid>` | `urn:ivcap:account:45a06508-...` |
| Queue | `urn:ivcap:queue:<uuid>` | `urn:ivcap:queue:7f8a9b0c-...` |
| Policy | `urn:ivcap:policy:<name>` | `urn:ivcap:policy:public` |
| Project | `urn:ivcap:project:<uuid>` | `urn:ivcap:project:9d8c7b6a-...` |

---

## Schema URN format

Schemas identify the type of an [Aspect](../concepts/aspects-and-provenance.md).

```
urn:ivcap:schema:<domain>:<name>.<version>
```

**Platform-defined schemas** (automatically recorded by the platform):

| Schema URN | When recorded |
|---|---|
| `urn:ivcap:schema:job-placed.1` | Job submitted |
| `urn:ivcap:schema:job.2` | Job status change (executing) |
| `urn:ivcap:schema:job-finished.1` | Job completed (succeeded/failed/error) |
| `urn:ivcap:schema:artifact-usedBy-order.1` | Artifact consumed by a job |
| `urn:ivcap:schema:order-produced-artifact.1` | Artifact produced by a job |

**User-defined schemas** follow the same format with a custom domain:

```
urn:ivcap:schema:remote-sensing:scene.1
urn:ivcap:schema:my-domain:classification.1
```

---

## Policy URNs

Policies control access to resources. Common built-in policies:

| URN | Meaning |
|---|---|
| `urn:ivcap:policy:public` | Readable by any authenticated user |
| `urn:ivcap:policy:private` | Accessible only to the owning account |

---

## CLI short-form aliases

The `ivcap` CLI maintains a short-form index of recently listed URNs so that
you don't have to type them in full.

After any `list` command, items are indexed as `@1`, `@2`, `@3`, …:

```bash
$ ivcap service list
+----+---------------------+-----------------------------------+
| ID | NAME                | ACCOUNT                           |
+----+---------------------+-----------------------------------+
| @1 | Gradient Text Image | urn:ivcap:account:45a06508-...    |
+----+---------------------+-----------------------------------+

# Use @1 in any subsequent command
$ ivcap service get @1
$ ivcap job create @1 msg="Hello IVCAP"
```

Short-form aliases are **session-scoped** — they are reset each time you run
a new `list` command.

---

## Using URNs in the REST API

URNs appear as:

- **Path parameters** — `GET /1/artifacts/urn:ivcap:artifact:<uuid>`
- **Query parameters** — `GET /1/aspects?entity=urn:ivcap:artifact:<uuid>`
- **Request body fields** — `"policy": "urn:ivcap:policy:public"`
- **Response body fields** — `"id": "urn:ivcap:job:<uuid>"`

When embedding a URN in a URL path, percent-encode the colons (`%3A`) if your
HTTP client does not handle that automatically. The `ivcap` CLI and SDKs handle
encoding transparently.
