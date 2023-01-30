# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ operates as a Software as a Service that enables researchers and analytics providers to use and implement services to collect, process, or analyse visual datasets using AI analytics.

The intended audience for this guide are the Researchers and Developers who intend to develop and publish services using __IVCAP__.

Use the API to build, and load services onto the IVCAP platform, which are then discovered and used by platform users for data analysis.
You can build services using the API, a Python software development kit (SDK), and the command line interface (CLI).

This reference guide provides the information you need to use the API to build and deploy your service.

### Developing __IVCAP__ services

At the heart of __IVCAP__ is a kubernetes (K8s) cluster that holds the internal and related external services for the analytics services (argo workflows/containers), storage for the visual image collections (artifacts), their metadata, data for the requested analytics services (order parameters, metadata, etc.), and the products generated from the services (reports, new artifacts). 

Implement a service as an __Argo__ workflow template and register it within __IVCAP__ with a detailed description for why the service exists, what it service does, and how to use it.

Ordering a service creates and executes an argo workflow using the parameters, metadata, artifacts, and the workflow template specified for the service.

Services are executed in a sandbox environment, with their own context.  
Services do not interact with other services, workflows, or external data sources other than via the REST API methods.
Access to input artifacts, data, or generated output is provided via the REST API methods.
The complexity of using the API is abstracted with the Python SDK, and the CLI.

#### Discovering a service

Discover services using the service description information and the SDK, CLI, or the API.  (The SDK and the CLI abstract and simplify the complexity of the API calls)
Users use the service description to find and choose the service to use.  
Use the list services method with the users search criteria to list the available services that match.

The service description information will need to contain detailed information about:
* What the service is
* What the service does
* Why the service is provided
* How it should, and should __not__ be used
* Its Configuration parameters
* Optional and required metadata
* A brief description of the workflow and its analytics tasks

Supply the service description for the service when it is created.
Update the service description as necessary using the `update service` API method and the Service ID that is assigned to the service when the service is created.

#### Executing a service 

Start a service with the Create_order method, Service ID, service parameters, metadata and anything else specified in the service description.
The service initiates the docker container registered for the service.  Complex services which have more than a single analytics task will typically run an [argo workflow](https://argoproj.github.io/workflows/).

Each service workflow order run in its own sandboxed container, isolating the service from all other applications.
Messaging and external data access is provided by, and must use, the API.

#### Context for service execution

TODO

## Architecture from a developers perspective

The IVCAP platform makes use of best of breed, open source tools to minimise engineering complexity while maximising capability and flexibility.  

### IVCAP components

IVCAP consists of loosely coupled, independent containerised technology components that support its flexibility, agility and adaptability.  
The underlying platform may be Google Cloud, Azure, or on your local machine using [minikube]().

Core External services and components include:
* [Kubernetes](https://kubernetes.io/) to containerise and deploy services that provide analytics on IVCAP.  Use [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local install.
* [Magda](https://magda.io/) to hold, catalogue and manage the IVCAP data and meta-data.
* [Argo Workflows](https://argoproj.github.io/argo-workflows/) for sequencing analytics activities (tasks, parts of workflows, etc.) in workflow templates that provide the service.  Argo is used to execute all orders.
* [Minio](https://min.io/) for object and data storage.
* [Postgres]() that acts as an underlying database.
* [Mitterwald]() to share authorisation tokens and secrets between services.
* [Loki](https://github.com/grafana/loki) a monitoring and logging stack for storing logs and processing queries
  * [Promtail]() for gathering and sending logs to Loki
  * [Grafana]() for querying and displaying logs

Internal Services included in [IVCAP-core](https://github.com/reinventingscience/ivcap-core) include:
* Api_gateway: acts as the REST API endpoint, authorises requests, and directs requests to the appropriate service.
* Order_dispatcher: actions order requests and initiate service workflows.  
* Data_proxy: Provides access to, caching, and related logging of artifacts for services.
* Exit_handler: Reports the exit state of orders to update the order records in Magda.
...TODO

### Containers

IVCAP uses Kubernetes as the environment to run the containerised services which comprise the IVCAP platform.
containerise platform which contains the services which constitutes the IVCAP platform and the additional analytics services.

#### Docker Provisioning

TODO
Name your service using camel case, replacing any dashes with underscores.
Use the Dockerfile Allocate to build the docker image structure, add, and define resource settings, such as:

* files and folders
* listen ports
* idle timeout
* header size limits
* https 
* connection policies
* paths for services
* method type
* default response types 

Build the docker image using the `docker build` command within __Make__.
Use the Makefile for IVCAP services as an examples showing how docker images are built


#### Docker Registering

Register your services docker image within __Make__ using the `docker tag` and `docker push` commands.
Running your registered docker service in the cloud environment within __Make__ with the `docker -it --rm run` command.  Running locally in your dev env with mini-kube is simply a case of calling the container using its full path within __Make__.

### Tools

Software used to install, develop and deploy services that doesn't form part of the system on a Mac includes:
* [brew](https://brew.sh/) to install useful utilities and tools
* coreutils: `brew install coreutils`
* yq: `brew install yq`
* hyperkit is recommended for Minikube: `brew install hyperkit`
* docker client: `brew install docker`
* Kubernetes client: `brew install kubernetes-cli`
* helm: `brew install helm`
* argo: `brew install argo`


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

Integrate your application with __IVCAP__ using the REST API and [JSON]{https://jsonapi.org/} data objects.  The methods and JSON schemas are documented in this documentation.

#### Calling the Rest API

The API can be used to upload data or modify data, list services, book a service on the data, and retrieve the results.

API requests to interact with __IVCAP__ data and meta-data must have the JWT authorisation bearer token set, see [Sessions]{#Sessions} for more detail.

## Getting started

Services built for IVCAP are built using  that may contain one or more workflows.  Each workflow may contain one or more task.  The artifacts generated (output of the service) may be a report, file, data set as is required by the needs at the time.

### Install the IVCAP development environment

Install and configure the Kubernetes/minikube environment [IVCAP core install latest instructions](TODO/deploy#cluster), which detail the installation for Google Cloud, Azure, and a local installation with Minikube (on MacOS).

This step will set:
* Provisioning of the resources for docker/minikube.
* Enable support services/apps.
* Make the docker/minikube DNS visible to the host OS (MacOS).

Once the environment is functional, deploying the application and building it. 

## Sessions

Interacting with IVCAP via the REST Api will need an bearer token in the header.

The bearer token is attained via the 'create session' method.




