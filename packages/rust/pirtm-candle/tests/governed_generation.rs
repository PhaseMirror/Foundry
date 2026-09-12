use pirtm_candle::{TinyLlamaConfig, TinyLlamaModel, GenerationConfig};
use candle_core::Device;

#[test]
fn test_governed_generation() {
    let mut config = TinyLlamaConfig::default();
    // Reduce sizes so the dummy model doesn't take gigabytes of RAM in the test
    config.hidden_size = 64;
    config.intermediate_size = 128;
    config.num_hidden_layers = 2;
    config.num_attention_heads = 4;
    config.num_kv_heads = 2;
    config.vocab_size = 1000;

    let device = Device::Cpu;
    let lambda_m = 0.95;

    let mut model = TinyLlamaModel::load_dummy(config, device, lambda_m).expect("Failed to load dummy model");

    let gen_config = GenerationConfig {
        max_tokens: 8,
        temperature: 0.7,
        top_p: 0.9,
        lambda_m: 0.95,
    };

    let prompt_tokens = vec![1, 10, 20];
    let output = model.generate_governed(&prompt_tokens, gen_config).expect("Generation failed");

    // We passed 3 prompt tokens and asked for 8 max tokens
    // Actually generate_governed loops max_tokens times (8 times)
    assert_eq!(output.receipt.lambda_trace.zero_spacings.len(), 8);
    
    let product = output.receipt.lambda_trace.lambda_p * output.receipt.lambda_trace.l_p;
    assert!(product < 1.0, "Contractivity violation in test: {}", product);
    assert_eq!(output.receipt.status, "OK");
}
