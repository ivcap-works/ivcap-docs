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
* Date: 2024-07-15

## Context

We currently support two facets of the a single service model, namely a batch workflow to be executed by an [Argo workflow engine](https://argoproj.github.io/workflows/). However, as described in [ADR 1](./001-standing-orders.md), we have already identified other types of services for quite some time. In addition, the _web UI hosting_ service (e.g. [iBenthos](https://ibenthos.develop.ivcap.io/)) is currently realised in a round-about way which can easily lead to uncaught mis-configurations.

In short, we need an easily extendible solution to more easily allow for the introduction of new service models.

## Decision Drivers

* Need to easily add new service models
* Minimise changes to existing architecture
* Maximise reuse of existing extension mechanisms

## Decision

_What is the change that we're proposing and/or doing?_

## Consequences

_What becomes easier or more difficult to do because of this change?_

## Considered Options

* [option 1]
* [option 2]
* ...

## Detailed Discussion (Optional)

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
  "$schema": "urn:ivcap:schema:service.1",
  "id": "urn:ivcap:service:cd1f418c-...",
  ...
  "executor": {
    "$schema": "urn:ivcap:schema:service.basic.1",
    "image": ".../cps.data61.csiro.au/cv_pipeline_v0_ps1_gpu:4937747",
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
  "$schema": "urn:ivcap:schema:service.1",
  "id": "urn:ivcap:service:281606c8-...",
  ...
  "executor": {
    "$schema": "urn:ivcap:schema:service.app-server.1",
    "host": "crewai.develop.ivcap.io",
    "artifact": "urn:ivcap:artifact:000000-...",
    "404": "index.html",
    ...
  },
  ...
```

---
_This template is a light variation of the one introduced in [Documenting architecture decisions - Michael Nygard](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions)._
