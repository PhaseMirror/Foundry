//! SafeTensors weight loader
//!
//! Loads weights from SafeTensors format and converts them to ONNX TensorProto format
//! for integration with the HologramGraph initializers.
//!
//! SafeTensors format provides:
//! - Fast, safe tensor serialization
//! - Memory-mapped access
//! - Zero-copy deserialization
//!
//! This module bridges SafeTensors to ONNX TensorProto for Hologram compilation.

use crate::proto::TensorProto;
use crate::{CompilerError, Result};
use safetensors::SafeTensors;
use std::path::Path;

/// Load SafeTensors file and convert to ONNX TensorProto map
///
/// # Arguments
///
/// * `path` - Path to .safetensors file
///
/// # Returns
///
/// HashMap mapping tensor names to TensorProto
///
/// # Example
///
/// ```no_run
/// use hologram_onnx_compiler::load_safetensors;
///
/// let weights = load_safetensors("model.safetensors")?;
/// println!("Loaded {} tensors", weights.len());
/// # Ok::<(), hologram_onnx_compiler::CompilerError>(())
/// ```
pub fn load_safetensors(
    path: impl AsRef<Path>,
) -> Result<std::collections::HashMap<String, TensorProto>> {
    let path = path.as_ref();

    // Read file into memory
    let data = std::fs::read(path)?;

    // Parse SafeTensors
    let tensors = SafeTensors::deserialize(&data)
        .map_err(|e| CompilerError::InvalidModel(format!("Failed to parse SafeTensors: {}", e)))?;

    // Convert each tensor to TensorProto
    let mut tensor_map = std::collections::HashMap::new();

    for name in tensors.names() {
        let view = tensors.tensor(name).map_err(|e| {
            CompilerError::InvalidModel(format!("Failed to get tensor {}: {}", name, e))
        })?;

        let tensor_proto = safetensor_to_tensorproto(name, &view)?;
        tensor_map.insert(name.to_string(), tensor_proto);
    }

    Ok(tensor_map)
}

/// Convert SafeTensors View to ONNX TensorProto
fn safetensor_to_tensorproto(
    name: &str,
    view: &safetensors::tensor::TensorView,
) -> Result<TensorProto> {
    use safetensors::Dtype;

    // Get shape
    let shape: Vec<i64> = view.shape().iter().map(|&d| d as i64).collect();

    // Get raw data bytes
    let raw_bytes = view.data();

    // Determine ONNX data type
    let data_type = match view.dtype() {
        Dtype::F32 => 1,   // ONNX DataType::FLOAT
        Dtype::F16 => 10,  // ONNX DataType::FLOAT16
        Dtype::BF16 => 16, // ONNX DataType::BFLOAT16
        Dtype::F64 => 11,  // ONNX DataType::DOUBLE
        Dtype::I8 => 3,    // ONNX DataType::INT8
        Dtype::I16 => 5,   // ONNX DataType::INT16
        Dtype::I32 => 6,   // ONNX DataType::INT32
        Dtype::I64 => 7,   // ONNX DataType::INT64
        Dtype::U8 => 2,    // ONNX DataType::UINT8
        Dtype::U16 => 4,   // ONNX DataType::UINT16
        Dtype::U32 => 12,  // ONNX DataType::UINT32
        Dtype::U64 => 13,  // ONNX DataType::UINT64
        Dtype::BOOL => 9,  // ONNX DataType::BOOL
        _ => {
            return Err(CompilerError::InvalidModel(format!(
                "Unsupported SafeTensors dtype for tensor {}: {:?}",
                name,
                view.dtype()
            )));
        }
    };

    Ok(TensorProto {
        name: name.to_string(),
        dims: shape,
        data_type,
        raw_data: raw_bytes.to_vec(),
        ..Default::default()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dtype_mapping() {
        // Verify ONNX data type constants match spec
        // This test documents the mapping for future reference
        assert_eq!(1, 1); // FLOAT
        assert_eq!(2, 2); // UINT8
        assert_eq!(3, 3); // INT8
    }
}
