# MacOS Minikube DNS

The following was adapted from [Domain-specific DNS server on your Macbook
Pro](https://medium.com/@jamieeduncan/i-recently-moved-to-a-macbook-for-my-primary-work-laptop-7c704dbaff59).

To allow the host to resolve Minikube deployed services, the Minikube IP needs
to be added to the host as a DNS server. In MacOS this can be done by adding the
Minikube IP to the `/etc/resolver directory.

Record the Minikube IP address:

```bash
% minikube ip
192.168.64.11
```

Ensure that `/etc/resolver` exists. If not, create it:

```
sudo mkdir /etc/resolver
```

Then create the resolver configuration in `/etc/resolver/minikube.test` with the
following content:

```
domain test
nameserver 192.168.64.11
search_order 1
timeout 5
```

Note that the `nameserver` IP should be the IP address returned the `minikube
ip` command.

For more information, refer to the [Minikube Ingress DNS documentation](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/)