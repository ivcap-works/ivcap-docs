# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ enables researchers and analytics providers to use or implement analytics serverices (collecting, processing, and analysing) for visual datasets.

The intended audience for this guide are the Researchers and Developers who intend to develop and publish services using __IVCAP__.

The API lets you build, and load services into the IVCAP platform which platform users may use for data analysis.

This reference guide provides the information you need to use the API to build and deploy your service.

## Integration options

### Command Line Interface

The Command Line Interface provides a simple to use interface for simple data operation with __IVCAP__.
[Ready to use binaries](https://github.com/reinventingscience/ivcap-cli/releases/latest) are available for download, with [source code and earlier releases](https://github.com/reinventingscience/ivcap-cli/releases) are also available on github.

The command line interface may also be built and installed using the go command:
```go
    go install https://github.com/reinventingscience/ivcap-cli@latest
```
View the [ivcap-cli git repo](https://github.com/reinventingscience/ivcap-cli/) for more information on using the command line interface.

### SDK

The Software Development Kit is a python service that makes the __IVCAP__ data objects and methods available to you to use in your service / application.

### REST API

Integrate your application with __IVCAP__ using the REST API and [JSON]{https://jsonapi.org/} data objects.  The methods and JSON schemas are documented in this docmentaion.

#### Calling the Rest API

The API can be used to upload data or modify data, list services, book a service on the data, and retrieve the results.

API requests to interact with __AVCAP__ data and meta-data must have the JWT authorisation bearer token set, see [Sessions]{#Sessions} for more detail.

## Getting started

Services built for IVCAP are built using  that may contain one or more workflows.  Each workflow may contain one or more task.  The artifacts generated (output of the service) may be a report, file, data set as is reqiured by the needs at the time.

## Sessions

Interacting with IVCAP via the REST Api will need an bearer token in the header.

The bearer token is attained via the 'create session' method.




