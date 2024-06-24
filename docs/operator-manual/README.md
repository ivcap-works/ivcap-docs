# Operator Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ operates as a Software as a Service that enables researchers and analytics providers to use and implement services to collect, process, or analyse visual datasets.

IVCAP is a complex software system using a microservices architecture that enables flexibility, portability, component reuse, and service providers to add custom bespoke services tailored to their specific user needs.
The configuration management is captured and managed in the [IVCAP-core](https://github.com/ivcap-works/ivcap-core) Repo along with the code.

### Intended audience

The intended audience for this guide is the Systems Engineers and Admin staff who provision cloud services and will deploy, support and maintain the __IVCAP__ systems.

### Onboarding

Onboarding service providers involves setting up their account permissions to allow them to load and register new services.
There is no automation, and each service provider will need to be allocated a service provider ID.

New service providers must have contracts in place that specify what they can provide, and the term of their access.  Details of who will be provided access and how their CI/CD processes will work and integrate must be specified.

The CI/CD processes for a service provider will specify how new services are migrated from development to non-production and the standards to be met for production deployment.
