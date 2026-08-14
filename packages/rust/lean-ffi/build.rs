fn main() -> Result<(), Box<dyn std::error::Error>> {
    lean_toolchain::CargoLeanCapability::new("lean", "FFI")
        .package("Prime")
        .module("FFI")
        .build()?;
    Ok(())
}
