# Create Sessions {#sessions}

After [authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication) Creates a session and returns the ***bearer token*** which must be inserted into the header of resource requests using the API

## HTTP Request

'POST /1/sessions'

### Request headers

'Content-Type: application/json'

### Request body

The request body consists of a [JSON object](https://www.json.org/json-en.html) that contains the auth string

Example
```
{
  "auth": "eyJhbGciOiJIUz..."
}
```

```
Valid Request body elements                                           
+---------+-----------+---------------------------------+
| Element | Type      | Description                     |
+---------+-----------+---------------------------------+
| auth    | string    | the JWT used for authentication |
+---------+-----------+---------------------------------+
```

### Response

Response Headers
