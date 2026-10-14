# Agricultural Supply Chain Traceability Platform Research

> Research targets: IBM Food Trust, TE-FOOD, OriginTrail, VeChain  
> Research date: 2026-09-30  
> Purpose: Provide references for the business scope, data model, blockchain design, and deployment model of the Agricultural Supply Chain Tracker.

## 1. Core Conclusions

These platforms generally do not require every enterprise in the supply chain to replace its ERP, WMS, TMS, or farm management system with one shared system. The common pattern is:

```text
Enterprise internal systems
ERP / WMS / TMS / Farm Management / IoT Platform
                         │
                         ▼
                   API / EPCIS / File / App
                         │
                         ▼
Cross-enterprise traceability platform
Identity / Event Validation / Access Control / Ledger / Trace Query
```

Large enterprises typically retain their existing systems and publish, through APIs, only the subset of traceability events that must be shared across organizations. Small farms or suppliers without mature internal systems can directly use the mobile or Web interfaces provided by the platform.

The most common data-modeling idea in the industry follows the GS1 EPCIS pattern of “identified objects + events”:

- objects can be product classes, lots, serialized items, cases, pallets, containers, and locations;
- events answer what, when, where, why, and how;
- ObjectEvent, AggregationEvent, and TransformationEvent can cover most food traceability processes;
- different product lines add versioned extension fields on top of a stable event structure.

A reasonable role for blockchain is to prove the provenance, ordering, and integrity of events shared across enterprises, rather than replacing all enterprise databases. High-frequency IoT data, personal information, large files, and commercially sensitive information generally need to be stored off-chain.

## 2. IBM Food Trust

### 2.1 Platform Positioning

IBM Food Trust is a shared traceability SaaS for the food supply chain. Its underlying technology uses IBM Blockchain Platform/Hyperledger Fabric. It provides a cross-organizational network for sharing data and executing trace queries, rather than a unified ERP jointly used by supply-chain enterprises.

IBM has published cloud service withdrawal information for Food Trust/Blockchain Transparent Supply, so this project treats it as a historical architectural reference rather than a current product recommendation.

### 2.2 Traceable Objects and Data Model

IBM Food Trust supports data including:

- Product ID;
- lot number;
- pallet number;
- Serial Shipping Container Code (SSCC);
- EPCIS Object Event;
- EPCIS Aggregation Event;
- EPCIS extension;
- dispatch advice and receiving advice;
- purchase order;
- item data notification;
- certificate.

Therefore, IBM does not prescribe a single traceability granularity. Instead, it uses standardized identifiers and events to connect products, lots, pallets, shipments, receipts, and certificates.

### 2.3 Platform-Native Business Capabilities

- enterprise, user, and facility onboarding;
- data entry and Connector API;
- EPCIS event ingestion;
- end-to-end trace queries;
- certificate manager;
- sharing of compliance, testing, audit, facility, and transaction certificates;
- data entitlement and inter-organizational visibility control;
- Fresh Insights and platform activity analytics.

Each organization owns the data it uploads and chooses which organizations can view it. After multiple organizations upload records that refer to the same product instance, the platform can connect those records into a supply-chain history.

### 2.4 Business Capabilities Handled by External Systems

IBM Food Trust generally does not replace:

- farm and production management;
- complete inventory management;
- warehouse picking and transportation scheduling;
- finance, payments, and contracts;
- laboratory testing processes;
- IoT device operations;
- internal enterprise quality approvals.

Large enterprises need to extract data from internal systems, transform it into the required XML/JSON/EPCIS structure, and then upload it through the Connector API. Smaller participants can enter data through the platform interface.

### 2.5 Modification and Immutability

IBM allows events to be corrected without overwriting history. Re-ingesting the same `eventID` produces a new version, while the old version remains on the ledger and queries normally expose the latest version.

```text
Event E1 v1
    ↓ correction using the same eventId
Event E1 v2
```

### 2.6 Deployment and Decentralization

The Food Trust product itself is a SaaS running on IBM Cloud. Hyperledger Fabric technically supports each organization independently operating peers, CAs, and ordering nodes, as well as cross-cloud and on-premises Kubernetes deployment. However, public Food Trust product materials do not clearly state whether ordinary subscribers can run their own Food Trust peers or orderers.

