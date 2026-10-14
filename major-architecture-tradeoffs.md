# Major Architecture Trade-offs

> Purpose: Record only the decisions that materially define the system boundary or architecture. Detailed modelling rules and implementation choices remain in their respective design documents.

## 1. Traceability layer rather than a complete ERP

**Decision:** Build a cross-organisation traceability layer. Participant ERP, farm-management, WMS, TMS, MES and POS systems remain external.

**Alternative not selected:** A complete agricultural ERP covering production, inventory, warehousing, transport, sales, payment and accounting.

**Reason:** The distinctive problem is connecting assertions made by independent organisations into a verifiable provenance history. Reimplementing participant operations would broaden the system without improving that capability.

**Trade-off:** The platform depends on participant systems or its limited PWA to supply events and cannot guarantee the completeness or accuracy of their internal records.

## 2. Verifiable assertions rather than guaranteed physical truth

**Decision:** Define trustworthiness as the ability to establish attribution, authorisation, content integrity, correction history, conflicts and lineage validity.

**Alternative not selected:** Claim that blockchain or platform validation proves that a physical shipment, sensor reading or certificate is true.

**Reason:** Cryptography can show who made an assertion and whether it was changed, but cannot observe the physical world directly.

**Trade-off:** False but correctly signed source claims remain possible and require independent evidence, inspection and governance.

## 3. Event history rather than mutable batch state

**Decision:** Store accepted traceability events as append-only history and derive current batch, handover and provenance views from them.

**Alternative not selected:** Treat a mutable batch record or current-status field as the authoritative history.

**Reason:** Cross-organisation audit requires the original assertion, later contradictions and corrections to remain visible. Batch splitting, merging, containment and repeated handovers also form a graph rather than one linear state.

**Trade-off:** Queries require projections, replay and reconciliation instead of reading one authoritative current-state row.

## 4. Minimal ledger commitments rather than full on-chain storage

**Decision:** Keep canonical accepted events in PostgreSQL and place minimal event commitments and receipts on a permissioned consortium ledger.

**Alternative not selected:** Store complete events, documents and query state on the blockchain.

**Reason:** The ledger is needed for independent tamper evidence and shared governance, not as the primary operational database. Full on-chain storage would increase privacy, retention, query and governance costs.

**Trade-off:** Verification combines the PostgreSQL record with its ledger commitment, and ledger unavailability introduces an explicit pending state.

## 5. One PostgreSQL database rather than polyglot persistence

**Decision:** Use one PostgreSQL application database with logical separation between registry data, append-only events, projections and operational records.

**Alternative not selected:** Separate transactional, event, graph and read-model databases from the first release.

**Reason:** PostgreSQL provides transactions, relational constraints, JSON support and recursive lineage traversal while keeping operational and student-project complexity manageable. No measured workload currently justifies additional consistency boundaries.

**Trade-off:** The database is a shared operational dependency, and a specialised graph or read store may be introduced later if measured query complexity or workload requires it.

## 6. External ownership of non-essential artifacts rather than central data custody

**Decision:** Retain only the facts needed to validate traceability. Raw IoT telemetry, certificates, laboratory files and sensitive commercial documents remain in participant-controlled stores and are represented by references and content commitments.

**Alternative not selected:** Copy all participant data and evidence into platform-owned storage.

**Reason:** Central custody would expand privacy, retention and regulatory responsibility without being necessary for the core provenance graph.

**Trade-off:** External content may become unavailable. The platform can prove whether later-presented content matches its commitment, but cannot guarantee continued access.

## 7. Modular application rather than premature microservices

**Decision:** Implement the backend initially as one modular Traceability Application with explicit domain boundaries and ports.

**Alternative not selected:** Deploy commit, query, identity, governance and integration as independent microservices and databases immediately.

**Reason:** The domain boundaries matter, but the case provides no team-scale, deployment or workload evidence that justifies distributed transactions and additional operational failure modes.

**Trade-off:** Modules share a deployment and failure domain until evidence supports extracting a specific capability.

## 8. Trustworthiness rather than concurrency as the primary quality driver

**Decision:** Prioritise attribution, authorisation, tamper detection, visible conflict, correction history, lineage validity, evidence verification and governance independence.

**Alternative not selected:** Centre the architecture around speculative public-query concurrency, cache design or invented latency and throughput targets.

**Reason:** Query scaling can be handled using ordinary projections, caching and cloud scaling when demand is measured. Establishing credible history across mutually independent organisations is the difficult and architecture-defining problem.

**Trade-off:** The baseline does not promise unsupported percentile latency, throughput or availability figures. These become capacity-planning decisions once a workload and service-level agreement exist.

## 9. Core IoT evidence integration and optional advisory AI

**Decision:** Treat IoT evidence integration as core, while keeping AI/ML risk scoring asynchronous, advisory and optional.

**Alternative not selected:** Make an AI model part of event acceptance, ledger consensus or regulatory decision-making.

**Reason:** IoT evidence is explicitly required for traceability, but model output cannot become the source of historical or legal truth.

**Trade-off:** AI may enrich investigation and visualisation, but disabling it must not affect event submission, verification or provenance queries.
