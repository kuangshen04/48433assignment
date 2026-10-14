# GS1 EPCIS Model Notes

> Applicable versions: EPCIS 2.0 / 2.0.1 and CBV 2.0  
> Recorded on: 2026-09-30  
> Purpose: Define the cross-enterprise traceability event language for the Agricultural Supply Chain Tracker, rather than serving directly as a complete business system design.

## 1. What Is EPCIS?

GS1 EPCIS (Electronic Product Code Information Services) is a supply-chain visibility event data model and a set of standard interfaces. It enables different enterprises and software systems to use a common language to express:

```text
A physical or digital object
at a particular time and place
undergoing a business activity
and being in a particular business or environmental state
```

EPCIS mainly specifies:

- the data model for supply-chain events;
- event types and semantics;
- how identifiers for products, lots, logistics units, locations, and similar entities are referenced;
- the Capture Interface for event submission;
- the Query Interface for event retrieval;
- JSON, JSON-LD, and XML representations;
- event correction semantics;
- mechanisms for custom industry extensions.

EPCIS is not a complete supply-chain system, nor does it prescribe databases, blockchains, identity governance, access control, or enterprise approval workflows.

## 2. Events Rather Than Mutable Objects

The core record in EPCIS is an `EPCISEvent`: a business fact describing something that happened to an object in the real world.

```text
Batch A was created at Farm X
Batch A was shipped
Batch A was received at Warehouse Y
Cases A1-A10 were loaded onto Pallet P
Harvest Lots A and B were processed into Packaged Lot C
```

EPCIS is not centered on a universal `TraceableObject` that is continuously overwritten and updated. An object's history and current state are usually derived from all relevant events:

```text
Object current state
= fold/reduce(all valid related events)
```

Therefore, EPCIS is closer to a standardized event-sourcing/event-sharing model.

## 3. The Five Dimensions of an Event

Each EPCIS event answers what, when, where, why, and how.

| Dimension | Question | Main Fields |
|---|---|---|
| What | What objects are involved? | `epcList`, `quantityList`, parent/child, input/output |
| When | When did it occur and when was it recorded? | `eventTime`, `eventTimeZoneOffset`, `recordTime` |
| Where | Where did it occur, and where is the object after the event? | `readPoint`, `bizLocation` |
| Why | What business step and business state apply? | `bizStep`, `disposition`, transactions, source/destination |
| How | What was the condition of the object or environment? | `sensorElementList` |

### 3.1 What

EPCIS supports different identification granularities.

#### Instance-level

A specific individual instance, for example:

- a serialized retail item;
- an individual case;
- a pallet;
- a transport container;
- a reusable asset.

These are usually referenced through fields such as:

- `epcList`;
- `childEPCs`;
- `inputEPCList`;
- `outputEPCList`.

#### Class/lot-level

Only the product class or lot and quantity are known, for example:

```text
Strawberry Lot L20260930
Quantity: 500 kg
```

This is expressed using quantity elements:

```text
epcClass
quantity
uom
```

Therefore, EPCIS does not require every agricultural product to have a unique item-level identifier; lot-level traceability is a valid model.

### 3.2 When

EPCIS distinguishes between:

```text
eventTime
The time when the event occurred in the real world

recordTime
The time when the EPCIS Repository recorded the event
```

`recordTime` is a repository bookkeeping field and does not describe the real-world event. It should be ignored in the Capture Interface and should be present in events returned through the Query Interface.

This distinction is useful in offline environments:

```text
eventTime  = the time when the farm actually completed shipment
recordTime = the time when the device successfully submitted the event after connectivity was restored
```

`eventTimeZoneOffset` preserves the timezone offset at the event location at that time, helping retain the business-time context.

### 3.3 Where

EPCIS distinguishes between two types of location:

```text
readPoint
The location where the event was actually observed, scanned, or captured

bizLocation
The business location where the object is considered to be after the event is completed
```

For example:

```text
readPoint   = Warehouse Y Receiving Gate 3
bizLocation = Warehouse Y Cold Room
```

Locations can use GLNs, other URIs, or appropriate geographic identifiers.

### 3.4 Why

Why describes business context, not free-text explanation.

#### `bizStep`

Represents the business step being performed when the event occurs, for example:

- `commissioning`;
- `packing`;
- `shipping`;
- `receiving`;
- `inspecting`;
- `sampling`;
- `retail_selling`;
- `sensor_reporting`.

#### `disposition`

Represents the business state of the object after the event, for example:

- `active`;
- `in_transit`;
- `expired`;
- `recalled`;
- `retail_sold`;
- `stolen`.

The distinction is:

```text
bizStep     = what was done in this event
disposition = what state the object is in afterward
```

Example:

```text
bizStep     = shipping
disposition = in_transit
```

Other Why fields include:

