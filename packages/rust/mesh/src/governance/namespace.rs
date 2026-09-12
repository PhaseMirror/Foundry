use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, RwLock};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AgentNamespace {
    pub name: String,
    pub description: String,
    pub parent: Option<String>,
    pub members: HashSet<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct NamespaceRule {
    pub source_namespace: String,
    pub target_namespace: String,
    pub allowed: bool,
}

pub struct NamespaceManager {
    namespaces: Arc<RwLock<HashMap<String, AgentNamespace>>>,
    rules: Arc<RwLock<Vec<NamespaceRule>>>,
}

impl NamespaceManager {
    pub fn new() -> Self {
        Self {
            namespaces: Arc::new(RwLock::new(HashMap::new())),
            rules: Arc::new(RwLock::new(Vec::new())),
        }
    }

    pub fn create_namespace(&self, name: String, description: String, parent: Option<String>) -> anyhow::Result<()> {
        let mut namespaces = self.namespaces.write().unwrap();
        if namespaces.contains_key(&name) {
            return Err(anyhow::anyhow!("Namespace already exists: {}", name));
        }
        if let Some(ref p) = parent {
            if !namespaces.contains_key(p) {
                return Err(anyhow::anyhow!("Parent namespace does not exist: {}", p));
            }
        }
        namespaces.insert(name.clone(), AgentNamespace {
            name,
            description,
            parent,
            members: HashSet::new(),
        });
        Ok(())
    }

    pub fn add_member(&self, namespace_name: &str, agent_did: String) -> anyhow::Result<()> {
        let mut namespaces = self.namespaces.write().unwrap();
        let ns = namespaces.get_mut(namespace_name).ok_or_else(|| anyhow::anyhow!("Namespace not found"))?;
        ns.members.insert(agent_did);
        Ok(())
    }

    pub fn can_communicate(&self, from_did: &str, to_did: &str) -> bool {
        let namespaces = self.namespaces.read().unwrap();
        let mut from_ns = None;
        let mut to_ns = None;

        for (name, ns) in namespaces.iter() {
            if ns.members.contains(from_did) { from_ns = Some(name.clone()); }
            if ns.members.contains(to_did) { to_ns = Some(name.clone()); }
        }

        match (from_ns, to_ns) {
            (Some(f), Some(t)) => {
                if f == t { return true; }
                // Ancestor check would go here
                let rules = self.rules.read().unwrap();
                rules.iter().any(|r| r.source_namespace == f && r.target_namespace == t && r.allowed)
            },
            _ => false,
        }
    }
}
