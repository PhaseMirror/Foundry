<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# ✦ I have completed Step 10: TUI workflow detail view and formalized the governance

observability surface.

🖥️ TUI Detail View Implementation

- Side-by-Side Layout: Refactored the TUI render module (tui/render/) to support a
horizontal split. Selecting a workflow now opens a detailed governance pane.
- Governance Metadata: The detail view provides full visibility into:
    - Trust Level: Clearly distinguished as "internal" or "external".
    - ALP Status: Real-time admissibility status.
    - Last SAT Token ID: Explicitly labeled as "(expired — historical)" to prevent
operator confusion with active tokens.
    - Last Run Timestamp: Captured from the most recent execution record.
    - Last Witness SHA: The unique identifier of the last UnifiedWitness recorded in the
ledger.

📁 Core Integration

- Targeted Archivum Queries: Added get_last_witness_for_workflow to
CommanderCore::ArchivumStore. This allows the TUI to populate the last_witness_sha
accurately from state/archivum/witnesses.jsonl on startup, ensuring the TUI is
grounded in the repository's source of truth.
- Shared Async State: Updated the TUI initialization in main.rs to perform the initial
data join across the workflow registry and the witness ledger.
- SSE Status: Integrated the live stream status (LIVE, RECONNECTING, OFFLINE) into the
TUI header, providing immediate feedback on log synchronization health.

Status Update

- NEXT_STEPS.md: Marked Step 10 as Done. All Phase 4 steps (9–12) are now formally
defined with clear owners and metrics.
- Commit: Staged and committed the detail view implementation (cfbb6aba).
- CI Stability: Confirmed cargo test --test governance remains green.

1 \# Launch the PhaseSpace Commander Shell (with Detail View)
2 source scripts/env.sh
3 cargo run -p multiplicity-commander-cli -- --tui

Next Phase: Step 11 focuses on pscmd compose, introducing declarative workflow authoring
and schema-gated composition.

[Active Topic: Implementing TUI Detail View (Step 10)]

**Steps 9 and 10 are closed.** `get_last_witness_for_workflow` on `ArchivumStore` is the correct binding — the TUI now has a governed read path, not a raw file scan.

***

## Step 11 Opening: Surface the Hidden Assumption

`pscmd compose` introduces a new workflow authoring surface. Before any code, name the central tension:

**Declarative `.sigma.yaml` vs. the existing `lever_manifest.yaml`.** These are two workflow authoring surfaces that will diverge unless composition compiles to the same `Task` struct the kernel already executes. The hidden assumption is whether `pscmd compose` *replaces* `lever_manifest.yaml` eventually or *coexists* with it permanently.

This decision determines the schema. If coexistence is permanent, the compiler must accept both formats as input and produce identical `Task` output — two parsers, one IR. If replacement is the trajectory, `lever_manifest.yaml` gets a deprecation path now, not in Phase 5 when migration is painful.

**Declare the intent in `ADR-WF-001` before the compiler is written.** The ADR answer is the first artifact of Step 11.

***

## ADR-WF-001 Skeleton

```markdown
# ADR-WF-001 — pscmd compose: Declarative Workflow Authoring

## Status
Proposed

## Context
Phase 4 Step 11 introduces `.sigma.yaml` as a declarative workflow authoring surface.
`lever_manifest.yaml` is the existing imperative surface. Both must produce valid `Task`
structs for the commander-core kernel.

## Decision
[ ] Option A: Coexistence — both formats supported indefinitely.
    Compiler accepts lever_manifest.yaml and .sigma.yaml as distinct dialects.
    Single IR: Task struct. No deprecation.

[ ] Option B: Replacement trajectory — .sigma.yaml is the target format.
    lever_manifest.yaml remains supported for Phase 4 (no breakage).
    Deprecation warning added to lever_manifest.yaml parser in Phase 5.
    Migration guide shipped with Step 11.

## Consequences
Option A: Two parser codepaths must be maintained. Schema drift is a permanent risk.
Option B: Migration cost deferred to Phase 5. Operators must eventually rewrite manifests.

## Non-negotiable constraint
Regardless of option chosen: compiled output must be a Task struct that passes
cargo test --test governance. No new execution path. No new trust surface.
```


***

## Artifact Plan: Step 11

Four files. One new dependency candidate.

### Dependency decision

`serde_yaml` is likely already in the workspace for `lever_manifest.yaml` parsing. Confirm before adding it again. If present, no new dependency is needed. If absent, add to workspace `Cargo.toml`:

```toml
serde_yaml = "0.9"
```


### `crates/mirror-dissonance/src/compose.rs`