- `bizTransactionList`: business transactions such as orders, invoices, and bills of lading;
- `sourceList`: source organizations or locations involved in the business transfer;
- `destinationList`: destination organizations or locations involved in the business transfer;
- `persistentDisposition`: persistent states that must be explicitly set/unset across events.

### 3.5 How

EPCIS 2.0 uses `sensorElementList` to represent sensor information.

```text
sensorElementList
├── sensorMetadata
└── sensorReport
```

`sensorMetadata` can contain:

- `deviceID`;
- `startTime`, `endTime`;
- `deviceMetadata`;
- `rawData`;
- `dataProcessingMethod`;
- `bizRules`.

`sensorReport` can contain:

- measurement type;
- observation time;
- value and unit;
- min/max/mean;
- standard deviation;
- microorganism;
- chemical substance;
- alarm/exception.

EPCIS does not require all high-frequency raw data to be embedded in a single event. An event can store statistical summaries and reference external time-series data through `rawData`.

## 4. The Five Standard Event Types

### 4.1 ObjectEvent

`ObjectEvent` represents one or more objects undergoing the same business event.

Typical scenarios:

- batch creation/commissioning;
- inspection;
- shipping;
- receiving;
- sensor reporting;
- retail selling;
- destroying/decommissioning.

Main What fields:

```text
epcList          instance-level objects
quantityList     class/lot-level objects
action
```

ObjectEvent actions:

- `ADD`: starts the object's lifecycle;
- `OBSERVE`: an observation or ordinary business activity during the object's lifecycle;
- `DELETE`: ends the object's lifecycle.

`DELETE` does not mean deleting a database record. It declares that the object should no longer appear in subsequent normal events.

### 4.2 AggregationEvent

`AggregationEvent` represents a reversible physical packing, loading, or containment relationship.

```text
Cases A1-A10 → Pallet P
Pallets P1-P5 → Container C
```

Main fields:

```text
parentID
childEPCs / childQuantityList
action
```

AggregationEvent actions:

- `ADD`: children are added to the parent;
- `OBSERVE`: the aggregation relationship is observed to exist;
- `DELETE`: children are removed from the parent.

Key semantic point: each child retains its own identity, and the aggregation relationship can usually be reversed.

### 4.3 TransformationEvent

`TransformationEvent` represents one or more input objects being fully or partially consumed to produce one or more new output objects.

```text
Harvest Lot A ─┐
               ├─→ Packaged Lot C
Harvest Lot B ─┘
```

Main fields:

```text
inputEPCList
inputQuantityList
outputEPCList
outputQuantityList
transformationID
```

The distinction between Transformation and Aggregation is:

```text
Aggregation
Objects are merely packed together; each child still exists and the relationship is reversible

Transformation
Inputs participate in producing new outputs and the relationship is usually irreversible
```

Multiple transformation events that occur over a period of time can share the same `transformationID`.

### 4.4 TransactionEvent

`TransactionEvent` represents creating, maintaining, or removing an association between objects and commercial transactions.

```text
Pallet P
↔ Purchase Order 123
↔ Invoice 456
```

It does not handle payment and does not automatically represent ownership or custody transfer. In many scenarios, orders or invoices can simply be attached to other events through `bizTransactionList`, so a separate TransactionEvent is not always necessary.

### 4.5 AssociationEvent

`AssociationEvent` is a type introduced in EPCIS 2.0 for associations that are more persistent than packing relationships.

```text
Sensor D is installed on Reusable Container C
Equipment E is permanently associated with Location L
```

Main fields:

```text
parentID
childEPCs / childQuantityList
action = ADD / OBSERVE / DELETE
```

Difference from Aggregation:

- Aggregation mainly represents temporary packing, loading, and co-movement;
- Association mainly represents installation or more persistent composition relationships;
- the `parentID` of an Association can use a physical location identifier.

In this project, AssociationEvent can represent long-term `Device → Container` or `Sensor → Cold Room` bindings. Temporary device bindings for a single shipment can also be represented using ordinary events and evidence references.

## 5. Action Semantics

| Event Type | ADD | OBSERVE | DELETE |
|---|---|---|---|
| ObjectEvent | Start object lifecycle | Observation or ordinary business activity | End object lifecycle |
| AggregationEvent | Add to parent | Observe aggregation relationship | Remove from parent |
| TransactionEvent | Establish transaction association | Observe association | Remove association |
| AssociationEvent | Establish persistent association | Observe association | Remove association |
| TransformationEvent | Not used | Not used | Not used |

`action` and `bizStep` are different fields:

```text
action  = OBSERVE
bizStep = shipping
```

This means the object is neither created nor destroyed; it is simply going through the shipping step during its lifecycle.

## 6. CBV: A Shared Business Vocabulary

