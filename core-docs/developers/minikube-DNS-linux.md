# Linux Minikube DNS

To allow the host to resolve Minikube deployed services, the Minikube IP needs
to be added to the host as a DNS server. In Linux this can be done by adding the
Minikube IP to `/etc/hosts` file.

Record the Minikube IP address:

```bash
$ minikube ip
192.168.64.11
```

Add the Minikube IP address to `/etc/hosts`:

```
.
.
.
192.168.64.11    ivcap.minikube
.
.
.

```

For more information, refer to the [Minikube Ingress DNS documentation](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/)