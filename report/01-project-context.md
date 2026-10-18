# 1. Project Context

*Draft — untrimmed. Section 1 rows: 1.1 context, 1.2 relevance, 1.3 exclusions.*

## 1.1 Problem, objectives, stakeholders, risks and constraints

### 1.1.1 The problem

An agricultural product moves through a chain of independent businesses — grower, packer, processor,
distributor, retailer — and each one keeps its own records of what it received, what it did, and what it
passed on. Nothing joins those records together. When a food safety incident occurs, a regulator has to
reconstruct the chain by asking each business in turn for its paperwork, and every one of them answers with
a different identifier scheme, a different time zone, and a different idea of what a "batch" is. The result
is that the answer to "where did this come from and where did it go" arrives in weeks, while the product is
still on shelves.

Three things are missing, and they are missing for different reasons:

1. **No shared, attributable record.** Businesses can produce evidence about their own stage, but there is
   no place where a claim made by one organisation can be compared with a claim made by another, with both
   attributions intact.
2. **No affordable way in for small producers.** Enterprise traceability suites are priced and shaped for
   large manufacturers. A farm with two employees and intermittent mobile coverage cannot adopt one, so the
   tier that the regulator most needs to see is the tier that is least instrumented.
3. **No reason to trust the record keeper.** Any shared record has to be hosted by somebody. If that
   somebody can silently rewrite or delete the history, or can decide unilaterally who may read it, the
   record is only as trustworthy as the host — which is exactly the weakness it was supposed to fix.

### 1.1.2 Objectives of the proposed solution

The system is a **cross-organisation traceability layer**, not an ERP and not an inventory system. It
interoperates with the systems participants already run and provides only what cannot be done inside a
single organisation.

| ID | Objective | Success looks like |
|---|---|---|
| O1 | Let any participant publish an attributable claim at low cost, including offline | A smallholder can submit a valid, signed event from a phone or a gateway without buying enterprise software |
| O2 | Make confirmed history tamper-evident to parties who do not trust the operator | A member, auditor or regulator can verify that a record existed at a point in time and has not been replaced, without holding the plaintext |
| O3 | Let a regulator establish the affected scope of an incident quickly and defensibly | A recall scope is produced from confirmed claims in minutes, with every edge traceable to its publisher |
| O4 | Give consumers a truthful public view | A scan returns an allowlisted, versioned projection that never claims more than the evidence supports |
| O5 | Keep commercial detail and private evidence out of the shared record | Raw telemetry, contracts and lab reports remain with their owners; the shared record holds only a commitment |
| O6 | Stay operable by a small team at pilot scale | One modular application, one managed database, no bespoke infrastructure fleet |
| O7 | Integrate device evidence without becoming a device platform | A sensor summary can be required by a profile and checked against private raw data; the platform holds no raw telemetry |
| O8 | Make regulatory screening a capability, with ML as an option | Rules are owned, signed and versioned by the regulator; disabling analytics degrades advice, never traceability |

**Explicit non-objectives** (stated here because they drive the architecture as much as the objectives do):
the system does not prove that goods physically exist, does not adjudicate which of two conflicting claims
is true, does not execute recalls, does not price or settle transactions, and does not replace participants'
ERP, WMS or quality systems.

### 1.1.3 Stakeholders and their interests

Stakeholders are numbered `S1`–`S12` and referenced by these identifiers throughout Sections 2–5.

| ID | Stakeholder | Primary interest | What they need from the architecture |
|---|---|---|---|
| S1 | Producer — grower, packer, smallholder or cooperative | Get paid, avoid unfair blame, minimal admin | Low-cost capture (PWA or existing system), offline queue, signing without a corporate PKI, ability to attach private evidence without publishing it |
| S2 | Processor / manufacturer | Defend transformation and yield decisions; prove inputs | Transformation claims between lots, with quantities and units; no platform-imposed mass-balance verdict |
| S3 | Distributor / logistics, incl. cold chain | Prove custody and condition on handover; limit liability | Two-sided handover claims with a shared pairing key; sensor summaries rather than raw telemetry |
| S4 | Retailer / food business | Execute recalls precisely, protect brand, meet duties | Fast, conservative recall scope; a public projection that is accurate and cacheable |
| S5 | Consumer | Know what they are buying; be warned quickly | QR entry to a versioned public view; clear separation of "confirmed", "pending" and "no record" |
| S6 | Regulator — statutory officers | Investigate and act on evidence that survives legal challenge | Read access to the shared trace, case-scoped access to private evidence, signed findings and notices, defensible audit trail |
| S7 | Regulator — analytics function | Screen the whole network without leaking method | Its own runtime and rule ownership; minimised datasets; results that are private by default |
| S8 | Consortium governance / membership authority | Control who participates; contain liability | Registries for organisations, keys and delegations; dual control over high-impact changes |
| S9 | Platform operator and its staff | Run a viable service at low cost | A deployable modular application, one database, managed services; **and a design that does not require participants to trust them** |
| S10 | Independent trustees — archive holder, KMS trustee, recovery authority | Discharge a duty of independence | Verifiable, minimal obligations: sign for stored bytes, hold keys, be able to recover without the platform |
| S11 | Third-party verifiers — auditors, courts, insurers | Check a claim after the fact | Inclusion and consistency proofs; signed declarations; replayable derivation rules |
| S12 | IoT vendors and device providers | Sell and support devices; keep telemetry | A defined interface: device identity, summary generation, raw data staying private |