EPCIS defines the structure of event fields; the Core Business Vocabulary (CBV) defines commonly used values for those fields and their business semantics.

CBV mainly defines:

- business step;
- disposition;
- business transaction type;
- source/destination type;
- error reason;
- standard vocabularies for sensor measurements and similar concepts.

The purpose of adopting CBV is to avoid different companies using different terms for the same business meaning, such as:

```text
shipping
shipped
dispatch
sent_out
```

If CBV does not contain an appropriate value, a consortium-controlled URI can be defined, for example:

```text
https://example.org/cbv/bizstep/field_harvesting
```

However, the more custom vocabulary is introduced, the lower the interoperability.

## 7. Identification Methods

EPCIS can reference:

- EPC URNs;
- GS1 Digital Link URIs;
- other compliant URIs.

Common GS1 identifiers include:

| Identifier | Purpose |
|---|---|
| GTIN | Product class |
| GTIN + lot | Product lot |
| SGTIN | Serialized product instance |
| SSCC | Logistics unit such as a case, pallet, or container |
| GLN | Enterprise or location |
| GRAI | Reusable asset |
| GIAI | Individual asset |

EPCIS itself does not handle:

- assigning GTINs/GLNs;
- printing QR codes;
- managing RFID;
- preventing label cloning or replacement;
- proving that a label is attached to the correct physical object.

## 8. Capture and Query Interfaces

### 8.1 Capture Interface

The Capture Interface receives EPCIS events generated by business systems:

```text
ERP / WMS / Mobile / IoT Adapter
                 │
                 ▼
           EPCIS Capture API
                 │
                 ▼
           EPCIS Repository
```

EPCIS 2.0 supports REST/OpenAPI, JSON, JSON-LD, and XML.

### 8.2 Query Interface

The Query Interface supports retrieving events based on conditions including:

- object ID;
- event ID/type;
- event/record time;
- bizStep/disposition;
- location/read point;
- source/destination;
- parent/child;
- transformation input/output;
- error declaration.

REST resources include:

```text
/events
/events/{eventID}
/eventTypes/{eventType}/events
```

The standard also defines SimpleEventQuery and standing query/callback. GS1 provides normative artefacts including OpenAPI, JSON Schema, XSD, SHACL, and JSON-LD context files.

EPCIS does not prescribe whether the repository must use a relational database, graph database, or blockchain.

## 9. Corrections and Non-Overwritten History

The EPCIS Capture/Query Interface does not provide operations to directly modify or delete recorded events. When an error is discovered, a new `ErrorDeclaration` is used.

```text
Original Event E1
        │
Error Declaration
"The business assertion in E1 is incorrect"
        │
Corrective Event E2
```

ErrorDeclaration contains:

```text
declarationTime
reason
correctiveEventIDs
```

An error-declaration event is identical to the original event except for `errorDeclaration` and `recordTime`, and it retains the same `eventID`. The original event is not modified; subsequent queries can return the original event, the error declaration, and the corrective event.

This aligns well with this project's append-only blockchain ledger: corrections are expressed by appending records rather than overwriting history.

## 10. Certification and Extensions

EPCIS events can contain `certificationInfo`, which points to certification details related to objects, locations, or organizations in the event. Certification details can be represented using `CertificationDetails` from the GS1 Web Vocabulary.

EPCIS allows industry- or enterprise-specific fields to be added using namespaces, URIs, and JSON-LD contexts. For example, an agricultural profile could add:

```text
harvestMethod
cropVariety
farmPlot
pesticideTreatment
organicClaim
qualityGrade
```

Recommended extension order:

```text
EPCIS core
+ CBV standard values
+ consortium-approved agricultural profiles
+ limited company-specific extensions
```

Each enterprise should not be allowed to submit arbitrarily different JSON structures.

## 11. What EPCIS Does Not Specify

EPCIS does not define:

- how enterprises join or leave a consortium;
- organisation/user/device identity;
- login, RBAC, or ABAC;
- digital signatures and key management;
- which events require endorsement from both parties;
- field-level data visibility;
- whether data is stored on-chain or off-chain;
- blockchain type and consensus mechanism;
- database and cloud deployment;
- enterprise dispute handling;
- IoT device registration, calibration, and revocation;
- regulatory compliance decisions;
- offline synchronization;
- consumer UI;
- complete recall workflows.

EPCIS can separately express:

```text
Company A declares that Batch X was shipped
Company B declares that Batch X was received
```

However, it does not require A and B to jointly sign the same handover, nor does it determine who is correct when the two parties disagree.

## 12. How This Project Should Use EPCIS

It is recommended to structure the system into four layers:

