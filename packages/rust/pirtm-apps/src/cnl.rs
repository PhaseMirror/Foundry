use pirtm_invariants::PhaseMirrorInvariants;
use pirtm_stdlib::prelude::*;

pub const LEXICON: &[(&str, u64)] = &[
    ("deploy", 2),
    ("scale", 3),
    ("destroy", 17),
    ("web-service", 5),
    ("database", 7),
    ("cluster", 11),
    ("replicas", 13),
    ("all", 1),
];

const FILLERS: &[(&str, u64)] = &[
    ("on", 23),
    ("with", 29),
    ("it", 31),
    ("the", 37),
    ("to", 41),
    ("at", 43),
];

const REVOKE_PRIME: u64 = 19;

pub const MIN_REPLICAS: u32 = 1;
pub const MAX_REPLICAS: u32 = 32;

#[derive(Debug, Clone, PartialEq)]
pub enum Mode {
    Assert,
    Retract,
}

#[derive(Debug)]
pub enum VerifiedAction {
    Deploy {
        service: String,
        target: String,
        replicas: u32,
    },
    Scale {
        service: String,
        replicas: u32,
    },
    Destroy {
        service: String,
    },
    Revoke {
        previous_action_id: String,
    },
}

pub struct CompilationResult {
    pub moc_word: MOCWord,
    pub c: f64,
    pub rsc: f64,
    pub diagnostic: Option<String>,
    pub verified_action: Result<VerifiedAction, String>,
    pub mode: Mode,
}

impl CompilationResult {
    pub fn invariants_passed(&self) -> bool {
        self.diagnostic.is_none()
    }
}

pub fn compile_command(input: &str) -> Result<CompilationResult, String> {
    let tokens: Vec<String> = input.split_whitespace().map(|t| t.to_string()).collect();
    if tokens.is_empty() {
        return Err("Empty input".to_string());
    }

    let verb = tokens[0].to_lowercase();
    match verb.as_str() {
        "deploy" | "scale" | "destroy" | "revoke" | "cancel" => {}
        other => return Err(format!("Unknown verb '{}'", other)),
    }

    let mode = if verb == "revoke" || verb == "cancel" {
        Mode::Retract
    } else {
        Mode::Assert
    };

    let verified_action = parse_action(&tokens, &verb)?;

    let mut ast: Option<MOCWord> = None;
    for t in &tokens {
        let p = token_prime(&t.to_lowercase());
        ast = Some(match ast {
            None => Ap(p),
            Some(word) => word + Ap(p),
        });
    }

    let new_stratum = MOCWord::StratumBoundary(Box::new(ast.expect("tokens is non-empty")));

    let diagnostic = PhaseMirrorInvariants::enforce_all(&new_stratum)
        .err()
        .map(|e| e.to_string());

    let (c, r1, r2, r3) = EvalNF::evaluate(&new_stratum);
    let rsc = Resonance::calculate(r1, r2, r3);

    Ok(CompilationResult {
        moc_word: new_stratum,
        c,
        rsc,
        diagnostic,
        verified_action: Ok(verified_action),
        mode,
    })
}

fn parse_action(tokens: &[String], verb: &str) -> Result<VerifiedAction, String> {
    let rest = &tokens[1..];
    match verb {
        "deploy" => parse_deploy(rest),
        "scale" => parse_scale(rest),
        "destroy" => parse_destroy(rest),
        "revoke" | "cancel" => parse_revoke(rest),
        _ => Err(format!("Unknown verb '{}'", verb)),
    }
}

fn parse_deploy(rest: &[String]) -> Result<VerifiedAction, String> {
    let mut service: Option<String> = None;
    let mut target: Option<String> = None;
    let mut replicas: Option<u32> = None;

    let mut i = 0;
    while i < rest.len() {
        let token = &rest[i];
        let lower = token.to_lowercase();

        if is_filler(&lower) {
            i += 1;
            continue;
        }

        if let Some(r) = parse_replicas_at(rest, &mut i)? {
            if replicas.is_some() {
                return Err(format!("Unexpected token '{}'", token));
            }
            replicas = Some(r);
            continue;
        }

        if service.is_none() {
            service = Some(token.clone());
        } else if target.is_none() {
            target = Some(token.clone());
        } else {
            return Err(format!("Unexpected token '{}'", token));
        }
        i += 1;
    }

    let service =
        service.ok_or_else(|| "deploy requires <service> <target> [replicas=N]".to_string())?;
    let target =
        target.ok_or_else(|| "deploy requires <service> <target> [replicas=N]".to_string())?;
    let replicas = replicas.unwrap_or(1);

    Ok(VerifiedAction::Deploy {
        service,
        target,
        replicas,
    })
}

