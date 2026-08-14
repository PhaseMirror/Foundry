// Minimal Kani stub – only the #[kani::proof] attribute.

extern crate proc_macro;
use proc_macro::TokenStream;

#[proc_macro_attribute]
pub fn proof(_attr: TokenStream, item: TokenStream) -> TokenStream {
    // In the real Kani crate this registers a verification harness.
    // Here we simply pass the function through unchanged.
    item
}