```text
┌────────────────────────────────────────┐
│ Consortium-specific Business Rules     │
│ Handover confirmation, approvals,      │
│ correction authorization, compliance   │
├────────────────────────────────────────┤
│ Ledger Envelope                        │
│ publisher, signature, visibility, hash │
├────────────────────────────────────────┤
│ EPCIS Event                            │
│ what, when, where, why, how             │
├────────────────────────────────────────┤
│ GS1 IDs + Agricultural Extensions      │
│ GTIN, lot, SSCC, GLN, product profile  │
└────────────────────────────────────────┘
```

### 12.1 EPCIS Is Responsible For

- the core event structure;
- references to objects at different granularities;
- aggregation/transformation/association;
- time, location, and business context;
- sensor evidence;
- capture/query formats;
- error declarations.

### 12.2 This Project Must Design

- Organisation identity;
- enterprise, user, and device signatures;
- schema/profile governance;
- access control and visibility projection;
- sender/receiver endorsement;
- blockchain submission;
- on-chain/off-chain data partitioning;
- compliance rules;
- offline synchronization;
- consumer portal.

## 13. Recommended Minimum EPCIS Subset

### 13.1 Initial Event Types

Must support:

```text
ObjectEvent
AggregationEvent
TransformationEvent
```

Optionally support:

```text
AssociationEvent
for long-term Device → Container/Location bindings
```

The first version does not need to provide a separate TransactionEvent; `bizTransactionList` can initially be used to associate orders and shipping documents.

### 13.2 Fields Made Mandatory by This Project

Some EPCIS fields are optional, but the agricultural profile in this project should impose stronger constraints:

```text
eventID                   mandatory
eventTime                 mandatory
eventTimeZoneOffset       mandatory
eventType                 mandatory
bizStep                   mandatory
schemaProfile/version     mandatory in project extension

At least one What structure:
epcList / quantityList /
parent-child / input-output

readPoint or bizLocation  mandatory
publisher organisation    mandatory in ledger envelope
publisher signature       mandatory in ledger envelope
visibility policy         mandatory in ledger envelope
```

For shipping/receiving, the project profile should additionally require:

```text
sourceList
destinationList
disposition
```

### 13.3 Initial CBV Subset

Business steps:

```text
commissioning
packing
shipping
receiving
inspecting
sensor_reporting
retail_selling
decommissioning
```

Object states:

```text
active
in_transit
recalled
expired
retail_sold
destroyed
```

## 14. Simplified Event Example

The following is a simplified JSON-LD-style event for illustration; it is not a complete normative EPCIS document:

```json
{
  "type": "ObjectEvent",
  "eventID": "urn:uuid:44207a31-6ec7-45d7-a642-59ad49e9c802",
  "eventTime": "2026-09-30T10:15:00+10:00",
  "eventTimeZoneOffset": "+10:00",
  "quantityList": [
    {
      "epcClass": "https://example.org/products/strawberry/lot/L20260930",
      "quantity": 500,
      "uom": "KGM"
    }
  ],
  "action": "OBSERVE",
  "bizStep": "shipping",
  "disposition": "in_transit",
  "readPoint": {
    "id": "https://example.org/locations/farm-a/loading-dock"
  },
  "sourceList": [
    {
      "type": "possessing_party",
      "source": "https://example.org/organisations/farm-a"
    }
  ],
  "destinationList": [
    {
      "type": "possessing_party",
      "destination": "https://example.org/organisations/distributor-b"
    }
  ]
}
```

In this project, the EPCIS payload also requires an outer Ledger Envelope:

```json
{
  "publisherOrganisationId": "farm-a",
  "schemaProfile": "fresh-produce/1.0",
  "visibilityPolicyId": "trade-partners-only",
  "payloadHash": "...",
  "publisherSignature": "...",
  "epcisEvent": {}
}
```

## 15. Design Conclusion

EPCIS provides this project with:

> A standard syntax, semantics, and API for expressing and exchanging supply-chain events across enterprises, rather than a complete agricultural business workflow or blockchain solution.

This project should adopt EPCIS as the canonical event model, and add enterprise identity, signatures, permissions, handover endorsement, blockchain proofs, and agricultural schema profiles around it.

## 16. Official Resources

- [GS1 EPCIS & CBV](https://www.gs1.org/standards/epcis)
- [EPCIS 2.0.1 Standard](https://ref.gs1.org/standards/epcis/2.0.1/)
- [EPCIS Normative Artefacts](https://ref.gs1.org/standards/epcis/artefacts)
- [EPCIS/CBV Implementation Guideline 2.0](https://ref.gs1.org/guidelines/epcis-cbv/2.0.0/)
- [Core Business Vocabulary 2.0](https://ref.gs1.org/standards/cbv/2.0.0/)
- [EPCIS JSON/XML Examples](https://ref.gs1.org/docs/epcis/examples)
- [GS1 Digital Link](https://www.gs1.org/standards/gs1-digital-link)
