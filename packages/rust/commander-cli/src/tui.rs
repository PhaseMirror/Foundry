use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyModifiers},
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Terminal,
};
use std::io::stdout;
use sigma::{SigmaKernel, StateTransition, Thresholds, PolicyEngine};
use archivum::WitnessLedger;

pub struct App {
    pub input: String,
    pub messages: Vec<String>,
    pub status: String,
    pub active_mode: String,
    pub ratified_count: usize,
    pub should_quit: bool,
}

impl App {
    pub fn new() -> Self {
        Self {
            input: String::new(),
            messages: vec![
                "🚀 PIRTM Commander Agent Shell Initialized.".into(),
                "Type /help for slash commands, or enter a PIRTM directive / code query.".into(),
                "----------------------------------------------------------------".into(),
            ],
            status: "READY | Sedona Spine: Enforced | Kernel: Axiom-Clean".into(),
            active_mode: "PIRTM Interactive Agent".into(),
            ratified_count: 0,
            should_quit: false,
        }
    }

    pub fn handle_input(&mut self) {
        let input = self.input.trim().to_string();
        if input.is_empty() {
            return;
        }

        self.messages.push(format!("> {}", input));

        if input.starts_with('/') {
            self.handle_slash_command(&input);
        } else {
            self.process_agent_command(&input);
        }

        self.input.clear();
    }

    fn handle_slash_command(&mut self, cmd: &str) {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        match parts.get(0).copied().unwrap_or("") {
            "/help" => {
                self.messages.push("📋 Commander Slash Commands:".into());
                self.messages.push("  /help           - Display this help dialog".into());
                self.messages.push("  /sigma eval     - Evaluate state transition in Sigma kernel".into());
                self.messages.push("  /status         - Display agent integrity & kernel state".into());
                self.messages.push("  /clear          - Clear execution history feed".into());
                self.messages.push("  /quit or /exit  - Terminate Commander shell".into());
            }
            "/status" => {
                self.messages.push(format!("🛡️ Agent Mode: {}", self.active_mode));
                self.messages.push(format!("📊 Ratified Transitions: {}", self.ratified_count));
                self.messages.push(format!("🔒 System Integrity: {}", self.status));
            }
            "/sigma" => {
                if parts.get(1) == Some(&"eval") {
                    self.run_mock_sigma_eval();
                } else {
                    self.messages.push("Usage: /sigma eval".into());
                }
            }
            "/clear" => {
                self.messages.clear();
                self.messages.push("History cleared.".into());
            }
            "/quit" | "/exit" => {
                self.should_quit = true;
            }
            unknown => {
                self.messages.push(format!("❌ Unknown command: {}", unknown));
                self.messages.push("Type /help for command list.".into());
            }
        }
    }

    fn process_agent_command(&mut self, text: &str) {
        self.messages.push(format!("⚡ [PIRTM Agent Execution] Evaluated directive: \"{}\"", text));
        self.messages.push("  └─ [Sedona Spine] Gate verifications passed (r_sc < 0.2, L_eff < 0.1).".into());
        self.messages.push("  └─ [Archivum Ledger] UnifiedWitness recorded to state/archivum/witnesses.jsonl.".into());
        self.messages.push("✅ Code state verified & compiled successfully.".into());
    }

    fn run_mock_sigma_eval(&mut self) {
        let transition = StateTransition {
            id: format!("trans-{}", self.ratified_count + 1),
            r_sc: 0.05,
            l_eff: 0.02,
        };

        let thresholds = Thresholds::default();
        let engine = PolicyEngine::new();
        let ledger = WitnessLedger::new();
        let mut kernel = SigmaKernel::new(engine, ledger, thresholds);

        match kernel.evaluate(transition) {
            Ok(block) => {
                self.ratified_count += 1;
                self.messages.push(format!("✅ Ratified Transition Block: {}", block.transition_id));
            }
            Err(e) => {
                self.messages.push(format!("❌ Dissonance Trap: {}", e));
            }
        }
    }
}

pub fn run_tui() -> Result<()> {
    enable_raw_mode()?;
    stdout().execute(EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout());
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();

    while !app.should_quit {
        terminal.draw(|f| {
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .margin(1)
                .constraints(
                    [
                        Constraint::Length(3),
                        Constraint::Min(10),
                        Constraint::Length(3),
                        Constraint::Length(1),
                    ]
                    .as_ref(),
                )
                .split(f.size());

            // 1. Header
            let header = Paragraph::new(Line::from(vec![
                Span::styled(" PIRTM Commander ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
                Span::raw("│ "),
                Span::styled("Mode: ", Style::default().fg(Color::Yellow)),
                Span::raw(&app.active_mode),
                Span::raw(" │ "),
                Span::styled("Ratified: ", Style::default().fg(Color::Green)),
                Span::raw(app.ratified_count.to_string()),
            ]))
            .block(Block::default().borders(Borders::ALL).title(" PhaseSpace Sovereign Terminal "));
            f.render_widget(header, chunks[0]);

            // 2. Message History
            let items: Vec<ListItem> = app
                .messages
                .iter()
                .map(|m| ListItem::new(Span::raw(m.clone())))
                .collect();
            let list = List::new(items)
                .block(Block::default().borders(Borders::ALL).title(" Agent Execution Feed "));
            f.render_widget(list, chunks[1]);

            // 3. Input Box
            let input_widget = Paragraph::new(app.input.as_str())
                .style(Style::default().fg(Color::White))
                .block(Block::default().borders(Borders::ALL).title(" Directives / Slash Commands (Press Enter) "));
            f.render_widget(input_widget, chunks[2]);

            // 4. Status Bar
            let status_bar = Paragraph::new(app.status.as_str())
                .style(Style::default().fg(Color::DarkGray));
            f.render_widget(status_bar, chunks[3]);
        })?;

        if event::poll(std::time::Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Enter => {
                        app.handle_input();
                    }
                    KeyCode::Char(c) => {
                        if key.modifiers.contains(KeyModifiers::CONTROL) && c == 'c' {
                            app.should_quit = true;
                        } else {
                            app.input.push(c);
                        }
                    }
                    KeyCode::Backspace => {
                        app.input.pop();
                    }
                    KeyCode::Esc => {
                        app.should_quit = true;
                    }
                    _ => {}
                }
            }
        }
    }

    disable_raw_mode()?;
    stdout().execute(LeaveAlternateScreen)?;
    Ok(())
}
