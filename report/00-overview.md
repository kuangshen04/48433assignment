# 0. How it works — read this page first

The system is a shared, attributable record of what happened to a product as it moves between organisations. It
does not replace anyone's ERP; it records claims and makes them checkable.

**Writing a claim** (Figures 4 and 12). A participant signs an EPCIS event and submits it with a
client-generated identifier. The platform validates the profile and the signature, then persists the event and
enqueues an archive intent in one transaction. Workers encrypt the payload under a fresh data key, wrapped by a
consortium key held outside the platform, write the ciphertext to an archive in another control domain, and
record the holder's signature over the stored bytes. That acknowledgement is what allows a receipt to be issued.
Every thirty minutes the relayer commits a Merkle root over the receipted events to a public chain. An event
becomes `CONFIRMED` only when both have happened: an outside holder has signed for the bytes, and the root is
final.

**Reading a claim** (Figure 2). Every read goes through one entrance, `QueryPort`, which enforces scope,
non-collapsing and watermark. Lineage is derived once into an indexed table, so a recall traversal is a bounded
recursive query rather than a walk through the archive. Consumers never reach the application: they read
versioned snapshots from a CDN, which is why a media-driven burst costs the origin almost nothing.

**Who owns what.** Four accounts: the platform, the trustee (archive and keys), the regulator's analytics
workspace, and the regulator's evidence mirror. The operator can read consortium plaintext — an authorised
capability, not an accident — but it cannot read private evidence, forge a holder's signature, or rewrite a
confirmed batch without detection.

**What it deliberately does not do.** Decide whether a claim is true, execute recalls, or hold raw telemetry.
