use serde_json::Value;

pub fn record_event(_name: impl Into<String>, _payload: Value) -> Result<(), String> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_record_event_accepts_any_payload() {
        let result = record_event("test_event", serde_json::json!({"key": "value"}));
        assert!(result.is_ok());
    }

    #[test]
    fn test_record_event_accepts_empty_name() {
        let result = record_event("", serde_json::json!({}));
        assert!(result.is_ok());
    }
}
pub mod overlay;
