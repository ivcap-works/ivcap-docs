# Service

## Overview

A `Service` is an container for an analytics workflow template and its tasks. Systems users discover services using the `list service` method, and create an order for the service using the orders `create order` method.

Create a new service with the `create service` method.  Read, update, and delete services with the respective `read service`, `update service`, and `delete service` methods.

The `listOrders service` method returns a collection of the orders for a nominated service with the details for the order and its status.

| Method | HTTP request | Description |
| ----- | ----- | ----- |
| List service | GET /1/services | Returns a collection of zero or more `ServiceListItem` objects that match the request criteria.  An individual service is accessed by the `Read service` method. |
| Create service | POST /1/services | Creates a new service with the details supplied in the `ServiceDescriptionT` json object.  The success response body from the create request is the `ServiceStatusRT` json object.  In some instances, the `CreateResponseBodyTiny2` object may be returned. |
| Read service | GET /1/services/{id} | Returns the `ServiceStatusRT` json object containing the details of the service that matches the `id` parameter. |
| Update service | PUT /1/services/{id} | Updates the Service that matches the `id` parameter with the details supplied in the `ServiceDescriptionT` json object.  The `force-create` parameter may be used to create the service where there is no service that matches the `id` parameter.  The success response body from the update request is the `ServiceStatusRT` json object.  In some instances, the `CreateResponseBodyTiny2` object may be returned.  |
| Delete service | DELETE /1/services/{id} | Deletes the service that matches the `id` parameter.  There is no response body on success. |

## Methods

### List services

#### Common use cases

This method is used to retrieve a collection of zero or more `ServiceListItem` records that match the search criteria given via the parameters.  You can access the detail for an individual artifact with the `ServiceStatusRT` object returned by the `Read` method.

#### List services HTTP request

GET https://site.uri/1/services

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | OK | `ServiceListRT` JSON resource |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | |
| 501 | Not Implemented response | |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| $filter | string | ```$filter=FirstName eq 'Scott'``` | The search term or string used to limit the result set |
| $orderby | string | ```$orderby=EndsAt desc``` | The order of the artifacts in the result set |
| $top | string |  |  |
| $skip | integer |  |  |
| $select | string |  |  |
| offset | integer |  |  |
| limit | integer |  |  |
| pageToken | string |  |  |

#### ServiceListRT JSON Resource

 ```json
{
    "links"*: {
        "first": "uri",
        "next": "uri",
        "self": "uri"
    }
    "services"*: [{
        "description": "string",
        "id": "string",
        "links"*: {
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
        },
        "name": "string",
        "provider": {
            "id": "uri",
            "links": {
                "describedBy": {
                    "href": "uri",
                    "type": "string"
                },
                "self": "string"
            }
        }
    }]
}
```

| Property | |
| ---- | --- |
| links | optional, contains the `NavT` json object containing the resource `first`, `next`, and `self` uri elements. |
| links.first | `uri` object describing the location of the first `ServiceListItem` in the collection |
| links.next | `uri` the uri for the artifact |
| links.self | `uri` description for the resource type |
| services | an array of the `ServiceListItem` json objects, where each item contains |
| services.description | `string` the brief (optional) description of the service |
| services.id | `string` the ID for the service |
| services.links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects) |
| services.links.describedBy | the `DescribedByT` json object |
| services.links.describedBy.href | `uri`  |
| services.links.describedBy.type | `string`  |
| services.links.self | `string`  |
| services.name | `string` the name for the service |
| services.provider | which contains the details for the provider of the service |
| services.provider.id | `string` the ID for the service |
| services.provider.links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects) |
| services.provider.links.describedBy | the `DescribedByT` json object |
| services.provider.links.describedBy.href | `uri`  |
| services.provider.links.describedBy.type | `string`  |
| services.provider.links.self | `string`  |

#### ServiceListItem JSON Resource

```json
{
    "description": "string",
    "id": "string",
    "links"*: {
        "describedBy": {
            "href": "uri",
            "type": "string"
        },
        "self": "string"
    },
    "name": "string",
    "provider": {
        "id": "uri",
        "links": {
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
         }
    }
}
```

| Property | |
| ---- | --- |
| description | `string` a (optional) description of the service as supplied by the service provider. |
| id | `string` the service ID within __AVCAP__. |
| links | which contains a `SelfT` style json object (which contains the `DescribedByT` and `self` objects) |
| links.describedBy | the `DescribedByT` json object |
| links.describedBy.href | `uri`  |
| links.describedBy.type | `string` |
| links.self | `string`  |
| name | `string` Optional name for the service, as provided by the service provider(?). |
| provider | which contains the details for the provider of the service |
| provider.id | `string` the ID for the service provider |
| provider.links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects) |
| provider.links.describedBy | the `DescribedByT` json object |
| provider.links.describedBy.href | `uri`  |
| provider.links.describedBy.type | `string`  |
| provider.links.self | `string`  |

### Create services

#### Common use cases

This method is used to create a new service with the details supplied in the `ServiceDescriptionT` json object.  The success response body from the create request is the `ServiceStatusRT` json object.  In some instances, the `CreateResponseBodyTiny2` object may be returned.