fn parse_scale(rest: &[String]) -> Result<VerifiedAction, String> {
    let mut service: Option<String> = None;
    let mut replicas: Option<u32> = None;

    let mut i = 0;
    while i < rest.len() {
        let token = &rest[i];
        let lower = token.to_lowercase();

        if is_filler(&lower) {
            i += 1;
            continue;
        }

        if let Some(r) = parse_replicas_at(rest, &mut i)? {
            if replicas.is_some() {
                return Err(format!("Unexpected token '{}'", token));
            }
            replicas = Some(r);
            continue;
        }

        if service.is_none() {
            service = Some(token.clone());
        } else {
            return Err(format!("Unexpected token '{}'", token));
        }
        i += 1;
    }

    let service = service.ok_or_else(|| "scale requires <service> [replicas=N]".to_string())?;
    let replicas = replicas.unwrap_or(1);

    Ok(VerifiedAction::Scale { service, replicas })
}

fn parse_destroy(rest: &[String]) -> Result<VerifiedAction, String> {
    let mut service: Option<String> = None;

    let mut i = 0;
    while i < rest.len() {
        let token = &rest[i];
        let lower = token.to_lowercase();

        if is_filler(&lower) {
            i += 1;
            continue;
        }

        if parse_replicas_at(rest, &mut i)?.is_some() {
            return Err("destroy takes no replicas".to_string());
        }

        if service.is_none() {
            service = Some(token.clone());
        } else {
            return Err(format!("Unexpected token '{}'", token));
        }
        i += 1;
    }

    let service = service.ok_or_else(|| "destroy requires <service>".to_string())?;

    Ok(VerifiedAction::Destroy { service })
}

fn parse_revoke(rest: &[String]) -> Result<VerifiedAction, String> {
    let mut previous_action_id: Option<String> = None;

    for token in rest {
        let lower = token.to_lowercase();

        if is_filler(&lower) {
            continue;
        }

        if previous_action_id.is_none() {
            previous_action_id = Some(token.clone());
        } else {
            return Err(format!("Unexpected token '{}'", token));
        }
    }

    let previous_action_id =
        previous_action_id.ok_or_else(|| "revoke requires <action_id>".to_string())?;

    Ok(VerifiedAction::Revoke { previous_action_id })
}

fn parse_replicas_at(rest: &[String], index: &mut usize) -> Result<Option<u32>, String> {
    let token = &rest[*index];
    let lower = token.to_lowercase();

    if let Some(value) = lower.strip_prefix("replicas=") {
        let n = parse_number(value).ok_or_else(|| {
            format!(
                "replicas must be between {} and {}, got '{}'",
                MIN_REPLICAS, MAX_REPLICAS, value
            )
        })?;
        *index += 1;
        return Ok(Some(n));
    }

    if lower == "replicas" {
        let next = rest.get(*index + 1).ok_or_else(|| {
            format!(
                "replicas must be between {} and {}, got end of input",
                MIN_REPLICAS, MAX_REPLICAS
            )
        })?;
        let n = parse_number(next).ok_or_else(|| {
            format!(
                "replicas must be between {} and {}, got '{}'",
                MIN_REPLICAS, MAX_REPLICAS, next
            )
        })?;
        *index += 2;
        return Ok(Some(n));
    }

    if lower.bytes().all(|b| b.is_ascii_digit()) {
        let n = parse_number(token).ok_or_else(|| {
            format!(
                "replicas must be between {} and {}, got '{}'",
                MIN_REPLICAS, MAX_REPLICAS, token
            )
        })?;
        *index += 1;
        return Ok(Some(n));
    }

    Ok(None)
}

fn parse_number(token: &str) -> Option<u32> {
    let n: u32 = token.parse().ok()?;
    if (MIN_REPLICAS..=MAX_REPLICAS).contains(&n) {
        Some(n)
    } else {
        None
    }
}

fn is_filler(lower: &str) -> bool {
    FILLERS.iter().any(|(word, _)| *word == lower)
}

fn token_prime(token: &str) -> u64 {
    if token.starts_with("replicas=") {
        return stable_prime(token);
    }

    for (word, p) in LEXICON {
        if *word == token {
            return *p;
        }
    }

    for (word, p) in FILLERS {
        if *word == token {
            return *p;
        }
    }

    match token {
        "revoke" | "cancel" => REVOKE_PRIME,
        _ => stable_prime(token),
    }
}

fn stable_prime(token: &str) -> u64 {
    let mut hash: u64 = 0xcbf29ce484222325;
    for byte in token.bytes() {
        hash ^= byte as u64;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    let mut candidate = 19 + (hash % 500);
    while !is_prime(candidate) {
        candidate += 1;
    }
    candidate
}

fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n % 2 == 0 {
        return n == 2;
    }
    let mut divisor = 3;
    while divisor * divisor <= n {
        if n % divisor == 0 {
            return false;
        }
        divisor += 2;
    }
    true
}

