# Running Locally

## Local Environment Requirements

Develop analytics services on your computer using python and a local instance of __IVCAP__ on minikube. 

Install minikube, the support software for IVCAP, and the git repositories (repos) to configure and build the IVCAP services.  
Then download and build the [Python SDK](https://github.com/reinventingscience/ivcap-sdk-python), [Command Line Interface (CLI)](https://github.com/reinventingscience/ivcap-cli), and [sample service](https://github.com/reinventingscience/ivcap-python-service-example) to get started on your analytics service. 

### Software and tools {#software}

[Assuming Researcher just getting started not be a seasoned dev.  early success is good success]: 

- what is the list of software which will need to be installed for a local dev/run environment?
- what is the install configuration for each (where changes are required)
- what does the developer/researcher need to have on their computer to run a make file and build a (sample / stub) local service.  i.e. cloning a/the Git repo?
- How do they run a make
- How do they run the service and interact with it?

- How do they load sample data (locally)
- Do they pause minikube rather than stopping it at the end of the day / session?

The software you will need includes:
 
- The [Basic Tools](#basic-tools)
  * Your code editing environment, such as [`Visual Studio Code`](https://code.visualstudio.com/)
  * [`Github Desktop`](https://desktop.github.com/) or your preferred github client to clone or download a [Github](https://github.com/) repository
  * On MacOS, check that [Homebrew](https://brew.sh/) (`brew`) is installed, as it is used to install and configure the __IVCAP__ software components.
  * The helper tools `coreutils` and `yq`
  * [`helm`](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#k8s-services-deployment-)
- The [Virtual cluster (minikube)](#install-minikube)
  * [Minikube](https://minikube.sigs.k8s.io/docs/start/), to act as your local kubernetes environment.
  * [Hyperkit](https://github.com/moby/hyperkit) enables hypervisor capabilities
  * docker client [`docker-cli`](https://docs.docker.com/engine/reference/commandline/cli/)
  * kubernetes command line tool ([`kubectl`](https://kubernetes.io/docs/tasks/tools/), or `kubernetes-cli`) depending on your operating system:
    * [Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
    * [MacOS](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos)
    * [Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
- IVCAP [Support Services](#support-services), which includes:
  * [Mitterwald](https://helm.mittwald.de)
  * [Argo Workflows](https://argoproj.github.io/argo-workflows/)
  * [Postgres](https://www.postgresql.org/)
  * [Loki](https://github.com/grafana/loki)
- [IVCAP](https://github.com/reinventingscience/ivcap-core)

These software components emulate the cloud based software environment, enabling you to develop and run services locally as they would in the deployed environment.
The following sections will help you to install and configure the software for the development environment.

#### Basic Tools

The basic environment includes the tools you would ordinarily use to develop software on your local computer.
Use your preferred authoring tool to edit the code, [`Visual Studio Code`](https://code.visualstudio.com/) is an example of a popular tool.

Github manages the repositories (repos) for IVCAP and its services.  
A GitHub client is necessary to clone (copy and synchronise) the repos to your computer.
[`Github Desktop`](https://desktop.github.com/) simplifies the Github commands for cloning and synchronising the repos.

Use [Homebrew](https://brew.sh/) (`brew`) from the command line (shell environment) to install or configure software and access services via their command line tools.  `Brew` is usually installed on MacOS by default.

[Install `coreutils`, `yq`](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#install-basic-tools-), and `helm` to prepare your computer for minikube and the IVCAP install.

#### Install minikube

The software environment for minikube includes:
* On MacOS, check that [Homebrew](https://brew.sh/) (`brew`) is installed.  Brew is used to install and configure the __IVCAP__ software components.
* The helper tools `coreutils` and `yq`
* [Hyperkit](https://github.com/moby/hyperkit) enables hypervisor capabilities
* docker client `docker-cli`
* install [`kubectl`](https://kubernetes.io/docs/tasks/tools/) 
* install [minikube](https://minikube.sigs.k8s.io/docs/start/)
* the kubernetes command line tool `kubernetes-cli`
* Configure minikube using the installation instructions using the following link

The detailed instructions for the installation and configuration for minikube is found in the [IVCAP core install latest instructions](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#cluster)

Question for Max - There are additional configuration steps in the DEVELOPERS.md file, do we need to refer to any of those steps here?
https://github.com/reinventingscience/ivcap-core/blob/develop/DEVELOPERS.md.

#### Support Services

After the minikube is installed and configured, the IVCAP support software can be installed.
This installation is done by using the make-targets in the IVCAP repo.

Ton install the support services:

* [Check and install the tools](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#k8s-services-deployment-) `kubernetes-cli`, `helm`, and `argo`
* Clone the [IVCAP core github repo](https://github.com/reinventingscience/ivcap-core) to your computer
* Open your favoured shell prompt (Ksh, Zsh, Power-Shell, etc.)
* Navigate to your local clone of IVCAP core
* [deploy Mitterwald](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#mitterwald-)
* [deploy Argo Workflow](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#argo-workflow-)
* [deploy and configure Postgres](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#postgres-)
* [deploy and configure Loki](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#loki-monitoring-)

#### Deploy IVCAP
Once the environment is functional, deploying the application and building it.

After minikube and the support services are installed, and the [IVCAP core repo](https://github.com/reinventingscience/ivcap-core) is on your machine (details in [Support Services](#support-services)), building and running a local instance of IVCAP is attained via the make target `helm-upgrade-minikube` 

More information is found on the [IVCAP Deployment](https://github.com/reinventingscience/ivcap-core/tree/develop/deploy#ivcap-deployment) page.

### Developing locally {#local-dev}

Download and build the [Python SDK](https://github.com/reinventingscience/ivcap-sdk-python), [Command Line Interface (CLI)](https://github.com/reinventingscience/ivcap-cli), and [sample service](https://github.com/reinventingscience/ivcap-python-service-example) to get started on your analytics service. 

Review and make changes to the code in the sample service to see how it runs.

### Access and Use



## Developer Resources

The ***API reference*** contains the description of the API endpoints. 

The command line interface 
