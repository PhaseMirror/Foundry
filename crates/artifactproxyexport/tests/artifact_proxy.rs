use artifactproxyexport::{ArtifactProxyBundle, ConsentRecord, DocumentInput, ProxyError, Role, TlsState};

fn secure_tls() -> TlsState {
    TlsState {
        min_version: "1.3",
        certificate_pinned: true,
        hostname_verified: true,
    }
}

fn consent_fixture() -> ConsentRecord {
    ConsentRecord {
        consent_id: "consent-synth-100".to_string(),
        patient_id: "patient-synth-100".to_string(),
        proxy_id: "proxy-synth-100".to_string(),
        scope: "synthetic-vitals-export".to_string(),
        granted_at: 100,
        expires_at: 1_000,
    }
}

#[test]
fn end_to_end_synthetic_artifact_flow() {
    let mut bundle = ArtifactProxyBundle::new();

    bundle
        .capture_consent(Role::Patient, consent_fixture())
        .expect("patient should capture consent");

    bundle
        .approve_proxy(Role::Clinician, "consent-synth-100", "clinician-synth-100", 200, 200)
        .expect("clinician should approve proxy");

    bundle
        .store_document(
            Role::Proxy,
            &secure_tls(),
            DocumentInput {
                document_id: "doc-synth-100".to_string(),
                consent_id: "consent-synth-100".to_string(),
                proxy_id: "proxy-synth-100".to_string(),
                content: "synthetic artifact summary: normal ranges".to_string(),
                synthetic_only: true,
            },
            250,
            250,
        )
        .expect("proxy should store document");

    let document = bundle
        .fetch_document(Role::Auditor, "doc-synth-100", 260)
        .expect("auditor should fetch stored document");

    assert_eq!(document.document_id, "doc-synth-100");
    assert!(document.content.contains("synthetic"));
    assert_eq!(bundle.document_count(), 1);
    assert_eq!(bundle.audit_log().len(), 4);
    assert!(bundle.audit_log().iter().all(|event| event.success));
}

#[test]
fn storage_requires_tls_and_synthetic_data() {
    let mut bundle = ArtifactProxyBundle::new();
    bundle
        .capture_consent(Role::Patient, consent_fixture())
        .expect("patient should capture consent");
    bundle
        .approve_proxy(Role::SystemAdmin, "consent-synth-100", "admin-synth-100", 300, 300)
        .expect("admin should approve proxy");

    let weak_tls = TlsState {
        min_version: "1.2",
        certificate_pinned: false,
        hostname_verified: true,
    };

    let weak_tls_err = bundle.store_document(
        Role::Proxy,
        &weak_tls,
        DocumentInput {
            document_id: "doc-synth-weak".to_string(),
            consent_id: "consent-synth-100".to_string(),
            proxy_id: "proxy-synth-100".to_string(),
            content: "synthetic artifact payload".to_string(),
            synthetic_only: true,
        },
        301,
        301,
    );
    assert_eq!(weak_tls_err, Err(ProxyError::TlsFailed));

    let non_synth_err = bundle.store_document(
        Role::Proxy,
        &secure_tls(),
        DocumentInput {
            document_id: "doc-synth-non".to_string(),
            consent_id: "consent-synth-100".to_string(),
            proxy_id: "proxy-synth-100".to_string(),
            content: "artifact payload without marker".to_string(),
            synthetic_only: true,
        },
        302,
        302,
    );
    assert_eq!(non_synth_err, Err(ProxyError::SyntheticDataRequired));
}

#[test]
fn approval_and_access_checks_are_enforced() {
    let mut bundle = ArtifactProxyBundle::new();

    let missing_consent = bundle.approve_proxy(
        Role::Clinician,
        "consent-synth-missing",
        "clinician-synth-200",
        400,
        400,
    );
    assert_eq!(missing_consent, Err(ProxyError::ConsentNotFound));

    bundle
        .capture_consent(Role::Patient, consent_fixture())
        .expect("patient should capture consent");

    let denied_approval = bundle.approve_proxy(
        Role::Proxy,
        "consent-synth-100",
        "proxy-synth-100",
        410,
        410,
    );
    assert_eq!(denied_approval, Err(ProxyError::AccessDenied("approve_proxy")));

    let no_approval_store = bundle.store_document(
        Role::Proxy,
        &secure_tls(),
        DocumentInput {
            document_id: "doc-synth-no-approval".to_string(),
            consent_id: "consent-synth-100".to_string(),
            proxy_id: "proxy-synth-100".to_string(),
            content: "synthetic waiting for approval".to_string(),
            synthetic_only: true,
        },
        420,
        420,
    );
    assert_eq!(no_approval_store, Err(ProxyError::ProxyNotApproved));
}

#[test]
fn expired_consent_blocks_approval() {
    let mut bundle = ArtifactProxyBundle::new();

    // Consent that has already expired (expires_at < now)
    let expired_consent = ConsentRecord {
        consent_id: "consent-synth-expired".to_string(),
        patient_id: "patient-synth-300".to_string(),
        proxy_id: "proxy-synth-300".to_string(),
        scope: "synthetic-expired-scope".to_string(),
        granted_at: 1,
        expires_at: 50,
    };
    bundle
        .capture_consent(Role::Patient, expired_consent)
        .expect("patient should capture consent");

    // Attempt to approve after expiry (now = 100 > expires_at = 50)
    let result = bundle.approve_proxy(
        Role::Clinician,
        "consent-synth-expired",
        "clinician-synth-300",
        100,
        100,
    );
    assert_eq!(result, Err(ProxyError::ConsentExpired));
}

#[test]
fn duplicate_document_is_rejected() {
    let mut bundle = ArtifactProxyBundle::new();
    bundle
        .capture_consent(Role::Patient, consent_fixture())
        .expect("patient should capture consent");
    bundle
        .approve_proxy(Role::Clinician, "consent-synth-100", "clinician-synth-400", 200, 200)
        .expect("clinician should approve proxy");

    let input = || DocumentInput {
        document_id: "doc-synth-dup".to_string(),
        consent_id: "consent-synth-100".to_string(),
        proxy_id: "proxy-synth-100".to_string(),
        content: "synthetic duplicate test".to_string(),
        synthetic_only: true,
    };

    bundle
        .store_document(Role::Proxy, &secure_tls(), input(), 250, 250)
        .expect("first store should succeed");

    let result = bundle.store_document(Role::Proxy, &secure_tls(), input(), 260, 260);
    assert_eq!(result, Err(ProxyError::DuplicateDocument));
}

#[test]
fn fetch_missing_document_fails() {
    let mut bundle = ArtifactProxyBundle::new();

    let result = bundle.fetch_document(Role::Auditor, "doc-synth-nonexistent", 300);
    assert_eq!(result, Err(ProxyError::DocumentNotFound));
}
