> DRAFT!

# ADR 6: Supporting different Service Models

In the context of __(use case)__
facing __(concern)__
we decided for __(option)__
to achieve __(quality)__
accepting __(downside)__.

## Status

* Status: proposed (_any of proposed, accepted, rejected, deprecated, superseded_)
* Author(s): Max Ott
* Deciders: ???
* Date: 2024-08-21

## Context

We currently support two facets of the a single service model, namely a batch workflow to be executed by an [Argo workflow engine](https://argoproj.github.io/workflows/). However, as described in [ADR 1](./001-standing-orders.md), we have already identified other types of services for quite some time. In addition, the _web UI hosting_ service (e.g. [iBenthos](https://ibenthos.develop.ivcap.io/)) is currently realised in a round-about way which can easily lead to uncaught mis-configurations.

In short, we need an easily extendible solution to more easily allow for the introduction of new service models.

## Decision Drivers

* Need to easily add new service models
* Minimise changes to existing architecture
* Maximise reuse of existing extension mechanisms

## Decision

The change is best implemented in `order_dispatcher`. It seems natural to apply
the `provider` pattern we have been using in other modules, such as `datafabric`, or `storage
where a single API can be implemented in various ways given a specific context.

The `order_dispatcher/pkg/order/order.go` implements the `goa` endpoint. While it currently immediately passes it on to 'workflow', we will first fetch the respective service record (`Service2T`) and then select the appropriate 'provider' based on the `$schema` field in `Service2T.Controller`.

**Please note**, that if no appropriate provider is found, we need to distinguish betwn two error
cases. The first one is an order for 'known' controller schemes, such as 'service-proxy' and
'app-server'. While they exist and are defined, they cannot be ordered. The second one is a request for an unknown service type. While both are errors, we should disinguish between those two cases in the error message we will return.

We will still use Argo to execute the 'basic' (one container) service type and therefore we need
to refactor the current `workflow` package to separate the primarily argo workflow relevant code from that which creates a proper Argo workflow description for the single node case. It may be as
simple as moving some of the templates to the 'basic' provider which itself calls the 'argo' provider with the workflow description created by the template.

In that process, we should further clean up the `workflow` directory as it was initially designed to support different workflow providers beside Argo, but that separation was never done cleanly and the current code organsiation is likely to be unnecessarily confusing. Specifically, we should separate and likely cleanup parameter verification and replacement (e.g. queues). That has become a lot more complex and likely deserves a separate file.

We also should separate handling of the 'data-proxy' sidecar. Currently we add a data-proxy side car to every pod, but we have discussed that a per-node data-proxy may be more efficient and secure. Security is currently an issue as we need to provide the data-proxy with credentials to
access the datafabric backend directly. Deploying a datafabric service, as we do with storage, would remove that concern. As it is unclear at this stage how and when we make those changes,
it would be prudent to cleanly isolate the provisioning of the data-proxy service for the
individual workflow nodes (pods)

## Detailed Discussion

We currently support only a single service execution model based on the Argo workflow engine. However,
as most of our current services only consist of a single processing node, we are providing a _simple_
variant, which only requires a reference to the the respective docker image and use a template in
`order_dispatcher` to translate that into a proper Argo workflow.

Currently, this is reflected in the service description which has a `workflow` property and within a `type`
property. For instance, a "simple" workflow may look like:

```
{
  "$schema": "urn:ivcap:schema:service.1",
  "id": "urn:ivcap:service:cd1f418c-...",
  ...
  "workflow": {
    "type": "basic",
    "basic": {
      "image": ".../cps.data61.csiro.au/cv_pipeline_v0_ps1_gpu:4937747",
      "command": [
        "python",
        "/app/service.py"
      ],
      "cpu": {},
      "memory": {},
      "ephemeral-storage": {}
    }
  },
  ...
```

The problem with this is that all the different service execution models need to be part of the
top level service schema. Therefore, any changes in any of the different models will effect all service
description as the schema has changed.

An alternative would be to require the content of the `workflow` property to declare the schema of
the model used. In fact, we would change that to a more generic name, such as
`executor` (can anyone think of a better term?).
This would then allow us internally to chose the implementation of the different execution models
purely on that _internal_ schema.

As an example, the above definition may look like:

```
{
  "$schema": "urn:ivcap:schema:service.2",
  "id": "urn:ivcap:service:cd1f418c-...",
  ...
  "controller": {
    "$schema": "urn:ivcap:schema:service.basic.1",
    "image": "45a06508-5c3a-4678-8e6d-.../cv_pipeline_v0_ps1_gpu:4937747",
    "command": [
      "python",
      "/app/service.py"
    ],
    "cpu": {},
    "memory": {},
    "ephemeral-storage": {}
  },
  ...
```

And the above mentioned  _web UI hosting_ service, could be more cleanly defined as:

```
{
  "$schema": "urn:ivcap:schema:service.2",
  "id": "urn:ivcap:service:281606c8-...",
  ...
  "controller": {
    "$schema": "urn:ivcap:schema:service.app-server.1",
    "host": "crewai.develop.ivcap.io",
    "artifact": "urn:ivcap:artifact:000000-...",
    "404": "index.html",
    ...
  },
  ...
```

and finally, a multi-node Argo workflow:

```
{
  "$schema": "urn:ivcap:schema:service.2",
  "id": "urn:ivcap:service:281606c8-...",
  ...
  "parameters": [{
    "name": "message",
    "description": "message to display",
    "type": "string"
  }],
  ...
  "controller": {
    "$schema": "urn:ivcap:schema:service.argo-wf.1",
    "entrypoint": "main-workflow",
    "templates": [
      {
        "name": "main-workflow",
        "dag": {
          "tasks": [
            {
              "name": "first-task",
              "template": "task1"
            },
            {
              "name": "second-task",
              "dependencies": ["first-task"],
              "template": "task2"
            }
          ]
        }
      },
      {
        "name": "task1",
        "inputs": {
          "parameters": [
            {
              "name": "message"
            }
          ]
        },
        "container": {
          "image": "alpine:3.7",
          "command": ["sh", "-c"],
          "args": ["echo '{{inputs.parameters.message}}'"]
        }
      },
      {
        "name": "task2",
        "container": {
          "image": "alpine:3.7",
          "command": ["sh", "-c"],
          "args": ["echo Hello from task 2!"]
        }
      }
    ]
  }
}
```
