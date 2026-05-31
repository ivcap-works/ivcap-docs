# Queues API

Queues provide **asynchronous message passing** between services or pipeline
stages. One service (or client) enqueues work items; another dequeues and
processes them. Each queue is identified by a `urn:ivcap:queue:<uuid>`.

See [Queues concept](../../concepts/queues.md) for architectural patterns.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/1/queues` | List queues |
| `POST` | `/1/queues` | Create a queue |
| `GET` | `/1/queues/{id}` | Get queue details |
| `DELETE` | `/1/queues/{id}` | Delete a queue |
| `POST` | `/1/queues/{id}/messages` | Enqueue a message |
| `GET` | `/1/queues/{id}/messages` | Dequeue message(s) |

---

## List queues

```
GET /1/queues
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Maximum results per page |
| `page` | string | Pagination cursor from `links.next` |

**Response `200 OK`:**

```json
{
  "queues": [
    {
      "id":   "urn:ivcap:queue:<uuid>",
      "name": "my-work-queue",
      "links": { "self": "..." }
    }
  ],
  "links": { "self": "...", "next": "..." }
}
```

---

## Create a queue

```
POST /1/queues
```

**Request body:**

```json
{
  "name":   "my-work-queue",
  "policy": "urn:ivcap:policy:private"
}
```

**Response `201 Created`** — returns the new queue record with its assigned URN.

---

## Get queue details

```
GET /1/queues/{id}
```

Returns queue metadata and current depth (number of pending messages).

---

## Delete a queue

```
DELETE /1/queues/{id}
```

**Response `204 No Content`** on success. Deleting a queue also removes all
unprocessed messages in it.

---

## Enqueue a message

```
POST /1/queues/{id}/messages
```

**Request body** — any valid JSON object:

```json
{
  "task":       "analyse-region",
  "region":     "Tasmania-North",
  "artifact":   "urn:ivcap:artifact:<uuid>",
  "priority":   1
}
```

**Response `202 Accepted`** — message has been accepted into the queue.

---

## Dequeue message(s)

```
GET /1/queues/{id}/messages
```

**Query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `limit` | integer | Number of messages to dequeue (default: 1) |

Returns messages and removes them from the queue. If the queue is empty,
returns an empty list (long-polling is not currently supported — poll at
your preferred interval).

**Response `200 OK`:**

```json
{
  "messages": [
    {
      "id":      "msg-uuid",
      "content": {
        "task":     "analyse-region",
        "region":   "Tasmania-North",
        "artifact": "urn:ivcap:artifact:<uuid>"
      }
    }
  ]
}
```

---

## CLI equivalents

```bash
ivcap queue list
ivcap queue create --name my-work-queue
ivcap queue get urn:ivcap:queue:<uuid>
ivcap queue enqueue urn:ivcap:queue:<uuid> -f message.json
ivcap queue dequeue urn:ivcap:queue:<uuid>
ivcap queue delete urn:ivcap:queue:<uuid>
```

---

## Typical pipeline pattern

```
Producer service                    Consumer service
─────────────────                   ─────────────────
POST /1/queues/{id}/messages  →→→   GET /1/queues/{id}/messages
  { "task": "...", ... }               process message
                                       POST /1/aspects  (record result)
```

Both producer and consumer can be IVCAP services running as jobs, external
clients, or AI agents.
