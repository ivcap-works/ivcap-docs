
# Architecture from a developers perspective

The IVCAP platform makes use of best of breed, open source tools to minimise engineering complexity while maximising capability and flexibility.
While IVCAP employs internal and external services, the developer does not need to interact with them.
The complexity of the underlying service and architecture is simplified via the use of the SDK, which also abstracts and simplifies the API calls.

## IVCAP components

IVCAP consists of loosely coupled, independent containerised technology components that support its flexibility, agility and adaptability.
The underlying platform may be Google Cloud, Azure, or on your local machine using [Minikube](https://minikube.sigs.k8s.io/docs/start/).

Core External services and components include:

* [Kubernetes](https://kubernetes.io/) to containerise and deploy services that provide analytics on IVCAP.  Use [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local install.
* [Magda](https://magda.io/) to hold, catalogue and manage the IVCAP data and meta-data.
* [Argo Workflows](https://argoproj.github.io/argo-workflows/) for sequencing analytics activities (tasks, parts of workflows, etc.) in workflow templates that provide the service.  Argo is used to execute all orders.
* [Minio](https://min.io/) for object and data storage.
* [Postgres](https://www.postgresql.org/) that acts as an underlying database.
* [Mitterwald](https://helm.mittwald.de) to share authorisation tokens and secrets between services.
* [Loki](https://github.com/grafana/loki) a monitoring and logging stack for storing logs and processing queries
  * [Promtail](https://github.com/jafernandez73/grafana-loki/blob/master/docs/promtail-setup.md) for gathering and sending logs to Loki
  * [Grafana](https://grafana.com/docs/loki/latest/api/) for querying and displaying logs

Internal Services included in [IVCAP-core](https://github.com/ivcap-works/ivcap-core) include:

* Api_gateway: waits and listens for requests, authorises requests, directs requests to the requested analytics service, acts as the REST API endpoint.
* Order_dispatcher: actions order requests and initiate service workflows.
* Data_proxy: Provides access to, caching, and related logging of artifacts for services.
* Exit_handler: Reports the exit state of orders to update the order records in Magda.
**...TODO**

###




## Containers

IVCAP uses Kubernetes as the environment to run the containerised services which comprise the IVCAP platform.
containerise platform which contains the services which constitutes the IVCAP platform and the additional analytics services.
