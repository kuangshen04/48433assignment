# 1. Project Context

An agricultural product moves through independent businesses, each keeping its own record of what it received,
did and passed on. Nothing joins those records: a regulator reconstructing a recall asks each business in turn
and gets a different identifier scheme, a different time zone and a different idea of "batch", so the answer
arrives in weeks while the product is still on shelves. Three things are missing — a shared, attributable
record; an affordable way in for small producers; and a reason to trust whoever hosts the record.

## 1.1 Objectives, stakeholders, risks and constraints

The system is a cross-organisation traceability layer, not an ERP: it provides only what cannot be done inside
one organisation.

| ID | Objective |
|---|---|
| O1 | Any participant can publish an attributable claim at low cost, including offline |
| O2 | Confirmed history is tamper-evident to parties who distrust the operator |
| O3 | A regulator establishes incident scope quickly and defensibly |
| O4 | Consumers see a truthful public view |
| O5 | Commercial detail and private evidence stay out of the shared record |
| O6 | A small team can operate the pilot |
| O7 | Device evidence is integrated without becoming a device platform |
| O8 | Regulatory screening is a capability, with ML as an option |

**Not objectives**, because they shape the design as much as the objectives do: proving that goods physically
exist, adjudicating conflicting claims, executing recalls, pricing or settling transactions, and replacing
participants' ERP, WMS or quality systems.

| ID | Stakeholder | What they need |
|---|---|---|
| S1 | Producer, grower, packer | Low-cost offline capture; signing without a corporate PKI |
| S2 | Processor | Transformation claims with quantities; no imposed mass-balance verdict |
| S3 | Distributor, cold chain | Two-sided handover; summaries, not raw telemetry |
| S4 | Retailer | Fast, conservative recall scope; a cacheable public view |
| S5 | Consumer | QR entry; "confirmed", "pending" and "no record" kept distinct |
| S6 | Regulator officer | Read access, case-scoped evidence, signed findings, audit trail |
| S7 | Regulator analytics | Its own runtime and rules; minimised data; private findings |
| S8 | Consortium governance | Registries and dual control over membership and keys |
| S9 | Platform operator | Low cost — and a design that does not require trust in them |
| S10 | Trustees: archive, KMS, recovery | Minimal, verifiable obligations |
| S11 | Auditors, courts, insurers | Inclusion and consistency proofs; replayable derivation |
| S12 | IoT vendors | A device interface that keeps raw telemetry private |

| ID | Risk | ID | Constraint |
|---|---|---|---|
| R1 | No real consortium exists to operate validators | C1 | The brief requires a blockchain |
| R2 | The operator becomes the single point of trust | C2 | Australian and NSW food, privacy and records law applies |
| R3 | Evidence is not defensible in a legal process | C3 | Participants' existing systems must interoperate |
| R4 | Smallholders are excluded, leaving holes where it matters | C4 | Rural connectivity is intermittent |
| R5 | An immutable log breaches privacy obligations | C5 | Pilot scale: 200 organisations, 10 000 events/day |
| R6 | Scope creeps into ERP, inventory or adjudication | C6 | A student team, one semester, no procurement |
| R7 | Blockchain cost and latency make it impractical | C7 | The report is bounded (5 000 words, 3-page glossary) |
| R8 | Regulatory analytics over-reach | C8 | No production credentials, no real participants |
| R9 | Vendor or chain lock-in | | |
| R10 | False or collusive claims, stated as a non-guarantee | | |

## 1.2 Why these are relevant to the architecture

The test for inclusion was whether removing an item would change a structural decision. Three clusters pass it.

**S1, S4 and C4 force an integration tier.** If every participant were a large manufacturer, an ERP integration
and a corporate signing key would do. Because the smallest tier must also publish, the design needs a
browser-first capture path, a durable offline queue, a custody mode whose key never leaves a device, and
client-generated identifiers — a different integration architecture, not a different screen.

**S6 and S7 force a boundary that would otherwise be invisible.** Analytics could run cheaply inside the
platform's account, which would make the operator the party that can read every rule and finding. Placing it in
the regulator's own account is what creates the two control domains, the signed cross-tenant messages, and the
obligation to model analytics at container, component and code level.

**S9 is the stakeholder whose interest the design is allowed to frustrate.** Its interest in low cost is served;
its interest in unilateral control is not — which is the source of the external archive, the non-platform key
holder and a verification path that does not need the platform's cooperation.

Two risk pairs then decide the shape. **R1 and R3** eliminate the otherwise attractive permissioned ledger: it
would satisfy the evidentiary requirement elegantly, but it needs genuinely independent validators, which this
project does not have. **C1 and C2** are in tension — a public chain is mandatory, and regulated personal data
must remain correctable — and the resolution (chain holds commitments only, plaintext encrypted off-chain,
personal data in the mutable layer) is constraint-driven rather than a preference.

## 1.3 Considered and excluded

An architecture is defined as much by what it refuses to serve. Each item below is plausible for agricultural
traceability and is out of scope because it would change the system's category or because its need is already
satisfied indirectly.

| Excluded | Why it is out of scope |
|---|---|
| Banks and insurers | Their need is financial risk assessment, which pulls pricing, contracts and settlement into scope; the design keeps commercial documents out of the record |
| Customs and biosecurity | The pilot is one domestic jurisdiction; a border authority adds a second legal regime and residency model before the basic chain is proven |
| Consumers as data producers | Serves marketing, not food safety, and creates personal data that conflicts with the immutable-record constraint |
| Certification bodies | Their certificates can enter as private evidence attached by the certified organisation; they need not become identities in the architecture |
| Recycling and circular-economy operators | Different regulatory regime and different event semantics would widen the event model before it is validated |
| Marketing, growth and BI teams | Served, if at all, by the Insights module within its boundary; not allowed to shape the architecture or rank participants |
| Active-active multi-region | The availability target is met by one region plus cross-failure-domain copies; active-active multiplies cost and consistency complexity |
| On-premises or air-gapped deployment | Incompatible with a public chain and with the multi-party, low-operations model |

Excluded risks are nation-state adversaries, build-pipeline attacks and quantum cryptanalysis (an organisational
security programme, not an architecture decision), collusion by a majority of participants and sensor tampering
(not solvable by record-keeping, and stated as non-guarantees instead of assumed away), operator bankruptcy as a
going-concern event, and fraudulent onboarding of a shell company (a named residual risk with documented
mitigation, not an eliminated one). Native mobile applications per platform and a contracted archive operator at
launch are excluded as delivery choices: the PWA covers the requirement, and the design defines the holder's
eligibility condition rather than naming a supplier.
