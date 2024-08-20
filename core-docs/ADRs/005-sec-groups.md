> DRAFT

# ADR 5: Security Groups

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

We are going to introduce CIDs (capability ID) which identify the capability a caller would
need to posses in order for a specific request to be performed by the system. A request is further
defined by an action and an optional context. Currently, the set of actions are: `create`, `read`,
and `retract`. The context is effectively restricting the request. It may include a set of
schema or entity URNs. In addition, certain requests may require an explicit context on the
required CID

The provisioning of the token, or any additional verification services will be provided by a
separate service and are not part of this ADR.

### Reading and Retracting Aspect Records

Each aspect record will include two additional columns holding the CID required to read or retract the record accordingly. Those CIDs need to be set when the record is created. If it needs ot be changed, the
current record needs to be retracted and a new one with the exact content, but a new CID needs to be
created. Note, this require the necessary CID to create a new aspect record.

### Creating a new Aspect Record

Creating a new "generic" record is straight forward as long as the caller can provide verified CIDs
to constrain future reading and retracting of the new record.

However, we need to add a few restrictions to that. First of all, any URNs starting with `urn:ivcap:...`
can only be created by internal processes. While we have previously established that the entity name (URN)
itself has no meaning, we enforce that restrictions for convenience (e.g. debugging, monitoring) sake.

Any additional constraints will refer to specific schemas and the number of aspects with that schema attached to a single entity.

#### Creating a new `Service` Record

Services are a fundamental offering of IVCAP and will very likely require some additional verification and validation. It start with ensuring that referenced docker images are indeed accessible. A deployment may also
require additional onboarding steps or QA controls. To support service discovery, we may require a more detailed
description of the service. In addition, there can only be exactly one single aspect for that schema for every service URN.

However, we will still allow users to add additional aspects to a service URN, except for schemas starting with `urn:ivcap:schema:system...` (**TODO**: Needs to further verified)

#### Creating a new `Artifact` Record

Artifacts in IVCAP are associated with a corresponding _blob_ stored either in IVCAP's blob storage or retrievable via a URL. We therefore want to ensure that a URN starting with `urn:ivcap:artifact:...` will from the beginning be associated with a specific schema (**TODO**: specific schema). It should be noted, that _deleting_ an artifact would simply require the retraction of the respective aspect.

## Consequences

_What becomes easier or more difficult to do because of this change?_

## Considered Options

* OPA's
[partial evaluation](https://blog.openpolicyagent.org/partial-evaluation-162750eaf422) feature

We have been using OPA so far and ran into multiple issues. One of them was that authorisation was
enforced at multipe places with it's own set of policies leading to potential inconsistencies.

We also encountered scalability issues given that it turned out ot be very difficult to turn
the many possible policies into SQL.

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
 Records  ┌────┬───────────-───────┬───────────────────────────────────────────┐
          │ ID │ ENTITY            │ SCHEMA                                    │
          ├────┼───────────-───────┼───────────────────────────────────────────┤
          │ @1 │ artifact:4fade... │ urn:ivcap:schema:artifact-in-collection.1 │
          │ @2 │ artifact:4fade... │ urn:ivcap:schema:artifact.1               │
          │ @3 │ artifact:4fade... │ urn:ivcap:schema:image.photo.1            │
          │ @4 │ artifact:4fade... │ urn:ibenthos:schema.survey_image.3        │
          └────┴───────-───────────┴───────────────────────────────────────────┘
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

What is unclear to me right now, if we can also control the number of aspects with the same schema also through an additional property of the schema record.
