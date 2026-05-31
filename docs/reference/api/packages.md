# Packages API

Packages are Docker container images stored in the platform's
**account-scoped registry**. Every service runs inside a container image;
the Packages API lets you list and clean up images associated with your
account.

---

## How packages work

1. Build your service container image locally.
2. Push it to the platform registry using `docker push` and registry
   credentials obtained from your deployment operator.
3. Reference the image in your service definition's `workflow.basic.image`
   field.
4. Use the Packages API (or CLI) to list and remove images as needed.

The Packages API is for **lifecycle management** only — image pushing uses
the standard Docker registry protocol.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/packages/list` | List container images for your account |
| `DELETE` | `/1/packages/remove` | Remove an image by tag |

---

## List packages

```
GET /1/packages/list
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |

**Response `200 OK`:**

```json
{
  "packages": [
    {
      "tag":       "my-registry.example.com/fire-risk:1.2.3",
      "digest":    "sha256:abc123...",
      "size":      524288000,
      "pushedAt":  "2025-05-28T09:12:00Z"
    }
  ],
  "links": { "self": "...", "next": "..." }
}
```

---

## Remove a package

```
DELETE /1/packages/remove?tag={tag}
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `tag` | string | Full image tag to remove (e.g. `my-registry.../fire-risk:1.2.3`) |

**Response `204 No Content`** on success.

!!! warning
    Removing a package image that is still referenced by an active service
    definition will cause future job submissions to fail. Ensure no active
    services use the image before removing it.

---

## CLI equivalents

```bash
ivcap package list
ivcap package remove my-registry.example.com/fire-risk:1.2.3
```

---

## Pushing an image

Obtain registry credentials from your deployment operator, then:

```bash
# Authenticate to the registry
docker login my-registry.example.com

# Build and push
docker build -t my-registry.example.com/fire-risk:1.2.3 .
docker push my-registry.example.com/fire-risk:1.2.3
```

After pushing, reference the image in your service YAML:

```yaml
workflow:
  type: basic
  basic:
    image: my-registry.example.com/fire-risk:1.2.3
    command: ["/app/run"]
    memory:
      request: 512Mi
      limit:   2Gi
    cpu:
      request: 250m
      limit:   2000m
```