Therefore, it is necessary to distinguish:

```text
The multi-organization deployment capability of IBM Blockchain Platform
does not mean
ordinary Food Trust SaaS customers necessarily operate independent nodes
```

Food Trust decentralizes data ownership and authorization, but infrastructure control may remain highly centralized under IBM. This can prevent ordinary participants from silently modifying data, but protection against the platform operator itself controlling the network depends on the actual node and governance arrangement.

### 2.7 Lessons for This Project

- use EPCIS as the shared data language between enterprises;
- let uploaders own their data and control visibility;
- implement corrections by appending versions rather than overwriting history;
- separate the shared traceability layer from enterprise internal systems.

## 3. TE-FOOD

### 3.1 Platform Positioning

TE-FOOD is a relatively complete food traceability product covering identification, data capture, ledgering, processing, and consumer-facing presentation. It can serve both as a directly used business application for small enterprises and as a traceability layer above the ERP systems of large enterprises.

### 3.2 Traceable Objects and Identification

TE-FOOD supports:

- item;
- lot/batch;
- case;
- transport;
- livestock;
- serialized retail product;
- QR, RFID, and security seal.

A retail product's unique serial can be linked to the production or packaging batch it belongs to:

```text
Retail Item Serial
        ↓ belongs to
Packaging Batch
        ↓ derived from
Production/Harvest Batch
```

### 3.3 Platform-Native Business Capabilities

- product and packaging serialization;
- QR/RFID/label management;
- B2B mobile app and Web admin;
- recording of farm, processing, packaging, shipping, and receiving events;
- batch and raw-material relationships;
- blockchain traceability ledger;
- end-to-end traceability;
- targeted recall;
- supplier protocol/control point;
- company-, product-, and batch-level certificate management;
- reporting and process analytics;
- consumer scan pages and recall notifications.

### 3.4 Integration with Existing Systems

TE-FOOD provides multiple entry points according to participants' level of digital maturity:

```text
Small farms                    → B2B mobile app
Enterprises with basic digital capability → Web admin
Enterprises with only legacy systems      → Excel upload
Large enterprises              → API / EPCIS integration
IoT                            → staging system / integration API
```

The API can create and update master data, submit batch traceability data, and connect industrial printers for product serialization. The platform can receive EPCIS XML and can also transform non-standard events into EPCIS.

TE-FOOD Enterprise supports customized supply-chain processes and datasets, while the Lite version provides more fixed processes and datasets.

### 3.5 Business Capabilities Handled by External Systems

Enterprises can still retain:

- ERP and farm management systems;
- MES/WMS/TMS;
- laboratory systems;
- industrial printing and packaging equipment;
- IoT device management;
- internal production, inventory, and quality control.

Small enterprises may host their traceability records directly in TE-FOOD; large enterprises are more likely to synchronize only the data required for cross-organizational traceability.

### 3.6 Deployment and Decentralization

TE-FOOD applications are usually hosted by TE-FOOD or implementation partners. Its TrustChain is described as a public-permissioned/public-private hybrid blockchain:

- only verified and authorized participants can write or validate;
- some Supernodes are operated by supply-chain companies;
- some Masternodes are operated by the community;
- enterprises can choose which data is made public in the explorer;
- only traceability-related business activities are processed on-chain.

This is more distributed than having a single vendor operate all nodes, but admission, validator permissions, chaincode upgrades, and governance can still depend on TE-FOOD. It is therefore a permissioned network with limited decentralization.

### 3.7 Lessons for This Project

- provide App, Web, Excel, API, and EPCIS options for enterprises with different levels of technical maturity;
- support both batch traceability and serialized retail items;
- allow the platform to function both as a complete tool and as a shared traceability layer above enterprise systems;
- do not require every small farm to operate a node.

## 4. OriginTrail

### 4.1 Platform Positioning

OriginTrail is a Decentralized Knowledge Graph (DKG) and trusted-data infrastructure rather than an out-of-the-box agricultural supply-chain SaaS. Business applications must be built by enterprises or solution providers.

### 4.2 Data Model

OriginTrail packages interconnected data as Knowledge Assets. A Knowledge Asset can represent:

