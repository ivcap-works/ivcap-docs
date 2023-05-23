## Architecture

IVCAP uses a microservices architecture, where services are deployed as docker images to run within a Kubernetes (K8S) cluster.

The microservices include external support software, the internal services that comprise IVCAP, and the published analytics services.
Service execution is controlled via Argo workflows where each service has its own sandboxed execution space and communication between services occurs via the API.

Service providers can access a python software development kit (SDK) that helps simplify building analytics services for IVCAP.  Sample applications are available to demonstrate the SDK use.

IVCAP uses cloud infrastructure such as Azure, Amazon Web Services (AWS) to host its constituent services and software components.  
[Terraform](https://www.terraform.io/) is used to provision and manage the infrastructure.

### External applications & services

Core External services and components include:
* [Kubernetes](https://kubernetes.io/) to containerise and deploy discrete services that provide analytics on IVCAP.  Use [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local install.
* [Magda](https://magda.io/) to hold, catalogue and manage the IVCAP data and meta-data.
* [Argo Workflows](https://argoproj.github.io/argo-workflows/) for sequencing analytics activities (tasks, parts of workflows, etc.) in workflow templates that provide the service.  Argo is used to execute all orders.
* [Minio](https://min.io/) for object and data storage.
* [Postgres](https://www.postgresql.org/) that acts as an underlying database.
* [Mitterwald](https://helm.mittwald.de) to share authorisation tokens and secrets between services.
* [Loki](https://github.com/grafana/loki) a monitoring and logging stack for storing logs and processing queries
  * [Promtail](https://github.com/jafernandez73/grafana-loki/blob/master/docs/promtail-setup.md) for gathering and sending logs to Loki
  * [Grafana](https://grafana.com/docs/loki/latest/api/) an endpoint for querying and displaying logs

### Internal services

The internal services are built with the IVCAP deployment and include:
* Api_gateway: acts as the REST API endpoint, authorises requests, and directs requests to the appropriate service.
* Order_dispatcher: actions order requests and initiate service workflows.  
* Data_proxy: Provides access to, caching, and related logging of artifacts for services.
* Exit_handler: Reports the exit state of orders to update the order records in Magda. 

### Namespaces

Namespaces are used to isolate internal and underlying services from the analytics services that are accessible for systems users.
Namespaces are discussed in the how to [Deploy IVCaP on Azure Kubernetes Service](https://github.com/reinventingscience/ivcap-core/blob/develop/deploy/aks/README.md).
