use std::collections::HashMap;
use std::fmt::{Display, Formatter};

pub type Timestamp = u64;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Role {
    Patient,
    Proxy,
    Clinician,
    Auditor,
    SystemAdmin,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TlsState {
    pub min_version: &'static str,
    pub certificate_pinned: bool,
    pub hostname_verified: bool,
}

impl TlsState {
    pub fn is_secure(&self) -> bool {
        matches!(self.min_version, "1.2" | "1.3")
            && self.certificate_pinned
            && self.hostname_verified
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConsentRecord {
    pub consent_id: String,
    pub patient_id: String,
    pub proxy_id: String,
    pub scope: String,
    pub granted_at: Timestamp,
    pub expires_at: Timestamp,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProxyApproval {
    pub consent_id: String,
    pub approver_id: String,
    pub approved_at: Timestamp,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocumentInput {
    pub document_id: String,
    pub consent_id: String,
    pub proxy_id: String,
    pub content: String,
    pub synthetic_only: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredDocument {
    pub document_id: String,
    pub consent_id: String,
    pub proxy_id: String,
    pub content: String,
    pub stored_at: Timestamp,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuditEntry {
    pub timestamp: Timestamp,
    pub actor_role: Role,
    pub action: &'static str,
    pub success: bool,
    pub detail: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ProxyError {
    AccessDenied(&'static str),
    ConsentNotFound,
    ConsentExpired,
    ProxyNotApproved,
    DuplicateDocument,
    DocumentNotFound,
    TlsFailed,
    SyntheticDataRequired,
    AlreadyApproved,
}

impl Display for ProxyError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ProxyError::AccessDenied(action) => write!(f, "access denied for action: {action}"),
            ProxyError::ConsentNotFound => write!(f, "consent not found"),
            ProxyError::ConsentExpired => write!(f, "consent expired"),
            ProxyError::ProxyNotApproved => write!(f, "proxy not approved"),
            ProxyError::DuplicateDocument => write!(f, "document already exists"),
            ProxyError::DocumentNotFound => write!(f, "document not found"),
            ProxyError::TlsFailed => write!(f, "tls checks failed"),
            ProxyError::SyntheticDataRequired => write!(f, "synthetic data required"),
            ProxyError::AlreadyApproved => write!(f, "proxy already approved"),
        }
    }
}

impl std::error::Error for ProxyError {}

#[derive(Debug, Default)]
pub struct ArtifactProxyBundle {
    consents: HashMap<String, ConsentRecord>,
    approvals: HashMap<String, ProxyApproval>,
    documents: HashMap<String, StoredDocument>,
    audit_log: Vec<AuditEntry>,
}

impl ArtifactProxyBundle {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn capture_consent(
        &mut self,
        actor_role: Role,
        consent: ConsentRecord,
    ) -> Result<(), ProxyError> {
        let action = "capture_consent";
        let result = if !matches!(actor_role, Role::Patient | Role::SystemAdmin) {
            Err(ProxyError::AccessDenied(action))
        } else {
            self.consents.insert(consent.consent_id.clone(), consent);
            Ok(())
        };

        self.record_audit(0, actor_role, action, &result);
        result
    }

    pub fn approve_proxy(
        &mut self,
        actor_role: Role,
        consent_id: &str,
        approver_id: &str,
        approved_at: Timestamp,
        now: Timestamp,
    ) -> Result<(), ProxyError> {
        let action = "approve_proxy";
        let result = if !matches!(actor_role, Role::Clinician | Role::SystemAdmin) {
            Err(ProxyError::AccessDenied(action))
        } else if self.approvals.contains_key(consent_id) {
            Err(ProxyError::AlreadyApproved)
        } else {
            let consent = self.consents.get(consent_id).ok_or(ProxyError::ConsentNotFound)?;
            if consent.expires_at < now {
                Err(ProxyError::ConsentExpired)
            } else {
                self.approvals.insert(
                    consent_id.to_string(),
                    ProxyApproval {
                        consent_id: consent_id.to_string(),
                        approver_id: approver_id.to_string(),
                        approved_at,
                    },
                );
                Ok(())
            }
        };

        self.record_audit(approved_at, actor_role, action, &result);
        result
    }

    pub fn store_document(
        &mut self,
        actor_role: Role,
        tls: &TlsState,
        input: DocumentInput,
        stored_at: Timestamp,
        now: Timestamp,
    ) -> Result<(), ProxyError> {
        let action = "store_document";
        let result = if !matches!(actor_role, Role::Proxy | Role::SystemAdmin) {
            Err(ProxyError::AccessDenied(action))
        } else if !tls.is_secure() {
            Err(ProxyError::TlsFailed)
        } else if !input.synthetic_only || !input.content.to_ascii_lowercase().contains("synthetic") {
            Err(ProxyError::SyntheticDataRequired)
        } else if self.documents.contains_key(&input.document_id) {
            Err(ProxyError::DuplicateDocument)
        } else {
            let consent = self
                .consents
                .get(&input.consent_id)
                .ok_or(ProxyError::ConsentNotFound)?;
            if consent.proxy_id != input.proxy_id {
                Err(ProxyError::AccessDenied(action))
            } else if consent.expires_at < now {
                Err(ProxyError::ConsentExpired)
            } else if !self.approvals.contains_key(&input.consent_id) {
                Err(ProxyError::ProxyNotApproved)
            } else {
                self.documents.insert(
                    input.document_id.clone(),
                    StoredDocument {
                        document_id: input.document_id,
                        consent_id: input.consent_id,
                        proxy_id: input.proxy_id,
                        content: input.content,
                        stored_at,
                    },
                );
                Ok(())
            }
        };

        self.record_audit(stored_at, actor_role, action, &result);
        result
    }

    pub fn fetch_document(
        &mut self,
        actor_role: Role,
        document_id: &str,
        at: Timestamp,
    ) -> Result<StoredDocument, ProxyError> {
        let action = "fetch_document";

        if !matches!(
            actor_role,
            Role::Patient | Role::Proxy | Role::Clinician | Role::Auditor | Role::SystemAdmin
        ) {
            let result: Result<(), ProxyError> = Err(ProxyError::AccessDenied(action));
            self.record_audit(at, actor_role, action, &result);
            return Err(ProxyError::AccessDenied(action));
        }

        if !self.documents.contains_key(document_id) {
            let result: Result<(), ProxyError> = Err(ProxyError::DocumentNotFound);
            self.record_audit(at, actor_role, action, &result);
            return Err(ProxyError::DocumentNotFound);
        }

        let result = Ok(self.documents.get(document_id).expect("checked above").clone());
        let audit_result: Result<(), ProxyError> =
            result.as_ref().map(|_| ()).map_err(Clone::clone);
        self.record_audit(at, actor_role, action, &audit_result);
        result
    }

    pub fn audit_log(&self) -> &[AuditEntry] {
        &self.audit_log
    }

    pub fn consent_count(&self) -> usize {
        self.consents.len()
    }

    pub fn document_count(&self) -> usize {
        self.documents.len()
    }

    fn record_audit<T>(
        &mut self,
        timestamp: Timestamp,
        actor_role: Role,
        action: &'static str,
        result: &Result<T, ProxyError>,
    ) {
        let entry = AuditEntry {
            timestamp,
            actor_role,
            action,
            success: result.is_ok(),
            detail: match result {
                Ok(_) => "ok".to_string(),
                Err(err) => err.to_string(),
            },
        };
        self.audit_log.push(entry);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tls_must_be_secure() {
        let weak_tls = TlsState {
            min_version: "1.1",
            certificate_pinned: true,
            hostname_verified: true,
        };
        assert!(!weak_tls.is_secure());

        let strong_tls = TlsState {
            min_version: "1.3",
            certificate_pinned: true,
            hostname_verified: true,
        };
        assert!(strong_tls.is_secure());
    }

    #[test]
    fn role_based_capture_is_enforced() {
        let mut bundle = ArtifactProxyBundle::new();
        let consent = ConsentRecord {
            consent_id: "consent-synth-001".to_string(),
            patient_id: "patient-synth-001".to_string(),
            proxy_id: "proxy-synth-001".to_string(),
            scope: "synthetic-lab-summary".to_string(),
            granted_at: 10,
            expires_at: 500,
        };

        let denied = bundle.capture_consent(Role::Proxy, consent.clone());
        assert_eq!(denied, Err(ProxyError::AccessDenied("capture_consent")));

        let ok = bundle.capture_consent(Role::Patient, consent);
        assert!(ok.is_ok());
        assert_eq!(bundle.consent_count(), 1);
        assert_eq!(bundle.audit_log().len(), 2);
    }
}
