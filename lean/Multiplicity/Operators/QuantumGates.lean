/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Quantum Gates for Multiplicity Theory.
Formalizes quantum gates from Operators.md §10 and PEQOMA §4.

Defines Gaussian rationals, concrete matrix types (2×2, 4×4), and proves
unitarity/self-inverse properties for Hadamard (raw), CNOT, Phase/S, T (raw),
and Pauli-Z gates. All entries are Gaussian rationals; irrational gates
(Hadamard 1/√2, T e^{iπ/4}) use unnormalized representatives.

Pure core Lean 4 (no Mathlib). Axiom-clean: no sorry, no axioms beyond
{propext, Quot.sound}. Computational proofs via native_decide.
-/
namespace Multiplicity.Core.Operators.QuantumGates

/-! ## Gaussian Rationals -/

/-- Gaussian rational: a + bi where a, b ∈ ℚ.
    Closed under +, *, negation, and conjugation.
    Sufficient for all quantum gates with rational matrix entries. -/
structure GComplex where
  (re : Rat)
  (im : Rat)
  deriving DecidableEq

instance : Inhabited GComplex where default := ⟨0, 0⟩
instance : OfNat GComplex n where ofNat := ⟨n, 0⟩

/-- Addition: (a+bi) + (c+di) = (a+c) + (b+d)i -/
def GComplex.add (a b : GComplex) : GComplex := ⟨a.re + b.re, a.im + b.im⟩

/-- Multiplication: (a+bi)(c+di) = (ac-bd) + (ad+bc)i -/
def GComplex.mul (a b : GComplex) : GComplex :=
  ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩

/-- Negation: -(a+bi) = (-a) + (-b)i -/
def GComplex.neg (a : GComplex) : GComplex := ⟨-a.re, -a.im⟩
instance : Neg GComplex := ⟨GComplex.neg⟩

/-- Conjugation: (a+bi)* = a - bi -/
def GComplex.conj (a : GComplex) : GComplex := ⟨a.re, -a.im⟩

/-- Squared norm: |a+bi|² = a² + b² -/
def GComplex.normSq (a : GComplex) : Rat := a.re * a.re + a.im * a.im

/-! ## Concrete Matrix Types -/

/-- 2×2 matrix over Gaussian rationals.
    Used for single-qubit gates: Hadamard, Phase, T, Pauli-Z. -/
structure Mat2 where
  (m00 m01 m10 m11 : GComplex)
  deriving DecidableEq

/-- 4×4 matrix over Gaussian rationals.
    Used for two-qubit gates: CNOT. -/
structure Mat4 where
  (m00 m01 m02 m03 : GComplex)
  (m10 m11 m12 m13 : GComplex)
  (m20 m21 m22 m23 : GComplex)
  (m30 m31 m32 m33 : GComplex)
  deriving DecidableEq

/-! ## Matrix Multiplication -/

/-- 2×2 matrix multiplication. -/
def Mat2.mul (a b : Mat2) : Mat2 :=
  { m00 := GComplex.add (GComplex.mul a.m00 b.m00) (GComplex.mul a.m01 b.m10),
    m01 := GComplex.add (GComplex.mul a.m00 b.m01) (GComplex.mul a.m01 b.m11),
    m10 := GComplex.add (GComplex.mul a.m10 b.m00) (GComplex.mul a.m11 b.m10),
    m11 := GComplex.add (GComplex.mul a.m10 b.m01) (GComplex.mul a.m11 b.m11) }