pub fn suggest_correction(tokens: &[&str]) -> Vec<String> {
    let mut suggestions = Vec::new();
    if tokens.contains(&"all") {
        suggestions.push("deploy web-service cluster".to_string());
        suggestions.push("deploy database cluster".to_string());
    }
    suggestions
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deploy_parses_real_parameters() {
        let result = compile_command("deploy my-service cluster 4").expect("should compile");
        assert!(result.invariants_passed());
        match result.verified_action {
            Ok(VerifiedAction::Deploy {
                service,
                target,
                replicas,
            }) => {
                assert_eq!(service, "my-service");
                assert_eq!(target, "cluster");
                assert_eq!(replicas, 4);
            }
            Ok(_) => panic!("expected Deploy action"),
            Err(e) => panic!("action should parse, got: {}", e),
        }
    }

    #[test]
    fn deploy_supports_replicas_equals_and_space_forms() {
        let a = compile_command("deploy web-service cluster replicas=6").unwrap();
        let b = compile_command("deploy web-service cluster with replicas 6").unwrap();
        for result in [&a, &b] {
            match &result.verified_action {
                Ok(VerifiedAction::Deploy { replicas, .. }) => assert_eq!(*replicas, 6),
                Ok(_) => panic!("expected Deploy"),
                Err(e) => panic!("action should parse, got: {}", e),
            }
        }
    }

    #[test]
    fn metrics_are_derived_from_invariants_not_constants() {
        let result = compile_command("deploy my-service cluster 4").unwrap();
        let (c, r1, r2, r3) = EvalNF::evaluate(&result.moc_word);
        assert_eq!(result.c, c);
        assert_eq!(result.rsc, Resonance::calculate(r1, r2, r3));
    }

    #[test]
    fn metrics_vary_with_input() {
        let single = compile_command("deploy a cluster 2").unwrap();
        let composite = compile_command("deploy a cluster 32").unwrap();
        assert_ne!(single.c, composite.c);
        assert_ne!(single.rsc, composite.rsc);
    }

    #[test]
    fn compile_is_deterministic() {
        let a = compile_command("deploy my-service cluster 4").unwrap();
        let b = compile_command("deploy my-service cluster 4").unwrap();
        assert_eq!(a.c, b.c);
        assert_eq!(a.rsc, b.rsc);
        assert_eq!(a.moc_word, b.moc_word);
    }

    #[test]
    fn scale_parses_service_and_replicas() {
        let result = compile_command("scale my-service 5").unwrap();
        match result.verified_action {
            Ok(VerifiedAction::Scale { service, replicas }) => {
                assert_eq!(service, "my-service");
                assert_eq!(replicas, 5);
            }
            Ok(_) => panic!("expected Scale action"),
            Err(e) => panic!("action should parse, got: {}", e),
        }
    }

    #[test]
    fn destroy_parses_service() {
        let result = compile_command("destroy my-service").unwrap();
        match result.verified_action {
            Ok(VerifiedAction::Destroy { service }) => assert_eq!(service, "my-service"),
            Ok(_) => panic!("expected Destroy action"),
            Err(e) => panic!("action should parse, got: {}", e),
        }
    }

    #[test]
    fn revoke_is_retract_mode() {
        let result = compile_command("revoke W-1234").unwrap();
        assert_eq!(result.mode, Mode::Retract);
        match result.verified_action {
            Ok(VerifiedAction::Revoke { previous_action_id }) => {
                assert_eq!(previous_action_id, "W-1234");
            }
            Ok(_) => panic!("expected Revoke action"),
            Err(e) => panic!("action should parse, got: {}", e),
        }
    }

    #[test]
    fn unknown_verb_is_rejected() {
        assert!(compile_command("please frobnicate the widget").is_err());
        assert!(compile_command("frobnicate").is_err());
    }

    #[test]
    fn ambiguous_or_missing_arguments_never_default() {
        assert!(compile_command("deploy").is_err());
        assert!(compile_command("deploy only-a-service").is_err());
        assert!(compile_command("scale").is_err());
        assert!(compile_command("destroy").is_err());
        assert!(compile_command("revoke").is_err());
    }

    #[test]
    fn out_of_bounds_replicas_are_rejected() {
        assert!(compile_command("deploy a b 0").is_err());
        assert!(compile_command("deploy a b 33").is_err());
        assert!(compile_command("deploy a b replicas=0").is_err());
        assert!(compile_command("scale a 100").is_err());
    }

    #[test]
    fn destroy_takes_no_replicas() {
        assert!(compile_command("destroy a 3").is_err());
    }

    #[test]
    fn all_maps_to_prime_one_and_fails_invariants() {
        let result = compile_command("deploy all cluster").unwrap();
        assert!(!result.invariants_passed());
        let diagnostic = result.diagnostic.as_deref().unwrap_or_default();
        assert!(diagnostic.contains("L0_08_PrimeOneForbidden"));
        assert!(result.verified_action.is_ok());
    }

    #[test]
    fn suggest_correction_handles_all() {
        let suggestions = suggest_correction(&["deploy", "all", "cluster"]);
        assert!(suggestions.contains(&"deploy web-service cluster".to_string()));
    }

    #[test]
    fn old_agent_command_still_parses() {
        let result = compile_command("deploy web-service cluster 3").unwrap();
        assert!(result.invariants_passed());
        match result.verified_action {
            Ok(VerifiedAction::Deploy { replicas, .. }) => assert_eq!(replicas, 3),
            Ok(_) => panic!("expected Deploy"),
            Err(e) => panic!("action should parse, got: {}", e),
        }
    }

    #[test]
    fn empty_input_is_rejected() {
        assert!(compile_command("").is_err());
    }
}
