//! Truth-Value Algebras Modules

pub mod classical;
pub mod fuzzy;
pub mod heyting;
pub mod modal;
pub mod quantum;

pub use classical::*;
pub use fuzzy::*;
pub use heyting::*;
pub use modal::*;
pub use quantum::*;
