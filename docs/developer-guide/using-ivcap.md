## Usage <a name="usage">

The easiest way to interact with an IVCAP deployment is to install the `ivcap` cli tool from
the Github [release](https://github.com/reinventingscience/ivcap-cli/releases/latest) page.

After downloading and installing it on you machine you'll need to create a context for every
IVCAP deployment. For instance, if you have installed a local deployment with minikube and
DNS integration, you would run:

    ivcap config create-context minikube --url http://ivcap.minikube

followed by a login:

    ivcap login foo@testing.com

After that, you should be able to list the deployed services:

```
% ivcap services list
+--------------------------+---------------------+---------------------------------+
| ID                       | NAME                | PROVIDER                        |
+--------------------------+---------------------+---------------------------------+
| cayp:service:d939b74d... | Gradient Text Image | cayp:provider:1a18fe6b-ffd4-... |
+--------------------------+---------------------+---------------------------------+
```

To list the details of a service:

```
% ivcap service get cayp:service:d939b74d-0070-59a4-a832-36c5c07e657d

          ID  cayp:service:d939b74d-0070-59a4-a832-36c5c07e657d              
        Name  Gradient Text Image                                            
 Description  Creates an image with a customizable text.                     
      Status  ???                                                            
 Provider ID  cayp:provider:1a18fe6b-ffd4-594b-89fb-4c3e8b3ac188:testing.com 
  Account ID  cayp:account:58d8e161-9a2b-513a-bd32-28d7e8af1658:testing.com  
  Parameters  ┌─────────┬─────────────┬──────────┬─────────┐                 
              │ NAME    │ DESCRIPTION │ TYPE     │ DEFAULT │                 
              ├─────────┼─────────────┼──────────┼─────────┤                 
              │     msg │             │ string   │ ???     │                 
              ├─────────┼─────────────┼──────────┼─────────┤                 
              │ img-art │             │ artifact │ ???     │                 
              ├─────────┼─────────────┼──────────┼─────────┤                 
              │ img-url │             │ string   │ ???     │                 
              └─────────┴─────────────┴──────────┴─────────┘ 
```

A more basic way to interact with a deployment is to open it's home screen `https://api.....`

<img src="../assets/home-screen.jpg" width="600" />

We also providing SDKs for python ([ivcap-sdk-python](https://github.com/reinventingscience/ivcap-sdk-python)), ... to build services to deploy on a platform as well as consume them from an external application, such as a Jupyter notebook.

