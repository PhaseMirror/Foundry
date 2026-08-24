# Helix‑Core Cloud Usage and Migration Plan
(Development Credits, Data Ethics, and Long‑Term Architecture)

## 1. Context and Intent
Helix‑Core is being developed as an open‑source Constitutional AI framework focused on governance, verifiable sovereignty, and self‑custody of data, not as a hosted retail AI assistant or corporate agent service. Its long‑term architecture assumes self‑hosted or user‑controlled models, with cloud providers used only as temporary development scaffolding during early habitat bring‑up.

During this initial phase, limited cloud resources have been used to accelerate prototyping and hardening of GOOSE‑CORE and associated Civic Firmware, with a clear plan to exit cloud inference in favour of locally hosted models.

## 2. Current Cloud Usage
A single major cloud provider (Google Cloud) has been used under a one‑time promotional credit (approximately CAD$400) to support:

*   Initial GOOSE‑CORE spin‑up and experimentation.
*   Backup search / inference during early development and debugging.

Roughly 85% of that credit has been consumed over the most recent development period, primarily for:

*   Test runs of constitutional habitat behaviour.
*   Validation of ledger and permission mechanisms under realistic load.

No large‑scale scraping, continuous crawling, or bulk data harvesting is performed. External calls are limited to:

*   Targeted search / inference operations needed for GOOSE‑CORE’s development and testing.
*   Normal, documented use of cloud APIs as intended by the provider.

In other words, cloud resources are being used as development infrastructure, not as a production‑grade inference backend for end‑users.

## 3. Data and Policy Posture
The following principles guide cloud usage:

*   **No scraping:** The system does not run automated scraping pipelines; it relies on standard, supported API calls within documented limits, and does not attempt to circumvent rate limits or access restrictions.
*   **Good‑faith policy compliance:** Provider terms and acceptable‑use policies are checked periodically. When changes are identified, Helix‑Core’s usage patterns are reviewed, and adjustments are made as needed to avoid competitive or prohibited use.
*   **Non‑competition stance:** Helix AI Innovations does not intend to operate a retail AI assistant, chatbot product, or managed corporate agent that competes directly with cloud providers’ own AI offerings. Helix‑Core is positioned as:
    *   Open‑source governance infrastructure (constitutional grammar, Civic Firmware, SSI‑aligned vaults, ledger tooling).
    *   Optional, narrowly scoped services such as Merkle‑to‑Bitcoin anchoring and audits, which sit at the verification and compliance layer, not at the end‑user AI service layer.
*   **Transparency of AI assistance:** When external AI systems contribute to design or documentation, this is acknowledged in governance/hardening documents, while retaining clear ownership of Helix‑Core as an independent, open‑source project.

## 4. Migration Plan to Local Models
Once the current development and hardening cycle is complete, the intended architecture is:

*   **Primary inference on local Helix server models:**
    *   Models hosted on hardware controlled by Helix or by deploying communities/organizations.
    *   Cloud providers become optional, pluggable backends rather than a default dependency.
*   **Cloud usage reduced to optional extensions:**
    *   Burst capacity or specialized models, when explicitly configured by an operator.
    *   Never a mandatory component for running the constitutional habitat.
*   **Configuration defaults:**
    *   Default deployments of HELIX‑CORE will ship configured to use local or user‑provided endpoints.
    *   Any cloud integration will be clearly marked as optional and off by default, requiring deliberate operator choice.

## 5. Summary
In this early phase, Helix‑Core uses limited cloud credits to accelerate development of a self‑governing, self‑hostable AI habitat. The project:

*   Avoids scraping and abusive data practices.
*   Makes reasonable, documented efforts to comply with provider policies.
*   Does not aim to compete with retail AI agent products.
*   Has a clear plan to migrate core inference to local models, leaving cloud services as optional, bounded integrations.

This approach aligns Helix‑Core’s development with its core mission: human‑first governance, verifiable sovereignty, and infrastructure that communities can ultimately run on their own terms.

