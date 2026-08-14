// src/pirtm/dialect/mlir_wrapper.rs
// Stub implementation for when MLIR is not available.
// In production, this would use mlir-sys bindings.

/// Context stub - would be MlirContext in production
#[derive(Clone, Copy)]
pub struct MlirContextStub;

/// Operation stub - would be MlirOperation in production
pub struct MlirOperationStub;

/// Attribute stub
#[derive(Clone)]
pub struct MlirAttributeStub;

/// Create a stub context.
pub fn create_context() -> MlirContextStub {
    MlirContextStub
}

/// Destroy a stub context.
pub fn destroy_context(_ctx: MlirContextStub) {}

/// Create an integer attribute.
pub fn create_integer_attr(_ctx: MlirContextStub, _val: i64) -> Result<MlirAttributeStub, String> {
    Ok(MlirAttributeStub)
}

/// Create a float attribute.
pub fn create_float_attr(_ctx: MlirContextStub, _val: f64) -> Result<MlirAttributeStub, String> {
    Ok(MlirAttributeStub)
}

/// Create a stub operation.
pub fn create_operation(
    _ctx: MlirContextStub,
    _name: &str,
    _attributes: &[(&str, MlirAttributeStub)],
) -> Result<MlirOperationStub, String> {
    Ok(MlirOperationStub)
}

/// Print a stub operation to string.
pub fn print_operation(_op: MlirOperationStub) -> Result<String, String> {
    Ok(
        "pirtm.stub { prime_index = 0 : i64, epsilon = 0.1 : f64, op_norm_t = 1.0 : f64 }"
            .to_string(),
    )
}
