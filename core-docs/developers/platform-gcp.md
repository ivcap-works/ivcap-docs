# Installing and configuring a Google Cloud Platform Kubernetes cluster

> :warning: This file is an incomplete stub that needs to be populated with the
  correct information. The sections in this file are included as a template to
  help maintain a consistent style across the `README.md` files. Modify the
  sections and text as necessary.


There are [**two/three/four**] steps to deploying IVCAP in a [Google Cloud
Platform](https://cloud.google.com/) Kubernetes cluster. In the first step,
[requirements](#requirements-gcp) are installed on the cloud platform. In the
[**second step**], [something happens](#gcp-another-step). In the [**third**]
step, the Kubernetes cluster is [created and configured](#gcp-create-cluster).


## Requirements <a name="gcp-requirements"></a>

The GCP environment is set up with Terraform. In order for Terraform to be able
to act on the GCP environment, it needs to be set up with Vault, with the GCP
Secrets Engine. The scripts in the gcp-vault-terraform directory describe how to
do this.

## Some other step <a name="gcp-another-step"></a>

Once you have added the necessary values to Terraform, you can run it to set up
the environment including the cluster. The Terraform code lives in the
deploy/gcp/terraform directory.