### 1.1.4 Major project risks

| ID | Risk | Why it threatens the project | Architectural response |
|---|---|---|---|
| R1 | **No real consortium exists.** The brief implies multiple organisations, but no governing body, budget or volunteer operators are given | Any design that depends on many independent node operators cannot be delivered in this project | Do not build a permissioned ledger with validator membership; anchor commitments on a public chain and keep the number of independent parties to the few that are unavoidable (archive holder, KMS trustee) |
| R2 | **The platform operator becomes the single point of trust** | If the operator holds the only copy, the only keys and the only verification path, the blockchain adds nothing | Require a copy outside the operator's control domain before an event counts as confirmed; hold the consortium key outside the operator's account; make verification possible without plaintext |
| R3 | **Evidence is not defensible in a legal or regulatory process** | A record that cannot show who published it, when, and that it was not altered is not evidence | Signed events, signed archive acknowledgements, append-only correction, Merkle inclusion proofs, explicit statement of what each gate does and does not prove |
| R4 | **Smallholders are excluded, so the chain has holes exactly where it matters** | Coverage gaps defeat the purpose | PWA and gateway paths, offline queue, device-bound signing where the device supports it, flat read scope in the pilot |
| R5 | **Privacy obligations are breached by an immutable record** | Personal information written into an immutable log cannot be corrected or deleted on request | No natural-person references in the immutable trace; personal data only in the mutable operational layer; private evidence kept off-platform |
| R6 | **Scope creep into ERP, inventory or compliance adjudication** | The project becomes undeliverable and the platform becomes an unauthorised decision-maker | Explicit non-objectives; the core records assertions and refuses to adjudicate; business semantics sit in modules, not in the core |
| R7 | **Cost and latency of blockchain use make the system impractical** | Per-event transactions and confirmation waits would dominate cost and user experience | Deterministic Merkle batching on a fixed window; only commitments on chain |
| R8 | **Regulator analytics over-reach** | Automated scoring or enforcement would make the platform an adjudicator and destroy participant trust | Analytics sits in the regulator's own account, findings are private by default, only signed advisories reach participants, and no automated enforcement |
| R9 | **Vendor or chain lock-in** | A pilot that cannot move chains or providers is a pilot that cannot be procured | Versioned canonicalisation, chain-agnostic Merkle leaves, migration metadata, portable archive format |
| R10 | **False or collusive claims** | Participants can conspire to misdescribe reality | Out of the guarantee scope by construction; stated explicitly so that no stakeholder reads the record as proof of physical truth |

### 1.1.5 Constraints

| ID | Constraint | Consequence |
|---|---|---|
| C1 | The brief requires a blockchain-based solution | A public-chain anchoring mechanism is mandatory, and must carry a real responsibility rather than a decorative one |
| C2 | Australian and NSW food, privacy and records obligations apply to the pilot | Residency in Australian regions; privacy-by-design; retention and legal hold modelling |
| C3 | Products and events must interoperate with participants' existing systems | Standard event model (EPCIS 2.0 / CBV) rather than a bespoke schema |
| C4 | Rural connectivity is intermittent | Durable offline queues and client-generated identifiers |
| C5 | Pilot scale, not national scale | 200 organisations, 10 000 events/day design point; no premature distribution |
| C6 | A student team, one semester, no procurement | Managed services, no bespoke infrastructure, no contracted archive operator at launch |
| C7 | The report is bounded (5 000 words, C4 views, 3-page glossary) | Scope must be defensible at the level of containers and components, not exhaustive implementation |
| C8 | No production credentials, no real participants | Deployment and parameters must be stated as a reference configuration with explicit assumptions |

