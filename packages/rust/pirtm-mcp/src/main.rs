use clap::Parser;
use pirtm_mcp::McpServer;
use std::io::{self, BufReader, BufWriter};
use std::net::TcpListener;

#[derive(Parser, Debug)]
#[command(name = "pirtm-mcp", about = "Model Context Protocol server for PIRTM formal governance")]
struct Args {
    /// Transport mode: stdio or tcp
    #[arg(short, long, default_value = "stdio")]
    transport: String,

    /// Port for TCP transport
    #[arg(short, long, default_value_t = 8090)]
    port: u16,
}

fn main() -> Result<(), anyhow::Error> {
    let args = Args::parse();
    let server = McpServer::new();

    match args.transport.as_str() {
        "stdio" => {
            eprintln!("PIRTM MCP Server running on stdio");
            let stdin = io::stdin();
            let stdout = io::stdout();
            server.run_stdio(stdin.lock(), stdout.lock())?;
        }
        "tcp" => {
            let addr = format!("127.0.0.1:{}", args.port);
            eprintln!("PIRTM MCP Server listening on TCP {}", addr);
            let listener = TcpListener::bind(&addr)?;
            for stream in listener.incoming() {
                if let Ok(stream) = stream {
                    let reader = BufReader::new(stream.try_clone()?);
                    let writer = BufWriter::new(stream);
                    let _ = server.run_connection(reader, writer);
                }
            }
        }
        other => {
            eprintln!("Unknown transport '{}', defaulting to stdio", other);
            let stdin = io::stdin();
            let stdout = io::stdout();
            server.run_stdio(stdin.lock(), stdout.lock())?;
        }
    }

    Ok(())
}
