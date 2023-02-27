# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ operates as a Software as a Service that enables researchers and analytics providers to use and implement services to collect, process, or analyse visual datasets using AI analytics.

The intended audience for this guide are the Researchers and Developers who intend to develop and publish services using __IVCAP__.

Use the API to build, and load services onto the IVCAP platform, which are then discovered and used by platform users for data analysis.
You can build services using the API, a Python software development kit (SDK), and the command line interface (CLI).

This reference guide provides the information you need to use the API to build and deploy your service.

## Getting started

Services built for IVCAP are built using  that may contain one or more workflows.  Each workflow may contain one or more task.  The artifacts generated (output of the service) may be a report, file, data set as is required by the needs at the time.

### Install the IVCAP development environment

Install and configure the Kubernetes/minikube environment [IVCAP core install latest instructions](TODO/deploy#cluster), which detail the installation for Google Cloud, Azure, and a local installation with Minikube (on MacOS).

This step will set:

* Provisioning of the resources for docker/minikube.
* Enable support services/apps.
* Make the docker/minikube DNS visible to the host OS (MacOS).

Once the environment is functional, deploying the application and building it.

## Security

Interacting with IVCAP via the REST Api will need an bearer token in the header.

The bearer token is attained via the 'create session' method.

### Authentication

IVCAP implements the [oauth2](https://oauth.net/2/) authentication model.
Authentication for the user device is currently provided via the [ivcap-cli](https://github.com/reinventingscience/ivcap-cli) command line interface.

The [cli login command](https://github.com/reinventingscience/ivcap-cli) illustrates the oauth2 authentication flow, token management, and the refresh of the JWT token within the service using golang.
Service providers may choose to implement the authentication and token management within their service.

### Authorisation

Authorisation protocols are set in the IVCAP-core and are used to determine what, when, and how an authenticated user may access things within the system.

For example, the controls may determine access to:

* list artifacts, i.e. May only generate a list artifacts that are owned by the authenticated account.
* read artifacts, May only return an artifact owned by the authenticated account.
* Allow authenticated users to upload artifacts, add metadata, add collections, etc.
* Restrict listing and returning order details to only those orders submitted by the account.
* Ensure orders are only created when the nominated account matches the authenticated users account.
* list services, but only be able to create or update them if they're a service provider and the service owner (for updates).
