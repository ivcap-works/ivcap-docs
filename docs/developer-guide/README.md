# Developer Guide

## Overview

__IVCAP__ enables researchers and analytics providers to use and develop analytics services that support a researcher's daily work.

The intended audiences for this guide are the Researchers and Developers who intend to develop analytics services for __IVCAP__.

A [Python SDK](https://ivcap-works.github.io/ivcap-service-sdk-python/) has been published to facilitate the development of services and there is [a sample service](https://github.com/ivcap-works/ivcap-python-service-example) to help you get started using the SDK.

## Getting started

__IVCAP__ and its services are deployed to a Kubernetes (K8s) cluster, often hosted in a cloud environment.  Analytics service development will follow the CI/CD framework used by the custodian of __IVCAP__ and can be developed locally using minikube.

There are currently two types of services, a _simple_ one consisting of a single compute task;
and a _workflow_ type containing one or more tasks. Workflow type services are currently managed and executed by an [Argo workflow engine](https://argoproj.github.io/workflows/).

In either case, the compute tasks are docker containers which will be executed according to a provided service plan as well user provider arguments and data.

## Security Considerations

Interacting with IVCAP via the REST API will need a bearer token in the header.
The bearer token is attained via the 'create session' method.

### Authentication

IVCAP implements the [oauth2](https://oauth.net/2/) authentication model.
Authentication for the user device is currently provided via the [ivcap-cli](https://github.com/ivcap-works/ivcap-cli) command line interface.

The [`ivcap context login`](https://github.com/ivcap-works/ivcap-cli?tab=readme-ov-file#configure-context-for-a-specific-deployment) illustrates the oauth2 authentication flow, token management, and the refresh of the JWT token within the service using Golang.
Service providers may choose to implement authentication and token management within their service.

### Authorisation

Authorisation protocols are set in the IVCAP core and are used to determine what, when, and how an authenticated user may access things within the system.

For example, the controls may determine access to:

* List artifacts, i.e. May only generate a list of artifacts that are owned by the authenticated account.
* Read artifacts, May only return an artifact owned by the authenticated account.
* Allow authenticated users to upload artifacts, add metadata, add collections, etc.
* Restrict listing and returning order details to only those orders submitted by the account.
* Ensure orders are only created when the nominated account matches the authenticated user account.
* List services, but only be able to create or update them if they're a service provider and the service owner (for updates).
