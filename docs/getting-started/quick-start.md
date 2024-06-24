# Quick Start

To see how IVCAP works, we will _order_ the simple `hello-world` service and view  the computed _artifacts_.

The steps required are:

* find the service
* ... then order it
* ... check on progress
* ... list created artifacts
* ... download image

But before we can proceed, please ensure that the following [prerequisites¶](#prerequisites) are in place and that you an successfully [authenticate](#authenticate) with your respective IVCAP deployment. When all that is done, proceed to the [Our First Order](#our-first-order) section below.



## Prerequisites¶ <a name="prerequisites¶"></a>

Before you start you need to have access to an IVCAP deployment and have the `ivcap-cli` tool installed ([see instructions](../installing-cli/)).

## Authenticate <a name="authenticate"></a>

Almost all interactions with IVCAP require an authorisation token. To obtain this token, use the `ivcap context login` command:

```
% ivcap context login

    █▀▀▀▀▀█    ▀█  ▄▀▄▀▀ ▄▄▀▄ █▀▀▀▀▀█
    █ ███ █ █  █▀ ▀█▀ █  ▀▀█  █ ███ █
    █ ▀▀▀ █ █ ▀▀▄▀▀▀▀█▀ ▀█ ▀▀ █ ▀▀▀ █
    ▀▀▀▀▀▀▀ █▄█ █ █ █ █ █▄█ ▀ ▀▀▀▀▀▀▀
    █ ██▀▀▀▄▄▄ ▄ ██ ██▄█▀▄█▄█ ██▀██ ▄
    █▀▄▄ ▀▀  █ █▀█▀▀▀█▄  █  █ ▄ █▄█▀
...
To login to the IVCAP Service, please go to:  https://id-provider.com/activate?user_code=....
or scan the QR Code to be taken to the login page
Waiting for authorisation...
```

## Our First Order <a name="our-first-order"></a>

As mentioned above, an IVCAP deployment provides a set of **services** which a user can **order**. An order in this context is a request to execute the steps defined by a service and optionally customised by service specific parameters provided by the user at the time of order. The order execution will usually create a set of **artifacts** (aka dataset, image, table) which the user can download or use as input to another order.

An analogy would be a _designer shoe_ store, which lists a set of shoe designs (aka _services_) were a user can _order_ a specific design, additionally defining shoe size or color. This will trigger the manufacturing of a new pair of shoes (aka _artifact_) based on the specific design as well as the user specifications of shoe size and color.

For our first order, we will request the creation of an image with the obligatory "Hello World" message. As mention above the following steps required are:

* [find the service](#find-the-service)
* ... [then order it](#order-the-service)
* ... [check on progress](#check-on-progress)
* ... [list created artifacts](#list-artifacts)
* ... [download image](#download-image)

### Find the Service <a name="find-the-service"></a>

So let's start with finding the service:

```
% ivcap service list --filter "name~='hello-world-python'"
+----+--------------------+--------------------------------+
| ID | NAME               | ACCOUNT                        |
+----+--------------------+--------------------------------+
| @1 | hello-world-python | urn:ivcap:account:45a06508-... |
+----+--------------------+--------------------------------+
```

We can get more information on it with:
```
% ivcap service get @1

          ID  urn:ivcap:service:8e048dfc-... (@1)
        Name  hello-world-python
 Description  A simple IVCAP service using the IVCAP Service SDK to create an ...
  Account ID  urn:ivcap:account:45a06508-...
  Parameters  ┌────────────────┬────────────────────────┬──────────┬─────────┬──────────┐
              │ NAME           │ DESCRIPTION            │ TYPE     │ DEFAULT │ OPTIONAL │
              ├────────────────┼────────────────────────┼──────────┼─────────┼──────────┤
              │            msg │ Message to display.    │ string   │         │ false    │
              ├────────────────┼────────────────────────|──────────┼─────────┼──────────┤
              │ background-img │ Image artifact to use  │ artifact │         │ true     │
              │                │ as background.         │          │         │          │
              ├────────────────┼──────────────────────-─┼──────────┼─────────┼──────────┤
              │          width │ Image width.           │ int      │ 640     │ false    │
              ├────────────────┼────────────────────────┼──────────┼─────────┼──────────┤
              │         height │ Image height.          │ int      │ 480     │ false    │
              └────────────────┴────────────────────────┴──────────┴─────────┴──────────┘
```

### Order the Service <a name="order-the-service"></a>

As we can see from the **parameters** listing we can not only set the message, but also
choose an optional background image, as well as the width and height. So let's be not
too creative with the message, but a bit more playful with the background.

```
% ivcap order create -n "test image order #1" urn:ivcap:service:8e048dfc-4605-503e-85a4-03c77f98bf2e \
     msg="Hello World" \
     background-img=https://wallpaperaccess.com/full/4482737.png
Order 'urn:ivcap:order:394a877c-1231-4f4f-93f0-93bf738a49e5' with status 'pending' submitted.
```
We have now successfully ordered the service with order ID `urn:ivcap:order:394a877c-1231-4f4f-93f0-93bf738a49e5`

### Check on Progress <a name="check-on-progress"></a>

The `ivcap order get urn:ivcap:order:...` command allows us to monitor the
status of an order.

```
% ivcap order get urn:ivcap:order:394a877c-1231-4f4f-93f0-93bf738a49e5

         ID  urn:ivcap:order:394a877c-1231-4f4f-93f0-93bf738a49e5 (@5)
       Name  test image order #1
     Status  executing
    Ordered  2 minutes ago
    Service  hello-world-python (@6)
 Account ID  urn:ivcap:account:45a06508-...
 Parameters  ┌─────────────────────────────────────────────────────────────────┐
             │             msg =  Hello World                                  │
             │  background-img =  https://wallpaperaccess.com/full/4482737.png │
             │           width =  640                                          │
             │          height =  480                                          │
             └─────────────────────────────────────────────────────────────────┘
   Products
   Metadata  ┌────┬────────────────────────────────────────┐
             │ @3 │ urn:ivcap:schema:order-uses-workflow.1 │
             │ @4 │ urn:ivcap:schema:order-placed.1        │
             └────┴────────────────────────────────────────┘
```

As we can see from the above `Status  executing`, the order is now being executed. At some later stage
we can try again:

```
% ivcap orders get @1

         ID  urn:ivcap:order:394a877c-1231-4f4f-93f0-93bf738a49e5 (@8)
       Name  test image order #1
     Status  succeeded
    Ordered  17 hours ago (23 Jun 24 16:18 AEST)
    Service  hello-world-python (@9)
 Account ID  urn:ivcap:account:45a06508-5c3a-4678-8e6d-e6399bf27538
 Parameters  ┌─────────────────────────────────────────────────────────────────┐
             │             msg =  Hello World                                  │
             │  background-img =  https://wallpaperaccess.com/full/4482737.png │
             │           width =  640                                          │
             │          height =  480                                          │
             └─────────────────────────────────────────────────────────────────┘
   Products  ┌────┬───────────┬────────────┐
             │ @3 │ image.png │ image/jpeg │
             └────┴───────────┴────────────┘
   Metadata  ┌────┬────────────────────────────────────────────┐
             │ @4 │ urn:ivcap:schema:order-uses-workflow.1     │
             │ @5 │ urn:ivcap:schema:order-produced-artifact.1 │
             │ @6 │ urn:ivcap:schema:order-placed.1            │
             │ @7 │ urn:ivcap:schema:order-finished.1          │
             └────┴────────────────────────────────────────────┘
```

### List Created Artifacts <a name="list-artifacts"></a>

In "order" lingo the artifacts created by an order are called "products". In the above listing there is only one "product" (@3)

```
% ivcap artifact get @3

         ID  urn:ivcap:artifact:aee2decd-... (@4)
       Name  image.png
     Status  ready
       Size  44 kB
  Mime-type  image/jpeg
 Account ID  urn:ivcap:account:45a06508-...
   Metadata  ┌────┬──────────────────────────────────────────────┐
             │ @1 │ urn:ivcap:schema:artifact.1                  │
             │ @2 │ urn:ivcap:schema:artifact-producedBy-order.1 │
             │ @3 │ urn:example:schema:simple-python-service     │
             └────┴──────────────────────────────────────────────┘
```

### Download Image <a name="download-image"></a>

Finally, we can download and view that image:
```
% ivcap artifact download @4 -f /tmp/image.png
... downloading file 100% [==============================] (1.0 MB/s)
```
which may look like:

![result](../assets/images/artifact-aee2decd.png)