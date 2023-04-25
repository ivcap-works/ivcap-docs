# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ enables researchers and analytics providers to use and develop analytics services that collect, process, or analyse visual datasets using advanced analytics.

The intended audiences for this guide are the Researchers and Developers who intend to develop analytics services for __IVCAP__.

A [Python SDK](sdk/) has been published to facilitate the development of services and there is [a sample service](sdk/#using-the-sdk-for-the-ivcap_service) to help you get started using the SDK.

The [command line interface](https://github.com/reinventingscience/ivcap-cli) (CLI) is also available and can be used as another example service.
The CLI also demonstrates how to develop an analytics service using go.

## Getting started

__IVCAP__ and its services are deployed to a Kubernetes (K8s) cluster hosted in a cloud environment.  Analytics service development will follow the CI/CD framework used by the custodian of __IVCAP__ and can be developed locally using minikube.

An analytics service is built using Argo workflows, where a workflow may contain one or more tasks.

When built, the service is compiled into a container that is loaded into the K8s/minikube environment.

Each container is held and executed independently of any other containers and must get input and data from its startup parameters or use the REST API for data access and storage.

To get underway for local development: 
* install and configure the software for a [local dev environment](running-locally/)
* clone the sample service and start building your service

## Security Considerations

Interacting with IVCAP via the REST API will need a bearer token in the header.
The bearer token is attained via the 'create session' method.

### Authentication

IVCAP implements the [oauth2](https://oauth.net/2/) authentication model.
Authentication for the user device is currently provided via the [ivcap-cli](https://github.com/reinventingscience/ivcap-cli) command line interface.

The [cli login command](https://github.com/reinventingscience/ivcap-cli) illustrates the oauth2 authentication flow, token management, and the refresh of the JWT token within the service using golang.
Service providers may choose to implement authentication and token management within their service.

### Authorisation

Authorisation protocols are set in the IVCAP-core and are used to determine what, when, and how an authenticated user may access things within the system.

For example, the controls may determine access to:

* list artifacts, i.e. May only generate a list of artifacts that are owned by the authenticated account.
* read artifacts, May only return an artifact owned by the authenticated account.
* Allow authenticated users to upload artifacts, add metadata, add collections, etc.
* Restrict listing and returning order details to only those orders submitted by the account.
* Ensure orders are only created when the nominated account matches the authenticated user account.
* list services, but only be able to create or update them if they're a service provider and the service owner (for updates).
