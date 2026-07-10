pub mod identity;
pub mod audit;
pub mod transport;
pub mod governance;

#[cfg(test)]
mod tests {
    use crate::identity::{AgentIdentity, PrivilegeRing};
    use crate::identity::rotation::KeyRotationManager;

    #[tokio::test]
    async fn test_key_rotation() {
        let mut identity = AgentIdentity::create(
            "test-agent".to_string(),
            "test@example.com".to_string(),
            vec![],
            None,
            None,
        ).await.unwrap();
        let old_public_key = identity.public_key.clone();

        KeyRotationManager::rotate_keys(&mut identity);

        assert_ne!(old_public_key, identity.public_key);
    }
}
