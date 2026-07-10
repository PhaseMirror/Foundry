// crates/common/src/identity.rs

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum IssuerType {
    Bank,
    Hospital,
    University,
    Gov,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExternalIssuerConfig {
    pub issuer_id: String,
    pub issuer_type: IssuerType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub oidc_issuer_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub jwks_uri: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expected_client_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vc_did: Option<String>,
    pub uniqueness_salt_id: String,
    pub active: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct IdentityOnboardingConfig {
    pub issuers: Vec<ExternalIssuerConfig>,
    pub uniqueness_salts: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UniquenessAnchorInput {
    pub issuer: ExternalIssuerConfig,
    pub subject_id: String,
    pub context: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UniquenessAnchor {
    pub issuer_id: String,
    pub context: String,
    pub anchor_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ValidatedIdToken {
    pub issuer: String,
    pub subject: String,
    pub audience: String,
    pub issued_at: u64,
    pub expires_at: u64,
    pub claims: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifiedVerifiableCredential {
    pub issuer_did: String,
    pub subject_did: String,
    pub r#type: Vec<String>,
    pub issuance_date: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expiration_date: Option<String>,
    pub claims: serde_json::Value,
}

/// Helper function to compute HMAC-SHA256
fn hmac_sha256(key: &[u8], message: &[u8]) -> [u8; 32] {
    let mut padded_key = [0u8; 64];
    if key.len() > 64 {
        let hash = Sha256::digest(key);
        padded_key[..32].copy_from_slice(&hash);
    } else {
        padded_key[..key.len()].copy_from_slice(key);
    }

    let mut ipad = [0x36u8; 64];
    let mut opad = [0x5cu8; 64];
    for i in 0..64 {
        ipad[i] ^= padded_key[i];
        opad[i] ^= padded_key[i];
    }

    let mut inner = Sha256::new();
    inner.update(&ipad);
    inner.update(message);
    let inner_hash = inner.finalize();

    let mut outer = Sha256::new();
    outer.update(&opad);
    outer.update(&inner_hash);
    outer.finalize().into()
}

pub fn derive_uniqueness_anchor(
    input: &UniquenessAnchorInput,
    salt_secret: &str,
) -> UniquenessAnchor {
    let payload = format!("{}:{}:{}", input.issuer.issuer_id, input.subject_id, input.context);
    let digest_bytes = hmac_sha256(salt_secret.as_bytes(), payload.as_bytes());
    let anchor_hash = format!("0x{}", hex::encode(digest_bytes));

    UniquenessAnchor {
        issuer_id: input.issuer.issuer_id.clone(),
        context: input.context.clone(),
        anchor_hash,
    }
}

pub fn resolve_issuer_for_id_token(
    cfg: &IdentityOnboardingConfig,
    token: &ValidatedIdToken,
) -> Result<ExternalIssuerConfig> {
    let issuer = cfg
        .issuers
        .iter()
        .find(|i| i.oidc_issuer_url.as_ref() == Some(&token.issuer) && i.active)
        .ok_or_else(|| anyhow!("Unsupported or inactive OIDC issuer: {}", token.issuer))?;
    Ok(issuer.clone())
}

pub fn derive_membership_anchor_from_id_token(
    cfg: &IdentityOnboardingConfig,
    token: &ValidatedIdToken,
) -> Result<UniquenessAnchor> {
    let issuer = resolve_issuer_for_id_token(cfg, token)?;
    let salt_id = &issuer.uniqueness_salt_id;
    let salt_secret = cfg
        .uniqueness_salts
        .get(salt_id)
        .ok_or_else(|| anyhow!("Missing salt secret for uniquenessSaltId={}", salt_id))?;

    let input = UniquenessAnchorInput {
        issuer,
        subject_id: token.subject.clone(),
        context: "membership".to_string(),
    };
    Ok(derive_uniqueness_anchor(&input, salt_secret))
}

pub fn resolve_issuer_for_vc(
    cfg: &IdentityOnboardingConfig,
    vc: &VerifiedVerifiableCredential,
) -> Result<ExternalIssuerConfig> {
    let issuer = cfg
        .issuers
        .iter()
        .find(|i| i.vc_did.as_ref() == Some(&vc.issuer_did) && i.active)
        .ok_or_else(|| anyhow!("Unsupported or inactive VC issuer DID: {}", vc.issuer_did))?;
    Ok(issuer.clone())
}

pub fn derive_membership_anchor_from_vc(
    cfg: &IdentityOnboardingConfig,
    vc: &VerifiedVerifiableCredential,
) -> Result<UniquenessAnchor> {
    let issuer = resolve_issuer_for_vc(cfg, vc)?;
    let salt_id = &issuer.uniqueness_salt_id;
    let salt_secret = cfg
        .uniqueness_salts
        .get(salt_id)
        .ok_or_else(|| anyhow!("Missing salt secret for uniquenessSaltId={}", salt_id))?;

    let input = UniquenessAnchorInput {
        issuer,
        subject_id: vc.subject_did.clone(),
        context: "membership".to_string(),
    };
    Ok(derive_uniqueness_anchor(&input, salt_secret))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mock_config() -> IdentityOnboardingConfig {
        let issuer = ExternalIssuerConfig {
            issuer_id: "test-issuer".to_string(),
            issuer_type: IssuerType::Gov,
            oidc_issuer_url: Some("https://issuer.example.com".to_string()),
            jwks_uri: None,
            expected_client_id: None,
            vc_did: Some("did:example:issuer".to_string()),
            uniqueness_salt_id: "salt-1".to_string(),
            active: true,
        };
        let mut uniqueness_salts = HashMap::new();
        uniqueness_salts.insert("salt-1".to_string(), "my-secret-salt".to_string());
        IdentityOnboardingConfig {
            issuers: vec![issuer],
            uniqueness_salts,
        }
    }

    #[test]
    fn test_derive_uniqueness_anchor() {
        let cfg = mock_config();
        let input = UniquenessAnchorInput {
            issuer: cfg.issuers[0].clone(),
            subject_id: "alice-sub".to_string(),
            context: "membership".to_string(),
        };
        let anchor = derive_uniqueness_anchor(&input, "my-secret-salt");
        assert_eq!(anchor.issuer_id, "test-issuer");
        assert_eq!(anchor.context, "membership");
        assert!(anchor.anchor_hash.starts_with("0x"));
    }

    #[test]
    fn test_derive_membership_anchor_from_id_token() {
        let cfg = mock_config();
        let token = ValidatedIdToken {
            issuer: "https://issuer.example.com".to_string(),
            subject: "alice-sub".to_string(),
            audience: "app-client".to_string(),
            issued_at: 1000,
            expires_at: 2000,
            claims: serde_json::json!({}),
        };
        let anchor = derive_membership_anchor_from_id_token(&cfg, &token).unwrap();
        assert_eq!(anchor.issuer_id, "test-issuer");
        assert_eq!(anchor.context, "membership");
    }
}
