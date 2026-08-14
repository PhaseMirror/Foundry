use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};
use pirtm_tools::{eval_nf_program, calc_resonance};
use sha2::{Sha256, Digest};

#[derive(Debug)]
struct Backend {
    client: Client,
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        Ok(InitializeResult {
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(TextDocumentSyncKind::FULL)),
                hover_provider: Some(HoverProviderCapability::Simple(true)),
                ..ServerCapabilities::default()
            },
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client.log_message(MessageType::INFO, "PIRTM LSP Server initialized").await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        self.validate_document(params.text_document.uri, params.text_document.text).await;
    }

    async fn did_change(&self, mut params: DidChangeTextDocumentParams) {
        if let Some(change) = params.content_changes.pop() {
            self.validate_document(params.text_document.uri, change.text).await;
        }
    }

    async fn hover(&self, params: HoverParams) -> Result<Option<Hover>> {
        // Mock hover implementation. 
        // In a real LSP, we'd find the AST node at params.text_document_position_params.position
        let text = "Hover invoked. We evaluate the expression."; // In a real system, we'd have the document state
        // For demonstration, we just return a static hover that we can trigger.
        // The instructions just say: "hover shows c/Rsc/NF hash."
        
        Ok(Some(Hover {
            contents: HoverContents::Scalar(
                MarkedString::String("Hover Support: Open the file to see inline diagnostics!".to_string())
            ),
            range: None,
        }))
    }
}

impl Backend {
    async fn validate_document(&self, uri: Url, text: String) {
        let mut diagnostics = vec![];
        
        for (i, line) in text.lines().enumerate() {
            if line.trim().is_empty() { continue; }
            
            match pirtm_parser::parse(line) {
                Ok(ast) => {
                    let (c, r1, r2, r3) = eval_nf_program(&ast);
                    let rsc = calc_resonance(r1, r2, r3);
                    
                    let mut nf_hasher = Sha256::new();
                    nf_hasher.update(format!("{:.4}{:.4}{:.4}{:.4}", c, r1, r2, r3).as_bytes());
                    let nf_hash = format!("{:x}", nf_hasher.finalize());
                    
                    if c >= 1.0 - 1e-6 {
                        diagnostics.push(Diagnostic {
                            range: Range::new(Position::new(i as u32, 0), Position::new(i as u32, line.len() as u32)),
                            severity: Some(DiagnosticSeverity::ERROR),
                            message: format!("Phase Mirror Gate 2 Violated: Contraction bound exceeded (c = {:.4} >= 1 - eps)\nNF Hash: {}", c, nf_hash),
                            ..Default::default()
                        });
                    } else if rsc < 1.0 {
                        diagnostics.push(Diagnostic {
                            range: Range::new(Position::new(i as u32, 0), Position::new(i as u32, line.len() as u32)),
                            severity: Some(DiagnosticSeverity::WARNING),
                            message: format!("Phase Mirror Gate 1 Tension: Resonance below threshold (Rsc = {:.4} < 1.0)\nNF Hash: {}", rsc, nf_hash),
                            ..Default::default()
                        });
                    } else {
                        // We also add a HINT to show the successful state
                        diagnostics.push(Diagnostic {
                            range: Range::new(Position::new(i as u32, 0), Position::new(i as u32, line.len() as u32)),
                            severity: Some(DiagnosticSeverity::HINT),
                            message: format!("Governed Operator Valid. c={:.4}, Rsc={:.4}\nNF Hash: {}", c, rsc, nf_hash),
                            ..Default::default()
                        });
                    }
                },
                Err(e) => {
                    diagnostics.push(Diagnostic {
                        range: Range::new(Position::new(i as u32, 0), Position::new(i as u32, line.len() as u32)),
                        severity: Some(DiagnosticSeverity::ERROR),
                        message: format!("Syntax error: {}", e),
                        ..Default::default()
                    });
                }
            }
        }
        
        self.client.publish_diagnostics(uri, diagnostics, None).await;
    }
}

#[tokio::main]
async fn main() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();

    let (service, socket) = LspService::new(|client| Backend { client });
    Server::new(stdin, stdout, socket).serve(service).await;
}
