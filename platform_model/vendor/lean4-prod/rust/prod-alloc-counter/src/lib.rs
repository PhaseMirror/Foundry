//! A counting global allocator, for tests that must prove code never touches
//! the heap.
//!
//! The project's engineering standard requires the generated code to run
//! allocation-free. That is not something a type signature can prove, so
//! `prod-core` certifies it empirically: install [`CountingAllocator`] as the
//! test binary's global allocator, snapshot [`activity`], run the generated
//! functions, and assert the snapshot did not move.
//!
//! This crate exists purely so that the one `unsafe impl GlobalAlloc` lives
//! somewhere other than `prod-core`, which forbids unsafe code in every one of
//! its targets. Do not depend on it outside `dev-dependencies`.
//!
//! # Usage
//!
//! ```ignore
//! #[global_allocator]
//! static ALLOCATOR: CountingAllocator = CountingAllocator;
//!
//! let before = activity();
//! let result = some_generated_fn(..);
//! assert_eq!(activity(), before, "generated code allocated");
//! ```
//!
//! Counts are process-global, so tests using them must run serially
//! (`--test-threads=1`). Each integration test file is its own binary, which
//! keeps the blast radius to that file.

use std::alloc::{GlobalAlloc, Layout, System};
use std::cell::Cell;
use std::sync::atomic::{AtomicUsize, Ordering};

/// Every allocation, reallocation, and deallocation the process has performed
/// since start-up, as one saturating counter.
static ACTIVITY: AtomicUsize = AtomicUsize::new(0);

thread_local! {
    /// Scoped measurements deliberately ignore allocator traffic from the
    /// test harness and other worker threads. Both cells have const
    /// initializers, so entering the measurement cannot itself allocate.
    static MEASURING: Cell<bool> = const { Cell::new(false) };
    static SCOPED_ACTIVITY: Cell<usize> = const { Cell::new(0) };
}

/// Total heap operations observed so far.
///
/// Only differences between two readings are meaningful: the test harness
/// itself allocates before and after the code under test.
pub fn activity() -> usize {
    ACTIVITY.load(Ordering::Relaxed)
}

/// Run `body` while counting heap operations performed by its current thread.
///
/// The process-global [`activity`] counter is useful as an installation
/// tripwire, but a test runner may allocate concurrently on another thread.
/// This scoped counter isolates the generated call without hiding any
/// allocation, reallocation, or deallocation it performs. Measurements may
/// not be nested.
pub fn measure<T>(body: impl FnOnce() -> T) -> (T, usize) {
    MEASURING.with(|measuring| {
        assert!(
            !measuring.replace(true),
            "allocator measurements may not nest"
        );
    });
    SCOPED_ACTIVITY.with(|activity| activity.set(0));

    struct Reset;
    impl Drop for Reset {
        fn drop(&mut self) {
            MEASURING.with(|measuring| measuring.set(false));
        }
    }

    let reset = Reset;
    let value = body();
    let count = SCOPED_ACTIVITY.with(Cell::get);
    drop(reset);
    (value, count)
}

/// A pass-through global allocator that counts every heap operation.
///
/// Allocation itself is delegated to the system allocator unchanged, so
/// installing this affects timing but never behaviour.
pub struct CountingAllocator;

impl CountingAllocator {
    fn record() {
        // `Relaxed` is enough: tests that read this counter run serially, and
        // the counter is a tripwire, not a synchronisation point.
        ACTIVITY.fetch_add(1, Ordering::Relaxed);
        let measuring = MEASURING.try_with(Cell::get).unwrap_or(false);
        if measuring {
            let _ = SCOPED_ACTIVITY.try_with(|activity| {
                activity.set(activity.get().saturating_add(1));
            });
        }
    }
}

// SAFETY: every method forwards to `System`, which upholds the `GlobalAlloc`
// contract, with the same layout and pointer arguments it was given. The added
// work is an atomic counter increment, which cannot unwind or reenter the
// allocator.
unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        Self::record();
        unsafe { System.alloc(layout) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        Self::record();
        unsafe { System.dealloc(ptr, layout) }
    }

    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        Self::record();
        unsafe { System.realloc(ptr, layout, new_size) }
    }

    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        Self::record();
        unsafe { System.alloc_zeroed(layout) }
    }
}
