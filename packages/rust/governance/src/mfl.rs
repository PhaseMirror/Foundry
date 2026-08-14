use std::collections::{HashMap, HashSet};
use std::sync::LazyLock;

pub static MODE_RANK: LazyLock<HashMap<&'static str, u32>> = LazyLock::new(|| {
    let mut m = HashMap::new();
    m.insert("suspended", 0);
    m.insert("advisory", 1);
    m.insert("constrained", 2);
    m.insert("full", 3);
    m
});

pub fn classify_lambda_band(lambda_m: f64, quiet_max: f64, amber_max: f64) -> Result<String, String> {
    if quiet_max >= amber_max {
        return Err("quiet_max must be less than amber_max".to_string());
    }

    if lambda_m <= quiet_max {
        Ok("quiet".to_string())
    } else if lambda_m <= amber_max {
        Ok("amber".to_string())
    } else {
        Ok("red".to_string())
    }
}

pub fn clamp_mode(current_mode: &str, directive: Option<&str>) -> Result<String, String> {
    let current_rank = MODE_RANK.get(current_mode)
        .ok_or_else(|| format!("unknown mode: {}", current_mode))?;

    let directive = match directive {
        None | Some("") => return Ok(current_mode.to_string()),
        Some(d) => d,
    };

    let target_rank = if directive == "to_advisory" {
        *MODE_RANK.get("advisory").unwrap()
    } else {
        *MODE_RANK.get(directive)
            .ok_or_else(|| format!("unknown mode directive: {}", directive))?
    };

    let chosen_rank = std::cmp::min(*current_rank, target_rank);
    for (mode, rank) in MODE_RANK.iter() {
        if *rank == chosen_rank {
            return Ok(mode.to_string());
        }
    }

    Err("failed to resolve clamped mode".to_string())
}

pub fn parse_blocked_set(json_blob: Option<&str>) -> Result<HashSet<String>, String> {
    match json_blob {
        None | Some("") => Ok(HashSet::new()),
        Some(blob) => {
            let parsed: Vec<String> = serde_json::from_str(blob)
                .map_err(|e| format!("blocked set JSON must be a list: {}", e))?;
            Ok(parsed.into_iter().collect())
        }
    }
}

pub fn derive_allowed_set(baseline: &[String], blocked: &HashSet<String>) -> HashSet<String> {
    let baseline_set: HashSet<String> = baseline.iter().cloned().collect();
    baseline_set.difference(blocked).cloned().collect()
}

pub fn required_band_brakes(
    lambda_m_band: &str,
    rights_material: bool,
    domain_matches: bool,
    amber_blocked_actions: Option<&[String]>,
) -> Result<(Option<String>, HashSet<String>), String> {
    match lambda_m_band {
        "quiet" => Ok((None, HashSet::new())),
        "amber" => Ok((None, amber_blocked_actions.map(|v| v.iter().cloned().collect()).unwrap_or_default())),
        "red" => {
            let mut blocked = HashSet::new();
            if rights_material && domain_matches {
                blocked.insert("appeal_denial".to_string());
            }
            Ok((Some("to_advisory".to_string()), blocked))
        }
        _ => Err(format!("unknown lambda band: {}", lambda_m_band)),
    }
}
