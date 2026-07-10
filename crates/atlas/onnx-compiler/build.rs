fn main() {
    // Compile ONNX protobuf definitions
    let proto_path = "../hologram-onnx/proto/onnx.proto3";

    // Check if proto file exists
    if std::path::Path::new(proto_path).exists() {
        prost_build::Config::new()
            .out_dir("src/proto")
            .compile_protos(&[proto_path], &["../hologram-onnx/proto/"])
            .expect("Failed to compile ONNX protobuf");

        println!("cargo:rerun-if-changed={}", proto_path);
    } else {
        eprintln!("Warning: ONNX proto file not found at {}", proto_path);
    }
}
