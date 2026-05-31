# Sessions & Authentication

All IVCAP API calls require a **JWT Bearer token** in the `Authorization`
header. The Sessions API lets you exchange an externally-obtained JWT for
a platform session token, and retrieve information about the active session.

For a full guide on obtaining tokens and setting up contexts, see
[Authentication](../../guides/integrating/authentication.md).

---

## Authentication flow

```
1. Discover auth providers    GET  <base-url>/1/authinfo.yaml
2. Complete device auth flow  (handled by the CLI or your IdP client)
3. Exchange JWT for session   POST /1/sessions
4. Use session token          Authorization: Bearer <token>
5. Refresh on expiry          POST /1/sessions  (with refresh token)
```

The `ivcap` CLI handles steps 1–5 automatically via `ivcap context login`.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/authinfo.yaml` | Discover configured identity providers |
| `POST` | `/1/sessions` | Create a session / exchange a JWT for a bearer token |
| `GET` | `/1/sessions` | Get current session info |
| `DELETE` | `/1/sessions` | Invalidate the current session |

---

## Discover auth providers

```
GET <base-url>/1/authinfo.yaml
```

Returns a YAML document listing the configured identity providers and their
endpoints. This is the only public endpoint that does not require a token.

**Example response:**

```yaml
providers:
  - name: Auth0
    type: oidc
    issuer: https://your-tenant.auth0.com/
    device_authorization_endpoint: https://your-tenant.auth0.com/oauth/device/code
    token_endpoint: https://your-tenant.auth0.com/oauth/token
    client_id: abc123...
```

---

## Create a session

```
POST /1/sessions
```

Exchange an identity-provider JWT for a platform session token.

**Request body:**

```json
{
  "auth": "eyJhbGciOiJSUzI1NiIs..."
}
```

The `auth` value is the JWT obtained from the identity provider's device
authorisation or OIDC flow.

**Response `201 Created`:**

```json
{
  "token":      "eyJhbGciOiJIUz...",
  "expires_at": "2025-06-01T12:00:00Z"
}
```

Include the returned token in subsequent requests:

```
Authorization: Bearer eyJhbGciOiJIUz...
```

---

## Get current session

```
GET /1/sessions
```

Returns information about the authenticated identity associated with the
current token.

**Response `200 OK`:**

```json
{
  "account": "urn:ivcap:account:<uuid>",
  "subject":  "user@example.com",
  "expires_at": "2025-06-01T12:00:00Z"
}
```

---

## Delete session (logout)

```
DELETE /1/sessions
```

Invalidates the current session token server-side.

**Response `204 No Content`** on success.

---

## CLI equivalents

```bash
ivcap context login             # complete device auth flow and store token
ivcap context get               # show current context / session info
ivcap context logout            # invalidate and clear stored tokens
```

---

## Token expiry and refresh

Tokens have a finite lifetime (typically 1–24 hours depending on deployment
configuration). The `ivcap` CLI refreshes tokens automatically before expiry.

When using the REST API directly, monitor the `expires_at` field from
`GET /1/sessions` and re-authenticate via the identity provider's refresh
token flow before the token expires.
