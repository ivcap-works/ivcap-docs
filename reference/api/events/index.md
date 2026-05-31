# Live Events (Server-Sent Events)

IVCAP streams real-time job status updates using the
[Server-Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
protocol. This lets a client receive a live feed of events as a job moves
through its lifecycle — without polling.

---

## Endpoint

```
GET /1/services/{serviceId}/jobs/{jobId}/events
```

Opens an SSE stream that emits [CloudEvents](https://cloudevents.io/) JSON
objects as the job progresses. The stream **closes automatically** when the
job reaches a terminal state (`succeeded`, `failed`, or `error`).

---

## Authentication

Include your bearer token as usual:

```bash
curl -N \
  -H "Authorization: Bearer <token>" \
  -H "Accept: text/event-stream" \
  https://api.example.ivcap.net/1/services/<svcId>/jobs/<jobId>/events
```

The `-N` flag disables curl's output buffering, which is necessary for
streaming responses.

---

## Event format

Events are emitted in SSE format — each event has an `event` type line and
a `data` line containing a JSON object:

```
event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"scheduled","timestamp":"2025-06-01T10:00:01Z"}

event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"executing","timestamp":"2025-06-01T10:00:05Z"}

event: ivcap.job.status
data: {"id":"urn:ivcap:job:<uuid>","status":"succeeded","timestamp":"2025-06-01T10:04:23Z"}
```

The stream closes after the terminal-state event.

---

## Event types

| Event name | Emitted when |
|---|---|
| `ivcap.job.status` | Job status changes (`pending` → `scheduled` → `executing` → terminal) |
| `ivcap.job.log` | Service container emits a log line (if enabled on the deployment) |
| `ivcap.job.artifact` | A result artifact becomes available before job completion |

---

## Event data fields

| Field | Type | Description |
|---|---|---|
| `id` | string | Job URN (`urn:ivcap:job:<uuid>`) |
| `status` | string | New job status value |
| `timestamp` | ISO 8601 | When the event was recorded |
| `message` | string | Optional human-readable message (e.g. log line) |
| `artifact` | string | Artifact URN (for `ivcap.job.artifact` events) |

---

## Terminal states

The SSE stream closes when any of these statuses is received:

| Status | Meaning |
|---|---|
| `succeeded` | Service completed successfully |
| `failed` | Service reported a failure |
| `error` | Platform or infrastructure error |

After the stream closes, retrieve full results via
`GET /1/services/{id}/jobs/{jobId}` and
`GET /1/services/{id}/jobs/{jobId}/output`.

---

## CLI equivalent

The `ivcap order watch` command wraps SSE streaming with a progress display:

```bash
ivcap order watch urn:ivcap:job:<uuid>
```

This blocks until the job reaches a terminal state, printing status updates
as they arrive.

---

## Browser / JavaScript example

```javascript
const url = `https://api.example.ivcap.net/1/services/${svcId}/jobs/${jobId}/events`;
const evtSource = new EventSource(url, {
  headers: { Authorization: `Bearer ${token}` }
});

evtSource.addEventListener("ivcap.job.status", (e) => {
  const data = JSON.parse(e.data);
  console.log("Job status:", data.status);
  if (["succeeded", "failed", "error"].includes(data.status)) {
    evtSource.close();
  }
});
```

---

## Python example

```python
import sseclient
import requests

url = f"https://api.example.ivcap.net/1/services/{svc_id}/jobs/{job_id}/events"
headers = {"Authorization": f"Bearer {token}", "Accept": "text/event-stream"}

response = requests.get(url, headers=headers, stream=True)
client = sseclient.SSEClient(response)

for event in client.events():
    if event.event == "ivcap.job.status":
        import json
        data = json.loads(event.data)
        print(f"Status: {data['status']}")
        if data["status"] in ("succeeded", "failed", "error"):
            break
```
