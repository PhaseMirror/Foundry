# Research: Analysis of Anthropic's 30-Day Retention Policy
**Date:** 2026-01-23
**Source:** Anthropic Policies & Terms of Service Update
**Subject:** The distinction between Policy-Based Retention and Architectural Blinding.

### 1. [FACT] The Policy Change
Anthropic has updated its Privacy Policy to a default data retention period of 30 days for user interactions.

### 2. [REASONED] The "Trust Us" Model (Policy-Based Governance)
- This is a corporate promise, a Service Level Agreement (SLA) for data deletion.
- The user cedes custody of their data to Anthropic for a 30-day period.
- The "Right to be Forgotten" is a service request fulfilled by the corporation on a fixed timeline.
- This model is designed to be compliant with regulations like GDPR.

### 3. [REASONED] The "Verify, Don't Trust" Model (Architecture-Based Governance)
- The HELIX-CORE model, via the Takiwātanga Vault and Permission Braid, is architectural, not policy-based.
- The user retains custody at all times. The AI is granted temporary, verifiable access.
- The "Right to be Forgotten" is an instantaneous, user-initiated state change (`"access_level": "DENY"`). It is mechanical blinding, not a deletion process.
- This model is designed for user sovereignty, not just regulatory compliance.

### 4. [CONCLUSION] A Philosophical Divide
Anthropic's update, while positive, reinforces a fundamental difference in philosophy. They are building a more ethical version of the existing custodial paradigm. We are building a new, non-custodial paradigm where sovereignty is a physical property of the substrate, not a corporate policy.
