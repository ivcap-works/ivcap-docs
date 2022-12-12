# Orders

## Overview

Request analytics services on collections of artifacts with the `Order` methods.  _Create_, _list_, and _Read_ orders to request an analytics service, check progress, or access the results of the service.

| Method | HTTP request | Description |
| ----- | ----- | ----- |
| List | GET /1/orders | Returns a collection of zero or more `OrderListItem` objects that match the request criteria.  An individual order is accessed by the `Read` order method. |
| Create | POST /1/orders | Create an order using a service, supply necessary metadata and parameters.  Use the `OrderStatusRT` json object returned to access the order id, and other order information. |
| Read | GET /1/orders/{id} | Retrieves the details for the order that matches the supplied `id` parameter. |

## Methods

### List orders

#### Common use cases

This method is used to retrieve a collection of zero or more `OrderListItem` records that match the search criteria given via the parameters.  Access an orders detail with the `Read` method, which returns the `OrderStatusRT` json object.

#### List Orders HTTP request

GET https://site.uri/1/orders

#### HTTP response codes

| Response code | Response type | Response resource |
| --- | --- | --- |
| 200 | OK | `OrderListRT` json resource that contains an array of the `OrderListItem` objects |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | `InvalidScopesT` json resource with the id of the resource in error and the error message. |
| 501 | Not Implemented response | `NotImplementedT` json resource is returned which contains the an information message. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| $filter | string | ```$filter=FirstName eq 'Scott'``` | The search term or string used to limit the result set |
| $orderby | string | ```$orderby=EndsAt desc``` | The order of the orders in the result set |
| $top | string |  |  |
| $skip | integer |  |  |
| $select | string |  |  |
| offset | integer |  |  |
| limit | integer |  |  |
| pageToken | string |  |  |

#### OrderListRT JSON Resource

Use the OrderListRT structure to discover the Orders and their status.

```json
{
    "links"*: {
        "first": "uri",
        "next": "uri",
        "self": "uri"
    },
    "orders"*: [{
        "account_id": "string",
        "finished_at": "string",
        "id": "string",
        "links"*: {
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string",
        },
        "name": "string",
        "ordered_at": "string",
        "service_id": "string",
        "status": "enum"
    }]
}
```

