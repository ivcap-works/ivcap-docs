## Installation

Detailed Installation steps for IVCAP deployment are found at [ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy), including deployments to minikube, Azure, or GCP.

1. Provision infrastructure using Terraform
1. Create a new cluster
1. Access the cluster
1. Install Kubernetes
1. Install IVCAP into the K8s environment
1. Start using the services

### Provision Infrastructure

[Provision infrastructure and deploy a kubernetes cluster](https://developer.hashicorp.com/terraform/tutorials/kubernetes) in your cloud subscription.
Using [terraform](https://developer.hashicorp.com/terraform/language) to provision the platform and install core software components as per the [configuration files](#key-configuration-files).

Adjust the values and settings in the configuration files (Makefiles, yaml, and shell scripts) found in the `/deploy` sub-folders to suit your deployment.

### Use Terraform in an Azure subscription

The `/deploy/` directory contains information that describes how to [Deploy IVCAP on Azure Kubernetes Service](https://github.com/reinventingscience/ivcap-core/blob/develop/deploy/aks/README.md) (AKS), which describes what you need to be able to [deploy a new cluster using Terraform Enterprise](https://github.com/reinventingscience/ivcap-core/blob/develop/deploy/aks/DEPLOY.md) (an example of provisioning with a [Terraform Cloud](https://app.terraform.io/public/signup/account?product_intent=terraform) subscription).

After provisioning the terraform workspace and deploying the K8s cluster, access the cluster to [Deploy IVCAP](https://github.com/reinventingscience/ivcap-core/blob/develop/deploy/README.md) into the cluster by installing and building its software and services.

The installation and configuration of the software components use the kubernetes client, helm, and argo in addition to the terraform scripts.

A quick overview of the procedure highlights:
* Create a version controlled workspace
* Integrate with your DevOps version control repository (repo and terraform working directories)
* Configure the Terraform Variables and authentication secrets/passwords (may also be set in a terraform.tfvars file)
* Set the Environment Variables that validate the workspace as being a valid member of your cloud
* Create the cluster / initial deployment
* Use kubectl to Access the Cluster
* Install the necessary software components needed to build IVCAP
* Use the makefile targets to build and configure the IVCAP components

Note: Mitterwald, Argo Workflows, and Postgres must be installed prior to deploying IVCAP.  A docker registry must also be available to register the docker components for K8s.

### Key configuration files

Review the terraform resources, modules and variables definition files in the `/deploy/aks/deploy/terraform/` directory.

| application | file | description |
| ---- | ---- | ---- |
| terraform | `versions.tf` | Terraform and required providers defined |
| terraform | `main.tf` | The main terraform script with the initial data, provider, and module resource definitions for provisioning and creating the environment |
| terraform | `variables.tf` | Terraform variable and object definitions (for this deployment, a .tf.json file is not used) |
| helm | `tfe-backend.hcl` | The .hcl configuration file used to define the cloud resource |
| terraform | `cluster-resources/aks.tf` | The primary Azure Kubernetes service data and resource settings |
| terraform | `cluster-resources/datalake.tf` | Azure data storage and virtual network resource settings |
| terraform | `cluster-resources/outputs.tf` | Output definitions for the terraform provisioning.  <BR>**Note:** [Use the sensitive flag](#secrets-and-the-sensitive-flag) to avoid the inadvertent sharing of secrets, usernames, or passwords |
| terraform | `cluster-resources/rg.tf` | Cluster resource group definitions |
| terraform | `cluster-resources/variables.tf` | Cluster resource variable definitions |
| terraform | `cluster-setup/main.tf` | The main terraform script which calls Helm and a provisioner script are used to install and configure the software services |
| terraform | `cluster-setup/variables.tf` | Variable definitions used during the cluster setup |
| magda | `config/magda-config/templates/auth-secrets.yaml` | Contains the settings for application internal communication secrets using `mittwald` |
| magda | `config/magda-config/chart.yaml` | Magda components configuration and version settings |
| magda | `config/magda-config/values.yaml` | Key settings and values for the magda configuration |
| argo | `config/argo.yaml` | configuration used for Argo |
| istio | `config/istio.yaml` | configuration used for istio  |
| minio | `config/minio.yaml` | configuration used for minio |

#### Cluster-setup, Terraform and Helm

Set up the K8S cluster using Terraform and the `cluster-setup/main.tf` file.
The `main.tf` file uses `helm` and a provisioner script to install and configure the IVCAP services:

| Service | name | description |
| ---- | ---- | ---- |
| [sealed_secrets_controller](https://bitnami-labs.github.io/sealed-secrets) | sealed-secrets-controller | With the namespace `kube-system`|
| [cert-manager](https://charts.jetstack.io) | cert-manager | to TODO |
| [kubernetes_replicator](https://helm.mittwald.de) | kubernetes-replicator | Mittwald is used to manage the secure sharing of credentials and secrets between the constituent systems and services |
| [argo_controller](https://argoproj.github.io/argo-helm) | argo | Argo workflows are used to manage and execute the services.  The configuration is held in the file: `config/argo.yaml` |
| [minio_controller](https://helm.min.io) | argo-artifacts | Minio manages the storage of artifacts used for _Argo_.  The configuration is held in the file `config/minio.yaml`.  Note: extra arguments may be set to be stored at: `https://${var.storage_acc_name}.blob.core.windows.net` |
| kube config file | local.kube_config_path | The path to the config file for the kube configuration |
| Provisioner | `cluster-setup.sh` | A Generic _local-exec_ provisioner script is used to install and configure software components used for _IVCAP_ |
| magda | magda | using configuration files located in the `config/magda-config` directory to setup magda with the `config/magda-config/values.yaml` configuration file |

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
1. Deploy and configure the _docker_ secret
1. Deploy and configure the _minio_ secret 
1. Deploy and configure the _storage_ secret
1. Deploy and configure the _blob_ secret
1. Deploy and configure the _ACME_ secret
1. Deploy the manifests.

#### Terraform on Non-Azure platform

[Create the new Terraform Workspace](https://developer.hashicorp.com/terraform/cli/commands/workspace/new)

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

Check the deployment configuration for the prerequisite software for deploying IVCAP:
1. Mitterwald
1. Argo Workflows
1. Postgres

Use the makefile in the `/deploy` directory to deploy the services using the make targets `helm-upgrade-gke` or `helm-upgrade-aks` depending on your environment.
Deploying to minikube has its own make target `helm-upgrade-minikube`.

More details are found at [ivcap-core/deploy/](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy)

### Installing new releases and upgrades

Keeping system components current is set in the `makefile`, and the configuration file for the `terraform-plan` (in the `/ci/` directory).

Using the makefile to upgrade software components is achieved by running the make command within the confines of your CI/CD framework.

It is possible to specify the software component release version to mitigate the risk of an inadvertent component upgrade.

#### Service upgrades

When planning to upgrade the system component services (such as Argo), one approach might be:
* Stop accepting new requests through the `api_gateway` (which may be achieved by modifying the ingress configuration as per your SOPs)
* Wait for existing requests to finish from the `api_gateway` and the `order_dispatcher` (which are short lived)
* Upgrade the component or components
* Start accepting new requests through the `api_gateway` again.

#### Storage upgrades

Upgrades to the `database` or `storage_proxy` are recommended to wait until active workflows have finished before proceeding with the upgrade.