#### List services HTTP request

POST https://site.uri/1/services

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 201 | Created response | `ServiceStatusRT` json object with the service status and details |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | a json object containing the `id` of the resource and the `message` for the error |
| 404 | Not Found response | a json object containing the `id` of the missing resource and the `message` for the error |
| 409 | Conflict response | a json object containing the `id` of the conflicting resource and the `message` for the error |
| 422 | Request contained semantically wrong parameter value response | the `InvalidParameterValue` json object containing the `message` for the error, `name` of the parameter, and the `value` of the parameter with the bad value. |
| 501 | Not Implemented response | a json object containing the message for the error. |

#### ServiceDescriptionT JSON Resource

Specify or update the service workflow using the `ServiceDescriptionT` json object.  Service users will search for and use the service using the information provided with this object.

 ```json
{
    "account-id"*: "uri",
    "banner": "uri",
    "description"*: "string",
    "metadata": [{
        "name": "string",
        "value": "string"
    }],
    "name": "string",
    "parameters"*: [{
        "constant": "boolean",
        "default": "string",
        "description": "string",
        "label": "string",
        "name": "string",
        "optional": "boolean",
        "options": [{
            "description": "string",
            "value": "string"
        }],
        "type": "string",
        "unit": "string",
        "help": "string"
    }],
    "provider-id"*: "uri",
    "provider-ref": "string",
    "references": [{
        "title": "string",
        "uri": "uri"
    }],
    "tags": ["string"],
    "workflow"*: {
        "argo": "binary",
        "basic": {
            "command": ["string"],
            "cpu": {
                "limit": "string",
                "request": "string"
            },
            "image": "string",
            "memory": {
                "limit": "string",
                "request": "string"
            }
        },
        "opts": "binary",
        "type": "string"
    }
}

```

| Property | |
| ---- | --- |
| account-id | `uri` Reference to the account for the credit of revenues for this service |
| banner | `uri` link to the banner image that may optionally be used for this service |
| description | `uri` Detailed description of the service as supplied by the service provider. |
| metadata | optional, meta data tags used for this service. |
| metadata.name | `string` |
| metadata.value | `string` |
| name | `string` optional service name supplied by the service provider. |
| parameters | an array of the `ServiceListItem` json objects, to define the service parameters. |
| parameters.constant | `boolean` |
| parameters.default | `string` |
| parameters.description | `string` |
| parameters.label | `string` |
| parameters.name | `string` |
| parameters.optional | `boolean` |
| parameters.options |  |
| parameters.options.description | `string`  |
| parameters.options.value | `string`  |
| parameters.type | `string` |
| parameters.unit | `string` |
| provider-id | `uri` Reference for service provider; `cayp:provider:acme` |
| provider-ref | `string` Reference for provider, as a single string with punctuations allowed. |
| references | References for this service. |
| references.title | `string` title of the reference document |
| references.uri | `uri` the link to the document |
| tags | `string` - __What do these tags do?__ - |
| workflow | Defines the workflow to use to execute this service. Currently supported 'types' are 'basic' and 'argo'. In case of 'basic', use the 'basic' element for further parameters. In the current implementation 'opts' is expected to contain the same schema as 'basic'. |
| workflow.argo | `binary` the argo workflow definition using the argo WF schema |
| workflow.basic |  |
| workflow.basic.command | `[string]` The command needed to start the container, which is necessary in some container runtimes. |
| workflow.basic.cpu | the [kubernetes Quantity documentation](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/) provides more information on the units. |
| workflow.basic.cpu.limit | `string` minimal requirements [system limit] |
| workflow.basic.cpu.request | `string` minimal requirements [0] |
| workflow.basic.image | `string` the container image name |
| workflow.basic.memory | the [kubernetes Quantity documentation](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/) provides more information on the units. |
| workflow.basic.memory.limit | `string` minimal requirements [system limit] |
| workflow.basic.memory.request | `string` minimal requirements [0] |
| workflow.opts | `string` Type specific options __Deprecated__: left for backward compatibility, if possible use type specific elements. |
| workflow.type | `string` Type of workflow |

#### ServiceStatusRT JSON Resource

```json
{
    "account": {
        "id": "uri",
        "links": {
            "describedBy": {
                "href": "uri",
                "type": "string",
                },
            "self": "string"
        }
    },
    "description": "string",
    "id"*: "string",
    "links"*: {
        "describedBy": {
            "href": "uri",
            "type": "string",
        }
        "self": "string",
    },
    "metadata": [{
        "name": "string",
        "value": "string"
    }],
    "name": "string",
    "parameters"*: [{
        "constant": "boolean",
        "default": "string",
        "description": "string",
        "label": "string",
        "name": "string",
        "optional": "boolean",
        "options": [{
            "description": "string",
            "value": "string",
        }],
        "type": "string",
        "unit": "string"
    }],
    "provider": {
        "id": "uri",
        "links": {
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
        }
    },
    "provider-ref": "string",
    "status": "enum",
    "tags": "[string]"
} 
```

