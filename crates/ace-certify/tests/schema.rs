use ace_certify::*;

#[test]
fn test_validate_schema_version_1_valid() {
    let telemetry = KernelTelemetry {
        xn_kernel: 0.1,
        wt_max_kernel: 0.2,
        protection_zeta: 0.3,
        is_valid_kernel: true,
        telemetry_version: 1,
    };
    let cert = ACECertificate::from_telemetry(&[1, 2, 3], telemetry, &[4, 5, 6]);
    assert!(cert.validate_schema().is_ok());
}

#[test]
fn test_validate_schema_version_1_empty_field() {
    let telemetry = KernelTelemetry {
        xn_kernel: 0.1,
        wt_max_kernel: 0.2,
        protection_zeta: 0.3,
        is_valid_kernel: true,
        telemetry_version: 1,
    };
    let cert = ACECertificate::from_telemetry(&[], telemetry, &[4, 5, 6]);
    assert_eq!(cert.validate_schema(), Err(CertificateSchemaError::EmptyField));
}

#[test]
fn test_validate_schema_unsupported_version_0() {
    let telemetry = KernelTelemetry {
        xn_kernel: 0.1,
        wt_max_kernel: 0.2,
        protection_zeta: 0.3,
        is_valid_kernel: true,
        telemetry_version: 0,
    };
    let cert = ACECertificate::from_telemetry(&[1, 2, 3], telemetry, &[4, 5, 6]);
    assert_eq!(cert.validate_schema(), Err(CertificateSchemaError::UnsupportedVersion(0)));
}

#[test]
fn test_validate_schema_unsupported_version_unknown() {
    let telemetry = KernelTelemetry {
        xn_kernel: 0.1,
        wt_max_kernel: 0.2,
        protection_zeta: 0.3,
        is_valid_kernel: true,
        telemetry_version: 42,
    };
    let cert = ACECertificate::from_telemetry(&[1, 2, 3], telemetry, &[4, 5, 6]);
    assert_eq!(cert.validate_schema(), Err(CertificateSchemaError::UnsupportedVersion(42)));
}

#[test]
fn test_python_serialization_roundtrip() {
    use std::process::Command;
    
    let output = Command::new("python3")
        .arg("../../src/ace/governor.py")
        .arg("test_roundtrip")
        .output()
        .expect("Failed to execute Python script");
        
    assert!(output.status.success(), "Python script failed");
    
    let json_str = String::from_utf8(output.stdout).expect("Invalid UTF-8");
    let cert: ACECertificate = serde_json::from_str(&json_str).expect("Failed to deserialize JSON to ACECertificate");
    
    assert_eq!(cert.telemetry_version, 1);
    assert_eq!(cert.xn_kernel, 0.123);
    assert_eq!(cert.is_valid_kernel, 1);
    assert_eq!(cert.theta, b"theta_base_mock".to_vec());
    assert_eq!(cert.outputs, b"outputs_mock".to_vec());
}