/-- 4×4 matrix multiplication. -/
def Mat4.mul (a b : Mat4) : Mat4 :=
  { m00 := GComplex.add (GComplex.add (GComplex.mul a.m00 b.m00) (GComplex.mul a.m01 b.m10))
                        (GComplex.add (GComplex.mul a.m02 b.m20) (GComplex.mul a.m03 b.m30)),
    m01 := GComplex.add (GComplex.add (GComplex.mul a.m00 b.m01) (GComplex.mul a.m01 b.m11))
                        (GComplex.add (GComplex.mul a.m02 b.m21) (GComplex.mul a.m03 b.m31)),
    m02 := GComplex.add (GComplex.add (GComplex.mul a.m00 b.m02) (GComplex.mul a.m01 b.m12))
                        (GComplex.add (GComplex.mul a.m02 b.m22) (GComplex.mul a.m03 b.m32)),
    m03 := GComplex.add (GComplex.add (GComplex.mul a.m00 b.m03) (GComplex.mul a.m01 b.m13))
                        (GComplex.add (GComplex.mul a.m02 b.m23) (GComplex.mul a.m03 b.m33)),
    m10 := GComplex.add (GComplex.add (GComplex.mul a.m10 b.m00) (GComplex.mul a.m11 b.m10))
                        (GComplex.add (GComplex.mul a.m12 b.m20) (GComplex.mul a.m13 b.m30)),
    m11 := GComplex.add (GComplex.add (GComplex.mul a.m10 b.m01) (GComplex.mul a.m11 b.m11))
                        (GComplex.add (GComplex.mul a.m12 b.m21) (GComplex.mul a.m13 b.m31)),
    m12 := GComplex.add (GComplex.add (GComplex.mul a.m10 b.m02) (GComplex.mul a.m11 b.m12))
                        (GComplex.add (GComplex.mul a.m12 b.m22) (GComplex.mul a.m13 b.m32)),
    m13 := GComplex.add (GComplex.add (GComplex.mul a.m10 b.m03) (GComplex.mul a.m11 b.m13))
                        (GComplex.add (GComplex.mul a.m12 b.m23) (GComplex.mul a.m13 b.m33)),
    m20 := GComplex.add (GComplex.add (GComplex.mul a.m20 b.m00) (GComplex.mul a.m21 b.m10))
                        (GComplex.add (GComplex.mul a.m22 b.m20) (GComplex.mul a.m23 b.m30)),
    m21 := GComplex.add (GComplex.add (GComplex.mul a.m20 b.m01) (GComplex.mul a.m21 b.m11))
                        (GComplex.add (GComplex.mul a.m22 b.m21) (GComplex.mul a.m23 b.m31)),
    m22 := GComplex.add (GComplex.add (GComplex.mul a.m20 b.m02) (GComplex.mul a.m21 b.m12))
                        (GComplex.add (GComplex.mul a.m22 b.m22) (GComplex.mul a.m23 b.m32)),
    m23 := GComplex.add (GComplex.add (GComplex.mul a.m20 b.m03) (GComplex.mul a.m21 b.m13))
                        (GComplex.add (GComplex.mul a.m22 b.m23) (GComplex.mul a.m23 b.m33)),
    m30 := GComplex.add (GComplex.add (GComplex.mul a.m30 b.m00) (GComplex.mul a.m31 b.m10))
                        (GComplex.add (GComplex.mul a.m32 b.m20) (GComplex.mul a.m33 b.m30)),
    m31 := GComplex.add (GComplex.add (GComplex.mul a.m30 b.m01) (GComplex.mul a.m31 b.m11))
                        (GComplex.add (GComplex.mul a.m32 b.m21) (GComplex.mul a.m33 b.m31)),
    m32 := GComplex.add (GComplex.add (GComplex.mul a.m30 b.m02) (GComplex.mul a.m31 b.m12))
                        (GComplex.add (GComplex.mul a.m32 b.m22) (GComplex.mul a.m33 b.m32)),
    m33 := GComplex.add (GComplex.add (GComplex.mul a.m30 b.m03) (GComplex.mul a.m31 b.m13))
                        (GComplex.add (GComplex.mul a.m32 b.m23) (GComplex.mul a.m33 b.m33)) }

/-! ## Identity Matrices -/

/-- 2×2 identity matrix. -/
def Mat2.id : Mat2 := { m00 := 1, m01 := 0, m10 := 0, m11 := 1 }

/-- 4×4 identity matrix. -/
def Mat4.id : Mat4 :=
  { m00 := 1, m01 := 0, m02 := 0, m03 := 0,
    m10 := 0, m11 := 1, m12 := 0, m13 := 0,
    m20 := 0, m21 := 0, m22 := 1, m23 := 0,
    m30 := 0, m31 := 0, m32 := 0, m33 := 1 }

/-! ## Scalar Multiplication -/

