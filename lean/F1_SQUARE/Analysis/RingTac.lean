/-
F1 square — `ring_uor`: a from-scratch `ring`-replacement tactic (the v0.4.0 capstone of the
ring-normalizer brick).

v0.3.0 built the reflective normalizer as *data* (`PExpr`, `norm`, `norm_sound`, `nf_eq`); to use it
one had to hand-reify each identity into a `PExpr` tree. This file closes the loop: a real tactic
that automatically reifies an integer equality goal `lhs = rhs` into the syntax `PExpr`, applies the
soundness lemma `nf_eq`, and discharges the residual `norm lhsP = norm rhsP` by `decide` on the
finite normal-form data. The result is a genuine commutative-ring decision procedure for ℤ — the
analogue of Mathlib's `ring`, implemented in pure Lean 4 core metaprogramming (`Lean.Elab.Tactic`,
which is core), with NO Mathlib.

Soundness is inherited entirely from `nf_eq`: the tactic only *builds* the proof term `nf_eq …`; it
never adds an axiom. So every goal closed by `ring_uor` is as axiom-clean as `nf_eq` itself
(⊆ {propext, Quot.sound}, choice-free). Reification is fuel-bounded (no `partial def`), so the
tactic source carries no opacity either.
-/

import Lean
import F1Square.Analysis.RingNF

open Lean Elab Tactic Meta

namespace UOR.Bridge.F1Square.Analysis.RingNF

/-- Reify an `Int` expression into a `PExpr` term, collecting non-arithmetic subterms as atoms
    (deduplicated by syntactic equality) into `atoms`. Fuel-bounded to stay structurally terminating
    (no `partial def`). Numerals (`OfNat.ofNat …`) become `PExpr.const`; `+ * - neg` recurse; every
    other subterm is an atom `PExpr.var i`. -/
def reifyFuel : Nat → IO.Ref (Array Expr) → Expr → MetaM Expr
  | 0, _, _ => throwError "ring_uor: expression nesting exceeded fuel"
  | fuel + 1, atoms, e => do
    match e.getAppFnArgs with
    | (``HAdd.hAdd, #[_, _, _, _, a, b]) =>
        return mkAppN (mkConst ``PExpr.add) #[← reifyFuel fuel atoms a, ← reifyFuel fuel atoms b]
    | (``HMul.hMul, #[_, _, _, _, a, b]) =>
        return mkAppN (mkConst ``PExpr.mul) #[← reifyFuel fuel atoms a, ← reifyFuel fuel atoms b]
    | (``HSub.hSub, #[_, _, _, _, a, b]) =>
        return mkAppN (mkConst ``PExpr.sub) #[← reifyFuel fuel atoms a, ← reifyFuel fuel atoms b]
    | (``Neg.neg, #[_, _, a]) =>
        return mkAppN (mkConst ``PExpr.neg) #[← reifyFuel fuel atoms a]
    | (``OfNat.ofNat, _) =>
        return mkAppN (mkConst ``PExpr.const) #[e]
    | _ => do
        let cur ← atoms.get
        match cur.findIdx? (· == e) with
        | some i => return mkAppN (mkConst ``PExpr.var) #[mkNatLit i]
        | none =>
            atoms.set (cur.push e)
            return mkAppN (mkConst ``PExpr.var) #[mkNatLit cur.size]

/-- `ring_uor` proves an integer equality that holds by the commutative-ring axioms, by reflection
    onto the v0.3.0 canonical polynomial form. The from-scratch, no-Mathlib `ring`. -/
elab "ring_uor" : tactic => do
  let goal ← getMainGoal
  goal.withContext do
    let ty ← goal.getType
    let some (eqTy, lhs, rhs) := ty.eq? | throwError "ring_uor: goal is not an equality"
    unless ← isDefEq eqTy (mkConst ``Int) do
      throwError "ring_uor: goal is not an equality of integers"
    let atoms ← IO.mkRef (#[] : Array Expr)
    let lhsP ← reifyFuel 4096 atoms lhs
    let rhsP ← reifyFuel 4096 atoms rhs
    let arr ← atoms.get
    let atomsList ← mkListLit (mkConst ``Int) arr.toList
    let envE := mkApp (mkConst ``env) atomsList
    let normEq ← mkEq (mkApp (mkConst ``norm) lhsP) (mkApp (mkConst ``norm) rhsP)
    let dec ← mkDecideProof normEq
    let prf ← mkAppOptM ``nf_eq #[some envE, some lhsP, some rhsP, some dec]
    goal.assign prf

-- Demonstration that `ring_uor` discharges general ℤ identities and stays axiom-clean (audited).
theorem ring_uor_sq (a b : Int) : (a + b) * (a + b) = a * a + 2 * (a * b) + b * b := by ring_uor
theorem ring_uor_cube (a b : Int) :
    (a + b) * ((a + b) * (a + b)) = a * (a * a) + 3 * (a * (a * b)) + 3 * (a * (b * b)) + b * (b * b) := by
  ring_uor
theorem ring_uor_telescope (a b c d : Int) : (a + b) - (c + d) = (a - c) + (b - d) := by ring_uor

end UOR.Bridge.F1Square.Analysis.RingNF
