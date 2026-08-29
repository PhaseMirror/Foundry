pub mod group;
pub mod mask;
pub mod logits;
pub mod csl;
pub mod sinkhorn;
pub mod unitarize;
pub mod projection;

pub use group::AutomorphicGroup;
pub use group::act;
pub use mask::legendre_symbol;
pub use mask::residue_mask;
pub use logits::additive_logits;
pub use csl::csl_loss;
pub use sinkhorn::sinkhorn;
pub use unitarize::unitarize_exp;
pub use projection::weighted_l1_proj;
pub use projection::weighted_l1_kkt;