- a product or batch;
- logistics equipment;
- a location;
- an EPCIS supply-chain event;
- a trade document;
- a certificate or credential;
- relationships among the above entities.

Data is represented using RDF/JSON-LD and graph relationships, and can be combined with standards such as GS1 EPCIS, W3C Verifiable Credentials, and Digital Link. A Knowledge Asset has a stable UAL identifier, publisher, ownership, and version history.

### 4.3 Native Platform Capabilities

- publishing and updating Knowledge Assets;
- data identity and ownership;
- data provenance and publisher proof;
- data integrity verification;
- graph relationship linking, discovery, and querying;
- authorized sharing;
- blockchain anchoring.

### 4.4 Business Capabilities Not Provided Natively

OriginTrail does not directly provide:

- farm shipping or receiving UI;
- inventory management;
- transportation scheduling;
- food recall workflows;
- quality approvals;
- agriculture-specific consumer pages.

A typical integration process is:

```text
Enterprise TMS/ERP
        ↓ extract
Shipment/Product Event
        ↓ transform
GS1 EPCIS 2.0 Knowledge Asset
        ↓ publish
OriginTrail DKG
        ↓ query
Enterprise Traceability Application
```

### 4.5 On-Chain and Off-Chain

OriginTrail clearly separates two layers:

```text
DKG / knowledge graph
- stores and queries complete semantic data and relationships

Blockchain
- asset identity/ownership
- state update
- publisher and timestamp proof
- cryptographic fingerprint
```

In other words, complete graph data is not necessarily stored entirely on blockchain; blockchain primarily provides verifiable identity, state, and integrity proofs.

### 4.6 Deployment and Decentralization

The OriginTrail network is hosted by independent DKG nodes, and both organizations and individuals can operate nodes. Enterprises can also use third-party nodes or gateways rather than operating their own infrastructure. The DKG proof layer connects to external networks such as NeuroWeb, Gnosis, and Base.

Compared with a highly managed SaaS, enterprises can:

- run their own DKG node;
- store and query graph data themselves;
- retain custody of wallets and publishing keys;
- rely on external public blockchains to verify asset state.

This model provides stronger decentralization but increases the complexity of node operations, tokens, wallets, privacy-aware data sharing, and application development.

### 4.7 Lessons for This Project

- place complex supply-chain relationships in a queryable graph data layer;
- put only identity, version, fingerprint, and similar proofs on blockchain;
- use semantic standards to handle multiple products, multiple schemas, and cross-enterprise data linking;
- allow enterprises to independently store, publish, and verify data.

## 5. VeChain

### 5.1 Platform Positioning

VeChainThor is a public enterprise blockchain; ToolChain is a BaaS/SaaS and set of business templates built on top of it. Using the same public blockchain does not mean all enterprises use the same supply-chain application.

### 5.2 Traceability Model

ToolChain mainly uses:

- product ID;
- one-code-per-item serialization;
- QR, NFC, and RFID tags;
- basic product information;
- production, logistics, and circulation records;
- IoT environmental data;
- third-party certifications and consumer verification.

It places greater emphasis on serialized products, consumer scanning, anti-counterfeiting, and brand storytelling.

### 5.3 ToolChain Native Capabilities

- digital product identity;
- one-code-per-item serialization;
- basic traceability, anti-counterfeiting, and third-party certification management;
- circulation-record templates;
- APIs and custom templates;
- blockchain transactions and verification proofs.

### 5.4 Business Capabilities Handled by External Systems

Enterprises generally still need to retain or build:

- production and logistics systems;
- product, inventory, and quality management;
- IoT platforms;
- data mapping and blockchain-submission interfaces;
- consumer applications;
- business-specific smart contracts.

VeChainThor provides REST APIs, SDKs, and public nodes, and enterprises can also run their own full nodes.

### 5.5 Deployment and Decentralization

ToolChain applications can be hosted by the platform as SaaS/BaaS, while the underlying VeChainThor is an independent public blockchain:

- block production is currently handled by 101 permissioned validators;
- consensus requires `2/3 + 1` validators;
- validators require identity review and staking;
- anyone can run a full node to store and verify the ledger;
- ordinary full nodes do not automatically have block-production rights.

