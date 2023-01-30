# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ operates as a Software as a Service that enables researchers and analytics providers to use and implement services to collect, process, or analyse visual datasets using AI analytics.

The intended audience for this guide are the Systems Engineers and Admin staff who will deploy, support and maintain the __IVCAP__ systems configuration (configuration management).

IVCAP is a complex software systems using a microservices architecture that enables flexibility, portability, component re-use, and service providers to add custom bespoke services tailored for their specific user needs.
The configuration management is captured and managed in the [IVCAP-core](https://github.com/reinventingscience/ivcap-core) Repo along with the code.

## Architecture

IVCAP uses cloud infrastructure such as Azure, Amazon Web Services (AWS) to host its constituent services and software components.  
[Terraform](https://www.terraform.io/) is used to provision and manage the infrastructure.

Core External services and components include:
* [Kubernetes](https://kubernetes.io/) to containerise and deploy discrete services that provide analytics on IVCAP.  Use [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local install.
* [Magda](https://magda.io/) to hold, catalogue and manage the IVCAP data and meta-data.
* [Argo Workflows](https://argoproj.github.io/argo-workflows/) for sequencing analytics activities (tasks, parts of workflows, etc.) in workflow templates that provide the service.  Argo is used to execute all orders.
* [Minio](https://min.io/) for object and data storage.
* [Postgres]() that acts as an underlying database.
* [Mitterwald]() to share authorisation tokens and secrets between services.
* [Loki](https://github.com/grafana/loki) a monitoring and logging stack for storing logs and processing queries
  * [Promtail]() for gathering and sending logs to Loki
  * [Grafana](https://grafana.com/docs/loki/latest/api/) an endpoint for querying and displaying logs

The internal services are built with the IVCAP deployment and include:
* Api_gateway: acts as the REST API endpoint, authorises requests, and directs requests to the appropriate service.
* Order_dispatcher: actions order requests and initiate service workflows.  
* Data_proxy: Provides access to, caching, and related logging of artifacts for services.
* Exit_handler: Reports the exit state of orders to update the order records in Magda. 

## Installation

Detailed Installation steps for IVCAP deployment are found at [ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy), which includes the steps for deploying to minikube.

### Terraform

Create the infrastructure with Terraform.
Check the values and settings of the Makefiles, yaml, and shell scripts match your deployment.

Note: use the `sensitive` flag when generating output scripts and variable files to avoid the accidental sharing of secrets (passwords, etc.), for example:
```
output "db_username" {
  description = "Database administrator username"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "db_password" {
  description = "Database administrator password"
  value       = aws_db_instance.database.password
  sensitive   = true
}
```

### Kubernetes (K8s) cluster

Deploy and run the IVCAP components and services containers using kubernetes 

[ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy) discusses the installation for the K8s cluster.  
Additional tools and utilities may also need to be installed if they're not already installed, which may include:
* brews coreutils and yq, 
* Kubectl, or kubernetes-cli, the K8s command line interface 
* helm
* argo

#### Applications and Services

Prepare the K8s environment for IVCAP, and deploy or check the deployment of:
1. Mitterwald
1. Argo Workflows
1. Postgres
Using the make command with the makefile in the `/deploy` directory.

Deploy the IVCAP services using the make command `make helm-upgrade-gke`
Deploying to minikube has its own make command, as do 

### Key configuration files

Inspect deployment configuration files in the `ivcap-core/deploy` directory. 
Review any `.yaml` and template files in the `./helm` and `./helm/templates` sub directories.

### Platform specific considerations

TODO discussion on MS Platform (Azure) & Non-MS (AWS, etc.)

#### Specific Azure requirements

TODO if any

#### Specific AWS requirements

### Installing new releases and upgrades

TODO how to approach/plan for upgrades 

## Security

TODO - Should this be it's own sub-page?  - Or perhaps a checklist of the security specific points which should already be covered?

### General

User activities should be logged, and those logs moved to long term-storage for interrogation when needed.

### APIs 

### Encryption

### Run-time configuration

### Publishing containers

Scan containers for security and vulnerability threats prior to publishing them to the Container registry

### External services considerations

### Internal services considerations

### Bespoke services and workflow considerations

