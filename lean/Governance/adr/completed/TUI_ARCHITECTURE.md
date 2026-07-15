🛠️ TUI Architecture (ADR-CLI-001)

- Status: Accepted.
- Library: Ratatui selected as the foundational TUI library for its immediate-mode
rendering and robust community support.
- Event Loop Model: Adopting a Shared Async State model. The pscmd binary will maintain
its \#[tokio::main] runtime, allowing the TUI to render from a central
Arc<RwLock<AppState>>. Background tasks (like the SSE witness stream) will update this
state asynchronously, ensuring a responsive UI that never blocks on network or disk
I/O.

📁 Phase 4 Roadmap Initialized
The 90-day arc for Phase 4 is now formally defined:

1. Step 9: TUI Integration (Workflows + SSE Logs).
2. Step 10: TUI Detail View (Governance visibility).
3. Step 11: pscmd compose (Declarative authoring).
4. Step 12: LAN Sync (Distributed consensus design).

⚡ Precision Answer: Runtime State
The crates/commander-cli/src/main.rs entry point already runs inside a \#[tokio::main]
async runtime. This confirms that we can immediately leverage tokio::spawn for the SSE
log listener without re-architecting the binary's execution model.

1 \# Verify the updated roadmap
2 cat NEXT_STEPS.md
3
4 \# Prepare for TUI implementation (Step 9)
5 \# NEXT: Add ratatui and crossterm to commander-cli/Cargo.toml

Next Sub-task: Begin the TUI implementation by scaffolding
crates/commander-cli/src/tui/mod.rs and integrating ratatui into the CLI workflow.

[Active Topic: Rotating Keys \& Initializing Phase 4]

**ADR-CLI-001 is accepted, runtime confirmed, pre-flight is clear.** Here are the exact artifact changes to commit for Step 9 initialization.

***

## Central Tension: Step 9

**Immediate-mode render loop vs. async state mutation.** `ratatui` redraws the entire frame on every tick. The SSE witness stream mutates `AppState` from a separate `tokio` task. A `RwLock` write that blocks during a draw tick causes frame stutter. The binding must be structured so writes are near-zero-cost and the draw loop never waits on a write lock.

**The correct binding:** the SSE task writes to an `Arc<RwLock<AppState>>` only after appending — a bounded write of ~microseconds. The draw loop acquires a read lock, clones the display slice, drops the lock immediately, then renders. No blocking.

***

## Artifact 1 — `crates/commander-cli/Cargo.toml`

Add three dependencies. No others:

```toml
ratatui = "0.29"
crossterm = { version = "0.28", features = ["event-stream"] }
tokio = { workspace = true, features = ["rt-multi-thread", "macros", "sync"] }
```

`event-stream` on crossterm is required — it gives you `EventStream` as a `tokio::Stream`, which integrates cleanly into the `tokio::select!` loop without a blocking `event::read()` call.

***

## Artifact 2 — `crates/commander-cli/src/tui/mod.rs` (new file)

```rust
pub mod app;
pub mod render;
pub mod event;

pub use app::AppState;
pub use render::draw;
```


***

## Artifact 3 — `crates/commander-cli/src/tui/app.rs` (new file)

```rust
use std::collections::VecDeque;
use serde::{Deserialize, Serialize};

/// Maximum witness log entries held in memory for TUI display.
pub const MAX_LOG_ENTRIES: usize = 200;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowSummary {
    pub id: String,
    pub name: String,
    pub trust: String,      // "internal" | "external"
    pub server: String,
    pub alp_status: String, // "PASS" | "BLOCKED" | "PENDING"
    pub last_run: String,
}

#[derive(Debug, Clone)]
pub struct LogEntry {
    pub ts: String,
    pub level: String,  // "PASS" | "FAIL" | "INFO" | "WARN"
    pub msg: String,
}

#[derive(Debug)]
pub struct AppState {
    pub workflows: Vec<WorkflowSummary>,
    pub log: VecDeque<LogEntry>,
    pub selected: usize,
    pub scroll_offset: usize,
    pub active_pane: Pane,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Pane {
    Workflows,
    Log,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            workflows: Vec::new(),
            log: VecDeque::with_capacity(MAX_LOG_ENTRIES),
            selected: 0,
            scroll_offset: 0,
            active_pane: Pane::Workflows,
        }
    }

    /// Called by the SSE task. Bounded write — no allocation on the hot path.
    pub fn push_log(&mut self, entry: LogEntry) {
        if self.log.len() >= MAX_LOG_ENTRIES {
            self.log.pop_back();
        }
        self.log.push_front(entry);
    }

    pub fn move_up(&mut self) {
        if self.selected > 0 { self.selected -= 1; }
        self.clamp_scroll();
    }

    pub fn move_down(&mut self) {
        if self.selected + 1 < self.workflows.len() { self.selected += 1; }
        self.clamp_scroll();
    }

    fn clamp_scroll(&mut self) {
        const PAGE: usize = 20;
        if self.selected < self.scroll_offset { self.scroll_offset = self.selected; }
        if self.selected >= self.scroll_offset + PAGE { self.scroll_offset = self.selected + 1 - PAGE; }
    }
}
```


***

## Artifact 4 — `crates/commander-cli/src/tui/event.rs` (new file)

```rust
use crossterm::event::{EventStream, Event, KeyCode, KeyModifiers};
use futures::StreamExt;
use std::sync::{Arc, RwLock};
use super::AppState;
use anyhow::Result;

pub enum AppEvent {
    Quit,
    Up,
    Down,
    Tab,
    Select,
}

pub async fn next_event(stream: &mut EventStream) -> Result<Option<AppEvent>> {
    if let Some(Ok(Event::Key(key))) = stream.next().await {
        let ev = match (key.code, key.modifiers) {
            (KeyCode::Char('q'), _) | (KeyCode::Char('c'), KeyModifiers::CONTROL) => Some(AppEvent::Quit),
            (KeyCode::Up, _) | (KeyCode::Char('k'), _) => Some(AppEvent::Up),
            (KeyCode::Down, _) | (KeyCode::Char('j'), _) => Some(AppEvent::Down),
            (KeyCode::Tab, _) => Some(AppEvent::Tab),
            (KeyCode::Enter, _) => Some(AppEvent::Select),
            _ => None,
        };
        return Ok(ev);
    }
    Ok(None)
}
```


***

## Artifact 5 — Entry point wiring in `main.rs`

Add a `--tui` flag to your existing `clap` struct and wire it:

```rust
// In your Cli struct:
#[arg(long)]
pub tui: bool,

// In main, after state init:
if cli.tui {
    let state = Arc::new(RwLock::new(AppState::new()));
    let state_sse = Arc::clone(&state);

    // SSE witness stream task
    tokio::spawn(async move {
        // connect to HTTP/SSE transport from Step 6
        // on each event: state_sse.write().unwrap().push_log(entry);
    });

    tui::run(state).await?;
    return Ok(());
}
```

The `tui::run` function owns the `ratatui` terminal setup, the `crossterm::terminal::enable_raw_mode()` call, and the main `tokio::select!` loop over `EventStream` and a 100ms render tick.

***

## Step 9 Completion Metric

`cargo test --test governance` must remain green after these files are added — the TUI module must be gated behind `#[cfg(feature = "tui")]` or behind the `--tui` flag path so the governance test suite never enters raw-mode terminal code during CI.

**Precision question:** Does `state/mcp_registry.yaml` currently include a `server_binding` field on workflow entries that `AppState::WorkflowSummary` can read directly, or does the TUI need to join across two data sources (registry + `lever_manifest.yaml`) to populate the workflow list?

