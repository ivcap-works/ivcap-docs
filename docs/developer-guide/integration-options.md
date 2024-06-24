# Integration options

## Command Line Interface

The Command Line Interface provides a simple to use interface for simple data operation with __IVCAP__.
[Ready to use binaries](https://github.com/ivcap-works/ivcap-cli/releases/latest) are available for download, with [source code and earlier releases](https://github.com/ivcap-works/ivcap-cli/releases) are also available on github.

The command line interface may also be built and installed using the go command:

```go
    go install https://github.com/ivcap-works/ivcap-cli@latest
```

View the [ivcap-cli git repo](https://github.com/ivcap-works/ivcap-cli/) for more information on using the command line interface.

## Software Development Kit - SDK

The Software Development Kit (SDK) is a python service that makes the __IVCAP__ data objects and methods available to you to use in your service / application.

See how to use the [SDK](sdk.md) with the [Example IVCAP Service](https://github.com/ivcap-works/ivcap-python-service-example) which demonstrates the key components needed for a service.

## REST API

Integrate your application with __IVCAP__ using the REST API and [JSON]{<https://jsonapi.org/>} data objects.  The methods and JSON schemas are documented in this documentation.

### Calling the Rest API

The API can be used to upload data or modify data, list services, book a service on the data, and retrieve the results.

API requests to interact with __IVCAP__ data and meta-data must have the JWT authorisation bearer token set, see [Sessions]{#Sessions} for more detail.
