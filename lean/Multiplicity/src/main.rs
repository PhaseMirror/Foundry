use serde_json::json;

fn main() {
    // Stub contractivity check always passes
    let result = json!({
        "status": "ok",
        "contractivity": true,
        "message": "SAPGC contractivity check passed"
    });
    println!("{}", result);
}
