#!/usr/bin/env python3
"""
Convert ONNX models to external data format for streaming.

This script converts ONNX models with embedded weights to external data format,
where weights are stored in separate .bin files. This enables true streaming
without loading multi-GB files into memory.
"""

import onnx
from pathlib import Path
import sys


def convert_to_external_data(model_path: Path, output_dir: Path = None):
    """Convert ONNX model to external data format."""

    if output_dir is None:
        output_dir = model_path.parent

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Loading model: {model_path}")
    print(f"  Size: {model_path.stat().st_size / 1024**2:.1f} MB")

    # Load model
    model = onnx.load(str(model_path))

    # Output paths
    output_onnx = output_dir / model_path.name
    output_data = output_dir / f"{model_path.stem}.bin"

    print(f"Converting to external data format...")
    print(f"  Graph file: {output_onnx}")
    print(f"  Weights file: {output_data}")

    # Convert to external data
    onnx.save_model(
        model,
        str(output_onnx),
        save_as_external_data=True,
        all_tensors_to_one_file=True,
        location=output_data.name,
        size_threshold=1024,  # Store tensors > 1KB externally
        convert_attribute=False,
    )

    # Verify sizes
    onnx_size = output_onnx.stat().st_size / 1024**2
    data_size = output_data.stat().st_size / 1024**2

    print(f"✓ Conversion complete!")
    print(f"  Graph: {onnx_size:.1f} MB")
    print(f"  Weights: {data_size:.1f} MB")
    print(f"  Total: {onnx_size + data_size:.1f} MB")
    print()

    return output_onnx, output_data


def main():
    models_dir = Path("/workspace/public/public/models/onnx/sd-turbo")
    output_dir = Path("/workspace/public/public/models/onnx/sd-turbo-external")

    # Models to convert
    models = [
        models_dir / "text_encoder" / "model.onnx",
        models_dir / "unet" / "model.onnx",
        models_dir / "vae_decoder" / "model.onnx",
    ]

    print("=" * 60)
    print("Converting SD Turbo models to external data format")
    print("=" * 60)
    print()

    for model_path in models:
        if not model_path.exists():
            print(f"⚠️  Model not found: {model_path}")
            continue

        model_output_dir = output_dir / model_path.parent.name
        convert_to_external_data(model_path, model_output_dir)

    print("=" * 60)
    print("✅ All models converted!")
    print("=" * 60)
    print()
    print("To use the converted models, update the path in hologram-onnx-diffusion.ts:")
    print(f"  const baseUrl = '/models/onnx/sd-turbo-external';")
    print()
    print("The converted models are in:")
    print(f"  {output_dir}")
    print()


if __name__ == "__main__":
    main()