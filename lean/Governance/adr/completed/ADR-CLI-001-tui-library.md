# ADR-CLI-001: TUI Library and Event Loop Model

## Status
Accepted (2026-05-22)

## Context
Phase 4 of the Commander roadmap requires a Terminal User Interface (TUI) to provide a rich, real-time observer surface for workflows and governance logs. We need to select a TUI library and define the event loop model, specifically how it interacts with the existing asynchronous `tokio` runtime and the SSE log stream.

## Decision

### 1. Library Selection: Ratatui
We will use **Ratatui** as the foundational TUI library. It is the community standard for Rust, provides a robust immediate-mode rendering model, and is highly compatible with the `crossterm` backend.

### 2. Event Loop Model: Shared Async State
To bridge the synchronous drawing loop of Ratatui with the asynchronous nature of the SSE stream and `tokio` runtime:
- **AppState**: All TUI state (workflows, logs, connection status) will reside in a central `Arc<RwLock<AppState>>` struct.
- **Async Tasks**: The SSE log listener and other background data fetchers will run as `tokio::spawn` tasks, updating the `AppState` via the `RwLock`.
- **TUI Thread**: The main TUI event loop will run in a dedicated thread or as a blocking task. It will use `crossterm::event::poll` with a short timeout to trigger redraws, ensuring responsiveness even when no background data is arriving.
- **Concurrency**: This model ensures that `commander-cli` remains non-blocking while providing a smooth, high-frame-rate UI.

### 3. Dependency Management
- `ratatui` and `crossterm` will be added to `crates/commander-cli/Cargo.toml`.
- Any large UI state objects (e.g., historical log buffers) will be managed via the `AppState` to prevent rendering lag.

## Consequences
- Requires careful management of `RwLock` contention to avoid UI stutter.
- Decouples UI rendering from data acquisition, simplifying the implementation of real-time SSE updates.
- Maintains the `#[tokio::main]` entry point in `main.rs`, allowing the TUI to be launched as an additive mode (`pscmd --tui`).

## Verification
- `pscmd --tui` launches and renders a static workflow list.
- Simulated log entries added to `AppState` appear in the TUI log pane in real-time.
- Keyboard navigation (scrolling, selecting) remains responsive during high-volume SSE activity.