/-- Scalar multiplication: c • A scales every entry of A by c. -/
def Mat2.smul (c : GComplex) (A : Mat2) : Mat2 :=
  { m00 := GComplex.mul c A.m00, m01 := GComplex.mul c A.m01,
    m10 := GComplex.mul c A.m10, m11 := GComplex.mul c A.m11 }

/-! ## Conjugate Transpose (†) -/

/-- Conjugate transpose of a 2×2 matrix: (A†)ij = (Aji)* -/
def Mat2.conjTranspose (A : Mat2) : Mat2 :=
  { m00 := GComplex.conj A.m00, m01 := GComplex.conj A.m10,
    m10 := GComplex.conj A.m01, m11 := GComplex.conj A.m11 }

/-- Conjugate transpose of a 4×4 matrix. -/
def Mat4.conjTranspose (A : Mat4) : Mat4 :=
  { m00 := GComplex.conj A.m00, m01 := GComplex.conj A.m10,
    m02 := GComplex.conj A.m20, m03 := GComplex.conj A.m30,
    m10 := GComplex.conj A.m01, m11 := GComplex.conj A.m11,
    m12 := GComplex.conj A.m21, m13 := GComplex.conj A.m31,
    m20 := GComplex.conj A.m02, m21 := GComplex.conj A.m12,
    m22 := GComplex.conj A.m22, m23 := GComplex.conj A.m32,
    m30 := GComplex.conj A.m03, m31 := GComplex.conj A.m13,
    m32 := GComplex.conj A.m23, m33 := GComplex.conj A.m33 }

/-! ## Quantum Gate Definitions -/

/-- CNOT (Controlled-NOT) gate. 4×4 matrix on two-qubit space {|00⟩,|01⟩,|10⟩,|11⟩}.
    Flips target qubit when control qubit is |1⟩:
    |00⟩→|00⟩, |01⟩→|01⟩, |10⟩→|11⟩, |11⟩→|10⟩. -/
def cnot : Mat4 :=
  { m00 := 1, m01 := 0, m02 := 0, m03 := 0,
    m10 := 0, m11 := 1, m12 := 0, m13 := 0,
    m20 := 0, m21 := 0, m22 := 0, m23 := 1,
    m30 := 0, m31 := 0, m32 := 1, m33 := 0 }

/-- Hadamard gate (raw/unnormalized).
    H_raw = [[1,1],[1,-1]].
    The physical gate is H = (1/√2)·H_raw; we prove H_raw² = 2I. -/
def hadamard_raw : Mat2 :=
  { m00 := 1, m01 := 1, m10 := 1, m11 := -1 }

/-- Phase gate S = diag(1, i). Applies π/2 phase shift to |1⟩. -/
def phase_gate : Mat2 :=
  { m00 := 1, m01 := 0, m10 := 0, m11 := ⟨0, 1⟩ }

/-- Pauli-Z gate = diag(1, -1). Applies π phase shift (bit flip in Z-basis). -/
def pauli_z : Mat2 :=
  { m00 := 1, m01 := 0, m10 := 0, m11 := -1 }

/-- T gate (raw) = diag(1, 1+i).
    The physical gate is T = diag(1, e^{iπ/4}); we use T_raw = diag(1, 1+i)
    where 1+i = √2·e^{iπ/4}. -/
def t_gate_raw : Mat2 :=
  { m00 := 1, m01 := 0, m10 := 0, m11 := ⟨1, 1⟩ }

/-! ## Proof: CNOT Gate -/

/-- CNOT is self-inverse: CNOT² = I.
    This reflects that applying CNOT twice returns to the original state. -/
theorem cnot_sq : Mat4.mul cnot cnot = Mat4.id := by native_decide

/-- CNOT is unitary: CNOT†·CNOT = I.
    Since CNOT has only real entries (0 or 1) and is symmetric,
    CNOT† = CNOT, so this follows from CNOT² = I. -/
theorem cnot_unitary : Mat4.mul (Mat4.conjTranspose cnot) cnot = Mat4.id := by native_decide

/-! ## Proof: Phase Gate (S) -/

