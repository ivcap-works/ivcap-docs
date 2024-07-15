> DRAFT

# Security Groups

In the context of __(use case)__
facing __(concern)__
we decided for __(option)__
to achieve __(quality)__
accepting __(downside)__.

## Status

* Status: proposed (_any of proposed, accepted, rejected, deprecated, superseded_)
* Author(s): Max Ott
* Deciders: ???
* Date: 2024-06-25

## Context

We currently use [OPA](https://www.openpolicyagent.org/) policies to control
what a user can do or see. We do that by
associating most resources (aspect, artifacts, ...) with policies which are
defining the actions a use can do or not depending on the resource and it's context.
Context may include the user's account, properties of the resource, or external information
such as account balance or expected usage.

While OPA policies give us extreme flexibility in covering even complex authorisation
requirements, we have been struggling to implement and deploy it correctly across our
entire stack. In addition, we currently pass every record returned by a datafabric query
through an OPA check which is quickly leading to performance bottlenecks.

While there are ways to improve the datafabric query bottleneck by taking advantage of OPA's
[partial evaluation](https://blog.openpolicyagent.org/partial-evaluation-162750eaf422) feature,
our desire to allow for an arbitrary number of policies will not easily translate to our context.

In addition, we have now invested considerable effort in incorporating [Topaz](https://www.topaz.sh/), which combines OPA and
[Zanzibar](https://research.google/pubs/zanzibar-googles-consistent-global-authorization-system/),
 Google’s global authorization system.

## Decision Drivers

_What are the main criteria relevant to, and driving, the decision_

* [driver 1, e.g., a force, facing concern, ...]
* [driver 2, e.g., a force, facing concern, ...]
* ...

## Decision

_What is the change that we're proposing and/or doing?_

## Consequences

_What becomes easier or more difficult to do because of this change?_

## Considered Options

* OPA's
[partial evaluation](https://blog.openpolicyagent.org/partial-evaluation-162750eaf422) feature

_Discuss both Pros and Cons of the Options_

## Detailed Discussion (Optional)

So what do we need to protect, or in other words, authorise?

To constrain the problem at hand we will focus on actions related to aspects in the DataFabric as
the vast majority of authorisation decisions can be reduced to this scenario.

From an authorisation point of view there are three actions we may want to control:

1. Creating a new aspect
1. Reading an existing aspect
1. Retracting an exisiting aspect

The context for "creating" an aspect is a) the _schema_ of the new aspect and b) the _entity_ the aspect
relates to. While for the remaining "reading" and "retracting" actions, we also have the aspect itself
as context.

### Creating an Aspect

The data model of the datafabric as described in [Providing a Datafabric Service](./004-datafabric.md) ADR, defines an entity as a "typeless pointer to some _thing_". The actual definition and description of an entity resides in one or more "typed" aspects "attached" to it. The datafabric ADR also advocates for an "open" information model putting the burden of what information (_aspect_) to trust and which one to ignore on the information "consumer". In other words, there does not seem to be any need for restricting the creation of
aspects as long as the source ("asserter") is verified.

However, the entity's "typeless pointer" is in reality a URN, and it inadvertently does convey some meaning. Specifically, all URN's starting with with `urn:ivcap:...` are expected to relate to system internal entities. And more specifically, it is assumed that certain information (_schema_) will only be added by privileged, internal processes. In addition, we may expect to find only one "active" aspect of a specific schema attached to some type of entity.

For instance, let us look at a particular Artifact holding an image:

```
% ivcap aspect list -e urn:ivcap:artifact:4fade...

  Entity  urn:ivcap:artifact:4fade...
 At Time  now
 Records  ┌────┬─────────────────────────────┬───────────────────────────────────────────┐
          │ ID │ ENTITY                      │ SCHEMA                                    │
          ├────┼─────────────────────────────┼───────────────────────────────────────────┤
          │ @1 │ urn:ivcap:artifact:4fade... │ urn:ivcap:schema:artifact-in-collection.1 │
          │ @2 │ urn:ivcap:artifact:4fade... │ urn:ivcap:schema:artifact.1               │
          │ @3 │ urn:ivcap:artifact:4fade... │ urn:ivcap:schema:image.photo.1            │
          │ @4 │ urn:ivcap:artifact:4fade... │ urn:ibenthos:schema.survey_image.3        │
          └────┴─────────────────────────────┴───────────────────────────────────────────┘
```

The first two aspects have schemas starting with `urn:ivcap:schema:artifact..` which have been created internally as part of creating and uploading the image. The last two aspects with schema `urn:ivcap:schema:image.photo.1
and`urn:ibenthos:schema.survey_image.3` respectively have been provided by a user with the `urn:ivcap:schema:image.photo.1` schema defined by the platform, while the last schema is defined by the use or their community.

Therefore, we can distinguish between aspects which only internal processes can create and those with no initial constraints. In addition, we want to enforce that any entity representing an artifact must only have __1 (one)__ aspect with schema `urn:ivcap:schema:artifact.1`. It can have any number (including zero) of aspects with schema `urn:ivcap:schema:artifact-in-collection.1` as an image can be in any number of collections.

In other words, we will likely need to restrict the creation of aspects with specific schemas for certain types of entities. While the entity handle (_URN_) is not supposed to hold any specific meaning, for simplicity and clarity we may restrict certain [urn scheme](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax) for specific purposes, such as identifying IVCAP primitives, such as services (`urn:ivcap:service:...`), orders, artifacts, and more.

### Reading and Retracting Aspects

Reading (accessing) and retracting aspects seem to be more straight forward as the "rules" can most likely be define when an aspect is created. As we don't support updating aspects, there is also no need to support updating the "rules" as we can always retract the an aspect and create a new one with the new rules.

### Sets and Groups

Zanzibar (as well as Topaz) maintains basic relationships such as  “user U has relation R to object O”. More complex ACLs take the form of “set of users S has relation R to set of objects O”. In addition, group (aka set) membership, as well as nested groups are supported.

While our current work on Topaz was motivated by managing account memberships - which user can _speak for_ a specific account - we may be able to directly extend that to the functionality currently provided by OPA and specific rules.

The basic idea is that we create __permission sets (PS)__ which can be associated with a particular action as described above. Authorisation then allows a user __U__ to perform a specific action __A__ related to a specific aspect or entity __X__ _iff_ the user is part of the respective __PS__.

For the aspect records themselves, we would add a `read_ps` and a `retract_ps` property to each record and then check if the requester is part of the respective PS. This would greatly simplify search as we further restrict any query with an additional check if the record's `read_ps` is within the set of PSs the requester is part of.

Creating an aspect, as mentioned above, is a bit more involved and, for pragmatic reasons, also extends to "creating" an entity URN. For the latter, we will likely only need to restrict the creation of "systems" URNs to platform internal processes. That leaves us with two remaining concerns:

* Who can create an aspect of a specific schema
* Can an entity have more then one aspect of the same schema

There are multiple reasons to maintain a record of schemas and their definitions; validation is one of them. If we manage schemas, we first of all, need to protect them in a similar (if not identical fashion) as aspects, where the entity is the name of the schema and the (only?) aspect being the schema definition. However, a particular schema can only be created, but never retracted. In addition, we may add an additional, but optional `create_ps` property, to indicate on who can create aspects of that schema type (that property can be modified at later stages).

WHat is unclear to me right now, if we can also control the number of aspects with the same schema also through an additional property of the schema record.
