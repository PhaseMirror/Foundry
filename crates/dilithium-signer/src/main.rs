use clap::{Parser, Subcommand};
use pqcrypto_dilithium::dilithium5::*;
use pqcrypto_traits::sign::{PublicKey, SecretKey, DetachedSignature};
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
    }
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Keygen { sk_path, pk_path } => {
            let (pk, sk) = keypair();
            fs::write(pk_path, pk.as_bytes()).expect("Failed to write PK");
            fs::write(sk_path, sk.as_bytes()).expect("Failed to write SK");
            println!("Keys generated successfully.");
        }
        Commands::Sign { sk_path, msg_hex } => {
            let sk_bytes = fs::read(sk_path).expect("Failed to read SK");
            let sk = dilithium5_SecretKey::from_bytes(&sk_bytes).expect("Invalid SK bytes");
            let msg_bytes = hex::decode(msg_hex.trim_start_matches("0x")).expect("Invalid hex message");
            let sig = detached_sign(&msg_bytes, &sk);
            let sig_hex = hex::encode(sig.as_bytes());
            println!("0x{}", sig_hex);
        }
        Commands::Verify { pk_path, msg_hex, sig_hex } => {
            let pk_bytes = fs::read(pk_path).expect("Failed to read PK");
            let pk = dilithium5_PublicKey::from_bytes(&pk_bytes).expect("Invalid PK bytes");
            let msg_bytes = hex::decode(msg_hex.trim_start_matches("0x")).expect("Invalid hex message");
            let sig_bytes = hex::decode(sig_hex.trim_start_matches("0x")).expect("Invalid hex signature");
            let sig = dilithium5_DetachedSignature::from_bytes(&sig_bytes).expect("Invalid signature bytes");
            
            match verify_detached_signature(&sig, &msg_bytes, &pk) {
                Ok(_) => println!("Signature verified"),
                Err(_) => println!("Signature invalid"),
            }
        }
    }
}
