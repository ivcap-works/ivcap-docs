# Search API

The Search API provides **full-text and faceted search** across platform
entities — services, artifacts, and aspects. Use it to discover resources
without knowing their URNs in advance.

---

## Endpoint

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/search` | Search across platform entities |

---

## Search entities

```
GET /1/search
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `q` | string | Full-text search query |
| `type` | string | Restrict to entity type: `service`, `artifact`, `aspect` |
| `schema` | string | Filter aspects by schema URN |
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |

**Examples:**

```bash
# Full-text search across all entities
GET /1/search?q=fire+risk

# Search only services
GET /1/search?q=fire+risk&type=service

# Search artifacts by name or metadata
GET /1/search?q=sentinel&type=artifact

# Find aspects of a given schema matching a term
GET /1/search?q=Tasmania&type=aspect&schema=urn:ivcap:schema:remote-sensing:scene.1
```

**Response `200 OK`:**

```json
{
  "results": [
    {
      "type":     "service",
      "id":       "urn:ivcap:service:b14569f9-...",
      "name":     "Fire Risk Analysis",
      "score":    0.97,
      "snippet":  "Runs fire risk analysis for a given region...",
      "links":    { "self": "/1/services/urn:ivcap:service:b14569f9-..." }
    },
    {
      "type":     "artifact",
      "id":       "urn:ivcap:artifact:6f390b51-...",
      "name":     "fire-risk-tasmania-2025.csv",
      "score":    0.84,
      "links":    { "self": "/1/artifacts/urn:ivcap:artifact:6f390b51-..." }
    }
  ],
  "total":  2,
  "links":  { "self": "..." }
}
```

---

## Result object fields

| Field | Type | Description |
|---|---|---|
| `type` | string | Entity type: `service`, `artifact`, or `aspect` |
| `id` | string | URN of the matching entity |
| `name` | string | Display name |
| `score` | float | Relevance score (0–1; higher is more relevant) |
| `snippet` | string | Highlighted excerpt showing why the result matched |
| `links.self` | string | Path to the full entity record |

---

## Search vs. filtered list endpoints

| Use case | Recommended endpoint |
|---|---|
| Discover resources by keyword | `GET /1/search?q=...` |
| List all artifacts | `GET /1/artifacts` |
| Find aspects by entity or schema | `GET /1/aspects?entity=...&schema=...` |
| Find services by exact name | `GET /1/services?filter=name eq '...'` |

The Search API is optimised for human-driven discovery. For programmatic
queries with known criteria, prefer the resource-specific list endpoints
with `filter` parameters.

---

## CLI equivalent

The `ivcap` CLI does not expose a dedicated `search` command — use
`ivcap service list --filter`, `ivcap artifact list --filter`, or
`ivcap aspect list --schema` for filtered listing from the CLI.
