# Developing __IVCAP__ services

At the heart of __IVCAP__ is a kubernetes (K8s) cluster that holds the internal and related external services for the analytics services (argo workflows/containers), storage for the visual image collections (artifacts), their metadata, data for the requested analytics services (order parameters, metadata, etc.), and the products generated from the services (reports, new artifacts).

Implement a service as an __Argo__ workflow template and register it within __IVCAP__ with a detailed description for why the service exists, what it service does, and how to use it.

Ordering a service creates and executes an argo workflow using the parameters, metadata, artifacts, and the workflow template specified for the service.

Services are executed in a sandbox environment, with their own context.  
Services do not interact with other services, workflows, or external data sources other than via the REST API methods.
Access to input artifacts, data, or generated output is provided via the REST API methods.
The complexity of using the API is abstracted with the Python SDK, and the CLI.

__Is / will there be a QA check / code review & approval or similar for services built by the service providers?  If so, How does a service provider submit their service for review and subsequent approval?__

## Service provider

Onboard as a service provider to build and register analytics services for the IVCAP platform.
*How does a service provider onboard?*
User your provider ID that is assigned to you when you onboard to register your services with IVCAP.

Services providers can use the SDK and CLI to simplify and accelerate building and registering services.

__What resources are made available to the service providers?  Will they get the source code for the SDK?, CLI?, Sample service?__

Service providers are responsible for their own build and test environments

## Discovering a service

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

## Executing a service

Start a service with the Create_order method, Service ID, service parameters, metadata and anything else specified in the service description.
The service initiates the docker container registered for the service.  Complex services which have more than a single analytics task will typically run an [argo workflow](https://argoproj.github.io/workflows/).

Each service workflow order run in its own sandboxed container, isolating the service from all other applications.
Messaging and external data access is provided by, and must use, the API.

## Context for service execution

Services are executed within the context of their container in Argo and do not directly interact with any other service.

All data, communication, and instructions are provided by either the arguments and parameters used at startup, or via the SDK and API methods.

All output and results from the service must be persisted by the SDK or API calls.

Once the service has completed its execution, any localised or cached data will be released as the execution container is released.
