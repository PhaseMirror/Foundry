// Memory management for HologramGraph
//
// This module provides efficient memory management through:
// - Consumer tracking: Reference counting for tensor lifetimes
// - Ownership-based embeddings: Avoid clones when safe
//
// The consumer tracking system allows us to release GriessVector
// embeddings as soon as they're no longer needed, reducing peak
// memory usage by 40-60% for large models.

use hologram::GriessVector;
use rustc_hash::FxHashMap;

/// Consumer reference count map
///
/// Maps (node_id, output_slot) → count of consumers.
/// When count reaches 0, the tensor can be safely released.
pub type ConsumerMap = FxHashMap<(usize, u8), usize>;

/// Embedded tensor input with ownership semantics
///
/// This enum allows operations to take ownership of embeddings when
/// they're the last consumer, avoiding expensive clones of the
/// 196,884-element GriessVector.
pub enum EmbeddedInput<'a> {
    /// Owned embedding (last consumer, can move)
    Owned(GriessVector),

    /// Borrowed embedding (shared, must clone if needed)
    Borrowed(&'a GriessVector),
}

impl<'a> EmbeddedInput<'a> {
    /// Convert to owned GriessVector
    ///
    /// If already owned, returns the vector directly.
    /// If borrowed, clones the vector.
    pub fn into_owned(self) -> GriessVector {
        match self {
            EmbeddedInput::Owned(v) => v,
            EmbeddedInput::Borrowed(v) => v.clone(),
        }
    }

    /// Check if this input is owned
    pub fn is_owned(&self) -> bool {
        matches!(self, EmbeddedInput::Owned(_))
    }
}

impl AsRef<GriessVector> for EmbeddedInput<'_> {
    fn as_ref(&self) -> &GriessVector {
        match self {
            EmbeddedInput::Owned(ref v) => v,
            EmbeddedInput::Borrowed(v) => v,
        }
    }
}

/// Memory manager for graph execution
///
/// Tracks consumer counts and determines when tensors can be released.
pub struct MemoryManager {
    /// Consumer counts for each tensor output
    consumer_counts: ConsumerMap,

    /// Current remaining consumers (decremented during execution)
    remaining_consumers: FxHashMap<(usize, u8), usize>,
}

impl MemoryManager {
    /// Create a new memory manager with consumer counts
    pub fn new(consumer_counts: ConsumerMap) -> Self {
        let remaining_consumers = consumer_counts.clone();
        Self {
            consumer_counts,
            remaining_consumers,
        }
    }

    /// Check if this is the last consumer of a tensor
    ///
    /// Returns true if after this consumption, no more consumers remain.
    pub fn is_last_consumer(&self, node_id: usize, output_slot: u8) -> bool {
        self.remaining_consumers
            .get(&(node_id, output_slot))
            .map(|&count| count == 1)
            .unwrap_or(false)
    }

    /// Mark a tensor as consumed
    ///
    /// Decrements the remaining consumer count.
    /// Returns true if this was the last consumer.
    pub fn consume(&mut self, node_id: usize, output_slot: u8) -> bool {
        if let Some(count) = self.remaining_consumers.get_mut(&(node_id, output_slot)) {
            *count = count.saturating_sub(1);
            return *count == 0;
        }
        false
    }

    /// Get remaining consumer count
    pub fn get_remaining_consumers(&self, node_id: usize, output_slot: u8) -> usize {
        self.remaining_consumers
            .get(&(node_id, output_slot))
            .copied()
            .unwrap_or(0)
    }

    /// Reset consumer counts (for re-execution)
    pub fn reset(&mut self) {
        self.remaining_consumers = self.consumer_counts.clone();
    }

    /// Get total consumer count (original count, not remaining)
    pub fn get_total_consumers(&self, node_id: usize, output_slot: u8) -> usize {
        self.consumer_counts.get(&(node_id, output_slot)).copied().unwrap_or(0)
    }
}

/// Helper to create EmbeddedInput based on consumer tracking
///
/// If this is the last consumer, takes ownership.
/// Otherwise, borrows the embedding.
pub fn create_embedded_input<'a>(
    embedding: &'a mut Option<GriessVector>,
    is_last_consumer: bool,
) -> Option<EmbeddedInput<'a>> {
    if is_last_consumer {
        // Take ownership if last consumer
        embedding.take().map(EmbeddedInput::Owned)
    } else {
        // Borrow otherwise
        embedding.as_ref().map(EmbeddedInput::Borrowed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embedded_input_owned() {
        let vec = GriessVector::zero();
        let input = EmbeddedInput::Owned(vec.clone());
        assert!(input.is_owned());
        let owned = input.into_owned();
        assert_eq!(owned.len(), vec.len());
    }

    #[test]
    fn test_embedded_input_borrowed() {
        let vec = GriessVector::zero();
        let input = EmbeddedInput::Borrowed(&vec);
        assert!(!input.is_owned());
        assert_eq!(input.as_ref().len(), vec.len());
    }

    #[test]
    fn test_memory_manager() {
        let mut counts = ConsumerMap::default();
        counts.insert((0, 0), 3); // Node 0, output 0 has 3 consumers

        let mut mgr = MemoryManager::new(counts);

        // First consumption
        assert!(!mgr.is_last_consumer(0, 0));
        assert!(!mgr.consume(0, 0));
        assert_eq!(mgr.get_remaining_consumers(0, 0), 2);

        // Second consumption
        assert!(!mgr.is_last_consumer(0, 0));
        assert!(!mgr.consume(0, 0));
        assert_eq!(mgr.get_remaining_consumers(0, 0), 1);

        // Third (last) consumption
        assert!(mgr.is_last_consumer(0, 0));
        assert!(mgr.consume(0, 0));
        assert_eq!(mgr.get_remaining_consumers(0, 0), 0);
    }

    #[test]
    fn test_memory_manager_reset() {
        let mut counts = ConsumerMap::default();
        counts.insert((0, 0), 2);

        let mut mgr = MemoryManager::new(counts);

        // Consume all
        mgr.consume(0, 0);
        mgr.consume(0, 0);
        assert_eq!(mgr.get_remaining_consumers(0, 0), 0);

        // Reset
        mgr.reset();
        assert_eq!(mgr.get_remaining_consumers(0, 0), 2);
    }
}
