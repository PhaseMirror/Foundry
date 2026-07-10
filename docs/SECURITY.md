# Security Policy

## Supported Versions

| Version | Supported          | Notes |
| ------- | ------------------ | ----- |
| 1.0.x-mvp | :white_check_mark: | Current MVP release |
| < 1.0.0 | :x: | Pre-release development |

## Reporting a Vulnerability

The Prime Materia Commons. takes security vulnerabilities seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security vulnerabilities by emailing:

📧 **security@phasemirror.com**

Include the following information in your report:

1. **Description**: A clear description of the vulnerability
2. **Impact**: The potential security impact (data exposure, privilege escalation, etc.)
3. **Reproduction Steps**: Detailed steps to reproduce the issue
4. **Affected Components**: Which parts of Phase Mirror are affected (mirror-dissonance, Terraform configs, API endpoints, etc.)
5. **Suggested Fix**: If you have one (optional but appreciated)

### What to Expect

- **Acknowledgment**: Within 48 hours of your report
- **Initial Assessment**: Within 7 business days
- **Resolution Timeline**: Dependent on severity (see below)
- **Credit**: Public acknowledgment in release notes (unless you prefer anonymity)

### Severity Classifications

| Severity | Response Time | Examples |
|----------|--------------|----------|
| **Critical** | 24-48 hours | RCE, authentication bypass, data exfiltration |
| **High** | 7 days | Privilege escalation, sensitive data exposure |
| **Medium** | 30 days | Information disclosure, CSRF |
| **Low** | 90 days | Minor information leaks, best practice violations |

## Security Architecture

### Threat Model

Phase Mirror operates as an Agentic AI Governance module that processes:

- **Governance Policies**: Organizational constraints and compliance rules
- **Dissonance Signals**: Detected contradictions between stated policy and observed behavior
- **Fingerprint Data**: Anonymized patterns for false-positive calibration
- **Consent Records**: User authorization for AI agent actions

### Security Controls

#### Data Protection
- **Encryption at Rest**: AES-256 for stored fingerprints and consent records
- **Encryption in Transit**: TLS 1.3 required for all API communications
- **Data Minimization**: Fingerprints use k-anonymity (k≥5) and differential privacy

#### Access Control
- **Authentication**: OAuth 2.0 / OIDC for API access
- **Authorization**: RBAC with principle of least privilege
- **Audit Logging**: All governance decisions are logged with tamper-evident hashes

#### Infrastructure Security
- **Terraform State**: Encrypted with customer-managed keys
- **Network Isolation**: Private subnets with explicit egress rules
- **Secret Management**: Integration with AWS Secrets Manager / HashiCorp Vault

### Known Security Boundaries

Phase Mirror's security model explicitly acknowledges:

1. **Trust Boundary**: The FP Calibration Service trusts input from authenticated governance sources
2. **Blast Radius**: Circuit breaker patterns limit cascading failures to 60-second windows
3. **Data Residency**: Fingerprint data may cross regional boundaries unless explicitly configured

## Security Best Practices for Deployers

### Infrastructure

```hcl
# Enforce encryption in Terraform configurations
terraform {
  backend "s3" {
    encrypt = true
    # Use customer-managed KMS key
    kms_key_id = "alias/phase-mirror-state"
  }
}
# Recommended security headers
security:
  cors:
    allowed_origins: ["https://your-domain.com"]
  rate_limiting:
    requests_per_minute: 100
  headers:
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    Content-Security-Policy: "default-src 'self'"

<!-- LawfulRecursionVersion:1.0 -->
