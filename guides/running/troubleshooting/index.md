# Troubleshooting

A diagnostic reference for common problems when running analyses on IVCAP.

---

## Authentication problems

### Symptoms

- CLI commands fail with `401 Unauthorized` or `403 Forbidden`
- The login flow starts but never completes
- Commands fail immediately after a long session

### Checklist

**1. Verify your active context**

```bash
ivcap context get
```

Check that the `URL` field points to the correct deployment and that you are logged in:

```
  Context  my-deployment
      URL  https://api.example.ivcap.net
   Status  authenticated
Token exp  2025-06-02T08:00:00Z
```

If `Token exp` is in the past, your token has expired — re-authenticate.

**2. Re-authenticate**

```bash
ivcap context login
```

This opens a browser window (or prints a device-authorisation URL if you are on a
headless machine). Complete the login flow and try your command again.

**3. Switch to the right context**

If you have multiple deployments configured, make sure you are using the correct one:

```bash
# List all configured contexts
ivcap context list

# Switch to a specific context
ivcap context use <context-name>
```

**4. Create a new context if needed**

```bash
ivcap context create <name> <base-url>
ivcap context login
```

---

## Job failures

### Status: `failed`

The service container ran but exited with a non-zero code. This is usually a
domain-level error (bad input, no results, etc.) rather than a platform problem.

**Diagnostic steps:**

```bash
# 1. Get the full job record
ivcap order get urn:ivcap:job:<uuid>

# 2. Check the metadata aspects for error details
ivcap aspect list --entity urn:ivcap:job:<uuid>

# 3. Get the content of the finished aspect, which may contain an error message
ivcap aspect get @<alias-of-finished-aspect>
```

**Common causes:**

| Cause | What to check |
|---|---|
| Missing required parameter | Re-read the service definition: `ivcap service get <svc>`. Ensure all non-optional parameters are provided. |
| Invalid parameter value | Check units, formats, and allowed values documented in the service description. |
| Artifact not found | Verify the artifact URN exists: `ivcap artifact get <urn>`. Check you have permission to access it. |
| No results for given inputs | Some services return a `failed` status when the query yields no data — this is normal; check the service description. |
| Input file format mismatch | Verify the MIME type of your uploaded artifact matches what the service expects. |

### Status: `error`

A platform-level fault — infrastructure failure, scheduling timeout, or resource
exhaustion. This is not caused by your inputs.

**What to do:**

1. Wait a few minutes and resubmit the job — transient infrastructure faults often
   resolve themselves.
2. Check with your platform administrator if the error persists.
3. Check whether the platform status page (if one exists for your deployment) reports
   any known outages.

---

## Service not found

### Symptoms

```
Error: No service with ID urn:ivcap:service:<uuid>
```

or

```
Error: service '@1' not found in history
```

### Checklist

- **For full URNs:** the service may have been deregistered. Run `ivcap service list` to
  confirm it is still present.
- **For `@1` aliases:** aliases are session-scoped. If you started a new terminal or
  cleared history, `@1` no longer resolves. Re-run `ivcap service list` and note the
  new alias or copy the full URN.

```bash
# Always prefer the full URN in scripts
ivcap order create urn:ivcap:service:ac158a1f-dfb4-5dac-bf2e-9bf15e0f2cc7 ...
```

---

## Artifact upload failures

### Symptoms

- Upload command hangs indefinitely
- `413 Request Entity Too Large` from the API
- Upload completes but artifact status stays `uploading` or `error`

### Checklist

**File too large for single-shot:**
The REST API's single-shot upload (`PUT /blob`) is limited to 16 MB. For larger files,
the CLI automatically uses the TUS resumable protocol. If you are calling the REST API
directly, switch to `PATCH /blob` with TUS headers.

**Network interruption during large upload:**
TUS uploads support resume — if the CLI was interrupted, re-run the same upload command.
The CLI will detect the incomplete upload and resume from where it left off.

**MIME type missing:**
Always specify `--mime-type` when uploading:

```bash
ivcap artifact upload data.csv --name "my-data" --mime-type text/csv
```

**Verify the upload completed:**

```bash
ivcap artifact get urn:ivcap:artifact:<uuid>
```

The `Status` field should be `ready`. If it is `error`, re-upload the file.

---

## Artifact not accessible to a service

### Symptoms

A job fails with a message like `artifact not found` or `permission denied` in the
service logs, even though `ivcap artifact get` works for you.

### Explanation

Artifacts have **access policies**. When you submit a job, the service container runs
under the platform's service account. If the artifact's policy does not grant read
access to service containers, the job will fail.

### Fix

Contact your platform administrator to adjust the artifact's policy to allow service
access, or re-upload the artifact with a permissive policy:

```bash
ivcap artifact upload data.csv \
    --name "my-data" \
    --mime-type text/csv \
    --policy urn:ivcap:policy:public
```

---

## CLI command reference issues

### `ivcap: command not found`

The CLI is not installed or not on your `PATH`. See
[Install the CLI](../../getting-started/install.md) for installation instructions.

### `ivcap order` vs `ivcap job`

The CLI currently uses `ivcap order create` / `ivcap order get` / `ivcap order list`
rather than `ivcap job ...`. These refer to the same concept — the CLI will be updated
in a future release to use the canonical `job` terminology.

### Unknown flag errors

If a flag is rejected, check you are running the latest version of the CLI:

```bash
ivcap version
```

Download the latest release from the
[GitHub releases page](https://github.com/ivcap-works/ivcap-cli/releases/latest).

---

## Getting more detail with verbose output

Add `--verbose` (or `-v`) to most CLI commands to see the underlying HTTP requests and
responses:

```bash
ivcap order create @1 region="Tasmania-North" --verbose
```

This is useful for debugging REST API calls and understanding exactly what the CLI is
sending.

---

## Still stuck?

1. **Check the platform status** — ask your administrator if there are any known issues.
2. **Check the provenance aspects** — use `ivcap aspect list --entity urn:ivcap:job:<uuid>`
   to read all recorded events for the job, including error messages from the service.
3. **Contact the service provider** — if the job is `failed` with a domain error, the
   service author can help interpret the failure.

---

## Related guides

- [Submit and Monitor Jobs](submit-jobs.md) — full job lifecycle reference
- [Work with Artifacts](work-with-artifacts.md) — upload, download, and manage artifacts
- [Query Provenance](query-provenance.md) — inspect all recorded events for a job
- [Install the CLI](../../getting-started/install.md) — install and configure the CLI