## 1.2 Why these stakeholders, risks and constraints are relevant to the architecture

The tables above are not background colour; each entry changes a structural decision, and the test for
inclusion was whether removing it would change the design. The table below states that test explicitly; the
paragraphs after it group the ones that interact.

| Item | Architectural consequence if it were not there, or if it were treated as a lesser concern |
|---|---|
| S1 producer | No offline queue, no device-bound signing, no low-cost capture path; the pilot would instrument only the large tiers |
| S2 processor | No transformation edges with quantities and units; recall could not cross a processing step |
| S3 distributor | No two-sided handover claims; custody and cold-chain disputes would remain unrecorded |
| S4 retailer | No recall execution path and no public projection requirement; freshness targets would be unmotivated |
| S5 consumer | No public snapshot container and no CDN; the "no record" versus "not affected" distinction would not exist |
| S6 regulator officer | No investigation entrance, no case-scoped evidence access, no signed assessment as the only route to a verdict |
| S7 regulator analytics | Analytics would silently live in the platform's account, and the whole two-domain structure would disappear |
| S8 governance | No registries, no dual control, no admission strength; membership would become an implicit operator decision |
| S9 operator | Without naming the operator as a *constrained* party, there is no reason for an external archive or a non-platform key holder |
| S10 trustees | No eligibility condition for the archive holder, no recovery identity outside the platform, so RPO 0 would be unverifiable |
| S11 verifiers | No inclusion or consistency proofs, no replayable derivation, and therefore no defensible audit trail |
| S12 IoT vendors | No device identity model, no summary-versus-telemetry boundary; raw sensor data would leak into the record |
| R1 no consortium | Would have led to a permissioned ledger with a validator set that cannot be populated |
| R2 operator as trust anchor | Would have produced a database with a hash column, not a verifiable record |
| R3 evidence not defensible | Would have removed signed archive acknowledgements and the explicit per-gate guarantees |
| R4 smallholder exclusion | Would have removed the PWA and offline paths, and with them the coverage argument |
| R5 privacy breach by design | Would have allowed natural-person identifiers into an immutable log |
| R6 scope creep | Would have produced an ERP rather than a traceability layer, and a platform that adjudicates |
| R7 blockchain cost | Would have produced per-event transactions and unacceptable confirmation delays |
| R8 regulator over-reach | Would have produced automated scoring and enforcement from analytics |
| R9 lock-in | Would have produced a chain-specific leaf format and an archive format with no exit |
| R10 false claims | Without stating it as a non-guarantee, the record would be read as proof of physical truth |
| C1 blockchain required | No public anchoring, and no reason to design proof formats at all |
| C2 food, privacy and records law | No residency, retention or privacy-by-design constraints; personal data would enter the shared record |
| C3 interoperability | A bespoke event model, with a lossy mapping at every participant boundary |
| C4 rural connectivity | No client-generated identifiers, no durable queue, no idempotency requirement |
| C5 pilot scale | Premature distribution: brokers, graph databases, multi-region active-active |
| C6 student team, no procurement | A design depending on a contracted archive operator or a validator consortium could not be delivered |
| C7 report bounds | The architecture would be documented at code level rather than at container and component level |
| C8 no production credentials | Deployment would be asserted as fact rather than stated as a reference configuration with assumptions |

**S1, S4 and C4 together force an entire integration tier.** If every participant were a large manufacturer,
the platform could assume an ERP integration and a corporate signing key. Because the smallest tier must
also be able to publish, the design needs a browser-first capture path, a durable offline queue, a custody
mode whose private key never leaves a device, and client-generated identifiers so that offline work is
idempotent. That is a different integration architecture, not a different screen.

**S6 and S7 force a boundary that would otherwise be invisible.** It would be cheaper to run regulatory
analytics inside the platform's own account. That choice would also make the platform operator the party that
can read every finding and every rule, which contradicts R2 and R8. Placing analytics in the regulator's own
cloud account is what creates the two-control-domain structure, the signed cross-tenant messages, and the
obligation to give the analytics subsystem its own container, component and code views.

**S9 is the stakeholder whose interest the design is allowed to frustrate.** Every other stakeholder is
served directly. The operator's interest in low cost and simple operations is served, but its interest in
convenient, unilateral control is deliberately not. That asymmetry is the source of the requirement for an
external archive, a non-platform key holder, and a verification path that does not need the platform's
cooperation.

**S11 forces the record to be checkable after the fact.** If the only consumer of the record were the
participant who wrote it, a database would do. Because an auditor or a court may need to check a claim years
later, the design must publish inclusion and consistency proofs, keep signed declarations rather than
derived states, and make edge derivation a published, replayable function.

