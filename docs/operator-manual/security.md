## Security

The overall security posture is defined as "honest but curious".

Meaning that while data is [encrypted](#encryption) between users & their service, it is generally not encrypted within the cluster.

Users must [authenticate](#authentication) to gain access to their service in a meaningful way.  Their ability to interact with their service is governed by [policy authorisation](#authorisation) using `OPA` `Rego` configuration files.

It is recommended that operators implement [threat and vulnerability scanning](#publishing-containers) before publishing containers into the cluster.

### Authentication 

IVCAP implements the [oauth2](https://oauth.net/2/) authentication model.
Authentication for the user device is currently provided via the [ivcap-cli](https://github.com/reinventingscience/ivcap-cli) command line interface.

The [cli login command](https://github.com/reinventingscience/ivcap-cli) illustrates the oauth2 authentication flow, token management, and the refresh of the JWT token within the service using golang.
Service providers may choose to implement the authentication and token management within their service.

Update the details for the oauth provider in the `/api-gateway/public/authinfo.yaml` yaml.
`Authinfo.yaml` is used to authenticate the user connection with the oauth provider you specify.  
While the data structure suggests multiple providers may be allowed, only the single provider is currently supported.

### Authorisation

Authorisation is controlled using the [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/) rules set in the [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) Policy and query language.

OPA is a technology independent open source policy central policy language for use in cloud environments and can enforce policies in microservices, Kubernetes, CI/CD, API Gateways, and related services.

Use the `.rego` files (found in the IVCAP-core `api_gateway/opa/default/` directory) to hold the policy rules for actions you want to `allow` (or not allow) with the services.

The rules files define if the caller is allowed to call a particular service, define the results the user may see, and define the actions a user may take.

Review the [getting started OPA documentation](https://www.openpolicyagent.org/docs/latest/policy-testing/#getting-started) for more information on writing `Rego` files.

An example of how the rules are used in the `artifact.rego` shows how a default deny, followed by the allowed actions for an authenticated account:

``` R
package cayp.artifact

default list_in = {"allow": false}

default read_out = {"allow": false}

default upload_in = {"allow": false}

default addcollection_in = {"allow": false}

default removecollection_in = {"allow": false}

default addmetadata_in = {"allow": false}

default removemetadata_in = {"allow": false}

# Extend list queries to only include the account holder's orders
list_in = {"allow": true, "account-id": aid} {
	aid := input.requester.Account
}

# Only return the details of a single artifact if the
# requester's 'Account.ID' is identical to the account ID associated with the artifact
read_out = {"allow": true} {
	c_acc := acc2uuid(input.requester.Account)
	r_acc := acc2uuid(input.data.response.Projected.Account.ID)
	print("c_acc:", c_acc, "r_acc:", r_acc)
	c_acc = r_acc
}

# Only accept artifacts where the 'Artifact.AccountID' in the payload
# is identical to the account ID (jwt: 'acc') of the caller
upload_in = {"allow": true} {
	print("upload_in!!!", input.requester.Account)
	isAccount(input.requester.Account)
}
```

### Logging

User activities should be logged, and those logs moved to long term-storage for interrogation when needed.

### APIs

All APIs require that the connecting application has a valid JWT token.
An error is returned when a valid JWT token is not present.

### Encryption

Data exchanged between the service and external users and services is encrypted in transit.  However data transfer between the services inside the K8s cluster is generally not encrypted.

This also means that third party containers executed inside the cluster may have access to the data used and stored for the services necessitating more solid security reviews and testing on service delivery & deployment.  

### Publishing containers

Container scanning for security and vulnerability threats prior to publishing them to the Container registry may be contingent on the hosted environment.

A robust policy of scanning containers for security and vulnerability threats should take place prior to publishing containers to the non-prod or  testing is recommended to be implemented by the system operators.

A program of code reviews may help mitigate the threat of the code within the containers being used for untoward activities.
