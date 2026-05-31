# REST API Reference

All IVCAP resources are accessed through a single REST API endpoint — the
**API Gateway**. All paths are prefixed with `/1/`.

```
<scheme>://<host>/1/<resource>
```

Authentication via `Authorization: Bearer <token>` is required on all
endpoints. See [Authentication](../../guides/integrating/authentication.md) for
how to obtain a token.

The **live OpenAPI 3 specification** is always authoritative and generated
directly from the service code:

```
GET <base-url>/1/openapi/openapi3.json
```

---

## Resources

| Resource | Base path | Description |
|---|---|---|
| [Services & Jobs](services.md) | `/1/services` | Register, update and invoke analytic services; manage job lifecycle |
| [Artifacts](artifacts.md) | `/1/artifacts` | Store, retrieve, and download binary and structured data |
| [Aspects](aspects.md) | `/1/aspects` | Record and query typed metadata and provenance |
| [Queues](queues.md) | `/1/queues` | Asynchronous message queues for inter-service communication |
| [Secrets](secrets.md) | `/1/secrets` | Manage API keys and credentials for service containers |
| [Packages](packages.md) | `/1/packages` | List and manage Docker images in the account registry |
| [Sessions](sessions.md) | `/1/sessions` | Exchange a JWT for a session token |
| [Live Events](events.md) | `/1/services/{id}/jobs/{jobId}/events` | Stream real-time job status via Server-Sent Events |
| [Search](search.md) | `/1/search` | Full-text and faceted search across platform entities |

---

## Common conventions

### Pagination

List endpoints support cursor-based pagination:

| Parameter | Description |
|---|---|
| `?limit=N` | Maximum results per page (default varies by resource) |
| `?page=<cursor>` | Opaque cursor from `links.next` in the previous response |

### Filtering

| Parameter | Applies to | Description |
|---|---|---|
| `?filter=<expr>` | All list endpoints | Filter on resource fields |
| `?schema=<urn>` | Aspects | Filter by schema URN |
| `?entity=<urn>` | Aspects | Filter by entity URN |
| `?at-time=<ISO8601>` | Aspects | Historical query — records valid at this timestamp |

### Content types

- Request bodies: `application/json`
- Response bodies: `application/json` (list responses may follow JSON:API conventions)
- Artifact blob downloads: content-type matches the artifact's registered MIME type

### Error responses

All errors follow a consistent structure:

```json
{
  "id":     "urn:ivcap:error:...",
  "status": 404,
  "code":   "not-found",
  "detail": "No service with ID urn:ivcap:service:xxx",
  "links":  { "about": "..." }
}
```

### Typical request flow

```
1. List available services       GET /1/services
2. Inspect a service             GET /1/services/{id}
3. Upload input data (optional)  POST /1/artifacts  →  PUT /1/artifacts/{id}/blob
4. Submit a job                  POST /1/services/{id}/jobs
5. Poll for completion           GET /1/services/{id}/jobs/{jobId}
6. Retrieve results              GET /1/services/{id}/jobs/{jobId}/output
7. Download result artifacts     GET /1/artifacts/{id}/blob
```
