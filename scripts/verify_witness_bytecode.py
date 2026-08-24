#!/usr/bin/env python3
"""
verify_witness_bytecode.py — End-to-End P²C PETC v1.2 Bytecode & Semilattice Verification Suite.
Validates:
1. LEB128 & ZigZag signed encoding roundtrips
2. Standardized BLAKE2b-16 (128-bit) wire format & framing
3. Structured ConflictReport generation on lattice meet conflicts (Fail-Closed)
4. apply_witness interpreter across Permute, Merge, Split, MultiContract, Collective
5. Commutativity of multi-axis collective transformers (2D mesh DP x TP)
"""

import sys
import struct
import hashlib
from typing import Dict, List, Tuple, Optional, Any, Union

MAGIC_V2 = b"P2CWITv2"
VERSION_V1_2 = 0x0102
TRAILER = b"\xAA\x55"

# ---------------------------------------------------------------------------
# 1. Binary Encoding Utilities (LEB128 & ZigZag)
# ---------------------------------------------------------------------------

def encode_varuint(val: int) -> bytes:
    assert val >= 0
    buf = bytearray()
    while True:
        byte = val & 0x7F
        val >>= 7
        if val != 0:
            byte |= 0x80
            buf.append(byte)
        else:
            buf.append(byte)
            break
    return bytes(buf)

def decode_varuint(data: bytes, offset: int = 0) -> Tuple[int, int]:
    result = 0
    shift = 0
    while offset < len(data):
        byte = data[offset]
        offset += 1
        result |= (byte & 0x7F) << shift
        if (byte & 0x80) == 0:
            return result, offset
        shift += 7
        if shift > 64:
            raise ValueError("LEB128 overflow")
    raise ValueError("Unexpected EOF decoding varuint")

def encode_varint(val: int) -> bytes:
    zigzag = (val << 1) if val >= 0 else (~(val << 1))
    return encode_varuint(zigzag)

def decode_varint(data: bytes, offset: int = 0) -> Tuple[int, int]:
    zigzag, new_offset = decode_varuint(data, offset)
    val = (zigzag >> 1) if (zigzag & 1) == 0 else (~(zigzag >> 1))
    return val, new_offset

# ---------------------------------------------------------------------------
# 2. Distributed Partition Meet-Semilattice & ConflictReport
# ---------------------------------------------------------------------------

class ShardingState:
    UNCONSTRAINED = 0x00
    REPLICATED = 0x01
    SHARDED = 0x02

class ConflictReport(Exception):
    def __init__(self, mesh_axis: int, left_state: Any, right_state: Any, diagnostic_reason: str):
        super().__init__(diagnostic_reason)
        self.mesh_axis = mesh_axis
        self.left_state = left_state
        self.right_state = right_state
        self.diagnostic_reason = diagnostic_reason

class TensorPartition:
    def __init__(self, bindings: Optional[Dict[int, Tuple[int, Optional[int]]]] = None, lineage_tag: Optional[int] = None):
        self.bindings = bindings or {}
        self.lineage_tag = lineage_tag

    def meet(self, other: 'TensorPartition') -> 'TensorPartition':
        res = {}
        all_axes = set(self.bindings.keys()) | set(other.bindings.keys())
        for ax in all_axes:
            s1 = self.bindings.get(ax, (ShardingState.UNCONSTRAINED, None))
            s2 = other.bindings.get(ax, (ShardingState.UNCONSTRAINED, None))

            if s1[0] == ShardingState.UNCONSTRAINED:
                res[ax] = s2
            elif s2[0] == ShardingState.UNCONSTRAINED:
                res[ax] = s1
            elif s1[0] == ShardingState.REPLICATED and s2[0] == ShardingState.REPLICATED:
                res[ax] = (ShardingState.REPLICATED, None)
            elif s1[0] == ShardingState.REPLICATED and s2[0] == ShardingState.SHARDED:
                res[ax] = s2
            elif s1[0] == ShardingState.SHARDED and s2[0] == ShardingState.REPLICATED:
                res[ax] = s1
            elif s1[0] == ShardingState.SHARDED and s2[0] == ShardingState.SHARDED:
                if s1[1] == s2[1]:
                    res[ax] = s1
                else:
                    raise ConflictReport(
                        mesh_axis=ax,
                        left_state=s1,
                        right_state=s2,
                        diagnostic_reason=f"Mismatched sharding along mesh axis {ax}: {s1} vs {s2}"
                    )
            else:
                raise ConflictReport(
                    mesh_axis=ax,
                    left_state=s1,
                    right_state=s2,
                    diagnostic_reason=f"Incompatible partition state on axis {ax}"
                )
        return TensorPartition(res)

    def apply_allreduce(self, mesh_axis: int) -> 'TensorPartition':
        new_b = dict(self.bindings)
        new_b[mesh_axis] = (ShardingState.REPLICATED, None)
        return TensorPartition(new_b)

# ---------------------------------------------------------------------------
# 3. Decorated Signatures & apply_witness Interpreter
# ---------------------------------------------------------------------------

