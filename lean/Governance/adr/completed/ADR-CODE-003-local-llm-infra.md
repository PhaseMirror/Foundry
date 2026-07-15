# ADR-CODE-003: Local LLM Infrastructure (Ollama)

## Status
Proposed

## Context
A reliable, high-performance local inference server is the foundation of the local coding stack. We need to standardize on a backend that supports modern coding models, provides a stable API, and is easy for developers to deploy across Linux, macOS, and Windows.

## Decision
We select **Ollama** as the primary local LLM infrastructure for the Commander ecosystem.

1. **Standard API**: We will utilize Ollama's OpenAI-compatible `/v1` endpoint for compatibility with most agentic planners.
2. **Model Selection**: The default recommended model for coding tasks is `qwen2.5-coder` (or the latest `qwen3-coder` variant) due to its high performance-to-size ratio and tool-use capabilities.
3. **Configuration (Modelfile)**: We will provide a standard `Ollama Modelfile` to ensure consistent temperature, context window (defaulting to 32,768 tokens), and system prompts across developer machines.
4. **Service Management**: Ollama will be managed as a background service (`ollama serve`). Commander will not manage the Ollama lifecycle but will verify connectivity at startup.

## Consequences
- **Ease of Setup**: Developers can get a working stack with a single `ollama run` command.
- **Resource Efficiency**: Ollama's efficient quantization and GPU acceleration allow robust coding agents to run on consumer-grade hardware.
- **Abstraction**: While Ollama is the default, the use of a standard OpenAI-compatible API means we can switch to `LM Studio` or `LocalAI` by simply changing a URL in `state/mcp_registry.yaml`.

## Verification
- Connectivity check: `curl http://localhost:11434/api/tags` should return the list of pulled models.
- Performance benchmark: A `coding.plan` request for a 10-file refactor should complete in under 30 seconds on a standard developer workstation (16GB RAM + M1/M2 or NVIDIA RTX GPU).
- The `mcp_registry.yaml` must contain a verified entry for the Ollama endpoint.
