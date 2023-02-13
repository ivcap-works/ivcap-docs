# Developer Guide

## Overview

The Intelligent Visual Collaboration Analytics Platform __IVCAP__ operates as a Software as a Service that enables researchers and analytics providers to use and implement services to collect, process, or analyse visual datasets.

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

Detailed Installation steps for IVCAP deployment on Azure is found at [ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy), which includes the steps for deploying to minikube.

1. Provision infrastructure using Terraform
1. Create a new cluster
1. Access the cluster
1. Install the Kubernetes?  CHECK!
1. Install IVCAP into the K8s environment
1. Start using the services

### Provision Infrastructure

[Provision infrastructure and deploy a kubernetes cluster](https://developer.hashicorp.com/terraform/tutorials/kubernetes) in your cloud subscription.
Use the [terraform language](https://developer.hashicorp.com/terraform/language) configuration files to provision the platform and install core software components.

Check the values and settings in the configuration files (Makefiles, yaml, and shell scripts) found in the `/deploy` sub-folders so they work for your environment.

#### Use Terraform in CSIRO Azure environment

Follow the [deploy a new cluster using Terraform Enterprise](https://github.com/reinventingscience/ivcap-core/blob/develop/deploy/aks/DEPLOY.md) procedure to deploy (create the terraform workspace, create the cluster, and accesses the cluster) with [https://terraform.csiro.cloud/](https://terraform.csiro.cloud/).

A quick overview of the procedure highlights:
* Create a version controlled workspace
* Integrate with your DevOps version control repository (repo and terraform working directories)
* Configure the Terraform Variables and authentication secrets/passwords (may also be set in a terraform.tfvars file)
* Set the Environment Variables that validate the workspace as being a valid member of your cloud
* Create the cluster / initial deployment
* Use kubectl to Access the Cluster 

Deploy a cluster, and the initial kubernetes environment using the makefile targets

#### Key configuration files

Review terraform resources, modules and variables definition files that are in the `/deploy/aks/deploy/terraform/` directory.

| application | file | description |
| ---- | ---- | ---- |
| terraform | `versions.tf` | Terraform and required providers defined |
| terraform | `main.tf` | The main terraform script with the initial data, provider, and module resource definitions for provisioning and creating the environment |
| terraform | `variables.tf` | Terraform variable and object definitions (a .tf.json file is not used) |
| ??? | `tfe-backend.hcl` | the hcl file used to define the cloud resource |
| terraform | `cluster-resources/aks.tf` | Containing the primary Azure Kubernetes service data and resource settings |
| terraform | `cluster-resources/datalake.tf` | Azure data storage and virtual network resource settings for the provisioning |
| terraform | `cluster-resources/outputs.tf` | Output definitions for the terraform provisioning.  Note: [Use the sensitive flag](#secrets-and-the-sensitive-flag) to avoid the inadvertent sharing of secrets, usernames, or passwords |
| terraform | `cluster-resources/rg.tf` | Resource group definitions for the provisioning |
| terraform | `cluster-resources/variables.tf` | Cluster resource variable definitions |
| terraform | `cluster-setup/main.tf` | The cluster setup using helm to install and configure the software services used in the IVCAP environment |
| terraform | `cluster-setup/variables.tf` | the variable definitions used during the cluster setup |
| magda | `config/magda-config/templates/auth-secrets.yaml` | ***I suspect this is one of the files no longer needed subsequent to the security review*** Contains the settings for creating the application internal communication secrets using `mittwald` |
| magda | `config/magda-config/chart.yaml` | Magda components configuration and version settings |
| magda | `config/magda-config/values.yaml` | Key settings and values for running _magda_ within your environment |
| argo | `config/argo.yaml` | configuration used for Argo |
| istio | `config/istio.yaml` | configuration used for istio  |
| minio | `config/minio.yaml` | configuration used for minio |


#### Use Terraform to setup the cluster

TODO - How the cluster-setup is triggered
TODO - main.tf sets up the cluster

Terraform sets up the cluster using the settings in the `cluster-setup/main.tf` file.  Which uses `helm` to install and do the initial configuration for:

| Service | name | description |
| ---- | ---- | ---- |
| [sealed_secrets_controller](https://bitnami-labs.github.io/sealed-secrets) | sealed-secrets-controller | With the namespace `kube-system`|
| [cert-manager](https://charts.jetstack.io) | cert-manager | to TODO |
| [kubernetes_replicator](https://helm.mittwald.de) | kubernetes-replicator | Mittwald is used to manage the secure sharing of credentials and secrets between the constituent systems and services |
| [argo_controller](https://argoproj.github.io/argo-helm) | argo | Argo workflows are used to manage and execute the services.  The configuration is held in the file: `config/argo.yaml` |
| [minio_controller](https://helm.min.io) | argo-artifacts | Minio manages the storage of artifacts used for _Argo_.  The configuration is held in the file `config/minio.yaml`.  Note: extra arguments may be set to be stored at: `https://${var.storage_acc_name}.blob.core.windows.net` |
| TODO! kube config file | local.kube_config_path | The path to the config file for the kube configuration |
| Note: Provisioner | `cluster-setup.sh` | A Generic _local-exec_ provisioner is used to be the primary work-horse and do the installation and configuration of the software components comprising _IVCAP_ |
| magda | magda | using configuration files located in the `config/magda-config` directory to setup magda with the values found in the `config/magda-config/values.yaml` file |

Deploy and run the IVCAP components and services containers using kubernetes 

[ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy) discusses the installation for the K8s cluster.  
Additional tools and utilities may also need to be installed if they're not already installed, which may include:
* brews coreutils and yq, 
* Kubectl, or kubernetes-cli, the K8s command line interface 
* helm
* argo

#### The cluster-setup script

Install and configure the additional services automatically with the `cluster-setup.sh` script.

The services installed or configured include:
1. Install [kubectl](https://storage.googleapis.com/kubernetes-release/release/stable.txt)
1. Create the namespace for the "order-runner"
1. Create the namespace for "minio"
1. Add label to kube-system namespace
1. Install [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) as the `kubeseal`
1. Install [istio](https://istio.io/)
1. Install the `config/istio.yaml` configuration to _istio_
1. Deploy and configure the _docker_ secret *Are these steps still reqiured?*
1. Deploy and configure the _minio_ secret 
1. Deploy and configure the _storage_ secret
1. Deploy and configure the _blob_ secret
1. Deploy and configure the _ACME_ secret
1. Deploy the manifests.

#### Terraform on Non-Azure platform

[Create the new Terraform Workspace](https://developer.hashicorp.com/terraform/cli/commands/workspace/new)

*TODO* - similar steps required?

#### Secrets and the sensitive flag <a name="secrets"></a>

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

#### Applications and Services

Check the deployment configuration for:
1. Mitterwald
1. Argo Workflows
1. Postgres
Using the make command with the makefile in the `/deploy` directory.

Deploy the IVCAP services using the make command `make helm-upgrade-gke`
Deploying to minikube has its own make target

### Platform specific considerations

TODO Are there platform specific considerations?

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

