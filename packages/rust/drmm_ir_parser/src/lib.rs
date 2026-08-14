pub mod ast;
pub mod canonical;
pub mod cli;
pub mod error;
pub mod parser;

pub use ast::*;
pub use canonical::{canonical_hash, canonicalize, canonicalize_doc};
pub use error::{IrError, Result};
pub use parser::{parse_ir, parse_ir_file, validate_ir};
