## Security

### Authentication 

IVCAP implements the [oauth2](https://oauth.net/2/) authentication model.
Authentication for the user device is currently provided via the [ivcap-cli](https://github.com/reinventingscience/ivcap-cli) command line interface.

The [cli login command](https://github.com/reinventingscience/ivcap-cli) illustrates the oauth2 authentication flow, token management, and the refresh of the JWT token within the service using golang.
Service providers may choose to implement the authentication and token management within their service.

Update the details for the oauth provider in the `/api-gateway/public/authinfo.yaml` yaml.
`Authinfo.yaml` is used to authenticate the user connection with the oauth provider you specify.  
While the data structure suggests multiple providers may be allowed, only the single provider is currently supported.

### Authorisation

Authorisation is controlled using the OPA rules set by the `.rego` files in the IVCAP-core `api_gateway/opa/default/` directory.

The rules files define if the caller is allowed to call a particular service, define the results the user may see, and define the actions a user may take.

### General

User activities should be logged, and those logs moved to long term-storage for interrogation when needed.

### APIs

All APIs require that the connecting application has a valid JWT token.
An error is returned when a valid JWT token is not present.

### Encryption

*Question* - Is data encrypted while in transit?
data xfer inside - not encrypted.
3rd party containers exec inside cluster. - More solid security review/resting on service delivery & deployment.  (honest but curious)
encrypted between users & their service.

### Publishing containers

Are containers scanned for security and vulnerability threats prior to publishing them to the Container registry?