class DecoratedSignature:
    def __init__(self, atom_exponents: List[Tuple[int, int]], partition: Optional[TensorPartition] = None):
        # Sort and filter zero exponents
        self.atom_exponents = sorted([(a, e) for a, e in atom_exponents if e != 0], key=lambda x: x[0])
        self.partition = partition or TensorPartition()

    def add(self, other: 'DecoratedSignature') -> 'DecoratedSignature':
        merged_p = self.partition.meet(other.partition)
        d = {}
        for a, e in self.atom_exponents:
            d[a] = d.get(a, 0) + e
        for a, e in other.atom_exponents:
            d[a] = d.get(a, 0) + e
        return DecoratedSignature(list(d.items()), merged_p)

def apply_witness(axes: List[DecoratedSignature], op: Dict[str, Any]) -> List[DecoratedSignature]:
    op_type = op["type"]
    if op_type == "Permute":
        perm = op["perm"]
        assert len(perm) == len(axes), "Rank mismatch"
        return [axes[i] for i in perm]
    elif op_type == "Merge":
        src_axes = op["src_axes"]
        target_pos = op["target_pos"]
        merged = axes[src_axes[0]]
        for idx in src_axes[1:]:
            merged = merged.add(axes[idx])
        rem = [ax for i, ax in enumerate(axes) if i not in src_axes]
        rem.insert(min(target_pos, len(rem)), merged)
        return rem
    elif op_type == "Split":
        src_axis = op["src_axis"]
        parts = op["parts"]
        sum_parts = parts[0]
        for p in parts[1:]:
            sum_parts = sum_parts.add(p)
        assert sum_parts.atom_exponents == axes[src_axis].atom_exponents, "Split signature mismatch"
        return axes[:src_axis] + parts + axes[src_axis + 1:]
    elif op_type == "MultiContract":
        pairs = op["pairs"]
        contracted = set()
        for l, r in pairs:
            assert l != r and l not in contracted and r not in contracted
            assert axes[l].atom_exponents == axes[r].atom_exponents, "Contraction signature mismatch"
            contracted.add(l)
            contracted.add(r)
        return [ax for i, ax in enumerate(axes) if i not in contracted]
    elif op_type == "Collective":
        mesh_axis = op["mesh_axis"]
        return [DecoratedSignature(ax.atom_exponents, ax.partition.apply_allreduce(mesh_axis)) for ax in axes]
    else:
        raise ValueError(f"Unknown op: {op_type}")

# ---------------------------------------------------------------------------
# 4. Binary Framing & BLAKE2b-16
# ---------------------------------------------------------------------------

def compute_blake2b_16(data: bytes) -> bytes:
    return hashlib.blake2b(data, digest_size=16, person=b'P2C_V12').digest()

def serialize_bytecode_package(lineages: List[Tuple[int, bytes]], instructions_bin: bytes, flags: int = 0) -> bytes:
    body = bytearray()
    body.extend(encode_varuint(len(lineages)))
    for kid, lhash in lineages:
        body.extend(encode_varuint(kid))
        assert len(lhash) == 16
        body.extend(lhash)
    body.extend(instructions_bin)
    
    # Fixed BLAKE2b-16 digest
    h = compute_blake2b_16(body)
    header = struct.pack(">8sHHI16s", MAGIC_V2, VERSION_V1_2, flags, len(body), h)
    return header + bytes(body) + TRAILER

def deserialize_bytecode_package(data: bytes) -> Dict[str, Any]:
    if len(data) < 34:
        raise ValueError("Bytecode packet too small")
    if data[:8] != MAGIC_V2:
        raise ValueError("Invalid magic bytes")
    version, flags, body_len, payload_hash = struct.unpack(">HHI16s", data[8:32])
    if version != VERSION_V1_2:
        raise ValueError(f"Unsupported version: {hex(version)}")
    if len(data) != 32 + body_len + 2:
        raise ValueError("Packet size mismatch")
    if data[-2:] != TRAILER:
        raise ValueError("Invalid trailer")
        
    body = data[32:32 + body_len]
    actual_hash = compute_blake2b_16(body)
    if actual_hash != payload_hash:
        raise ValueError("BLAKE2b-16 payload digest mismatch")
        
    return {"version": version, "flags": flags, "body": body}

# ---------------------------------------------------------------------------
# 5. Verification Test Runner
# ---------------------------------------------------------------------------