**R1 and R3 are the two risks that eliminated an otherwise attractive architecture.** A permissioned
consortium ledger would satisfy R3 elegantly, but it requires many genuinely independent operators, which R1
says do not exist for this project. Choosing public-chain commitments plus a small number of independent
custodians is a direct response to that pair of risks, and it is why the design spends its complexity budget
on proof formats rather than on consensus.

**C1 and C2 are in tension, and the tension is architectural.** C1 requires a public chain; C2 forbids
putting regulated personal information where it cannot be corrected or deleted. The resolution — chain holds
commitments only, plaintext stays encrypted off-chain, personal data stays in the mutable layer — is a
constraint-driven decision, not a preference.

## 1.3 Stakeholders, risks and constraints considered and excluded

Exclusions are recorded because an architecture is defined as much by what it refuses to serve. In each case
the excluded item is plausible for an agricultural traceability system; it is out of scope for the pilot
either because it would change the system's category, or because its needs are already satisfied indirectly.

### 1.3.1 Excluded stakeholders

| Excluded | Why it was considered | Why it is out of scope |
|---|---|---|
| Banks, insurers and lenders | They would pay for verified supply chain data, and traceability is a natural credit signal | Their need is financial risk assessment, which would pull pricing, contracts and settlement into scope. The design deliberately keeps commercial documents (purchase order, invoice, price) out of the shared record; adding lenders as a consumer would force them back in |
| Customs and biosecurity agencies | Cross-border movements are a real traceability use case | The pilot is a single domestic jurisdiction. Adding a border authority introduces a second legal regime, different data-sharing instruments and export-oriented residency rules, all before the basic chain is proven |
| Consumers as data producers (reviews, ratings, preferences) | Consumer engagement is often bundled into traceability apps | It serves marketing, not food safety, and it creates personal data that conflicts with the immutable-record constraint. Consumers are modelled only as readers of a public projection |
| Certification and accreditation bodies (e.g. organic certifiers) | Their certificates are exactly the kind of evidence a buyer wants | They are not needed to prove the core mechanism. Their certificates can enter the system as private evidence attached by the certified organisation, without the certifier becoming an identity in the architecture |
| Recycling, waste and circular-economy operators | Same physical objects, later lifecycle | Different regulatory regime and different event semantics (end-of-life rather than custody). Including them would widen the event model before it is validated |
| Platform marketing, growth and BI teams | They exist in any SaaS business | Their interest (aggregate behaviour analytics, campaign attribution) is served, if at all, by the Insights module within its stated boundary. It is not allowed to shape the architecture, and it may not produce rankings of participants |

### 1.3.2 Excluded risks

| Excluded risk | Why it is out of scope |
|---|---|
| Nation-state adversaries, supply-chain attacks on build infrastructure, quantum cryptanalysis | Real, but they require an organisational security programme rather than an architecture decision. The design states its cryptographic assumptions and leaves algorithm agility to key and version management |
| Collusion among a majority of participants to assert a false reality | Not solvable by any record-keeping design. It is stated as an explicit non-guarantee instead of being quietly assumed away |
| Physical tampering with sensors, or a device reporting from the wrong location | The system captures signed assertions, not physical facts. Attestation can raise cost of attack but cannot establish truth |
| Platform operator bankruptcy or malicious shutdown as a going-concern event | Partly addressed (history is recoverable without the platform), but the commercial continuity of the service is out of architectural scope |
| Fraudulent onboarding of a shell company | Acknowledged as a residual risk with a documented mitigation (entity verification, sponsor, dual approval, read audit), not eliminated. The design does not claim to solve identity fraud |

### 1.3.3 Excluded constraints

| Excluded constraint | Why it is out of scope |
|---|---|
| On-premises or air-gapped deployment | Incompatible with a public chain and with the intended multi-party, low-ops deployment model |
| Active-active multi-region operation | The pilot's availability target is met by a single Australian region plus cross-failure-domain copies; multi-region active-active would multiply cost and consistency complexity for no pilot benefit |
| Native mobile applications on every platform | A progressive web application plus device-bound signing on capable devices covers the requirement; native apps per platform would add delivery cost without changing the architecture |
| A contracted, dedicated archive operator at launch | Desirable for independence, but it is a procurement dependency rather than an architectural one; the design defines the eligibility condition instead of naming a supplier |
| Full BFT consensus among participants | Rejected as an architecture (Section 5 revisits it as an alternative), because the independent operators it requires do not exist for this project |
