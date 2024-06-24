
# Architecture from a developers perspective

The IVCAP platform makes use of best of breed, open source tools to minimise engineering complexity while maximising capability and flexibility.
While IVCAP employs internal and external services, the developer does not need to interact with them.
The complexity of the underlying service and architecture is simplified via the use of the SDK, which also abstracts and simplifies the API calls.

## IVCAP components

IVCAP consists of loosely coupled, independent containerised technology components that support its flexibility, agility and adaptability.
The underlying platform may be Google Cloud, Azure, or on your local machine using [Minikube](https://minikube.sigs.k8s.io/docs/start/).

Core External services and components include:

* [Kubernetes](https://kubernetes.io/) to containerise and deploy services that provide analytics on IVCAP.  Use [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local install.
* [Argo Workflows](https://argoproj.github.io/argo-workflows/) for sequencing analytics activities (tasks, parts of workflows, etc.) in workflow templates that provide the service.  Argo is used to execute all orders.
* [Postgres](https://www.postgresql.org/) that acts as an underlying database.
* [Loki](https://github.com/grafana/loki) a monitoring and logging stack for storing logs and processing queries
  * [Promtail](https://github.com/jafernandez73/grafana-loki/blob/master/docs/promtail-setup.md) for gathering and sending logs to Loki
  * [Grafana](https://grafana.com/docs/loki/latest/api/) for querying and displaying logs

Internal Services included in [IVCAP-core](https://github.com/ivcap-works/ivcap-core) include:

* _api_gateway_: waits and listens for requests, authorises requests, directs requests to the requested analytics service, acts as the REST API endpoint.
* _order_dispatcher_: actions order requests and initiate service workflows.
* _data_proxy_: Provides access to, caching, and related logging of artifacts for services.
* _storage_server_: Muliple versions can be configured depending on the storage infrastructure to be used (e.g. cloud buckets, local file system, API supplied, ...)


## Containers

IVCAP uses Kubernetes as the environment to run the containerised services. The container runtime used is [containerd](https://containerd.io).