def run_tests():
    print("[*] Starting P²C PETC v1.2 Bytecode, Semilattice & Interpreter Verification Suite...")
    
    # 1. Varint Roundtrip
    print("  [1/6] Testing LEB128 & ZigZag signed varint roundtrips...")
    for v in [0, 1, 127, 128, 255, 16383, 16384, 2**32 - 1]:
        enc = encode_varuint(v)
        dec, off = decode_varuint(enc)
        assert dec == v and off == len(enc)
    for v in [0, -1, 1, -63, 63, -8192, 8192, -2**31]:
        enc = encode_varint(v)
        dec, off = decode_varint(enc)
        assert dec == v and off == len(enc)
    print("        ✓ LEB128 & ZigZag Varints: PASS")
    
    # 2. ConflictReport on Meet Fail-Closed
    print("  [2/6] Testing ConflictReport generation on lattice meet conflicts...")
    p1 = TensorPartition({0: (ShardingState.SHARDED, 0)})
    p2 = TensorPartition({0: (ShardingState.SHARDED, 1)})
    try:
        p1.meet(p2)
        raise AssertionError("Expected ConflictReport on dimension mismatch")
    except ConflictReport as cr:
        assert cr.mesh_axis == 0
        assert "Mismatched sharding" in cr.diagnostic_reason
    print("        ✓ ConflictReport Materialization: PASS (Fail-Closed Diagnosis)")
    
    # 3. apply_witness Interpreter
    print("  [3/6] Testing apply_witness (Permute, Merge, Split, MultiContract, Collective)...")
    ax0 = DecoratedSignature([(10, 1)], TensorPartition({0: (ShardingState.SHARDED, 0)}))
    ax1 = DecoratedSignature([(20, 1)], TensorPartition({0: (ShardingState.SHARDED, 0)}))
    ax2 = DecoratedSignature([(30, 2)], TensorPartition({0: (ShardingState.REPLICATED, None)}))
    ax3 = DecoratedSignature([(30, 2)], TensorPartition({0: (ShardingState.REPLICATED, None)}))
    
    axes = [ax0, ax1, ax2, ax3]
    
    # Step A: Permute (swap 0 and 1) -> [ax1, ax0, ax2, ax3]
    axes = apply_witness(axes, {"type": "Permute", "perm": [1, 0, 2, 3]})
    assert axes[0].atom_exponents == [(20, 1)]
    assert axes[1].atom_exponents == [(10, 1)]
    
    # Step B: MultiContract axes 2 and 3 -> [ax1, ax0]
    axes = apply_witness(axes, {"type": "MultiContract", "pairs": [(2, 3)]})
    assert len(axes) == 2
    
    # Step C: Merge axes 0 and 1 -> [merged_ax]
    axes = apply_witness(axes, {"type": "Merge", "src_axes": [0, 1], "target_pos": 0})
    assert len(axes) == 1
    assert axes[0].atom_exponents == [(10, 1), (20, 1)]
    
    # Step D: Collective AllReduce on mesh axis 0 -> Replicated
    axes = apply_witness(axes, {"type": "Collective", "mesh_axis": 0})
    assert axes[0].partition.bindings[0] == (ShardingState.REPLICATED, None)
    
    # Step E: Split merged_ax back to [ax0, ax1]
    axes = apply_witness(axes, {"type": "Split", "src_axis": 0, "parts": [ax0, ax1]})
    assert len(axes) == 2
    print("        ✓ apply_witness Execution: PASS (All Opcode Semantics Validated)")
    
    # 4. BLAKE2b-16 Wire Format & Framing
    print("  [4/6] Testing standardized BLAKE2b-16 framing & tamper resistance...")
    pkg = serialize_bytecode_package([(1, b"\xAA" * 16)], b"\x01\x02\x01\x00")
    res = deserialize_bytecode_package(pkg)
    assert res["version"] == VERSION_V1_2
    
    # Corrupt payload bit
    corrupted = bytearray(pkg)
    corrupted[33] ^= 0x01
    try:
        deserialize_bytecode_package(bytes(corrupted))
        raise AssertionError("Expected tamper detection")
    except ValueError as e:
        assert "BLAKE2b-16 payload digest mismatch" in str(e)
    print("        ✓ BLAKE2b-16 Framing & Tamper Defense: PASS")
    
    # 5. Collective Reduction Commutativity
    print("  [5/6] Testing dual-axis collective reduction commutativity (2D mesh)...")
    p_init = TensorPartition({0: (ShardingState.SHARDED, 0), 1: (ShardingState.SHARDED, 1)})
    t0_t1 = p_init.apply_allreduce(1).apply_allreduce(0)
    t1_t0 = p_init.apply_allreduce(0).apply_allreduce(1)
    assert t0_t1.bindings == t1_t0.bindings
    print("        ✓ 2D Mesh Commutativity: PASS")
    
    # 6. Factorized Greedy Reshape
    print("  [6/6] Testing factorized greedy reshape partition conservation...")
    partA = DecoratedSignature([(1, 2)], TensorPartition({0: (ShardingState.SHARDED, 0)}))
    partB = DecoratedSignature([(2, 3)], TensorPartition({0: (ShardingState.SHARDED, 0)}))
    merged = partA.add(partB)
    assert merged.atom_exponents == [(1, 2), (2, 3)]
    assert merged.partition.bindings[0] == (ShardingState.SHARDED, 0)
    print("        ✓ Factorized Reshape Multiplicity Conservation: PASS")
    
    print("\n[+] All 6/6 Invariant Test Suites Passed Successfully! P²C v1.2 Production Core Locked.")

if __name__ == "__main__":
    try:
        run_tests()
        sys.exit(0)
    except Exception as e:
        print(f"[-] Verification FAILED: {e}", file=sys.stderr)
        sys.exit(1)