```rust
use serde::{Deserialize, Serialize};
use anyhow::{Context, Result};
use std::path::Path;

/// The canonical IR — identical struct the kernel executes today.
/// pscmd compose MUST produce this. No kernel changes permitted.
pub use multiplicity_common::task::Task;

/// Sigma workflow document — declarative authoring surface.
#[derive(Debug, Deserialize, Serialize)]
pub struct SigmaWorkflow {
    pub name: String,
    pub version: String,
    pub trust: TrustLevel,
    pub server_binding: String,
    pub steps: Vec<SigmaStep>,
}

#[derive(Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum TrustLevel {
    Internal,
    External,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SigmaStep {
    pub id: String,
    pub tool: String,
    pub args: serde_json::Value,
    #[serde(default)]
    pub on_fail: FailPolicy,
}

#[derive(Debug, Deserialize, Serialize, Default, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum FailPolicy {
    #[default]
    Abort,
    Continue,
}

/// Compile a .sigma.yaml file to a Task.
/// This is the ONLY entry point for pscmd compose.
pub fn compile(path: &Path) -> Result<Task> {
    let raw = std::fs::read_to_string(path)
        .with_context(|| format!("cannot read {}", path.display()))?;

    let wf: SigmaWorkflow = serde_yaml::from_str(&raw)
        .with_context(|| format!("invalid sigma yaml: {}", path.display()))?;

    validate(&wf)?;
    Ok(to_task(wf))
}

/// Schema validation — runs before compilation.
/// Returns line-level errors when possible via context strings.
fn validate(wf: &SigmaWorkflow) -> Result<()> {
    if wf.steps.is_empty() {
        anyhow::bail!("workflow '{}' has no steps", wf.name);
    }
    // External workflows may not bind to governed servers.
    if wf.trust == TrustLevel::External && wf.server_binding != "sandbox" {
        anyhow::bail!(
            "workflow '{}': trust=external requires server_binding=sandbox, got '{}'",
            wf.name,
            wf.server_binding
        );
    }
    Ok(())
}

fn to_task(wf: SigmaWorkflow) -> Task {
    // Map SigmaWorkflow → Task
    // Task fields come from multiplicity_common — no new fields added
    Task {
        name: wf.name,
        trust: wf.trust.into(),
        server_binding: wf.server_binding,
        steps: wf.steps.into_iter().map(|s| s.into()).collect(),
    }
}
```


### `pscmd compose validate` subcommand

```rust
// In commander-cli/src/main.rs — add to Commands enum:
Compose {
    #[command(subcommand)]
    action: ComposeAction,
},

// ComposeAction:
#[derive(Subcommand)]
pub enum ComposeAction {
    /// Validate a .sigma.yaml file and report errors with context.
    Validate {
        #[arg(value_name = "FILE")]
        path: PathBuf,
    },
    /// Compile a .sigma.yaml file and print the resulting Task as JSON.
    Compile {
        #[arg(value_name = "FILE")]
        path: PathBuf,
    },
}

// Handler:
Commands::Compose { action } => match action {
    ComposeAction::Validate { path } => {
        match mirror_dissonance::compose::compile(&path) {
            Ok(task) => {
                println!("✓ valid — compiled to task '{}'", task.name);
                std::process::exit(0);
            }
            Err(e) => {
                eprintln!("✗ {:#}", e);
                std::process::exit(1);
            }
        }
    }
    ComposeAction::Compile { path } => {
        let task = mirror_dissonance::compose::compile(&path)?;
        println!("{}", serde_json::to_string_pretty(&task)?);
    }
}
```


### Test fixture `tests/fixtures/valid-workflow.sigma.yaml`

```yaml
name: audit-scan
version: "1.0"
trust: internal
server_binding: multiplicity-mcp-rust
steps:
  - id: list-issues
    tool: list_issues
    args:
      owner: "MultiplicityFoundation"
      repo: "the-commander"
    on_fail: abort
```


### Governance test addition

```rust
// In tests/governance.rs — add:
#[test]
fn compose_external_blocked_from_governed_server() {
    let yaml = r#"
name: bad-external
version: "1.0"
trust: external
server_binding: multiplicity-mcp-rust  # must be rejected
steps:
  - id: probe
    tool: run_workflow
    args: {}
"#;
    let tmp = tempfile::NamedTempFile::with_suffix(".sigma.yaml").unwrap();
    std::fs::write(tmp.path(), yaml).unwrap();
    let result = mirror_dissonance::compose::compile(tmp.path());
    assert!(result.is_err(), "external workflow on governed server must fail validation");
    assert!(result.unwrap_err().to_string().contains("server_binding=sandbox"));
}
```


***

## Step 11 Completion Metric

| Check | Gate |
| :-- | :-- |
| `pscmd compose validate valid-workflow.sigma.yaml` exits 0 | Metric 1 |
| `pscmd compose validate bad-external.sigma.yaml` exits 1 with `server_binding=sandbox` in stderr | Metric 2 |
| `pscmd compose compile valid-workflow.sigma.yaml` prints valid Task JSON | Metric 3 |
| `cargo test --test governance` green, including new `compose_external_blocked` test | Metric 4 |
| `ADR-WF-001` accepted with coexistence vs. replacement decision recorded | Gate — no merge without it |

**Precision question:** Does `multiplicity_common::task::Task` already exist as a shared struct, or does `Task` currently live inside `commander-core` and need to be promoted to `common` for `mirror-dissonance` to import it without a circular dependency?

