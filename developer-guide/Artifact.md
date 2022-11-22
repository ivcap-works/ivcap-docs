# Artifact

## Overview

An `Artifact` is an individual image record, along with its associated MetaData held within IVCAP.  Upload an artifact with the Upload method, Get an individual records data and meta-data with the Read method, and search for an artifact with the List method.

| Method | HTTP request | Description |
| ----- | ----- | ----- |
| List | GET /1/artifacts | Returns a collection of zero or more `ArtifactListItem` that match the request criteria.  An individual artifact is accessed by the `Read` artifact method. |
| Upload | POST /1/artifacts | Uploads an artifact and its associated metadata. |
| Read | GET /1/artifacts/{id} | Retrieves the details for the artifact that matches the supplied `id` parameter. |

## Methods

### List artifacts {#ListArtifact}

#### Common use cases

This method is used to retrieve a collection of zero or more `ArtifactListItem` records that match the search criteria given via the parameters.  You can access the detail for an individual artifact with the `ArtifactStatusRT` object returned by the `Read` method.

#### List artifacts HTTP request

GET https://site.uri/1/artifacts

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | OK | `ArtifactListRT` JSON resource |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | `InvalidScopesT` json resource with the id of the resource in error and the error message. |
| 501 | Not Implemented response | `NotImplementedT` json resource is returned which contains the an information message. |

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

#### ArtifactListRT JSON Resource

The ArtifactListRT structure is returned by the [List Artifact]{#ListArtifact} method.

```json
{
  "artifacts"* [{
    "id": "string",
    "links"*: {
        "describedBy": {
          "href": "uri",
          "type": "string"
        },
        "self": "string"
    },
    "name": "string",
    "status": "enum"
  }]
  "links"*: {
    "first": "uri",
    "next": "uri",
    "self": "uri"
  },
}
```

| Property | |
| ---- | --- |
| artifacts | Is an array of the [ArtifactListItem]{#ArtifactListItem} json objects. |
| artifacts.id | `string` which is the ID for the artifact in the system. |
| artifacts.links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| artifacts.links.describedBy| |
| artifacts.links.describedBy.href | `uri` the uri for the artifact |
| artifacts.links.describedBy.type | `string` description for the resource type |
| artifacts.links.self | `string`  |
| artifacts.name | `string`  |
| artifacts.status | `enum` can be one of `pending`, `building`, `ready`, or `error` |
| links | An optional element which contains the `NavT` json structure of the first, next, and self URIs. |
| links.first | `uri` the uri for the first ... |
| links.next | `uri`  |
| links.self | `uri`  |

#### ArtifactListItem

The JSON structure used in a result set to refer to an individual Artifact record within the List.

```json
{
  "id": "cayp:artifact:0000-000",
  "links"*: {
      "describedBy": {
        "href": "https://api.com/swagger/...",
        "type": "application/openapi3+json"
      },
      "self": "Cupiditate aperiam quo."
  },
  "name": "Fire risk for Lot2",
  "status": "ready"
}
```

| Property | |
| ---- | --- |
| id | `string` which is the ID for the artifact in the system. |
| links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| links.describedBy| |
| links.describedBy.href | `uri` the uri for the artifact |
| links.describedBy.type | `string` description for the resource type |
| links.self | `string`  |
| name | `string`  |
| status | `enum` can be one of `pending`, `building`, `ready`, or `error` |

### Upload artifact {#UploadArtifact}

#### Common use cases

Upload a new Artifact, or Update an existing Artifact using the `ArtefactStatusRT` resource.

#### Upload artifact HTTP request

POST https://site.uri/1/artifacts

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 201 | Created response | Response Headers |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | |
| 501 | Not Implemented response | |

##### 201 Created response Headers

| Error code | response type | response resource |
| --- | --- | --- |
| Location | string | link record |
| Tus-Resumable | string | version of TUS supported |
| Upload-Offset | int64 | TUS offset for partially uploaded content |

#### Request Headers

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| Content-Type | string | `application/x-netcdf4` | the content type for the artifact |
| Content-Encoding | string | `gzip` | |
| Content-Length | int64 | `2376` |  |
| X-Name | string | `field-trip-jun-22` |  |
| X-Collection | string | `field-trip-jun-22` |  |
| Upload-Metadata | string | `filename ` |  |
| X-Content-Type | string | `application/x-netcdf4` |  |
| Upload-Length | int64 | `2376` |  |
| Tus-Resumable | string | `1.0.0` | |

### Read artifact {#ReadArtifact}

#### Common use cases

Upload a new Artifact, or Update an existing Artifact using the `ArtefactStatusRT` resource.

#### Read artifact HTTP request

GET https://site.uri/1/artifacts/{id}

#### HTTP response codes

| Error code | response type | response resource |
| --- | --- | --- |
| 200 | OK | `ArtefactStatusRT` JSON resource |
| 400 | Bad Request response | |
| 401 | Unauthorised response | |
| 403 | Forbidden response | |
| 404 | Artifact Not found response | |
| 501 | Not Implemented response | |

#### Parameters

| Parameter | Type | Use | Details |
| ----- | ----- | ----- | ----- |
| id | string | | The id for the artifact to return in the `ArtifactStatusRT` resource |

### ArtifactStatusRT

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
  "data": {
    "describedBy": {
      "href": "uri",
      "type": "string"
    },
    "self": "string"
  },
  "id"*: "string",
  "links"*: {
    "describedBy": {
      "href": "uri",
      "type": "string"
    },
    "self": "string"
  },
  "metadata": [{
  "name": "string",
  "value": "string"
  }],
  "mime-type": "string",
  "name": "string",
  "size": "int64",
  "status"*: "enum"
} 
```

| Property | |
| ---- | --- |
| account | 
| account.id | `string` which is the ID for the artifact in the system. |
| account.links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| account.links.describedBy |  |
| account.links.describedBy.href | `uri` the uri for the artifact |
| account.links.describedBy.type | `string` description for the resource type |
| account.links.self | `string`  |
| data | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| data.describedBy |  |
| data.describedBy.href | `uri` the uri for the artifact |
| data.describedBy.type | `string` description for the resource type |
| data.self | `string`  |
| id | `string` which is the ID for the artifact in the system. |
| links | contains the `describedBy` structure containing the resource `uri` and `type` and the `self` string element. |
| links.describedBy |  |
| links.describedBy.href | `uri` the uri for the artifact |
| links.describedBy.type | `string` description for the resource type |
| links.self | `string`  |
| metadata | the optional meta-data name - value pairs for the artifact |
| metadata.name | `string`  |
| metadata.value | `string`  |
| mime-type | `string`  |
| name | `string`  |
| size | `int64`  |
| status | `enum` can be one of `pending`, `building`, `ready`, or `error` |



