#!/usr/bin/env python3
"""
PyTorch to ONNX Converter

Converts PyTorch models (from SafeTensors) to ONNX format.
Called by the Rust wrapper in src/pytorch_converter.rs.

Supports:
- Stable Diffusion components (UNet, VAE, TextEncoder)
- Transformers (BERT, GPT, etc.)
- Vision models (ViT, etc.)

Dependencies:
- torch
- onnx
- onnxruntime
- transformers (for HuggingFace models)
- diffusers (for Stable Diffusion)
- safetensors
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, Optional, Tuple

def check_imports():
    """Check if required packages are installed"""
    required = {
        'torch': 'torch',
        'onnx': 'onnx',
        'transformers': 'transformers',
        'diffusers': 'diffusers',
        'safetensors': 'safetensors',
    }

    missing = []
    for name, package in required.items():
        try:
            __import__(package)
        except ImportError:
            missing.append(name)

    if missing:
        print(f"Error: Missing required packages: {', '.join(missing)}", file=sys.stderr)
        print(f"Install with: pip install {' '.join(missing)}", file=sys.stderr)
        sys.exit(1)


def detect_model_type(model_dir: Path) -> str:
    """Auto-detect model type from directory structure"""
    config_file = model_dir / "config.json"
    model_index = model_dir.parent / "model_index.json"

    # Check for Stable Diffusion
    if model_index.exists():
        return "stable-diffusion"

    # Check config.json for architecture hints
    if config_file.exists():
        with open(config_file) as f:
            config = json.load(f)

        # Check for specific architecture types
        if "_class" in config or "architectures" in config:
            arch = config.get("_class") or config.get("architectures", [""])[0]
            arch_lower = arch.lower()

            if "bert" in arch_lower:
                return "bert"
            elif "gpt" in arch_lower:
                return "gpt"
            elif "vit" in arch_lower or "vision" in arch_lower:
                return "vit"
            elif "unet" in arch_lower or "vae" in arch_lower:
                return "stable-diffusion"

    return "auto"


def convert_stable_diffusion(
    model_dir: Path,
    output_path: Path,
    opset_version: int,
    dynamic_axes: bool,
    optimize: bool,
    external_data: bool,
    verbose: bool,
) -> None:
    """Convert Stable Diffusion component to ONNX"""
    import torch
    from diffusers import (
        UNet2DConditionModel,
        AutoencoderTiny,
        AutoencoderKL,
    )
    from transformers import CLIPTextModel

    config_file = model_dir / "config.json"
    if not config_file.exists():
        raise ValueError(f"No config.json found in {model_dir}")

    with open(config_file) as f:
        config = json.load(f)

    # Detect component type
    model_class = config.get("_class_name", "")

    if verbose:
        print(f"Detected model class: {model_class}")

    # Load model based on type
    if "UNet" in model_class:
        model = UNet2DConditionModel.from_pretrained(model_dir)
        # Dummy inputs for UNet
        batch_size = 1
        sample = torch.randn(batch_size, 4, 64, 64)
        timestep = torch.tensor([1])
        encoder_hidden_states = torch.randn(batch_size, 77, 768)
        dummy_input = (sample, timestep, encoder_hidden_states)
        input_names = ["sample", "timestep", "encoder_hidden_states"]
        output_names = ["out_sample"]

        if dynamic_axes:
            dynamic_ax = {
                "sample": {0: "batch", 2: "height", 3: "width"},
                "encoder_hidden_states": {0: "batch", 1: "sequence"},
                "out_sample": {0: "batch", 2: "height", 3: "width"},
            }
        else:
            dynamic_ax = None

    elif "AutoencoderTiny" in model_class:
        model = AutoencoderTiny.from_pretrained(model_dir)
        batch_size = 1
        latent = torch.randn(batch_size, 4, 64, 64)
        dummy_input = latent
        input_names = ["latent"]
        output_names = ["image"]
        dynamic_ax = {"latent": {0: "batch"}, "image": {0: "batch"}} if dynamic_axes else None

    elif "AutoencoderKL" in model_class or "Autoencoder" in model_class:
        model = AutoencoderKL.from_pretrained(model_dir)
        batch_size = 1
        image = torch.randn(batch_size, 3, 512, 512)
        dummy_input = image
        input_names = ["image"]
        output_names = ["latent"]
        dynamic_ax = {"image": {0: "batch"}, "latent": {0: "batch"}} if dynamic_axes else None

    elif "CLIP" in model_class or "TextModel" in model_class:
        model = CLIPTextModel.from_pretrained(model_dir)
        batch_size = 1
        seq_length = 77
        input_ids = torch.randint(0, 49408, (batch_size, seq_length))
        dummy_input = input_ids
        input_names = ["input_ids"]
        output_names = ["last_hidden_state"]
        dynamic_ax = {
            "input_ids": {0: "batch", 1: "sequence"},
            "last_hidden_state": {0: "batch", 1: "sequence"}
        } if dynamic_axes else None
    else:
        raise ValueError(f"Unsupported Stable Diffusion component: {model_class}")

    # Set to eval mode
    model.eval()

    if verbose:
        print(f"Exporting to ONNX with opset {opset_version}...")

    # Export to ONNX
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        opset_version=opset_version,
        input_names=input_names,
        output_names=output_names,
        dynamic_axes=dynamic_ax,
        do_constant_folding=optimize,
        export_params=not external_data,
    )

    if verbose:
        print(f"✓ Exported to {output_path}")


def convert_transformer(
    model_dir: Path,
    output_path: Path,
    model_type: str,
    opset_version: int,
    dynamic_axes: bool,
    optimize: bool,
    external_data: bool,
    verbose: bool,
) -> None:
    """Convert transformer model to ONNX"""
    import torch
    from transformers import AutoModel, AutoConfig

    config = AutoConfig.from_pretrained(model_dir)
    model = AutoModel.from_pretrained(model_dir)
    model.eval()

    # Dummy inputs
    batch_size = 1
    seq_length = 128
    input_ids = torch.randint(0, config.vocab_size, (batch_size, seq_length))
    attention_mask = torch.ones(batch_size, seq_length, dtype=torch.long)

    dummy_input = {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
    }

    input_names = ["input_ids", "attention_mask"]
    output_names = ["last_hidden_state"]

    dynamic_ax = None
    if dynamic_axes:
        dynamic_ax = {
            "input_ids": {0: "batch", 1: "sequence"},
            "attention_mask": {0: "batch", 1: "sequence"},
            "last_hidden_state": {0: "batch", 1: "sequence"},
        }

    if verbose:
        print(f"Exporting transformer to ONNX...")

    torch.onnx.export(
        model,
        (dummy_input,),
        output_path,
        opset_version=opset_version,
        input_names=input_names,
        output_names=output_names,
        dynamic_axes=dynamic_ax,
        do_constant_folding=optimize,
        export_params=not external_data,
    )

    if verbose:
        print(f"✓ Exported to {output_path}")


def simplify_onnx(onnx_path: Path, verbose: bool) -> None:
    """Simplify ONNX model using onnx-simplifier"""
    try:
        import onnxsim
        import onnx

        if verbose:
            print("Simplifying ONNX model...")

        model = onnx.load(str(onnx_path))
        model_simplified, check = onnxsim.simplify(model)

        if check:
            onnx.save(model_simplified, str(onnx_path))
            if verbose:
                print("✓ Model simplified")
        else:
            if verbose:
                print("⚠ Simplification check failed, keeping original")
    except ImportError:
        if verbose:
            print("⚠ onnx-simplifier not installed, skipping simplification")


def main():
    parser = argparse.ArgumentParser(description="Convert PyTorch models to ONNX")
    parser.add_argument("--model-dir", type=Path, required=True, help="Model directory")
    parser.add_argument("--output", type=Path, required=True, help="Output ONNX file")
    parser.add_argument(
        "--model-type",
        type=str,
        default="auto",
        choices=["auto", "stable-diffusion", "bert", "gpt", "vit"],
        help="Model architecture type",
    )
    parser.add_argument("--opset", type=int, default=17, help="ONNX opset version")
    parser.add_argument("--dynamic-axes", action="store_true", help="Export with dynamic axes")
    parser.add_argument("--optimize", action="store_true", help="Optimize ONNX graph")
    parser.add_argument("--simplify", action="store_true", help="Simplify ONNX graph")
    parser.add_argument("--external-data", action="store_true", help="Use external data format")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # Check imports
    check_imports()

    # Verify model directory exists
    if not args.model_dir.exists():
        print(f"Error: Model directory not found: {args.model_dir}", file=sys.stderr)
        sys.exit(1)

    # Auto-detect model type if needed
    model_type = args.model_type
    if model_type == "auto":
        model_type = detect_model_type(args.model_dir)
        if args.verbose:
            print(f"Auto-detected model type: {model_type}")

    # Create output directory
    args.output.parent.mkdir(parents=True, exist_ok=True)

    # Convert based on type
    try:
        if model_type == "stable-diffusion":
            convert_stable_diffusion(
                args.model_dir,
                args.output,
                args.opset,
                args.dynamic_axes,
                args.optimize,
                args.external_data,
                args.verbose,
            )
        elif model_type in ["bert", "gpt", "vit"]:
            convert_transformer(
                args.model_dir,
                args.output,
                model_type,
                args.opset,
                args.dynamic_axes,
                args.optimize,
                args.external_data,
                args.verbose,
            )
        else:
            print(f"Error: Unsupported model type: {model_type}", file=sys.stderr)
            sys.exit(1)

        # Simplify if requested
        if args.simplify:
            simplify_onnx(args.output, args.verbose)

        if args.verbose:
            # Print file size
            size_mb = args.output.stat().st_size / (1024 * 1024)
            print(f"ONNX model size: {size_mb:.2f} MB")

    except Exception as e:
        print(f"Error during conversion: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