Therefore, ToolChain can reject, delay, or omit data before on-chain submission and can control its own consumer-facing presentation, but it cannot unilaterally rewrite transactions that have already been confirmed by public-chain validators. Enterprises can bypass the ToolChain API and verify on-chain records through their own full nodes.

This model is more resistant to tampering by the platform operator than a single-SaaS private ledger, but validator admission and network governance are still not fully open.

### 5.6 Data Authenticity Limitations

VeChain's service terms explicitly distinguish “not modified” from “true in the real world”: the platform can prove that information uploaded by a third-party enterprise has not been tampered with afterward, but it does not automatically guarantee that the originally uploaded data was accurate, complete, or truthful.

This reflects the oracle problem faced by all supply-chain blockchains. Authenticity also requires:

- enterprise identity verification;
- bilateral handover confirmation;
- device identity and secure hardware;
- tamper-evident labels;
- signatures from laboratories or certification bodies;
- on-site audits.

### 5.7 Lessons for This Project

- separate SaaS business applications from an independent public proof layer;
- allow enterprises to operate full nodes for independent verification;
- one-code-per-item serialization is suitable for consumer entry points and anti-counterfeiting, while batch-level traceability can remain the main granularity for food safety;
- do not claim that blockchain can automatically prove the truth of real-world data.

## 6. Cross-Platform Comparison

| Platform | Application Model | Enterprise System Integration | Node / Consensus Model | Decentralization Assessment |
|---|---|---|---|---|
| IBM Food Trust | IBM Cloud SaaS | API, XML/JSON, EPCIS, platform data entry | Fabric supports multi-organization nodes technically, but customer-operated Food Trust nodes are unclear | Data authorization is distributed; infrastructure may be highly managed |
| TE-FOOD | Hosted application + custom implementation | Mobile, Web, Excel, API, EPCIS | Permissioned enterprise Supernodes + community Masternodes | Distributed to some degree, but admission and governance are permissioned |
| OriginTrail | Infrastructure / middleware | Enterprises build their own publishing and query applications | Independent DKG nodes + external public blockchains | Closest of the four to an open, self-deployable model |
| VeChain | ToolChain SaaS/BaaS + public blockchain | API, SDK, custom applications | 101 validators; anyone can run a full node | Applications can be centralized, but the final ledger is not controlled by a single application |

## 7. Assessing SaaS and Decentralization

SaaS itself does not necessarily undermine decentralization. The assessment should be made at the following levels.

### 7.1 A Single SaaS Controls All Components

```text
SaaS controls:
- all application services
- all enterprise signing keys
- all peers
- all orderers/validators
- all governance keys
```

This deployment mainly provides append-only implementation and internal auditability. It cannot effectively address distrust of the SaaS operator itself.

### 7.2 SaaS Hosts the Application, Enterprises Sign Independently

```text
Company signs event
        ↓
SaaS validates and submits event
```

The SaaS can still reject or delay submission, but if enterprise private keys are not handed to the SaaS, the platform cannot forge enterprise events.

### 7.3 SaaS Hosts the Application, Multiple Organizations Operate Consortium Nodes

```text
Platform Operator    peer/orderer
Producer Group       peer/orderer
Logistics Group      peer/orderer
Retail Group         peer/orderer
Independent Body     peer/orderer
```

If endorsement and network governance require approval from multiple independent organizations, the platform operator cannot unilaterally write data, rewrite history, or change the rules.

### 7.4 Private Consortium Chain Anchored to a Public Blockchain

A consortium ledger can periodically calculate a Merkle root and write the root to a public blockchain:

```text
Private consortium ledger
          │ periodic commitment
          ▼
Public blockchain Merkle root
```

This avoids exposing sensitive business data while preventing the entire consortium from silently rebuilding history after the fact.

## 8. Preliminary Recommendations for This Project

### 8.1 Application Layer

Use SaaS hosting and provide:

- Farmer/SME PWA;
- enterprise integration API;
- EPCIS/file import;
- IoT ingestion;
- trace query and consumer portal;
- read model and analytics.

### 8.2 Identity and Keys

- each organization owns an independent identity and signing certificate;
- the platform stores only organization public keys;
- private keys are stored in enterprise connectors, secure device storage, or enterprise KMS/HSM;
- the platform must not sign business events on behalf of enterprises.

### 8.3 Consortium Ledger

