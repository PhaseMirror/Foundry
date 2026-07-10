#!/usr/bin/env bash
# setup-llvm15-prefix.sh — provisions the hermetic LLVM 15 prefix
# Per ADR-001: Production-Grade Build Plan for pirtm-mlir

set -euo pipefail

PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.ci/llvm15_prefix" && pwd)"
VERSION="15.0.7"
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/llvm-project-${VERSION}.src.tar.xz"

echo "Sealing LLVM ${VERSION} prefix at: ${PREFIX}"

mkdir -p "${PREFIX}"

# Download LLVM source
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

echo "Downloading llvm-project-${VERSION}.src.tar.xz..."
curl -L "${LLVM_URL}" -o "${TMPDIR}/llvm.tar.xz"

echo "Extracting..."
tar -xf "${TMPDIR}/llvm.tar.xz" -C "${TMPDIR}"

# Move into canonical LLVM source layout
mkdir -p "${TMPDIR}/llvm"
mv "${TMPDIR}/llvm-project-${VERSION}.src/llvm"/* "${TMPDIR}/llvm/"

echo "Building LLVM ${VERSION} (this takes 20-40 minutes)..."
cd "${TMPDIR}/llvm"
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DLLVM_ENABLE_PROJECTS="mlir;clang" \
  -DLLVM_TARGETS_TO_BUILD="host" \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_BUILD_UTILS=ON \
  -DLLVM_BUILD_TESTS=OFF \
  -DLLVM_BUILD_EXAMPLES=OFF \
  -DLLVM_BUILD_DOCS=OFF

cmake --build . --target install -j$(nproc)

echo ""
echo "=== LLVM ${VERSION} Provisioned ==="
echo "Prefix: ${PREFIX}"
echo "llvm-config: $("${PREFIX}/bin/llvm-config" --version)"
echo "mlir-opt: $("${PREFIX}/bin/mlir-opt" --version 2>/dev/null || echo 'not found')"
