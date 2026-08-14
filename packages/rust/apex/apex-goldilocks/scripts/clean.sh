#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Hologram Clean Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Parse arguments
CLEAN_ALL=false
CLEAN_MODELS=false
CLEAN_BIN=false
CLEAN_WASM=false
CLEAN_CARGO=false
CLEAN_NODE=false

if [ $# -eq 0 ]; then
    # No arguments - show help
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all         Clean everything (models, binaries, wasm, cargo, node)"
    echo "  --models      Clean downloaded ONNX models"
    echo "  --bin         Clean compiled .bin models"
    echo "  --wasm        Clean WASM build artifacts"
    echo "  --cargo       Clean Rust build artifacts (cargo clean)"
    echo "  --node        Clean node_modules"
    echo ""
    echo "Examples:"
    echo "  $0 --bin --wasm    # Clean compiled models and WASM"
    echo "  $0 --all           # Clean everything"
    exit 0
fi

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --all)
            CLEAN_ALL=true
            ;;
        --models)
            CLEAN_MODELS=true
            ;;
        --bin)
            CLEAN_BIN=true
            ;;
        --wasm)
            CLEAN_WASM=true
            ;;
        --cargo)
            CLEAN_CARGO=true
            ;;
        --node)
            CLEAN_NODE=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

if [ "$CLEAN_ALL" = true ]; then
    CLEAN_MODELS=true
    CLEAN_BIN=true
    CLEAN_WASM=true
    CLEAN_CARGO=true
    CLEAN_NODE=true
fi

# Clean downloaded models
if [ "$CLEAN_MODELS" = true ]; then
    echo "🗑️  Cleaning ONNX models..."
    rm -rf public/public/models/onnx/sd-turbo
    rm -rf public/public/models/onnx/sd-turbo-external
    echo "   ✓ Removed ONNX models"
fi

# Clean compiled binaries
if [ "$CLEAN_BIN" = true ]; then
    echo "🗑️  Cleaning compiled .bin models..."
    rm -rf public/public/models/bin/sd-turbo
    echo "   ✓ Removed compiled binaries"
fi

# Clean WASM artifacts
if [ "$CLEAN_WASM" = true ]; then
    echo "🗑️  Cleaning WASM build artifacts..."
    rm -rf public/public/pkg
    rm -rf hologram-sdk/rust/hologram-wasm/pkg
    echo "   ✓ Removed WASM packages"
fi

# Clean Cargo build artifacts
if [ "$CLEAN_CARGO" = true ]; then
    echo "🗑️  Cleaning Rust build artifacts..."
    cargo clean
    echo "   ✓ Cargo clean complete"
fi

# Clean node_modules
if [ "$CLEAN_NODE" = true ]; then
    echo "🗑️  Cleaning node_modules..."
    rm -rf public/node_modules
    rm -rf public/.next
    echo "   ✓ Removed node_modules and .next"
fi

echo ""
echo "✅ Clean complete!"
echo ""
echo "To rebuild, run:"
echo "  ./scripts/build-all.sh"