Do not require every small farm to run a node. Instead, nodes should be operated by mutually independent stakeholder groups:

- producer cooperative;
- logistics/distributor consortium;
- retail consortium;
- independent auditor/industry body;
- platform operator.

At minimum, ensure:

- 3–5 independent node-operating organizations;
- ordering/validator nodes distributed across different organizations or cloud accounts;
- each organization independently manages its CA, MSP, and administrator keys;
- network rule changes require multi-organization approval;
- ledgers and backups are not all located under the same operator account.

### 8.4 Event Endorsement

Different event types should use different endorsement policies:

```text
Create batch       → producer signature
IoT observation    → device signature + device-owning organisation
Product handover   → sender + receiver
Certificate        → certificate issuer
Historical correction → original publisher + authorised reviewer
```

### 8.5 On-Chain and Off-Chain

The consortium ledger stores:

- event ID and version;
- event type;
- traceable identifiers;
- publisher identity;
- event/recorded time;
- upstream/downstream relationships;
- payload/document hash;
- signatures and visibility policy reference.

Store off-chain:

- complete EPCIS JSON/JSON-LD;
- raw IoT time-series;
- PDFs, images, and test files;
- personal information;
- commercially sensitive fields;
- search indexes, read models, and analytics data.

Optionally, periodically anchor the consortium ledger's Merkle root to a public blockchain as an independent external proof.

## 9. References

### GS1

- [EPCIS & CBV](https://www.gs1.org/standards/epcis)
- [EPCIS 2.0 Standard](https://ref.gs1.org/standards/epcis/2.0.0/)

### IBM

- [Using IBM Food Trust with App Connect](https://www.ibm.com/docs/en/app-connect/13.0.x?topic=applications-using-food-trust-app-connect-enterprise)
- [IBM Food Trust Connector API](https://www.ibm.com/docs/en/app-connect/12.0.x?topic=hga-food-trust)
- [Changing data already ingested into IBM Food Trust](https://www.ibm.com/support/pages/changing-data-already-ingested-ibm-food-trust)
- [IBM Blockchain Platform: managing organisations](https://www.ibm.com/docs/en/blockchain-platform/2.5.2?topic=console-managing-organizations)
- [IBM Support for Hyperledger Fabric deployment](https://www.ibm.com/docs/en/hlf-support/1.0.0?topic=started-about-support-hyperledger-fabric)
- [IBM Food Trust cloud service withdrawal](https://www.ibm.com/support/pages/cloud-service-program-withdrawal-ibm-supply-chain-intelligence-suite-and-ibm-blockchain-transparent-supply-and-select-parts-withdrawal-ibm-sterling-order-management)

### TE-FOOD

- [TE-FOOD Solution](https://te-food.com/solution/)
- [TE-FOOD Data Capture](https://te-food.com/solution/data-capture/)
- [TE-FOOD Data Processing](https://te-food.com/solution/data-processing/)
- [TE-FOOD Blockchain](https://te-food.com/solution/blockchain/)
- [TE-FOOD Business Card and TrustChain](https://te-food.com/business-card/)
- [TE-FOOD Implementation Guide](https://te-food.com/how-to-plan-a-food-traceability-implementation/)

### OriginTrail

- [OriginTrail Documentation](https://docs.origintrail.io/)
- [Knowledge Assets](https://github.com/OriginTrail/dkg/blob/main/docs/how-dkg-works/knowledge-assets.md)
- [OriginTrail Supply Chain Assets](https://origintrail.io/blog/from-data-to-assets-transforming-global-supply-chains-with-origintrail-decentralized-knowledge-graph)
- [OriginTrail Multichain Architecture](https://origintrail.io/technology/multichain)

### VeChain

- [VeChain Nodes](https://docs.vechain.org/core-concepts/nodes)
- [VeChainThor Consensus](https://docs.vechain.org/introduction-to-vechain/about-the-vechain-blockchain)
- [Running a VeChain Node](https://docs.vechain.org/how-to-run-a-node)
- [VeChain ToolChain Definition](https://cdn.vechain.com/Toolchain/VeChainWork/html/profile_cn.html)
- [VeChain Pro Service Terms](https://cdn.vechain.com/vechainthorwallet/docs/cn/protocol/vechainproprotocol.html)
