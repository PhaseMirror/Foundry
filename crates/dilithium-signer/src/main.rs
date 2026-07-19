use clap::{Parser, Subcommand};
use dilithium_signer::{keygen, sign, verify};
use std::fs;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate a new Dilithium keypair
    Keygen {
        /// Output path for the secret key
        #[arg(short, long)]
        sk_path: String,
        /// Output path for the public key
        #[arg(short, long)]
        pk_path: String,
    },
    /// Sign a message using a detached signature
    Sign {
        /// Path to the secret key
        #[arg(short, long)]
        sk_path: String,
        /// The message to sign (in hex)
        #[arg(short, long)]
        msg_hex: String,
    },
    /// Verify a detached signature
    Verify {
        /// Path to the public key
        #[arg(short, long)]
        pk_path: String,
        /// The message that was signed (in hex)
        #[arg(short, long)]
        msg_hex: String,
        /// The detached signature (in hex)
        #[arg(short, long)]
        sig_hex: String,
    },
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Keygen { sk_path, pk_path } => {
            let (pk_bytes, sk_bytes) = keygen();
            fs::write(pk_path, pk_bytes).expect("Failed to write PK");
            fs::write(sk_path, sk_bytes).expect("Failed to write SK");
            println!("Keys generated successfully.");
        }
        Commands::Sign { sk_path, msg_hex } => {
            let sk_bytes = fs::read(sk_path).expect("Failed to read SK");
            let msg_bytes = hex::decode(msg_hex.trim_start_matches("0x")).expect("Invalid hex message");
            let sig = sign(&sk_bytes, &msg_bytes);
            let sig_hex = hex::encode(sig);
            println!("0x{}", sig_hex);
        }
        Commands::Verify { pk_path, msg_hex, sig_hex } => {
            let pk_bytes = fs::read(pk_path).expect("Failed to read PK");
            let msg_bytes = hex::decode(msg_hex.trim_start_matches("0x")).expect("Invalid hex message");
            let sig_bytes = hex::decode(sig_hex.trim_start_matches("0x")).expect("Invalid hex signature");
            match verify(&pk_bytes, &msg_bytes, &sig_bytes) {
                Ok(()) => println!("Signature verified"),
                Err(()) => println!("Signature invalid"),
            }
        }
    }
}
