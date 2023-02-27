# Deploy Services

## Docker Provisioning

Name your service with a meaningful name.  Use camel case, replacing any dashes with underscores.
Use the Dockerfile Allocate to build the docker image structure, add, and define resource settings that may include:

* files and folders
* listen ports
* idle timeout
* header size limits
* https
* connection policies
* paths for services
* method type
* default response types

Build the docker image using the `docker build` command within __Make__.
Use the Makefile for IVCAP services as an examples showing how docker images are built

## Docker Registering

Register your services docker image within __Make__ using the `docker tag` and `docker push` commands.
Running your registered docker service in the cloud environment within __Make__ with the `docker -it --rm run` command.  Running locally in your dev env with mini-kube is simply a case of calling the container using its full path within __Make__.

## Tools

Install the software used to develop and deploy services that may not be installed on a base system and may include:

* [brew](https://brew.sh/) to install useful utilities and tools
* coreutils: `brew install coreutils`
* yq: `brew install yq`
* hyperkit is recommended for Minikube: `brew install hyperkit`
* docker client: `brew install docker`
* Kubernetes client: `brew install kubernetes-cli`
* helm: `brew install helm`
* argo: `brew install argo`