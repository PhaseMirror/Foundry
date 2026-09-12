//! A counting global allocator (`CA-01`).
//!
//! R7 says the shipped crates allocate nothing. The absence of an `alloc`
//! dependency makes that true by construction, and this makes it *observable*:
//! a counter that increments on every allocation, and a test that runs a GEMM
//! between two readings.
//!
//! Construction and observation are different kinds of evidence, and the
//! second is the one that survives a refactor. A dependency added in the wrong
//! place would fail the build; a `Vec` introduced through some future generic
//! would not, and this is what would catch it.

use std::alloc::{GlobalAlloc, Layout, System};
use std::cell::Cell;

// Per *thread*, not per process. The test harness runs tests in parallel, and a
// process-wide counter would attribute another thread's allocations to the call
// under measurement --- which is not a small effect, it is the difference
// between a measurement and a coin flip.
thread_local! {
    /// Allocations on this thread.
    static ALLOCATIONS: Cell<usize> = const { Cell::new(0) };
    /// Bytes allocated on this thread.
    static BYTES: Cell<usize> = const { Cell::new(0) };
}

/// Bump both counters, unless the thread is shutting down and its locals are
/// already gone --- in which case there is nothing left to measure.
fn record(bytes: usize) {
    let _ = ALLOCATIONS.try_with(|c| c.set(c.get().wrapping_add(1)));
    let _ = BYTES.try_with(|c| c.set(c.get().wrapping_add(bytes)));
}

/// A pass-through allocator that counts.
pub struct Counting;

// SAFETY: every method forwards to `System`, which is a correct global
// allocator, and the counters are thread-local cells with no bearing on the
// memory returned.
unsafe impl GlobalAlloc for Counting {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        record(layout.size());
        // SAFETY: `layout` came from the caller and is forwarded unchanged.
        unsafe { System.alloc(layout) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        // SAFETY: `ptr` and `layout` came from a matching `alloc` call.
        unsafe { System.dealloc(ptr, layout) }
    }

    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        record(new_size);
        // SAFETY: `ptr`, `layout`, and `new_size` satisfy `realloc`'s contract
        // by the caller's obligation, and are forwarded unchanged.
        unsafe { System.realloc(ptr, layout, new_size) }
    }
}

/// A reading of the counters.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Reading {
    /// Allocation calls.
    pub allocations: usize,
    /// Bytes requested.
    pub bytes: usize,
}

/// Read this thread's counters now.
pub fn read() -> Reading {
    Reading {
        allocations: ALLOCATIONS.with(Cell::get),
        bytes: BYTES.with(Cell::get),
    }
}

/// What `body` allocated, on this thread.
///
/// Everything the call needs must already exist: this measures the *call*, and
/// a buffer allocated inside the closure would be counted against the library
/// that did not allocate it.
pub fn measure<T>(body: impl FnOnce() -> T) -> (T, Reading) {
    let before = read();
    let value = body();
    let after = read();
    (
        value,
        Reading {
            allocations: after.allocations - before.allocations,
            bytes: after.bytes - before.bytes,
        },
    )
}