| Property | |
| ---- | --- |
| links | An optional element which contains the `NavT` json structure of the first, next, and self URIs. |
| links.first | `uri` the uri for the first order in the collection. |
| links.next | `uri`  |
| links.self | `uri`  |
| orders | Is an array of the [OrderListItem](#orderlistitem-json-resource) json objects. |
| orders.account_id | `string` The account ID for the order. |
| orders.finished_at | `string` The date that the order finished. |
| orders.id | `string` The ID for the order. |
| orders.links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| orders.links.describedBy| |
| orders.links.describedBy.href | `uri` the uri for the order. |
| orders.links.describedBy.type | `string` description for the resource type. |
| orders.links.self | `string`  |
| orders.name | `string` An optional, customer supplied name. |
| orders.ordered_at | `string` The date the order was requested. |
| orders.service_id | `string` The ID for the service for the order. |
| orders.status | `enum` can be one of `pending`, `executing`, `finished`, or `error`. |

#### OrderListItem JSON Resource

The JSON structure used in a result set to provide the information for an individual order.

```json
{
    "account_id": "string",
    "finished_at": "string",
    "id": "string",
    "links"*: {
        "describedBy": {
            "href": "uri",
            "type": "string"
        },
        "self": "string"
    },
    "name": "string",
    "ordered_at": "string",
    "service_id": "string",
    "status": "enum"
}

```

| Property | |
| ---- | --- |
| account_id | `string` The account ID for the order. |
| finished_at | `string` The date that the order finished. |
| id | `string` The ID for the order. |
| links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| links.describedBy| |
| links.describedBy.href | `uri` the uri for the order. |
| links.describedBy.type | `string` description for the resource type. |
| links.self | `string`  |
| name | `string` The optional, customer supplied name. |
| ordered_at | `string` The data that the order was requested. |
| service_id | `string` The ID for the service. |
| status | `enum` can be one of `pending`, `executing`, `finished`, or `error` |

### Create order

#### Common use cases

Create an order to start an analytics service on a data collection.  Use the `ServiceListItem.id` as the `serviceID` (the `ListService` method lists the available services) and supply the necessary metadata and parameters using the `OrderRequestT` json object.
The `OrderStatusRT` json object contains the order details and is returned on success.

#### List services HTTP request

POST https://site.uri/1/orders

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | Created response | `ServiceStatusRT` json object with the service status and details. |
| 400 | Bad Request response. | |
| 401 | Unauthorised response. | |
| 403 | Forbidden response | `InvalidScopesT` json resource with the id of the resource in error and the error message. |
| 404 | Not Found response | `ResourceNotFoundT` json object containing the `id` of the missing resource and the `message` for the error. |
| 422 | Request contained semantically wrong parameter value response | the `InvalidParameterValue` json object containing the `message` for the error, `name` of the parameter, and the `value` of the parameter with the bad value. |
| 501 | Not Implemented response | `NotImplementedT` json resource is returned which contains the an information message. |
| 503 | Service Unavailable response. |  |

#### OrderRequestT JSON Resource

Order a new analytics service workflow with the `OrderRequestT` json object.

```json
{
    "accountID"*: "uri",
    "metadata"*: [{
        "name": "string",
        "value": "string"
    }],
    "name": "string",
    "parameters"*: [{
        "name": "string",
        "value": "string"
    }],
    "serviceID"*: "uri"
}
```

| Property | |
| ---- | --- |
| accountID | `uri` Reference to the account for the credit of revenues for the service. |
| metadata | Optional, meta data tags used for this service. |
| metadata.name | `string` |
| metadata.value | `string` |
| name | `string` An optional customer supplied name for the order. |
| parameters| Optional, the name/value parameters needed for the service. |
| parameters.name | `string` The name of the parameter. |
| parameters.value | `string` The value of the parameter. |
| serviceID | `string` The optional, customer supplied name. |

#### OrderStatusRT JSON Resource

```json
{
    "account": {
        "id": "uri",
        "links": {
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
        }
    },
    "id"*: "uuid",
    "links": {
        "describedBy": {
            "href": "uri",
            "type": "string"
        },
        "self": "string"
    },
    "metadata"*: [{
        "name": "string",
        "value": "string"
    }],
    "name": "string",
    "ordered_at": "string",
    "parameters"*: [{
        "name": "string",
        "value": "string"
    }],
    "products": [{
        "id": "string",
        "links": {
            "data": "string",
            "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
        }
        "mime-type": "string",
        "name": "string",
        "size": "int64",
        "status": "string"
    }]
    "service": {
        "id": "uri",
        "links": {
                "describedBy": {
                "href": "uri",
                "type": "string"
            },
            "self": "string"
        }
    },
    "status": "enum"
}
```

| Property | |
| ---- | --- |
| account | The account details for the order .|
| account.id | `string` The ID for the account for the order. |
| account.links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects). |
| account.links.describedBy | The `DescribedByT` json object. |
| account.links.describedBy.href | `uri`  |
| account.links.describedBy.type | `string`  |
| account.links.self | `string`  |
| id | `string` The ID for the order. |
| links | which contains the `SelfT` json object (which contains the `DescribedByT` and `self` objects). |
| links.describedBy | The `DescribedByT` json object. |
| links.describedBy.href | `uri`  |
| links.describedBy.type | `string`  |
| links.self | `string`  |
| metadata | Optional, meta data tags used for this service. |
| metadata.name | `string` |
| metadata.value | `string` |
| name | `string` Optional customer supplied name for the order. |
| ordered_at | `string` Containing the order date, example: 2022-01-01. |
| parameters| Optional, the name/value parameters used for the order. |
| parameters.name | `string` The name of the parameter. |
| parameters.value | `string` The value of the parameter. |
| products | An array of the products that are created by the service for the order. |
| products.id | `string` The ID for the product. |
| products.links | which contains the `SelfWithDataT` json object (which contains the `data`, `DescribedByT`, and `self` objects). |
| products.links.data | `string` |
| products.links.describedBy | the `DescribedByT` Json object. |
| products.links.describedBy.href | `uri`  |
| products.links.describedBy.type | `string` Example: 1705023718571840300. |
| products.links.self | `string`  |
| products.mime-type | `string` |
| products.name | `string` |
| products.size | `int64` |
| products.status | `string` |
| service | Information for the service to satisfy the order. |
| service.id | `uri` Reference for service provider, example: http://erdman.name/vivien.renner |
| service.links |  |
| service.links.describedBy | The `DescribedByT` json object. |
| service.links.describedBy.href | `uri` example:  https://api.com/swagger/... |
| service.links.describedBy.type | `string` example: application/openapi3+json |
| service.links.self | `string`  |
| status | `enum` Can be one of `pending`, `executing`, `finished`, or `error`. |

### Read order

#### Common use cases

Get the details for an order with the Read services method which returns the `OrderStatusRT` json object for supplied  id parameter.

#### List services HTTP request

GET https://site.uri/1/orders/{id}

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | OK response | `ServiceStatusRT` Json object with the service status and details. |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | `InvalidScopesT` Json resource with the id of the resource in error and the error message. |
| 404 | Not Found response | A service matching the `id` parameter is not found, of the missing resource and the `message` for the error. |
| 501 | Not Implemented response | A json object containing the message for the error. |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | string | | The id for the order to return in the `OrderStatusRT` resource. |

#### OrderStatusRT JSON Resource

The [`OrderStatusRT`](#orderstatusrt-json-resource) resource that contains the details for the service which matches the `{id}` parameter is given in the __OK__ response.

