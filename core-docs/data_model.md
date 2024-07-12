This document is an attempt to capture all the entities and relationships we have in the system and for which we may need to capture certain information about.

We have identified the following entities:

* **Principal:** An authenticated user or agent
* **Service:** A description of a service offered
* **Order:** A placed order for a particular service
* **ServiceInvocation**: Represent the invocation of particular service in fulfilling an order
* **Artefact:** Any artefact either consumed or produced by a service invocation.
* **Account:** A account will be associated with all chargeable events.
* **Policy**: Policies describes the conditions under which certain actions can be taken
* **Assertion:** Assertions are "endorsed" properties of any system entity consumed by policies

## Entity Diagram

Below find a slightly, non standard Entity Diagram capturing the entity attributes and relationships.

<img src="images/svg/data_flow.svg" />

### PlantUML code

```
@startuml


entity "Policy" as py {
  * id : UUID <<generated>>
  * name: TEXT
  * definition: JSON
}

entity "Service" as sv {
  * id : UUID <<generated>>
  * description: TEXT
  * service_definition: URL
  * parameter_schema: JSON
  * policy_id: ref<<Policy>>
}

entity "ServiceInvocation" as svi {
  * id : UUID <<generated>>
  * service_id : ref <<Service>>
  * order_id : ref <<Order>>
  * parameters: JSON
  * status: PENDING | ...
  cost: NUMBER
}

entity "Principal" as pr {
  * id : UUID <<generated>>
  * name: TEXT
}

entity "Account" as acc {
  * id : UUID <<generated>>
  * name: TEXT
}

entity "Order" as ord {
  * id : UUID <<generated>>
  * account_id : ref <<Account>>
  * placed_by: ref <<Principal>>
  * service_id : ref <<Service>>
  * parameters: JSON
  * placed_at: DATE
}

entity "Artefact" as art {
  * id : UUID <<generated>>
  * produced_by : ref <<ServiceInvocation>>
  * owned_by : ref <<Account>>
  * mime_type: STRING 
  * url: URL
}

entity "Assertion" as ass {
  * id : UUID <<generated>>
  * issuer_id: ref<<Principal>>
  * subject_id : ref <<any>>
  * property_name : TEXT
  * obj_type: STRING | NUMBER | REF 
    object_ref: UUID
    object_s: STRING
    object_n: NUMBER
  * valid_from: DATE
    valid_to: DATE
}

sv }|-- svi
sv }|-- ord
ord }|-- svi
pr }|-- ord
acc }|-- ord
acc }|-- art
svi }|-- art

py }|-- sv
py }|-- art
py }|-- acc

py ... ass

hide circle
hide methods
'skinparam linetype ortho
skinparam monochrome true
@enduml
```
