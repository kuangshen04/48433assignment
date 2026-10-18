# 1. Project context

An agricultural product moves through independent businesses, each keeping its own record of what it received, did
and passed on. Nothing joins those records: a regulator reconstructing a recall asks each business in turn and gets a
different identifier scheme, time zone and idea of "batch", so the answer arrives in weeks while the product is on
shelves. What is missing is a shared, attributable record a small producer can join cheaply and a regulator can trust
without trusting its host.

## 1.1 Who it serves, what it covers, and why that changes the design — rubric 1.1–1.3

**Objectives.** Publish a claim cheaply, including offline (O1); make confirmed history tamper-evident to parties who
distrust the operator (O2); let a regulator scope an incident quickly and defensibly (O3); give consumers a truthful
view (O4); keep commercial detail and private evidence off the record (O5); run on a small team (O6); take device
evidence without becoming a device platform (O7); screen regulatory risk with ML optional (O8).

**Counterparties.** Six parties exchange claims through the system; each constrains it.

| ID | Party | What they need |
|---|---|---|
| S1 | Producer, grower, packer | Low-cost offline capture; signing without a corporate PKI |
| S2 | Processor | Transformation claims with quantities; no imposed mass-balance verdict |
| S3 | Distributor, cold chain | Two-sided handover; summaries, not raw telemetry |
| S4 | Retailer | Fast, conservative recall scope; a cacheable public view |
| S5 | Consumer | QR entry; "confirmed", "pending" and "no record" kept distinct |
| S6 | Regulator officer | Read access, case-scoped evidence, signed findings, audit trail |

The rest are parties to the design, not users of it: analytics (S7), governance (S8), the operator (S9), archive and
key trustees (S10), courts and auditors (S11), device vendors (S12) — each surfacing once, where its interest bites
(§2.3, §4.5).

**Scope.** Six boundaries are easy to confuse, and each is deliberate.

| Mistaken for | It is instead |
|---|---|
| An ERP, WMS or quality system | A record of claims; participants keep their own systems |
| An adjudicator | It stores competing claims side by side and never picks one |
| A recall executor | It establishes scope and evidence; the businesses execute the recall |
| A device platform | Devices are organisation delegations publishing summaries |
| A payment or settlement system | No money moves; pricing and settlement are out of scope |
| A certification or customs system | Certificates enter as private evidence; a border adds a legal regime |

Consumers as data producers, recycling operators and marketing or BI are outside for the same reason: each would
change the system's category, or it is met inside the Insights module.

**Failure modes.** Five shape the architecture: no consortium exists to operate validators, so a permissioned ledger
cannot be built (R1, R3); the operator becomes the single point of trust unless history verifies from outside it
(R2); evidence may not survive a legal process (R3); an immutable log may breach privacy law (R5); scope creeps into
ERP, inventory or adjudication (R6). Two are stated, not solved: smallholders left out (R4) and false or collusive
claims (R10). Not attempted: state-level adversaries, build-pipeline and quantum attacks (a security programme, not
an architecture decision), bankruptcy, and fraudulent onboarding (a named residual risk).

**Constraints.** A blockchain is mandatory (C1); Australian and NSW law applies (C2); participants' systems must
interoperate (C3); connectivity is intermittent (C4); 200 organisations and 10 000 events/day (C5); a small operating
team (C6); no production access (C7). Delivery follows: one region, cloud only, PWA only, no contracted archive
operator at launch.

**Why these change the design.** The stakeholders fall into three clusters; device vendors (S12) are argued in §4.6.

**Participants (S1–S5) with C4 force an integration tier.** With only large manufacturers, an ERP integration and a
corporate key would do; because the smallest tier must publish, capture is browser-first, the queue survives offline,
the key never leaves the device and identifiers are client-generated.

**The regulator (S6, S7) forces a boundary that would otherwise be invisible.** Analytics inside the platform's
account would let the operator read every rule and finding; it runs in the regulator's own account instead.

**Trust infrastructure (S8–S11) forces the record out of the operator's hands.** Cost is served, unilateral control
is not — hence the external archive, the non-platform key holder and verification that needs no cooperation.

**R1 and R3** eliminate the permissioned ledger, which would fit the evidence requirement but needs validators this
project does not have. **C1 and C2** are in tension — a public chain is mandatory, personal data must stay
correctable — and the resolution follows: commitments on chain, ciphertext off it, personal data in the mutable
layer.

