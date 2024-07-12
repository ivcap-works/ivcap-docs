# Developer Instructions

There are two stages of deployment. In the first stage a
[Kubernetes](https://kubernetes.io/) cluster and related external services (such
as storage and database services) are installed on a [computing
platform](#computing-platform). In the second stage [IVCAP
services](#ivcap-services) are configured within the Kubernetes cluster.


## Computing Platform <a name="computing-platform"></a>

In the first stage of deployment a Kubernetes cluster is established. The
Kubernetes cluster can be hosted on cloud computing services such as [Google
Cloud Platform](https://cloud.google.com/) or [Microsoft
Azure](https://azure.microsoft.com/en-au). For local development,
[Minikube](https://minikube.sigs.k8s.io/) is used.

For installation instructions on your computing platform, follow one of the
guides listed below:

- *Local development*: [Minikube](./platform-minikube.md)
- *Cloud deployment*: [Google Cloud Platform](./platform-gcp.md)
- *Cloud deployment*: [Microsoft Azure](./platform-azure.md)

## IVCAP services <a name="ivcap-services"></a>

In the second stage of deployment, IVCAP services are installed and configured
within the Kubernetes cluster.

**For macOS users:** To make your Kubernetes services accessible from your local machine, you'll need to execute `minikube tunnel` in a separate terminal window. Ensure that the terminal remains active with `minikube tunnel` while you're working within your Kubernetes cluster.

Clone the `ivcap-core` repository to the host:

```bash
git clone git@github.com:ivcap-works/ivcap-core.git
git checkout main
```

Navigate to the `deploy` directory of the IVCAP core library:

```bash
$ cd ivcap-core/deploy/
```

Deploy IVCAP services into the Kubernetes cluster:

```bash
$ make k8s-install-mitterwald
$ make helm-install-argo
$ make helm-install-postgres
$ make helm-install-nats
$ make helm-install-loki
```

Navigate back to the root directory of the IVCAP core library:

```bash
$ cd ivcap-core/
```

Build IVCAP services and publish to Docker registry:

```bash
$ make DOCKER_VERSION=latest docker-publish
```

Navigate to the `deploy` directory of the IVCAP core library:

```bash
$ cd ivcap-core/deploy/
```

Upgrade the kubernetes cluster. Issue the command according to your computing platform:

| Platform              | Command                      |
| --------------------- |:----------------------------:|
| Minikube              | `make helm-upgrade-minikube` |
| Microsoft Azure       | `make helm-upgrade-aks`      |
| Google Cloud Platform | `make helm-upgrade-gke`      |

## Github actions to access private repo
By the time we replaced 'cayp' with multi git module in ivcap, the Github actions under .github/workflows needs permission to access module in private repo.
The settings are also useful in multi repo env, that github actions need to access other repos to run build.

We followed the instruction at [this blog post](https://blog.fabianmendez.dev/how-to-use-private-go-module-in-github-actions) :
1. Create a personal access token named 'Github action token' in github under [Settings->Developer settings](https://github.com/settings/tokens), set expiry time to be some reasonable period (such as 1 year), then copy the token
2. Create a 'Repository secrets' named 'GH_ACCESS_TOKEN' at [action secerets](https://github.com/ivcap-works/ivcap-core/settings/secrets/actions), paste the token copied
3. Declare the token in ENV at workflow files, such as [golangci-lint](https://github.com/ivcap-works/ivcap-core/blob/develop/.github/workflows/golangci-lint.yml#L28-L29)
4. Use the token when access the repo/module, such as [golangci-lint](https://github.com/ivcap-works/ivcap-core/blob/develop/.github/workflows/golangci-lint.yml#L41)
5. Add reminder in calendar to renew token