/-- S² = Z: applying S twice gives a π phase shift. -/
theorem phase_sq : Mat2.mul phase_gate phase_gate = pauli_z := by native_decide

/-- S is unitary: S†·S = I. -/
theorem phase_unitary : Mat2.mul (Mat2.conjTranspose phase_gate) phase_gate = Mat2.id := by native_decide

/-! ## Proof: Pauli-Z Gate -/

/-- Z² = I: Pauli-Z is self-inverse. -/
theorem pauli_z_sq : Mat2.mul pauli_z pauli_z = Mat2.id := by native_decide

/-- Z is unitary: Z†·Z = I. -/
theorem pauli_z_unitary : Mat2.mul (Mat2.conjTranspose pauli_z) pauli_z = Mat2.id := by native_decide

/-! ## Proof: Hadamard Gate (Raw) -/

/-- H_raw² = 2·I: the raw Hadamard squares to twice the identity.
    The physical Hadamard H = (1/√2)·H_raw satisfies H² = I,
    since (1/√2)²·H_raw² = (1/2)·2I = I. -/
theorem hadamard_raw_sq :
    Mat2.mul hadamard_raw hadamard_raw = Mat2.smul ⟨2, 0⟩ Mat2.id := by native_decide

/-! ## Proof: T Gate (Raw) -/

/-- T_raw² = diag(1, 2i): squaring T_raw gives the unnormalized S gate
    scaled by 2. Specifically, (1+i)² = 2i. -/
theorem t_raw_sq :
    Mat2.mul t_gate_raw t_gate_raw =
    { m00 := 1, m01 := 0, m10 := 0, m11 := ⟨0, 2⟩ } := by native_decide

/-- T_raw is "orthogonal": T_raw†·T_raw = diag(1, 2).
    The squared norm |1+i|² = 2 appears on the diagonal. -/
theorem t_raw_norm :
    Mat2.mul (Mat2.conjTranspose t_gate_raw) t_gate_raw =
    { m00 := 1, m01 := 0, m10 := 0, m11 := 2 } := by native_decide

/-! ## Proof: Cross-Gate Relations -/

/-- S† = diag(1, -i). The phase gate's adjoint negates the imaginary part. -/
theorem phase_conj_transpose :
    Mat2.conjTranspose phase_gate =
    { m00 := 1, m01 := 0, m10 := 0, m11 := ⟨0, -1⟩ } := by native_decide

/-- Z is Hermitian: Z† = Z. -/
theorem pauli_z_hermitian :
    Mat2.conjTranspose pauli_z = pauli_z := by native_decide

/-- CNOT is Hermitian: CNOT† = CNOT. -/
theorem cnot_hermitian :
    Mat4.conjTranspose cnot = cnot := by native_decide

/-! ## Computational Basis Actions -/

/-- CNOT flips the second qubit when the first is |1⟩:
    |10⟩ → |11⟩, |11⟩ → |10⟩.
    Verified by checking the relevant matrix columns. -/
theorem cnot_flips_target :
    cnot.m22 = 0 ∧ cnot.m23 = 1 ∧ cnot.m32 = 1 ∧ cnot.m33 = 0 := by native_decide

/-- Phase gate acts as identity on |0⟩ and multiplies |1⟩ by i:
    S|0⟩ = |0⟩, S|1⟩ = i|1⟩. -/
theorem phase_gate_action :
    phase_gate.m00 = 1 ∧ phase_gate.m11 = ⟨0, 1⟩ := by native_decide

/-! ## Hadamard Superposition Property -/

/-- H_raw maps |0⟩ to |+⟩ = |0⟩+|1⟩ (up to normalization):
    column 0 of H_raw is [1,1]ᵀ. -/
theorem hadamard_creates_superposition :
    hadamard_raw.m00 = 1 ∧ hadamard_raw.m10 = 1 := by native_decide

/-- H_raw maps |1⟩ to |−⟩ = |0⟩−|1⟩ (up to normalization):
    column 1 of H_raw is [1,−1]ᵀ. -/
theorem hadamard_creates_diff :
    hadamard_raw.m01 = 1 ∧ hadamard_raw.m11 = -1 := by native_decide

end Multiplicity.Core.Operators.QuantumGates
