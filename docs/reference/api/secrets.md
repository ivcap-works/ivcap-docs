# Secrets API

Secrets allow API keys, passwords, and other credentials to be stored
securely in the platform and injected into service containers at runtime —
without ever exposing values through the public API.

---

## How secrets work

1. An operator stores a secret value via `PUT /1/secrets/{name}`.
2. When a job executes, the IVCAP sidecar makes the secret available to the
   service container via a local proxy endpoint.
3. Service code retrieves the secret at runtime using the service SDK or the
   sidecar's `secret_proxy` endpoint — **not** via the public REST API.
4. Secret values are **never** returned by `GET /1/secrets` or any other
   public endpoint.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/secrets` | List secret names (values never returned) |
| `PUT` | `/1/secrets/{name}` | Create or update a secret value |
| `DELETE` | `/1/secrets/{name}` | Remove a secret |

---

## List secrets

```
GET /1/secrets
```

Returns only the secret **names** — values are never included in responses.

**Response `200 OK`:**

```json
{
  "secrets": [
    { "name": "MY_API_KEY" },
    { "name": "DATABASE_PASSWORD" }
  ]
}
```

---

## Create or update a secret

```
PUT /1/secrets/{name}
```

The secret name must consist of alphanumeric characters and underscores only
(e.g. `MY_API_KEY`). The request body carries the secret value.

**Request body:**

```json
{
  "value": "sk-abc123..."
}
```

Alternatively, supply the value as raw bytes in the request body with
`Content-Type: text/plain`.

**Response `204 No Content`** on success.

!!! warning
    Secret values transmitted in the request body are protected by TLS
    in transit. Ensure your deployment uses HTTPS in production.

---

## Delete a secret

```
DELETE /1/secrets/{name}
```

**Response `204 No Content`** on success.

---

## CLI equivalents

```bash
ivcap secret list
ivcap secret set MY_API_KEY -f ./api-key.txt     # value read from file
ivcap secret delete MY_API_KEY
```

---

## Using secrets in a service

In your service code (Python SDK example):

```python
from ivcap_sdk_service import get_secret

api_key = get_secret("MY_API_KEY")
```

The SDK communicates with the sidecar's `secret_proxy` endpoint; the value
never passes through the public API.