| Property | |
| ---- | --- |
| account | `string` the ID for the service |
| account.id | `string` the ID for the service |
| account.links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects) |
| account.links.describedBy | the `DescribedByT` json object |
| account.links.describedBy.href | `uri`  |
| account.links.describedBy.type | `string`  |
| account.links.self | `string`  |
| description | `string` the brief (optional) description of the service |
| id | `string` the ID for the service |
| links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects) |
| links.describedBy | the `DescribedByT` json object |
| links.describedBy.href | `uri`  |
| links.describedBy.type | `string`  |
| links.self | `string`  |
| metadata | optional, meta data tags used for this service. |
| metadata.name | `string` |
| metadata.value | `string` |
| name | `string` optional service name supplied by the service provider. |
| parameters | an array of the `ServiceListItem` json objects, to define the service parameters. |
| parameters.constant | `boolean` |
| parameters.default | `string` |
| parameters.description | `string` |
| parameters.label | `string` |
| parameters.name | `string` |
| parameters.optional | `boolean` |
| parameters.options |  |
| parameters.options.description | `string`  |
| parameters.options.value | `string`  |
| parameters.type | `string` |
| parameters.unit | `string` |
| provider | `uri` Reference for service provider; `cayp:provider:acme` |
| provider.id | `uri` Reference for service provider; `cayp:provider:acme` |
| provider.links | `uri` Reference for service provider; `cayp:provider:acme` |
| provider.links.describedBy | the `DescribedByT` json object |
| provider.links.describedBy.href | `uri`  |
| provider.links.describedBy.type | `string`  |
| provider.links.self | `string`  |
| provider-ref | `string` Reference for provider, as a single string with punctuations allowed. |
| status | `enum` can be one of `pending`, `building`, `ready`, or `error` |
| tags | `[string]` optional tags provided in the ServiceDescriptionT for the service. |

### Read services

#### Common use cases

Get the details for a service with the Read services method which returns the `ServiceStatusRT` json object for supplied service id parameter.

#### List services HTTP request

GET https://site.uri/1/services/{id}

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | OK response | `ServiceStatusRT` json object with the service status and details |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 404 | Not Found response | a service matching the `id` parameter is not found, of the missing resource and the `message` for the error |
| 501 | Not Implemented response | a json object containing the message for the error. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | string | | The id for the artifact to return in the `ArtifactStatusRT` resource |

#### ServiceStatusRT JSON Resource

The [`ServiceStatusRT`](#servicestatusrt-json-resource) resource that contains the details for the service which matches the `{id}` parameter is given in the __OK__ response.

### Update services

#### Common use cases

Update an existing service with the details supplied in the `ServiceDescriptionT` json object.  Similar to the [Create Service method](#create-services), the success response body contains the `ServiceStatusRT` json object.  
In some instances, the `CreateResponseBodyTiny2` object may be returned.

> Note: Force the service to be created with the `force-create` query-string parameter.

#### List services HTTP request

PUT https://site.uri/1/services/{id}

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | Ok response | `ServiceStatusRT` json object with the service status and details |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | a json object containing the `id` of the resource and the `message` for the error |
| 404 | Not Found response | a json object containing the `id` of the missing resource and the `message` for the error |
| 409 | Conflict response | a json object containing the `id` of the conflicting resource and the `message` for the error |
| 422 | Request contained semantically wrong parameter value response | the `InvalidParameterValue` json object containing the `message` for the error, `name` of the parameter, and the `value` of the parameter with the bad value. |
| 501 | Not Implemented response | a json object containing the message for the error. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | `string` | | The id for the artifact to return in the `ServiceStatusRT` resource |
| force-create | `boolean` | | force the creation of the `Service` resource |

#### ServiceDescriptionT JSON Resource

The [`ServiceDescriptionT`](#servicedescriptiont-json-resource) resource that contains the details to be used to update the service that matches the `{id}` parameter is given in the __OK__ response.

#### ServiceStatusRT JSON Resource

The [`ServiceStatusRT`](#servicestatusrt-json-resource) resource contains the returned details for the service.

### Delete service

#### Common use cases

Delete a service using the `DeleteService` method using the id to identify and delete the service.
No content objects are necessary for this method.

#### List services HTTP request

DELETE https://site.uri/1/services/{id}

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 204 | No content response | on successful deletion, the 204 No content response is returned. |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | a json object containing the `id` of the resource and the `message` for the error |
| 501 | Not Implemented response | a json object containing the message for the error. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | string | | The id for the existing service to be deleted. |

### List Orders service

#### Common use cases

List the orders that have been placed for the service identified by the ID parameter.

#### List services HTTP request

GET https://site.uri/1/services/{id}/orders

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | Ok response | `ServiceStatusRT` json object with the service status and details |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | a json object containing the `id` of the resource and the `message` for the error |
| 404 | Not Found response | a json object containing the `id` of the missing resource and the `message` for the error |
| 501 | Not Implemented response | a json object containing the message for the error. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | string | | The service id used to identify the orders for the service. |


