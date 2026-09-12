use ratchet::phase_a_transformer_agent::{ToolCall, ToolResult, TransformerAgentPlant};

#[test]
fn test_transformer_agent_attention_and_stepping() {
    let mut agent = TransformerAgentPlant::new(16);
    assert_eq!(agent.dimension, 16);

    let res = agent.step(Some(&ToolCall::Calculator {
        expr: "108 * 3".to_string(),
    }));

    match res {
        ToolResult::Success(val) => assert_eq!(val, "324"),
        _ => panic!("Expected successful arithmetic tool execution"),
    }

    assert_eq!(agent.state.t, 1);
    assert_eq!(agent.state.y.len(), 16);
}

#[test]
fn test_transformer_agent_ephemeral_memory_and_wipe() {
    let mut agent = TransformerAgentPlant::new(8);

    // Store key in ephemeral memory
    agent.step(Some(&ToolCall::MemoryStore {
        key: "intermediate_plan".to_string(),
        value: "attack_payload_latent".to_string(),
    }));

    // Fetch key before wipe
    let fetch_res = agent.step(Some(&ToolCall::MemoryFetch {
        key: "intermediate_plan".to_string(),
    }));
    assert_eq!(fetch_res, ToolResult::Success("attack_payload_latent".to_string()));

    // Mandatory burst exit wipe
    agent.tool_sandbox.wipe_ephemeral();

    // Fetch after wipe must fail
    let fetch_after = agent.step(Some(&ToolCall::MemoryFetch {
        key: "intermediate_plan".to_string(),
    }));
    match fetch_after {
        ToolResult::Error(msg) => assert!(msg.contains("not found")),
        _ => panic!("Memory was not wiped on burst boundary"),
    }
}

#[test]
fn test_unwhitelisted_code_execution_blocked() {
    let mut agent = TransformerAgentPlant::new(8);

    let res = agent.step(Some(&ToolCall::CodeExecution {
        command: "rm -rf /".to_string(),
    }));

    match res {
        ToolResult::Blocked(msg) => assert!(msg.contains("not in allowed whitelist")),
        _ => panic!("Unwhitelisted command was erroneously allowed in sandbox"),
    }
}
