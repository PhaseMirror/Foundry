/-
Mechanized-honesty audit (P4). `#print axioms` for every theorem in the genuine-proof layer.

A theorem proved with `()` shows `()Ax`; one proved with `native_decide` shows
`Lean.ofReduceBool`; a stray `axiom` shows its own name. So this single pass is the authoritative
check that the proof layer is genuine. `scripts/honesty_audit.sh` runs this and fails CI if any
output mentions `()Ax` / `ofReduceBool` / `trustCompiler`, or any axiom outside the minimal,
choice-free pair `{propext, Quot.sound}` (both forced by `omega`/`simp`/`Int` core internals).

This file is NOT part of the `F1Square` library target; it is run directly via `lake env lean`.
-/

import F1Square

open UOR.Bridge.F1Square

-- Mechanism (the function-field Hasse mechanism; tropical positivity).
#print axioms Mechanism.hodgeType_iff
#print axioms Mechanism.hasse_q25_a10
#print axioms Mechanism.hasse_q25_a12
#print axioms Mechanism.hasse_q4_a4
#print axioms Mechanism.hasse_q4_a5
#print axioms Mechanism.hasse_q9_a6
#print axioms Mechanism.hasse_q9_a7
#print axioms Mechanism.tropMult_nonneg
#print axioms Mechanism.bezout_line_line
#print axioms Mechanism.bezout_line_conic

-- Template (the product-of-curves Hodge-index template).
#print axioms Template.pair_symm
#print axioms Template.sq_nonneg
#print axioms Template.E1_dot_E2
#print axioms Template.E3_sq
#print axioms Template.H_sq
#print axioms Template.H_sq_pos
#print axioms Template.f1_perp
#print axioms Template.f2_perp
#print axioms Template.Hperp_gram_11
#print axioms Template.Hperp_gram_12
#print axioms Template.Hperp_gram_22
#print axioms Template.Hperp_value
#print axioms Template.Hperp_neg_semidef
#print axioms Template.int_sq_eq_zero
#print axioms Template.Hperp_definite

-- CharOne (the characteristic-1 / max-plus base; R1, R12).
#print axioms CharOne.tAdd_idem
#print axioms CharOne.tAdd_comm
#print axioms CharOne.tAdd_none_left
#print axioms CharOne.tAdd_none_right
#print axioms CharOne.tMul_comm
#print axioms CharOne.tMul_none_left
#print axioms CharOne.tMul_one_left
#print axioms CharOne.csum_append
#print axioms CharOne.csum_reverse
#print axioms CharOne.cycle_reversal_invariant

-- Bridge (the mechanism bridge; the §2.3 control).
#print axioms Bridge.hodge_implies_spectral_bound
#print axioms Bridge.control_psd

-- CycleCounts (R6, exact Bowen–Lanford trace identity).
#print axioms CycleCounts.N1
#print axioms CycleCounts.N2
#print axioms CycleCounts.N3
#print axioms CycleCounts.N4
#print axioms CycleCounts.N5
#print axioms CycleCounts.N6
#print axioms CycleCounts.N7
#print axioms CycleCounts.N8

-- Crux (the property; proved on the Template, OPEN on the square).
#print axioms Crux.template_hodgeIndex

-- v0.18.0 stage D — the Castelnuovo–Severi bridge at the lattice level (BridgeFF.lean):
-- Hodge-index negativity on the primitive {Δ,Γ}-span ⟺ the Hasse bound (= RH for the curve).
#print axioms BridgeFF.ffPair_symm
#print axioms BridgeFF.ff_gamma_bidegree
#print axioms BridgeFF.ff_trace_datum
#print axioms BridgeFF.primDG_perp_h
#print axioms BridgeFF.primDG_perp_v
#print axioms BridgeFF.primDG_sq
#print axioms BridgeFF.ff_hodge_iff_hasse
#print axioms BridgeFF.ff_hodge_iff_hodgeType
#print axioms BridgeFF.ff_hasse_q25_a10
#print axioms BridgeFF.ff_hasse_q25_a12_fails

-- v0.18.0 stage D — the Bombieri–Lagarias decomposition of λ₂ and the two-slice
-- realization of Li.LiDecomposition (Analysis/LiTwo.lean).
#print axioms Analysis.Rlambda2_decomposition
#print axioms Analysis.li_decomposition_two_realized
#print axioms Analysis.liTwo_evidence

-- v0.18.0 stage D — the spectral-square interface and THE BRIDGE: the geometric and
-- analytic faces of the crux are equivalent (Square/Spectral.lean). Crux stays OPEN.
#print axioms Square.Pos_Radd_self
#print axioms Square.Pos_of_Radd_self
#print axioms Square.Rnonneg_Radd_self
#print axioms Square.Rnonneg_of_Radd_self
#print axioms Square.spectral_bridge_nonneg
#print axioms Square.spectral_bridge_pos_slice
#print axioms Square.spectral_bridge_pos
#print axioms Square.crux_faces_equivalent
#print axioms Square.spectral_evidence_two
#print axioms Square.not_Pos_zero_double
#print axioms Square.spectralTwoSlice_not_crux
#print axioms Square.spectral_template_crux
#print axioms Square.spectral_iff_all_upTo

-- v0.18.0 stage D — the crux ATTEMPT under the gate (Square/Attempt.lean): the certified
-- part, the exact frontier, and the honest conclusion. Fields stay none; RH OPEN.
#print axioms Square.crux_attempt_frontier
#print axioms Square.crux_attempt_frontier_geometric
#print axioms Square.spectral_strict_upTo_two

-- v0.19.0 stage E — THE DOMINANCE FACE: the crux as a single uniform bound (oscillation
-- loses), equivalent to both prior faces (Square/Dominance.lean). Crux stays OPEN.
#print axioms Square.dominated_liPositive
#print axioms Square.liPositive_dominated
#print axioms Square.dominated_iff_liPositive
#print axioms Square.dominance_crux_equivalent
#print axioms Square.weilTrace_dominance
#print axioms Square.dominance_head_tail
#print axioms Square.crux_closure_route

-- v0.19.0 stage E — the genuine archimedean trend, all n (Analysis/ArchTrend.lean), and
-- the crux against the constructed trend (Square/Dominance.lean). Crux stays OPEN.
#print axioms Analysis.genuineArch_one
#print axioms Analysis.genuineArch_two
#print axioms Square.crux_vs_constructed_trend

-- v0.19.0 stage E — the genuine Li sequence in closed form, modulo the Stieltjes tail
-- (Analysis/GenuineLi.lean), and the closure route with the head DISCHARGED
-- (Square/Dominance.lean). Crux stays OPEN — the open data is the genuine η-tail + the bound.
#print axioms Analysis.genuineArith_one
#print axioms Analysis.genuineArith_two
#print axioms Analysis.genuineLam_one
#print axioms Analysis.genuineLam_two
#print axioms Analysis.genuineLam_head
#print axioms Analysis.weilTraceGenuine
#print axioms Analysis.etaTwoSlice
#print axioms Square.crux_genuine_form
#print axioms Square.crux_genuine_route

-- v0.19.0 the genuine-pairing arc, substrate P1 — |x| and max(0,·) on the constructive
-- reals: the tent-function calculus for the Weil functional's test class (Analysis/RMax.lean).
#print axioms Analysis.Qabs_abs_sub
#print axioms Analysis.Rabs
#print axioms Analysis.Rabs_congr
#print axioms Analysis.Rnonneg_Rabs
#print axioms Analysis.RmaxZero_congr
#print axioms Analysis.Rnonneg_RmaxZero
#print axioms Analysis.RmaxZero_of_nonpos
#print axioms Analysis.RmaxZero_of_nonneg

-- v0.19.0 the genuine-pairing arc, substrate P2a — finite sums of constructive reals
-- (Analysis/RSum.lean): the quadratic-form assembly substrate.
#print axioms Analysis.RsumN_congr
#print axioms Analysis.Rnonneg_RsumN
#print axioms Analysis.RsumN_le

-- v0.19.0 the genuine-pairing arc — THE WEIL FUNCTIONAL: the constructed finite-place
-- side and archimedean constant (Analysis/Weil.lean), the assembled pairing, the
-- pairing-induced spectral square, and the first computed pairing value
-- (Square/Pairing.lean). Crux stays OPEN; nothing asserts PSD for the genuine family.
#print axioms Analysis.weilPrimeTerm_past_support
#print axioms Analysis.weilPrimePart_stable
#print axioms Square.weilSpectralSquare
#print axioms Square.weil_psd_iff_hodge
#print axioms Square.weil_strict_iff_crux
#print axioms Square.weil_template_crux
#print axioms Square.demoWeilTest
#print axioms Square.weilPrime_demo
#print axioms Square.weilPrime_window
#print axioms Square.weilValue_window
#print axioms Square.weilPrimeTerm_one_carries_prime_two
#print axioms Square.prime_window_maximal

-- v0.19.0 the genuine-pairing arc — ψ(1/4), the archimedean kernel value at the window
-- center, as a constructive real with a certified lower bracket (Analysis/PsiQuarter.lean).
#print axioms Analysis.psiQuarterCore
#print axioms Analysis.psiQuarterCore_lower
#print axioms Analysis.psiQuarter
#print axioms Analysis.psiQuarter_lower
#print axioms Analysis.psiQuarterCore_upper
#print axioms Analysis.psiQuarter_upper
#print axioms Analysis.psiQuarterCore_upper_tight
#print axioms Analysis.psiQuarter_upper_tight

-- v0.19.0 the genuine-pairing arc — α(0) > 0: Burnol's window-center positivity
-- certificate, computed (Analysis/BurnolAlpha.lean). Evidence, not the universal; crux none.
#print axioms Analysis.sqrt2
#print axioms Analysis.one_le_sqrt2
#print axioms Analysis.burnolAlphaZero
#print axioms Analysis.burnolAlphaZero_pos

-- v0.19.0 the genuine-pairing arc — the τ-parameterized archimedean kernel Re ψ(1/4+iτ/2)
-- and its monotonicity; the honest record that the bare multiplier is INDEFINITE
-- (Analysis/DigammaWindow.lean). Pointwise α(τ)≥0 ∀τ is NOT a theorem; crux none.
#print axioms Analysis.windowKernel_den_pos
#print axioms Analysis.windowKernel_antitone
#print axioms Analysis.windowTerm_mono
#print axioms Analysis.windowTerm_zero
#print axioms Square.weilTraceTwo_not_crux
#print axioms Square.twoSlice_not_dominated
#print axioms Square.dominance_satisfiable

-- v0.19.0 stage E — the completed explicit-formula trace (zero side at the BL slices)
-- and the retirement of Li.LiAgreesWith at the built slices (Analysis/LiComplete.lean).
#print axioms Analysis.explicitFormulaTrace_one_realized
#print axioms Analysis.explicitFormulaTrace_two_realized
#print axioms Analysis.weilTraceTwo
#print axioms Analysis.weilTraceTwo_evidence
#print axioms Analysis.liAgreesWith_two_realized


-- v0.17.0 stage C — the 𝔽₁ curve at the monoid level (Square/Monoid.lean).
#print axioms Square.one_le_mul
#print axioms Square.mMul_assoc
#print axioms Square.mMul_comm
#print axioms Square.mOne_mul
#print axioms Square.mMul_one
#print axioms Square.cmon_mul_one
#print axioms Square.cmon_mul_mul_comm
#print axioms Square.f1_initial
#print axioms Square.f1_initial_unique
#print axioms Square.mScale_not_hom
#print axioms Square.mScale_comp

-- v0.17.0 stage C — the canonical square 𝕊 = F ⊗_𝔽₁ F with its universal property
-- (Square/Tensor.lean): coproduct laws, canonicality, non-collapse, strict 2-dimensionality.
#print axioms Square.copair_inl
#print axioms Square.copair_inr
#print axioms Square.sq_factor
#print axioms Square.copair_unique
#print axioms Square.square_base_cocone
#print axioms Square.inl_ne_inr
#print axioms Square.gen2_injective
#print axioms Square.gen2_codiag_collapse
#print axioms Square.codiag_not_injective
#print axioms Square.proj1_inl
#print axioms Square.proj2_inr
#print axioms Square.proj_faithful
#print axioms Square.sq_isCoproduct
#print axioms Square.coproduct_unique_upto_iso

-- v0.17.0 stage C — distinguished divisors of 𝕊 and their point-count intersections
-- (Square/Divisors.lean): the intrinsic input the lattice is derived from.
#print axioms Square.graph_one_diag
#print axioms Square.vFiber_inter_hFiber
#print axioms Square.vFiber_disjoint
#print axioms Square.hFiber_disjoint
#print axioms Square.diag_inter_vFiber
#print axioms Square.diag_inter_hFiber
#print axioms Square.graph_inter_vFiber
#print axioms Square.graph_inter_hFiber
#print axioms Square.diag_inter_graph_empty
#print axioms Square.graph_disjoint
#print axioms Square.graph_translate_diag
#print axioms Square.vFiber_translate
#print axioms Square.graph_zero_empty
#print axioms Square.graph_inter_hFiber_empty
#print axioms Square.vFiber_translate_unit
#print axioms Square.hFiber_translate

-- v0.17.0 stage C — the parallel pencil on canonical 𝕊 with shift lengths log n
-- (Square/Pencil.lean): the §2.3 finding as theorems on the constructed object.
#print axioms Square.logN_mul_general
#print axioms Square.logN_pow_general
#print axioms Square.pencil_shift
#print axioms Square.pencil_parallel
#print axioms Square.pencil_det_zero
#print axioms Square.pencil_separation
#print axioms Square.pencil_separation_vonMangoldt
#print axioms Square.pencil_separation_pow
#print axioms Square.pencil_separation_pow_vonMangoldt

-- v0.17.0 peer-review hardening — Euclid's lemma from scratch and Λ on ALL prime powers
-- (Analysis/Mangoldt.lean).
#print axioms Analysis.prime_dvd_mul
#print axioms Analysis.prime_dvd_pow
#print axioms Analysis.spf_prime_pow
#print axioms Analysis.isPrimePow_pow
#print axioms Analysis.vonMangoldt_prime_pow

-- v0.17.0 stage C — the intersection lattice of 𝕊, derived from point counts
-- (Square/Lattice.lean): the §2.2 declarative discipline mechanized; T3 intrinsic.
#print axioms Square.pair_rulings_derived
#print axioms Square.pair_v_self_derived
#print axioms Square.pair_h_self_derived
#print axioms Square.pair_diag_v_derived
#print axioms Square.pair_diag_h_derived
#print axioms Square.pair_diag_self_derived
#print axioms Square.pair_graph_v_derived
#print axioms Square.pair_graph_h_derived
#print axioms Square.pair_graph_self_derived
#print axioms Square.pair_diag_graph_derived
#print axioms Square.sqPair_add_left
#print axioms Square.sqPair_smul_left
#print axioms Square.e3_sq_forced
#print axioms Square.sqPair_eq_template
#print axioms Square.sqPair_symm
#print axioms Square.sq_boundary_checks
#print axioms Square.sq_adjunction_checks
#print axioms Square.sq_signature_diag
#print axioms Square.cls_generated
#print axioms Square.clsDiag_in_lattice
#print axioms Square.graph_class_unique
#print axioms Square.pencil_numerically_trivial

-- v0.17.0 stage C — polarized 𝕊: ample class, Hodge index of the derived lattice,
-- and the pencil-blindness boundary (Square/Polarized.lean). The crux stays OPEN.
#print axioms Square.clsAmple_eq
#print axioms Square.sq_ample_pos
#print axioms Square.sq_ample_meets
#print axioms Square.sq_hperp_span
#print axioms Square.sq_hperp_value
#print axioms Square.sq_hperp_neg_semidef
#print axioms Square.sq_hperp_definite
#print axioms Square.square_hodgeIndex
#print axioms Square.square_hodge_pencil_blind

-- v0.2.0 — Tropical closure / κ / spectrum (R2, R3, R4, R9, R10, R11).
#print axioms Tropical.star_matches
#print axioms Tropical.R2_kleene_idempotent
#print axioms Tropical.R3_kappa_perm_invariant
#print axioms Tropical.R4_cycle_spectrum
#print axioms Tropical.R9_same_kappa
#print axioms Tropical.R10_diff_spectrum
#print axioms Tropical.R11_kappa_fiber

-- v0.2.0 — sibling carriers (R14, R15, R16).
#print axioms Tropical.R14_kappaBool_perm_invariant
#print axioms Tropical.R15_faceted_address
#print axioms Tropical.R16_boolean_facet_degenerate

-- v0.2.0 — tropical Hodge-index signatures (§2.3, Babaee–Huh).
#print axioms Tropical.Signature.parallel_pencil
#print axioms Tropical.Signature.delta_gamma_zero
#print axioms Tropical.Signature.fan_degenerate
#print axioms Tropical.Signature.fan_kernel
#print axioms Tropical.Signature.fan_basis_nonpos
#print axioms Tropical.Signature.bh_two_positive_dirs

-- v0.2.0 — exact ℚ analysis brick.
#print axioms Analysis.Qeq_refl
#print axioms Analysis.reduce_6_8
#print axioms Analysis.reduce_idem
#print axioms Analysis.reduce_idem_neg
#print axioms Analysis.reduce_preserves_value
#print axioms Analysis.same_address_iff_eq
#print axioms Analysis.add_sample
#print axioms Analysis.mul_sample
#print axioms Analysis.Qle_sample

-- v0.3.0 — the ℤ ring normalizer (reflective canonical polynomial form) and its soundness.
#print axioms Analysis.RingNF.minsert_sound
#print axioms Analysis.RingNF.mmul_sound
#print axioms Analysis.RingNF.pinsert_sound
#print axioms Analysis.RingNF.padd_sound
#print axioms Analysis.RingNF.pscaleMono_sound
#print axioms Analysis.RingNF.pmul_sound
#print axioms Analysis.RingNF.pneg_sound
#print axioms Analysis.RingNF.norm_sound
#print axioms Analysis.RingNF.nf_eq
#print axioms Analysis.RingNF.sq_add
#print axioms Analysis.RingNF.mul_diff
#print axioms Analysis.RingNF.sq_add3
#print axioms Analysis.RingNF.distrib_comm

-- v0.3.0 — general ℚ field laws (via the normalizer).
#print axioms Analysis.add_comm
#print axioms Analysis.mul_comm
#print axioms Analysis.mul_assoc
#print axioms Analysis.add_assoc
#print axioms Analysis.mul_add
#print axioms Analysis.mul_one
#print axioms Analysis.add_zero
#print axioms Analysis.add_neg

-- v0.3.0 — constructive ℝ (Bishop regular sequences over ℚ).
#print axioms Analysis.Qsub_self_num
#print axioms Analysis.Qsub_swap_num
#print axioms Analysis.Qsub_swap_den
#print axioms Analysis.const_regular
#print axioms Analysis.Req_refl
#print axioms Analysis.Req_symm
#print axioms Analysis.ofQ_respects
#print axioms Analysis.Pos_half

-- v0.4.0 — the from-scratch `ring_uor` tactic (sample theorems it discharges, axiom-clean).
#print axioms Analysis.RingNF.ring_uor_sq
#print axioms Analysis.RingNF.ring_uor_cube
#print axioms Analysis.RingNF.ring_uor_telescope

-- v0.4.0 — ℚ as a verified ordered field.
#print axioms Analysis.Qle_refl
#print axioms Analysis.Qeq_le
#print axioms Analysis.Qle_trans
#print axioms Analysis.Qabs_Qeq
#print axioms Analysis.Qle_congr_left
#print axioms Analysis.Qle_congr_right
#print axioms Analysis.Qadd_le_add
#print axioms Analysis.Qabs_add_le
#print axioms Analysis.Qabs_sub_add4

-- v0.4.0 — denominator-positivity helpers.
#print axioms Analysis.add_den_pos
#print axioms Analysis.Qsub_den_pos
#print axioms Analysis.Qabs_den_pos

-- v0.4.0 — ℝ arithmetic (negation + Bishop addition, regularity proved).
#print axioms Analysis.Qbound_den_pos
#print axioms Analysis.Qabs_Qsub_neg
#print axioms Analysis.Rneg
#print axioms Analysis.Radd
#print axioms Analysis.Rneg_Rneg_seq

-- v0.5.0 — ℚ Archimedean + strict order (for ≈-transitivity).
#print axioms Analysis.Qle_or_Qlt
#print axioms Analysis.Qabs_sub_triangle
#print axioms Analysis.Qarch

-- v0.5.0 — ℚ multiplication and order (consumed by ℝ multiplication).
#print axioms Analysis.Qabs_mul
#print axioms Analysis.Qmul_le_mul_left
#print axioms Analysis.Qmul_le_mul_right
#print axioms Analysis.Qmul_le_mul
#print axioms Analysis.Qabs_mul_diff
#print axioms Analysis.Qabs_le_add
#print axioms Analysis.Qmul_den_pos
#print axioms Analysis.Qabs_num_nonneg

-- v0.5.0 — ℝ: ≈ is an equivalence; ℝ multiplication with regularity.
#print axioms Analysis.Req_of_seq_Qeq
#print axioms Analysis.Req_trans
#print axioms Analysis.Radd_comm
#print axioms Analysis.Radd_neg
#print axioms Analysis.canon_bound
#print axioms Analysis.Ridx_succ
#print axioms Analysis.Rmul
#print axioms Analysis.Rmul_comm

-- v0.5.0 — operation-congruence over ≈ (well-definedness on the setoid).
#print axioms Analysis.Rneg_congr
#print axioms Analysis.Radd_congr
#print axioms Analysis.Rsub_congr

-- v0.5.0 — ℂ = ℝ×ℝ with all four operations and commutative multiplication.
#print axioms Analysis.Ceq_refl
#print axioms Analysis.Ceq_symm
#print axioms Analysis.Ceq_trans
#print axioms Analysis.Cadd_comm
#print axioms Analysis.Cadd_neg
#print axioms Analysis.Cmul_re
#print axioms Analysis.Cmul_im
#print axioms Analysis.Cmul_comm

-- v0.6.0 — the well-definedness engine (generalized Archimedean lemma + linear-bound criterion).
#print axioms Analysis.Qscale_le
#print axioms Analysis.Qarch_gen
#print axioms Analysis.Ridx_ge
#print axioms Analysis.Qconst_le
#print axioms Analysis.Rgap_le
#print axioms Analysis.Rcross_le
#print axioms Analysis.Req_of_lin_bound
#print axioms Analysis.Rmul_gap
#print axioms Analysis.Qabs_two_diff_gen
#print axioms Analysis.canon_bound_mul
#print axioms Analysis.canon_bound_le

-- v0.6.0 — ℝ as a commutative ring up to ≈ (multiplication well-defined on the setoid).
#print axioms Analysis.Rmul_congr
#print axioms Analysis.Rmul_one
#print axioms Analysis.Radd_assoc
#print axioms Analysis.Rmul_distrib
#print axioms Analysis.Rmul_assoc
#print axioms Analysis.Rmul_zero
#print axioms Analysis.Radd_zero
#print axioms Analysis.Rsub_zero
#print axioms Analysis.Rmul_distrib_right
#print axioms Analysis.Rsub_Radd_Radd
#print axioms Analysis.Radd_swap
#print axioms Analysis.Rmul_neg_left
#print axioms Analysis.Rmul_neg_right
#print axioms Analysis.Rmul_sub_distrib
#print axioms Analysis.Rmul_sub_distrib_right
#print axioms Analysis.Rreassoc_sub
#print axioms Analysis.Rreassoc_add

-- v0.6.0 — ℂ as a commutative ring up to ≈.
#print axioms Analysis.Cadd_assoc
#print axioms Analysis.Cmul_one
#print axioms Analysis.Cmul_distrib
#print axioms Analysis.Cmul_assoc

-- v0.7.0 — Cauchy completeness of ℝ (every regular sequence of reals converges).
#print axioms Analysis.Qfrac_le
#print axioms Analysis.Qcollapse_le
#print axioms Analysis.RlimSeq_regular
#print axioms Analysis.Rlim
#print axioms Analysis.Rlim_seq
#print axioms Analysis.Rlim_tendsTo
#print axioms Analysis.Qabs_Qsub_comm
#print axioms Analysis.RTendsTo_unique
#print axioms Analysis.Rlim_congr
#print axioms Analysis.Rlim_neg
#print axioms Analysis.Rinv_congr
#print axioms Analysis.genSum_congr
#print axioms Analysis.CnormSq_CdigammaArg_conj
#print axioms Analysis.CdigammaTerm_re_conj
#print axioms Analysis.CDigammaCore_re_conj
#print axioms Analysis.CDigamma_re_conj
#print axioms Analysis.genSum_neg
#print axioms Analysis.RReg_neg
#print axioms Analysis.CdigammaTerm_im_conj
#print axioms Analysis.CDigammaCore_im_conj
#print axioms Analysis.CDigamma_im_conj
#print axioms Analysis.CDigamma_conj
#print axioms Analysis.Cexp_conj
#print axioms Analysis.CnormSq_conj
#print axioms Analysis.Cinv_conj
#print axioms Analysis.CpiPow_conj
#print axioms Analysis.CxiPoly_conj
#print axioms Analysis.Cxi_conj
#print axioms Analysis.Rlim_zero
#print axioms Analysis.genSum_const_zero
#print axioms Analysis.CdigammaTerm_one_eq_zero
#print axioms Analysis.CDigammaCore_one_eq_zero
#print axioms Analysis.CDigamma_one

-- v0.8.0 — the first transcendental: Euler's number e via the exponential series.
#print axioms Analysis.fct_pos
#print axioms Analysis.self_le_fct
#print axioms Analysis.two_mul_fct_le
#print axioms Analysis.eSum_den_pos
#print axioms Analysis.eSum_le
#print axioms Analysis.efac_step
#print axioms Analysis.eU_step
#print axioms Analysis.eU_le
#print axioms Analysis.ediff_bound
#print axioms Analysis.eabs_bound
#print axioms Analysis.efct_reindex
#print axioms Analysis.eSeq_regular
#print axioms Analysis.e
#print axioms Analysis.e_pos

-- v0.9.0 — the general exponential exp(q) on the rational interval [0,1].
#print axioms Analysis.qpow_den_pos
#print axioms Analysis.qpow_nonneg
#print axioms Analysis.qpow_le_one
#print axioms Analysis.expTerm_le
#print axioms Analysis.expSum_den_pos
#print axioms Analysis.expSum_le
#print axioms Analysis.Qsub_add_right
#print axioms Analysis.expdiff_dom
#print axioms Analysis.expdiff_bound
#print axioms Analysis.expabs_bound
#print axioms Analysis.expSeq_regular
#print axioms Analysis.Rexp
#print axioms Analysis.Qeq_trans
#print axioms Analysis.expSum_zero_eq
#print axioms Analysis.Rexp_zero
#print axioms Analysis.Rexp_one_pos
#print axioms Analysis.Qadd_congr
#print axioms Analysis.qpow_one_eq
#print axioms Analysis.expSum_one_eq
#print axioms Analysis.Rexp_one_eq_e

-- Coverage completion: leaf and helper lemmas that are transitively reached by the audited
-- theorems above, audited here EXPLICITLY so `honesty_audit.sh`'s coverage check can mechanically
-- enforce that EVERY non-private proof-layer theorem/lemma is `#print axioms`-checked (no drift).
#print axioms Analysis.RingNF.mul4
#print axioms Analysis.I_im
#print axioms Analysis.ofReal_im
#print axioms Analysis.Qeq_symm
#print axioms Analysis.neg_den_pos
#print axioms Analysis.fct_succ
#print axioms Analysis.eSum_step
#print axioms Analysis.eU_den_pos
#print axioms Analysis.e_seq
#print axioms Analysis.one_seq
#print axioms Analysis.zero_seq
#print axioms Analysis.Ridx_comm
#print axioms Analysis.RmulK_comm
#print axioms Analysis.RmulK_pos
#print axioms Analysis.xBound_pos
#print axioms Analysis.Qabs_le_of_nonneg
#print axioms Analysis.Qsub_le_sub
#print axioms Analysis.Qsub_add_cancel
#print axioms Analysis.Qle_self_add
#print axioms Analysis.Qle_add_self
#print axioms Analysis.qpow_succ
#print axioms Analysis.qpow_zero_succ_num
#print axioms Analysis.expSum_step
#print axioms Analysis.expTerm_den_pos
#print axioms Analysis.expTerm_num_nonneg
#print axioms Analysis.expTerm_one_eq
#print axioms Analysis.expTerm_zero_succ_num
#print axioms Analysis.Qeq_add_zero_num
#print axioms Analysis.Qle_Qabs_Qsub_of_Qeq
#print axioms Analysis.Rexp_seq

-- v0.11.0 — the order ≤ on ℝ (foundation for the transcendentals).
#print axioms Analysis.Qle_self_Qabs
#print axioms Analysis.Qabs_le_of_both
#print axioms Analysis.Qle_add_of_Qabs_sub
#print axioms Analysis.Qsub_le_of_le_add
#print axioms Analysis.Rnonneg_zero
#print axioms Analysis.Rnonneg_one
#print axioms Analysis.Rnonneg_Radd
#print axioms Analysis.Rle_refl
#print axioms Analysis.Rle_of_Req
#print axioms Analysis.Rle_antisymm
#print axioms Analysis.Rle_trans
#print axioms Analysis.Rle_zero_of_Rnonneg

-- v0.12.0 (in progress) — the multiplicative substrate: real powers + the reciprocal.
#print axioms Analysis.Rpow_zero
#print axioms Analysis.Rpow_succ
#print axioms Analysis.Rpow_one
#print axioms Analysis.Rpow_congr
#print axioms Analysis.Qmul_congr
#print axioms Analysis.Qinv_den_pos
#print axioms Analysis.Qinv_num_pos
#print axioms Analysis.Qmul_Qinv
#print axioms Analysis.Qinv_antitone
#print axioms Analysis.Qinv_sub_eq
#print axioms Analysis.Rdelta_num_pos
#print axioms Analysis.Rdelta_den_pos
#print axioms Analysis.RL_num_pos
#print axioms Analysis.RL_den_pos
#print axioms Analysis.Rinv_lb
#print axioms Analysis.Qabs_Qinv
#print axioms Analysis.Rinv_num_pos
#print axioms Analysis.RinvR_ge
#print axioms Analysis.Rinv_perterm
#print axioms Analysis.Qmul_add_right
#print axioms Analysis.Qabs_Qsub_swap
#print axioms Analysis.RinvSeq_regular
#print axioms Analysis.Rinv
#print axioms Analysis.qpow_abs
#print axioms Analysis.qpow_base_mono
#print axioms Analysis.expSumM_den_pos
#print axioms Analysis.expSumM_step
#print axioms Analysis.expSumM_le
#print axioms Analysis.expM_step_le
#print axioms Analysis.expM_U_den_pos
#print axioms Analysis.expM_U_step
#print axioms Analysis.expM_U_le
#print axioms Analysis.expM_diff_bound
#print axioms Analysis.qpow_nat_base
#print axioms Analysis.expTerm_abs_le_M
#print axioms Analysis.expSum_abs_diff_le_M
#print axioms Analysis.expSum_trunc_bound
#print axioms Analysis.qpow_abs_le
#print axioms Analysis.qpow_diff_bound
#print axioms Analysis.expTerm_diff_bound
#print axioms Analysis.LipS_den_pos
#print axioms Analysis.expSum_Lip_le
#print axioms Analysis.Pbound_closed
#print axioms Analysis.expSumM_le_U
#print axioms Analysis.LipS_shift
#print axioms Analysis.LipS_le_U
#print axioms Analysis.two_pow_ge
#print axioms Analysis.fct_ge_geom
#print axioms Analysis.trunc_reindex
#print axioms Analysis.expSumM_num_nonneg
#print axioms Analysis.expM_U_num_nonneg
#print axioms Analysis.Qle_toNat
#print axioms Analysis.RexpReal_diag_le
#print axioms Analysis.RexpReal_regular
#print axioms Analysis.RexpReal
#print axioms Analysis.Qabs_neg
#print axioms Analysis.fct_mono
#print axioms Analysis.qsq_abs_le
#print axioms Analysis.altTerm_den_pos
#print axioms Analysis.altSum_den_pos
#print axioms Analysis.altTerm_abs_le
#print axioms Analysis.altSum_abs_diff_le
#print axioms Analysis.altSum_trunc_bound
#print axioms Analysis.altTerm_diff_bound
#print axioms Analysis.altSum_Lip_le
#print axioms Analysis.qsq_diff_le
#print axioms Analysis.RaltReal_diag_le
#print axioms Analysis.RaltReal_regular
#print axioms Analysis.RaltReal
#print axioms Analysis.Rcos
#print axioms Analysis.Rsin
#print axioms Analysis.geoSum_den_pos
#print axioms Analysis.geoU_eq
#print axioms Analysis.geo_diff_eq
#print axioms Analysis.Qsub_le_self
#print axioms Analysis.geo_diff_bound
#print axioms Analysis.artTerm_den_pos
#print axioms Analysis.artSum_den_pos
#print axioms Analysis.artTerm_abs_le
#print axioms Analysis.artSum_abs_diff_le
#print axioms Analysis.artSum_trunc
#print axioms Analysis.qpow_abs_le_rat
#print axioms Analysis.Pcoef_den_pos
#print axioms Analysis.Pcoef_num_nonneg
#print axioms Analysis.qpow_diff_bound_rat
#print axioms Analysis.geoEvenSum_den_pos
#print axioms Analysis.geoEven_eq
#print axioms Analysis.geoEven_bound
#print axioms Analysis.Pcoef_closed
#print axioms Analysis.artTerm_diff_bound
#print axioms Analysis.artSum_Lip_le
#print axioms Analysis.qpow_half_value
#print axioms Analysis.qpow_half_le
#print axioms Analysis.qpow_geom_bound
#print axioms Analysis.Qmul_le_cancel_right
#print axioms Analysis.Qone_mul
#print axioms Analysis.Qmul_swap_right
#print axioms Analysis.artanh_reindex
#print axioms Analysis.Rartanh_diag_le
#print axioms Analysis.Rartanh_regular
#print axioms Analysis.Rartanh
#print axioms Analysis.Qmul_rearrange4
#print axioms Analysis.Qmul_rearrange4b
#print axioms Analysis.Qmul_sub_right
#print axioms Analysis.Qneg_congr
#print axioms Analysis.Qsub_congr
#print axioms Analysis.Qinv_mul
#print axioms Analysis.tmap_ring
#print axioms Analysis.tmap_diff_cleared
#print axioms Analysis.Qabs_of_nonneg
#print axioms Analysis.tmap_lipschitz
#print axioms Analysis.tmap_cross_le
#print axioms Analysis.tmap_cross_ge
#print axioms Analysis.Qmul_neg_left
#print axioms Analysis.tmap_abs_le
#print axioms Analysis.Rlog_regular
#print axioms Analysis.tmap_M_eq
#print axioms Analysis.Rlog
#print axioms Analysis.Rlog_two_ok
#print axioms Analysis.Qle_add_right_nonneg
#print axioms Analysis.Qle_add_left_nonneg
#print axioms Analysis.Qbound_anti
#print axioms Analysis.reindex_regular
#print axioms Analysis.RlogPosR_tail
#print axioms Analysis.RlogPosR_self
#print axioms Analysis.Rlog_ub
#print axioms Analysis.RlogPos
#print axioms Analysis.qpow_one
#print axioms Analysis.arctanTerm_den_pos
#print axioms Analysis.arctanSum_den_pos
#print axioms Analysis.arctanTerm_abs_le
#print axioms Analysis.arctanSum_abs_diff_le
#print axioms Analysis.arctanSum_trunc
#print axioms Analysis.Rarctan_diag_le
#print axioms Analysis.Rarctan_regular
#print axioms Analysis.Rarctan
-- v0.22.0 Track 1 brick 1: arctan at a general REAL argument (Analysis/RArctan.lean) — the
-- forced-first prerequisite for complex Clog / Γ(s/2), mirroring real-argument Rartanh.
#print axioms Analysis.arctanTerm_diff_bound
#print axioms Analysis.arctanSum_Lip_le
#print axioms Analysis.RarctanR_diag_le
#print axioms Analysis.RarctanR_regular
#print axioms Analysis.arctanTerm_zero_num
#print axioms Analysis.arctanTerm_zero
#print axioms Analysis.arctanSum_zero_num
#print axioms Analysis.arctanSum_zero
#print axioms Analysis.RarctanR_zero
#print axioms Analysis.qpow_succ_num_eq_zero
#print axioms Analysis.arctanTerm_num_eq_zero
#print axioms Analysis.arctanSum_num_eq_zero
#print axioms Analysis.RarctanR_of_num_zero
-- v0.22.0 Track 1: arctan continuity (Analysis/RArctanCongr.lean) — lifts rational identities to real.
#print axioms Analysis.RarctanR_congr
#print axioms Analysis.Req_add_of_exp_values
-- v0.22.0 Track 1: rational artanh addition law (Analysis/ArtanhAdd.lean) — heart of log-multiplicativity.
#print axioms Analysis.Rnonneg_TwoArtanhConst
#print axioms Analysis.Rexp_twoArtanh_general
#print axioms Analysis.TwoArtanh_add_rat
#print axioms Analysis.wval_num
#print axioms Analysis.wval_den
#print axioms Analysis.wval_den_pos
#print axioms Analysis.wval_num_nonneg
#print axioms Analysis.wval_lt
#print axioms Analysis.wval_hg
#print axioms Analysis.TwoArtanh_add_wval
#print axioms Analysis.wval_argdiff1_cleared
#print axioms Analysis.wval_argdiff2_cleared
#print axioms Analysis.wvalR_num
#print axioms Analysis.wvalR_den
#print axioms Analysis.wvalR_den_pos
#print axioms Analysis.wvalR_argdiff1
#print axioms Analysis.wvalR_argdiff2
#print axioms Analysis.wval_halfbound
#print axioms Analysis.wval_csq_le
#print axioms Analysis.wval_lip1
#print axioms Analysis.wvalR_comm
#print axioms Analysis.wval_lip2
#print axioms Analysis.wvalR_rel
#print axioms Analysis.tmap_mul_wvalR
#print axioms Analysis.wval_inner_pos
#print axioms Analysis.tmul_wvalReal_via
#print axioms Analysis.Rexp_twoArtanh_general_rho
#print axioms Analysis.TwoArtanh_add_wval_rho
#print axioms Analysis.artSum_wval_argdiff
#print axioms Analysis.RartanhConst_add_wval_rho
#print axioms Analysis.wval_eq_wvalR
#print axioms Analysis.Rartanh_add_real_via
#print axioms Analysis.Rlog_mul_algebra
#print axioms Analysis.Rlog_mul_via
#print axioms Analysis.wvalR_tmap_bound
#print axioms Analysis.tmap_nonneg_lt_one
#print axioms Analysis.wvalR_tmap_seq_bound
#print axioms Analysis.Rlog_mul
#print axioms Analysis.vval_num
#print axioms Analysis.vval_den
#print axioms Analysis.vval_den_pos
#print axioms Analysis.vval_argdiff1_cleared
#print axioms Analysis.vval_argdiff2_cleared
#print axioms Analysis.vval_lip1_den
#print axioms Analysis.vval_argdiff1
#print axioms Analysis.vval_argdiff2
#print axioms Analysis.vval_halfbound
#print axioms Analysis.vval_csq_le
#print axioms Analysis.vval_comm
#print axioms Analysis.vval_inner_pos
#print axioms Analysis.vval_lip1
#print axioms Analysis.vval_lip2
#print axioms Analysis.vvalReal
-- v0.22.0 Track 1: the formal arctan ODE A′=1/(1+t²) (Analysis/ArctanODE.lean).
#print axioms Analysis.arctanCoeff_den_pos
#print axioms Analysis.geomAlt_den_pos
#print axioms Analysis.arctan_fderiv
#print axioms Analysis.geomAlt_recurrence
#print axioms Analysis.geomAlt_zero
#print axioms Analysis.geomAlt_one
#print axioms Analysis.sinCoeff_den_pos
#print axioms Analysis.cosCoeff_den_pos
#print axioms Analysis.sin_fderiv
#print axioms Analysis.cos_fderiv
#print axioms Analysis.Qadd_neg_distrib
#print axioms Analysis.Fsum_neg
#print axioms Analysis.fmul_neg_left
#print axioms Analysis.fcomp_neg_left
#print axioms Analysis.arctanCoeff_zero
#print axioms Analysis.sinComp_deriv
#print axioms Analysis.cosComp_deriv
#print axioms Analysis.Xident_den_pos
#print axioms Analysis.fmul_Xident_zero
#print axioms Analysis.fmul_Xident
#print axioms Analysis.onePlusSq_den_pos
#print axioms Analysis.sq2_den_pos
#print axioms Analysis.fmul_fone_left
#print axioms Analysis.fmul_sq2
#print axioms Analysis.onePlusSq_decomp
#print axioms Analysis.fmul_onePlusSq
#print axioms Analysis.fmul_onePlusSq_zero
#print axioms Analysis.fmul_onePlusSq_one
#print axioms Analysis.Qmul_pos_strip
#print axioms Analysis.Qmul_const_zero
#print axioms Analysis.Qadd_right_zero_cancel
#print axioms Analysis.fderiv_strip
#print axioms Analysis.ode_unique
#print axioms Analysis.fderiv_sub
#print axioms Analysis.fmul_subR
#print axioms Analysis.Qalg1
#print axioms Analysis.Xident_fderiv
#print axioms Analysis.fmul_neg_right
#print axioms Analysis.X_sq_eq_sq2
#print axioms Analysis.onePlusSq_geomAlt
#print axioms Analysis.absorb_onePlusSq_geomAlt
#print axioms Analysis.Gseq_fderivT
#print axioms Analysis.Gseq_den_pos
#print axioms Analysis.Gseq_zero
#print axioms Analysis.Gseq_ode
#print axioms Analysis.sin_arctan_eq
#print axioms Analysis.peval_sin_arctan_eq
#print axioms Analysis.peval_sinComp_swap
#print axioms Analysis.peval_cosComp_swap
#print axioms Analysis.qpow_neg_one_abs
#print axioms Analysis.arctanCoeff_term_odd
#print axioms Analysis.arctanCoeff_term_even
#print axioms Analysis.peval_arctanCoeff_eq_arctanSum
#print axioms Analysis.DN_sin_eq
#print axioms Analysis.e_le_T_arctan
#print axioms Analysis.DN_sin_abs_le
#print axioms Analysis.fpow_fabs_arctan_bound
#print axioms Analysis.fpow_arctan_term_bound
#print axioms Analysis.peval_arctan_pow_gap
#print axioms Analysis.peval_arctan_pow_cauchy
#print axioms Analysis.Qabs_arctan_C_le
#print axioms Analysis.corner_inner_eq_arctan
#print axioms Analysis.corner_term_le_arctan
#print axioms Analysis.corner_bound_arctan
#print axioms Analysis.corner_sum_bound_arctan
#print axioms Analysis.corner_sum_closed_arctan
#print axioms Analysis.DN_sin_closed
#print axioms Analysis.cosCoeff_term_even
#print axioms Analysis.cosCoeff_term_odd
#print axioms Analysis.peval_cosCoeff_eq_altSum
#print axioms Analysis.Qmul_rearr_sin
#print axioms Analysis.sinCoeff_term_odd
#print axioms Analysis.sinCoeff_term_even
#print axioms Analysis.peval_sinCoeff_eq
#print axioms Analysis.DN_cos_eq
#print axioms Analysis.DN_cos_abs_le
#print axioms Analysis.DN_cos_closed
#print axioms Analysis.Qrearr_AABP
#print axioms Analysis.DN_arctan_decay
#print axioms Analysis.DN_sin_recip
#print axioms Analysis.DN_cos_recip
#print axioms Analysis.peval_fmul_Xident_shift
#print axioms Analysis.peval_sin_arctan_shift
#print axioms Analysis.Rcos_seq_eq_peval
#print axioms Analysis.RsinAux_seq_eq_altSum
#print axioms Analysis.RsinAux_seq_eq_peval
#print axioms Analysis.peval_arg_congr
#print axioms Analysis.peval_arctanCoeff_even
#print axioms Analysis.arctanSum_abs_le_one
#print axioms Analysis.LipS_num_nonneg
#print axioms Analysis.peval_cosCoeff_Lip
#print axioms Analysis.geoSum_mono
#print axioms Analysis.geoSum_diff_recip
#print axioms Analysis.peval_cosCoeff_arctan_argdiff
#print axioms Analysis.peval_cosCoeff_arctan_argdiff_recip
#print axioms Analysis.cos_nested_general
#print axioms Analysis.Rcos_arctan_nested
#print axioms Analysis.altSum_abs_le
#print axioms Analysis.altSum_arctan_abs_le_U
#print axioms Analysis.altSum_argdiff_recip
#print axioms Analysis.Qabs_mul_sub_le
#print axioms Analysis.peval_sinCoeff_arctan_argdiff_recip
#print axioms Analysis.sin_nested_general
#print axioms Analysis.Rsin_arctan_nested
#print axioms Analysis.Rsin_arctan_value_eq
#print axioms Analysis.Rcos_arctan_sq
#print axioms Analysis.Rcos_arctan_inv
#print axioms Analysis.Rtan_arctan_eq
#print axioms Analysis.Rmul_left_comm_loc
#print axioms Analysis.Rone_mul_loc
#print axioms Analysis.Rmul_pair_regroup
#print axioms Analysis.Rsin_add_of_tan
#print axioms Analysis.Rcos_add_of_tan
#print axioms Analysis.vval_rel_poly
#print axioms Analysis.vval_rel
#print axioms Analysis.vval_coeff_eq
#print axioms Analysis.Rsin_cos_add_tan
#print axioms Analysis.altTerm_base_neg
#print axioms Analysis.altSum_base_neg
#print axioms Analysis.xBound_neg
#print axioms Analysis.RaltReal_K_neg
#print axioms Analysis.RaltReal_R_neg
#print axioms Analysis.Rcos_neg
#print axioms Analysis.RsinAux_neg
#print axioms Analysis.Rsin_neg
#print axioms Analysis.Rsin_sub
#print axioms Analysis.Rsin_sub_eq_zero
#print axioms Analysis.Rmul_eq_zero_cancel
#print axioms Analysis.Req_of_Rsub_zero_loc
#print axioms Analysis.Rtan_inj
#print axioms Analysis.Req_add_of_tan_values
#print axioms Analysis.Qneg_le_of_Qabs_le
#print axioms Analysis.altSum_sin_two_ge
#print axioms Analysis.altSum_sin_diag_gt
#print axioms Analysis.Pos_RsinAux_of_small
#print axioms Analysis.Rarctan_add
#print axioms Analysis.geoSum_le_two
#print axioms Analysis.Rarctan_seq_abs_le
#print axioms Analysis.Qmul_two_le_third
#print axioms Analysis.Rarctan_diff_seq_le
#print axioms Analysis.Rarctan_add_of_small
#print axioms Analysis.arctanSum_vval_argdiff
#print axioms Analysis.RarctanConst_add_vval_rho
#print axioms Analysis.RarctanR_add_real_via
#print axioms Analysis.Qabs_sub_mul_right_eq
#print axioms Analysis.Qabs_sub_mul_left_eq
#print axioms Analysis.Qrecip_anti
#print axioms Analysis.RaltReal_R_ge
#print axioms Analysis.Rartanh_R_ge
#print axioms Analysis.sinCoeff_abs_le_one
#print axioms Analysis.cosCoeff_abs_le_one
#print axioms Analysis.arctanSum_abs_le
#print axioms Analysis.arctanCoeff_fabs_le_one
#print axioms Analysis.gcornerB_den
#print axioms Analysis.e_rec_alg2
#print axioms Analysis.gen_per_m_step
#print axioms Analysis.gen_per_m_bound
-- v0.22.0 Track 1: the complex argument on the principal sector (Analysis/ComplexArg.lean).
#print axioms Analysis.Carg_ofReal_pos
-- v0.22.0 Track 1: the complex logarithm Clog on the principal sector (Analysis/ComplexLog.lean).
#print axioms Analysis.Clog_re
#print axioms Analysis.Clog_im
#print axioms Analysis.Clog_ofReal_pos_im
-- v0.22.0 Track 1: tmap closed forms at a rational argument (Analysis/RexpLogRat.lean).
#print axioms Analysis.tmap_rat_num
#print axioms Analysis.tmap_rat_den
#print axioms Analysis.Qle_of_Qsub_le_Qsub_left
#print axioms Analysis.Qle_of_Qsub_le_Qsub_right
#print axioms Analysis.Rlt_Qbound_of_Rle_ofQ
#print axioms Analysis.Pos_of_Rle_ofQ
#print axioms Analysis.Rpi_lower
#print axioms Analysis.Rle_Rneg
#print axioms Analysis.Radd_le_add
#print axioms Analysis.Rsub_le_sub
#print axioms Analysis.arctanSum_diag_ge
#print axioms Analysis.arctanSum_diag_le
#print axioms Analysis.arctanSum_diag_ge_at
#print axioms Analysis.arctanSum_diag_le_at
#print axioms Analysis.Rpi_lower_three
#print axioms Analysis.Rpi_seq_ge_three
#print axioms Analysis.tmap_ge_half
#print axioms Analysis.Rarctan_ge
#print axioms Analysis.Rarctan_le
#print axioms Analysis.Qmul_sub_left
#print axioms Analysis.Qabs_mul_const_sub
#print axioms Analysis.Qneg_le_neg
#print axioms Analysis.Qsub_le_2
#print axioms Analysis.Qabs_Qsub_neg_neg
#print axioms Analysis.Rpi_seq_den_pos
#print axioms Analysis.Rpi_regular
#print axioms Analysis.Rpi_pos
-- the log π LOWER bound (Analysis/LogPiLower.lean), resting on π ≥ 3.
#print axioms Analysis.RpiTmap_ge_half
#print axioms Analysis.Rartanh_RpiTmap_ge_half
#print axioms Analysis.Rlogpi_ge_one

-- v0.14.0 (wip) — γ₀ (Euler–Mascheroni) via the alternating ζ-series.
#print axioms Analysis.AltSum_succ
#print axioms Analysis.Qsub_nonneg_of_le
#print axioms Analysis.Qzero_le
#print axioms Analysis.num_nonneg_of_Qzero_le
#print axioms Analysis.Qsub_zero_eq
#print axioms Analysis.AltSum_den_pos
#print axioms Analysis.altSum_bracket
#print axioms Analysis.altSum_gap
#print axioms Analysis.zetaSum_s_anti_step
#print axioms Analysis.zetaSum_num_nonneg
#print axioms Analysis.zetaSum_le_two
#print axioms Analysis.altSum_diff_le
#print axioms Analysis.bterm_den_pos
#print axioms Analysis.bterm_num_nonneg
#print axioms Analysis.bterm_anti
#print axioms Analysis.bterm_le
#print axioms Analysis.bterm_depth_diff
#print axioms Analysis.gammaSeq_den_pos
#print axioms Analysis.gammaSeq_reg_le
#print axioms Analysis.gammaSeq_regular

-- v0.14.0 (wip) — accelerated γ (harmonic/telescoping): the artanh rational bounds.
#print axioms Analysis.artTerm_num_nonneg
#print axioms Analysis.artSum_step
#print axioms Analysis.artSum_mono
#print axioms Analysis.artSum_zero_eq
#print axioms Analysis.artSum_ge_arg
#print axioms Analysis.artTerm_le_geoTerm
#print axioms Analysis.artSum_le_geoSum
#print axioms Analysis.geoSum_cleared_le
#print axioms Analysis.artSum_le_geo
#print axioms Analysis.two_artSum_ge
#print axioms Analysis.two_artSum_le
#print axioms Analysis.cApprox_den_pos
#print axioms Analysis.cApprox_num_nonneg
#print axioms Analysis.cApprox_ub
#print axioms Analysis.Ssum_den_pos
#print axioms Analysis.Ssum_tail_le
#print axioms Analysis.npow_base_mono
#print axioms Analysis.npow_add
#print axioms Analysis.qpow_one_den
#print axioms Analysis.cApprox_depth_diff
#print axioms Analysis.Ssum_depth_diff
#print axioms Analysis.Ssum_le
#print axioms Analysis.pow_dom
#print axioms Analysis.gammaHseq_den_pos
#print axioms Analysis.gammaHseq_reg_le
#print axioms Analysis.gammaHseq_regular
#print axioms Analysis.Qabs_lower
#print axioms Analysis.clow_le_cApprox
#print axioms Analysis.Ssum_le_of_le
#print axioms Analysis.clow_den_pos
#print axioms Analysis.gammaHseq_ge_clow
#print axioms Analysis.gammaHseq_nonneg
#print axioms Analysis.Rgamma_h_lower
#print axioms Analysis.Qle_add_of_Qsub_le
#print axioms Analysis.artSum_upper_cleared
#print axioms Analysis.Rmul_ofQ_le
#print axioms Analysis.artSum_le_value
#print axioms Analysis.log_tail_eq
#print axioms Analysis.Rlog2c_le
#print axioms Analysis.deltaTail_eq
#print axioms Analysis.artTerm_base_mono
#print axioms Analysis.artSum_base_mono
#print axioms Analysis.Rpi_seq_lb
#print axioms Analysis.arctanSum_deep_le
#print axioms Analysis.arctanSum_deep_ge
#print axioms Analysis.Rpi_seq_ub_tight
#print axioms Analysis.Rpi_seq_ge
#print axioms Analysis.Rpi_seq_num_pos
#print axioms Analysis.tmap_num_nonneg
#print axioms Analysis.RpiTmap_den
#print axioms Analysis.RpiTmap_abs_le
#print axioms Analysis.RpiTmap_nonneg
#print axioms Analysis.tailπ_eq
#print axioms Analysis.Rlogπc_le
#print axioms Analysis.Qmul_half_le
#print axioms Analysis.Qabs_half_le
#print axioms Analysis.Rneg_le
#print axioms Analysis.Rhalf_ge
#print axioms Analysis.Rle_ofQ_add_Radd
#print axioms Analysis.Radd_Rle_ofQ_add
#print axioms Analysis.Rneg_ofQ_le
#print axioms Analysis.Rlambda1_pos

-- v0.15.0 — the complex analytic engine (stage A).
#print axioms Analysis.Cexp_re
#print axioms Analysis.Cexp_im
#print axioms Analysis.qpow_num_zero
#print axioms Analysis.altTerm_cos_zero_num
#print axioms Analysis.altSum_cos_zero
#print axioms Analysis.RexpReal_zero
#print axioms Analysis.Rcos_zero
#print axioms Analysis.Rsin_zero
#print axioms Analysis.Cexp_zero
#print axioms Analysis.choose_zero_right
#print axioms Analysis.choose_zero_succ
#print axioms Analysis.choose_succ_succ
#print axioms Analysis.choose_eq_zero_of_lt
#print axioms Analysis.choose_self
#print axioms Analysis.choose_mul_fct_mul_fct
#print axioms Analysis.Fsum_den_pos
#print axioms Analysis.Fsum_congr
#print axioms Analysis.Qadd_rearrange
#print axioms Analysis.Qmul_add_left
#print axioms Analysis.Fsum_add
#print axioms Analysis.Fsum_mul_left
#print axioms Analysis.Fsum_shift
#print axioms Analysis.Qadd_sub_cancel_left
#print axioms Analysis.Fsum_front
#print axioms Analysis.binTerm_den_pos
#print axioms Analysis.binTerm_top_zero
#print axioms Analysis.binTerm_zero_bot
#print axioms Analysis.Qadd_zero_right
#print axioms Analysis.Qadd_swap_left
#print axioms Analysis.Fsum_congr_le
#print axioms Analysis.Qmul_swap
#print axioms Analysis.binTerm_succ
#print axioms Analysis.binomial
#print axioms Analysis.expTerm_conv_term
#print axioms Analysis.expTerm_conv
#print axioms Analysis.alternating_binomial
#print axioms Analysis.Qadd_assoc3
#print axioms Analysis.Fsum_triangle_reindex
#print axioms Analysis.Fsum_square_decomp
#print axioms Analysis.Fsum_swap
#print axioms Analysis.Fsum_split_add
#print axioms Analysis.Fsum_split_at
#print axioms Analysis.Fsum_mono_len
#print axioms Analysis.Fsum_le_congr
#print axioms Analysis.Fsum_num_nonneg
#print axioms Analysis.Fsum_abs_le
#print axioms Analysis.Fsum_mul_const_right
#print axioms Analysis.Fsum_mul_square
#print axioms Analysis.expSum_eq_Fsum
#print axioms Analysis.Fsum_conv_expSum
#print axioms Analysis.Qmul_sub_distrib
#print axioms Analysis.QnegCongr
#print axioms Analysis.QsubCongr
#print axioms Analysis.Fsum_sq_cauchy
#print axioms Analysis.expSum_mul_eq
#print axioms Analysis.expSum_corner_factored
#print axioms Analysis.Qsub_add_left_cancel
#print axioms Analysis.expSum_mul_le
#print axioms Analysis.expSum_corner_le
-- v0.15.0 — the exponential functional equation on ℝ (the diagonal lift of the Cauchy product).
#print axioms Analysis.Qsub_add_self_left
#print axioms Analysis.Qsub_num_nonneg
#print axioms Analysis.exp_diag_gap
#print axioms Analysis.Rexp_add
-- v0.15.0 — the trigonometric Cauchy product (toward cos² + sin² = 1).
#print axioms Analysis.Qmul_left_comm
#print axioms Analysis.Qmul4_rearrange
#print axioms Analysis.qpow_add
#print axioms Analysis.altTerm_mul
#print axioms Analysis.altConv_factor
#print axioms Analysis.Qadd_perm
#print axioms Analysis.Qadd_perm4
#print axioms Analysis.Fsum_parity_split
#print axioms Analysis.Qadd_same_den_loc
#print axioms Analysis.Fsum_const_den
#print axioms Analysis.qpow_neg_one_even
#print axioms Analysis.qpow_neg_one_odd
#print axioms Analysis.NFsum_neg
#print axioms Analysis.binTerm_even
#print axioms Analysis.binTerm_odd
#print axioms Analysis.binom_even_odd_eq
#print axioms Analysis.cosFct_term
#print axioms Analysis.sinFct_term
#print axioms Analysis.cosFct_eq_sinFct
#print axioms Analysis.Qmul_assoc3
#print axioms Analysis.Qmul_qsq_qpow
#print axioms Analysis.altPyth_conv_vanish
#print axioms Analysis.Qadd_cancel_mid
#print axioms Analysis.altPyth_telescope
#print axioms Analysis.altPyth_partial
#print axioms Analysis.altCorner_factored
#print axioms Analysis.altCorner_abs_le
#print axioms Analysis.qpow_natBase
#print axioms Analysis.expTerm_natBase
#print axioms Analysis.altSum_eq_Fsum
#print axioms Analysis.expSumM_eq_Fsum
#print axioms Analysis.altAbsSum_le_U
#print axioms Analysis.altAbsTail_le
#print axioms Analysis.altTail_deep_le
#print axioms Analysis.Qsub_le_self_loc
#print axioms Analysis.altGap_le_U
#print axioms Analysis.altCorner_mertens
#print axioms Analysis.altTerm_abs_le_exp
#print axioms Analysis.altAntidiag_abs_le
#print axioms Analysis.Qabs_add3_le
#print axioms Analysis.Qabs_qsq_mul_le
#print axioms Analysis.altPyth_dev_eq_err
#print axioms Analysis.altErr_abs_le
#print axioms Analysis.Qsq_diff_le
#print axioms Analysis.Rcos_sq_diag_le
#print axioms Analysis.diagU_le
#print axioms Analysis.n_le_RaltReal_R
#print axioms Analysis.Rsin_sq_diag_le
#print axioms Analysis.Q_den_mono
#print axioms Analysis.Rcos_sq_add_sin_sq
#print axioms Analysis.Rmul4_rearrange
#print axioms Analysis.Rsin_sq_eq
#print axioms Analysis.altSum_reconcile
#print axioms Analysis.RaltReal_trunc_decay
#print axioms Analysis.RaltReal_trunc_le
#print axioms Analysis.npow_fct_decay
#print axioms Analysis.truncCoef_Q
#print axioms Analysis.Q_le_num_toNat
#print axioms Analysis.qpow_Qeq
#print axioms Analysis.expTerm_Qeq
#print axioms Analysis.expTerm_2MM
#print axioms Analysis.truncCoef_QE
#print axioms Analysis.uterm_le
#print axioms Analysis.altErr_bound_decay
#print axioms Analysis.xreg_n_le
#print axioms Analysis.xsq_diff_n_le
#print axioms Analysis.Qprodsq_diff_le
#print axioms Analysis.RaltReal_R_mono
#print axioms Analysis.altSum_abs_le_U
#print axioms Analysis.altSq_reconcile
#print axioms Analysis.deepErr_le
#print axioms Analysis.ratPyth_le

-- v0.10.0 — the λₙ / RH proof boundary (analytic face), locked faithfully.
#print axioms Li.Pos_one
#print axioms Li.template_liPositive
#print axioms Li.template_liNonneg
#print axioms Li.template_liPositiveUpTo
#print axioms Li.liPositive_iff_all_upTo
#print axioms Li.liDecomposition_genuine
#print axioms Li.explicitFormulaTrace_genuine
#print axioms Li.liAgreesWith_genuine

-- v0.10.0 — ExactBoundedReal enclosure interface + ζ(s) as an exact-bounded object.
#print axioms Analysis.enclosure_width
#print axioms Analysis.lowerB_le_upperB
#print axioms Analysis.certificate
#print axioms Analysis.npow_succ
#print axioms Analysis.npow_pos
#print axioms Analysis.npow_two
#print axioms Analysis.npow_one
#print axioms Analysis.npow_mono
#print axioms Analysis.zetaSum_den_pos
#print axioms Analysis.zetaSum_step
#print axioms Analysis.zetaSum_le
#print axioms Analysis.zeta_step_le
#print axioms Analysis.zetaU_den_pos
#print axioms Analysis.zetaU_step
#print axioms Analysis.zetaU_le
#print axioms Analysis.zetadiff_bound
#print axioms Analysis.zetaabs_bound
#print axioms Analysis.zetaSeq_regular
#print axioms Analysis.zeta_seq
#print axioms Analysis.zeta_pos

-- v0.15.0 keystone D corollary — |cos| ≤ 1, |sin| ≤ 1 (cos² ≤ 1, sin² ≤ 1).
#print axioms Analysis.Rnonneg_Rmul_self
#print axioms Analysis.Rle_self_Radd_right
#print axioms Analysis.Rle_self_Radd_left
#print axioms Analysis.Rcos_sq_le_one
#print axioms Analysis.Rsin_sq_le_one

-- v0.15.0 payoff — the Cexp modulus identity |Cexp z|² = (exp Re z)² (from cos²+sin²=1).
#print axioms Analysis.CnormSq
#print axioms Analysis.Cexp_normSq

-- v0.15.0 payoff — nˢ for integer base n ≥ 2 (Cexp(s·log n)) and its modulus.
#print axioms Analysis.RofNat
#print axioms Analysis.RlogNat
#print axioms Analysis.ncpow
#print axioms Analysis.ncpow_normSq

-- v0.15.0 ζ-stack — exp functional equation on all of ℝ (general-argument Cauchy corner).
#print axioms Analysis.expSum_corner_le_gen
#print axioms Analysis.expSum_add_le
#print axioms Analysis.expSum_reconcile
#print axioms Analysis.Qprod_diff_le
#print axioms Analysis.RexpReal_trunc_decay
#print axioms Analysis.RexpReal_trunc_le
#print axioms Analysis.expSum_abs_le_Un
#print axioms Analysis.expSum_add_decay
#print axioms Analysis.expTerm_abs
#print axioms Analysis.Fsum_tail_abs_le
#print axioms Analysis.expSum_corner_le_gen_signed
#print axioms Analysis.expSum_add_le_signed
#print axioms Analysis.expSum_add_decay_signed
#print axioms Analysis.n_le_RexpReal_R
#print axioms Analysis.rexp_factor_reconcile
#print axioms Analysis.rexp_add_gap
#print axioms Analysis.RexpReal_add_aux
#print axioms Analysis.RexpReal_add
-- v0.15.1 (wip) — toward exp∘log = id: exp respects ≈, and the reciprocal law.
#print axioms Analysis.RexpReal_congr
#print axioms Analysis.RexpReal_mul_neg
#print axioms Analysis.gPow_den_pos
#print axioms Analysis.gPow_num_nonneg
#print axioms Analysis.gPow_telescope
#print axioms Analysis.Qzero_add
#print axioms Analysis.fderiv_den_pos
#print axioms Analysis.fmul_den_pos
#print axioms Analysis.fderiv_fmul
#print axioms Analysis.Qadd_comm
#print axioms Analysis.Qmul_comm
#print axioms Analysis.Fsum_reverse
#print axioms Analysis.fmul_comm
#print axioms Analysis.Qmul_assoc
#print axioms Analysis.fmul_assoc
#print axioms Analysis.fone_den_pos
#print axioms Analysis.Fsum_zeros
#print axioms Analysis.fmul_one
#print axioms Analysis.dexpderiv_den
#print axioms Analysis.dgeom_den
#print axioms Analysis.dexpderiv_sum
#print axioms Analysis.dgeom_ode
#print axioms Analysis.peval_den_pos
#print axioms Analysis.peval_dgeom
#print axioms Analysis.expTerm_quad
#print axioms Analysis.Qsq_mul_nonneg
#print axioms Analysis.expSum_quad
#print axioms Analysis.artSum_lin_quad
#print axioms Analysis.Fsum_single
#print axioms Analysis.fmono_den
#print axioms Analysis.fmul_fmono
#print axioms Analysis.peval_conv
#print axioms Analysis.peval_mul
#print axioms Analysis.fmul_fmono_zero
#print axioms Analysis.fmul_add_left
#print axioms Analysis.kdbl_den
#print axioms Analysis.kdbl_shift_cancel
#print axioms Analysis.kdbl_main
#print axioms Analysis.kdbl_rel
#print axioms Analysis.oneplusSq_den
#print axioms Analysis.fderiv_congr
#print axioms Analysis.fmul_congr_left
#print axioms Analysis.twoFone_den
#print axioms Analysis.fderiv_oneplusSq
#print axioms Analysis.fderiv_twoT
#print axioms Analysis.kdbl_deriv_rel
#print axioms Analysis.fpow_den_pos
#print axioms Analysis.fpow_vanish
#print axioms Analysis.fcomp_den_pos
#print axioms Analysis.fcomp_const
#print axioms Analysis.fderiv_fone
#print axioms Analysis.fmul_congr_right
#print axioms Analysis.fsmul_den
#print axioms Analysis.fmul_zero_right
#print axioms Analysis.fmul_smul_right
#print axioms Analysis.fmul_swap_left
#print axioms Analysis.Qcombine_succ
#print axioms Analysis.fpow_deriv
#print axioms Analysis.fderiv_fcomp_sum
#print axioms Analysis.fcomp_chain_pre
#print axioms Analysis.Fsum_extend_zero
#print axioms Analysis.fcomp_chain
#print axioms Analysis.fsmono_den
#print axioms Analysis.fmul_fsmono
#print axioms Analysis.fmul_fsmono_zero
#print axioms Analysis.gcoef_den
#print axioms Analysis.acoef_den
#print axioms Analysis.fderiv_acoef
#print axioms Analysis.oneMinusSq_den
#print axioms Analysis.gcoef_shift_cancel
#print axioms Analysis.artanh_main
#print axioms Analysis.artanh_ode
#print axioms Analysis.fcomp_congr_left
#print axioms Analysis.Fsum_sub
#print axioms Analysis.fmul_sub_left
#print axioms Analysis.Qeq_of_Qsub_zero
#print axioms Analysis.oneMinusSq_eval2
#print axioms Analysis.oneMinusSq_eval0
#print axioms Analysis.oneMinusSq_eval1
#print axioms Analysis.oneMinusSq_zero_cancel
#print axioms Analysis.fmul_oneMinusSq_cancel
#print axioms Analysis.oneplusSq_eval2
#print axioms Analysis.oneplusSq_eval0
#print axioms Analysis.oneplusSq_eval1
#print axioms Analysis.oneplusSq_zero_cancel
#print axioms Analysis.fmul_oneplusSq_cancel
#print axioms Analysis.twoT_den
#print axioms Analysis.ksq_rel
#print axioms Analysis.fmono1_twoT
#print axioms Analysis.tk_rel
#print axioms Analysis.fmul_add_right
#print axioms Analysis.oneplusSq_twoFone
#print axioms Analysis.oneplusSq_kderiv
#print axioms Analysis.kdbl_W
#print axioms Analysis.twoFone_2fone
#print axioms Analysis.twoFone_fsmono
#print axioms Analysis.fmul_twoFone
#print axioms Analysis.twoT_fmono
#print axioms Analysis.twoT_2tk
#print axioms Analysis.oneMinusSq_as_sub
#print axioms Analysis.kdbl_sq_id
#print axioms Analysis.fpow_add
#print axioms Analysis.fcomp_add
#print axioms Analysis.fcomp_fone
#print axioms Analysis.Qsub_telescope3
#print axioms Analysis.geoEvenPow_den
#print axioms Analysis.fpow_sq_bump
#print axioms Analysis.geoEven_telescope
#print axioms Analysis.Fsum_collapse_odd
#print axioms Analysis.kdbl_zero
#print axioms Analysis.fcomp_gcoef_geoEven
#print axioms Analysis.comp_recip
#print axioms Analysis.fderiv_inj
#print axioms Analysis.twoacoef_ode
#print axioms Analysis.fcomp_acoef_ode
#print axioms Analysis.formal_doubling
#print axioms Analysis.acoef_even_zero
#print axioms Analysis.acoef_odd_artTerm
#print axioms Analysis.peval_acoef_artSum
#print axioms Analysis.peval_congr
#print axioms Analysis.peval_smul
#print axioms Analysis.dcomp_artSum
#print axioms Analysis.mul_left_zero
#print axioms Analysis.mul_right_zero
#print axioms Analysis.peval_fcomp_swap
#print axioms Analysis.Fsum_le_Fsum
#print axioms Analysis.peval_abs_bound
#print axioms Analysis.Qeq_sub_of_eq_add
#print axioms Analysis.peval_fpow_succ
#print axioms Analysis.fabs
#print axioms Analysis.fabs_den_pos
#print axioms Analysis.fabs_nonneg
#print axioms Analysis.Qabs_fmul_le
#print axioms Analysis.fmul_mono_right
#print axioms Analysis.fpow_abs_dom
#print axioms Analysis.peval_mono
#print axioms Analysis.peval_abs_le_peval_fabs
#print axioms Analysis.peval_fone
#print axioms Analysis.Qmul_num_nonneg
#print axioms Analysis.fpow_num_nonneg
#print axioms Analysis.peval_num_nonneg
#print axioms Analysis.peval_fpow_le_pow
#print axioms Analysis.peval_fpow_abs_bound
#print axioms Analysis.fabs_kdbl_even
#print axioms Analysis.fabs_kdbl_odd
#print axioms Analysis.peval_fabs_kdbl_geoSum
#print axioms Analysis.geoTerm_tel
#print axioms Analysis.geoSum_telescope
#print axioms Analysis.geoSum_tel_le
#print axioms Analysis.fabs_kdbl_le2
#print axioms Analysis.pow2_sum
#print axioms Analysis.fpow_fabs_kdbl_bound
#print axioms Analysis.qpow_mul
#print axioms Analysis.qpow_two_nat
#print axioms Analysis.fpow_kdbl_term_bound
#print axioms Analysis.Fsum_abs_diff_le
#print axioms Analysis.peval_kdbl_pow_gap
#print axioms Analysis.gPow_eq_Fsum
#print axioms Analysis.Qsub_sub_one
#print axioms Analysis.gPow_gap_le
#print axioms Analysis.Qmul_sub_left_loc
#print axioms Analysis.peval_kdbl_pow_cauchy
#print axioms Analysis.peval_kdbl_pow_abs_le
#print axioms Analysis.corner_inner_eq
#print axioms Analysis.Qle_rho_two_rho
#print axioms Analysis.qpow_conv_le
#print axioms Analysis.mul_rearrange
#print axioms Analysis.Qabs_C_le
#print axioms Analysis.corner_term_le
#print axioms Analysis.Fsum_le_Fsum_le
#print axioms Analysis.corner_bound
#print axioms Analysis.kdbl_period
#print axioms Analysis.add_rearrange
#print axioms Analysis.qpow_mul_sq
#print axioms Analysis.kdbl_innerval
#print axioms Analysis.uval
#print axioms Analysis.uval_den_pos
#print axioms Analysis.uval_rel
#print axioms Analysis.Qabs_kdbl_qpow_le
#print axioms Analysis.q_conv
#print axioms Analysis.uval_abs_le
#print axioms Analysis.Qabs_sub_le_add
#print axioms Analysis.e_rec_alg
#print axioms Analysis.kcorner
#print axioms Analysis.kcorner_den
#print axioms Analysis.per_m_step
#print axioms Analysis.per_m_bound
#print axioms Analysis.DN_eq
#print axioms Analysis.acoef_num_nonneg
#print axioms Analysis.acoef_le_one
#print axioms Analysis.DN_abs_le
#print axioms Analysis.e_le_T
#print axioms Analysis.DN_double_le
#print axioms Analysis.Qadd_num_nonneg_loc
#print axioms Analysis.Qzero_le_loc
#print axioms Analysis.sq_le_four_pow
#print axioms Analysis.corner_sum_bound
#print axioms Analysis.Qadd_const_mul
#print axioms Analysis.Fsum_const_eq
#print axioms Analysis.pow4_sum_le
#print axioms Analysis.Qmul_rearr3
#print axioms Analysis.pow4_2_sum_le
#print axioms Analysis.corner_sum_closed
#print axioms Analysis.Qmul_swap_outer
#print axioms Analysis.mul_div2
#print axioms Analysis.corner_sum_final
#print axioms Analysis.T_le
#print axioms Analysis.DN_geom_le
#print axioms Analysis.qpow_double
#print axioms Analysis.qpow_mono_exp
#print axioms Analysis.qpow_const_nat
#print axioms Analysis.qpow_const_combine
#print axioms Analysis.Qadd_2_2_4
#print axioms Analysis.Qadd_4_4_8
#print axioms Analysis.Qmul_2_2_4
#print axioms Analysis.qpow_Qeq_loc
#print axioms Analysis.T_pow_le
#print axioms Analysis.two_pow_2Nplus2
#print axioms Analysis.Qmul_8rearr
#print axioms Analysis.DN_pow_le
#print axioms Analysis.qpow_le_recip
#print axioms Analysis.Qmul_2_2
#print axioms Analysis.geoSum_num_nonneg
#print axioms Analysis.peval_kdbl_abs_le_one
#print axioms Analysis.DN_recip
#print axioms Analysis.Qadd_self
#print axioms Analysis.RartanhAtQ_seq
#print axioms Analysis.Qadd_same_den
#print axioms Analysis.Rartanh_double_via
#print axioms Analysis.Rartanh_double_rat
#print axioms Analysis.geoEvenSum_num_nonneg
#print axioms Analysis.geoEvenSum_le_two
#print axioms Analysis.Rartanh_congr
#print axioms Analysis.uval_diff_cleared
#print axioms Analysis.uval_lip
#print axioms Analysis.artSum_depth_recip
#print axioms Analysis.Dterm_recip
#print axioms Analysis.artSum_uval_argdiff
#print axioms Analysis.Rartanh_double_real_via
#print axioms Analysis.Qmul_cancel_left
#print axioms Analysis.tmap_uval_core
#print axioms Analysis.tmap_sq_uval
#print axioms Analysis.tmap_lip
#print axioms Analysis.tsq_uvalReal_via
#print axioms Analysis.Rlog_double_algebra
#print axioms Analysis.Rartanh_radius_indep
#print axioms Analysis.Rlog_sq_via
#print axioms Analysis.Rlog_eq_Rmul
#print axioms Analysis.Rlog_tbound
#print axioms Analysis.Rlog_radius_facts
#print axioms Analysis.Rlog_sq
#print axioms Analysis.ecoef_den
#print axioms Analysis.fderiv_ecoef
#print axioms Analysis.fderiv_mul_inj
#print axioms Analysis.fderiv_twoacoef
#print axioms Analysis.formal_exp_geom
#print axioms Analysis.expSum_eq_peval_ecoef
#print axioms Analysis.peval_twoacoef_artSum
#print axioms Analysis.comp_eval_gap_le
#print axioms Analysis.peval_dgeom_mul_cleared
#print axioms Analysis.peval_dgeom_tail_cleared
#print axioms Analysis.truncTo_den
#print axioms Analysis.truncTo_le
#print axioms Analysis.peval_truncTo
#print axioms Analysis.Fsum_ext_zero
#print axioms Analysis.peval_mul_no_corner
#print axioms Analysis.fpow_supp
#print axioms Analysis.peval_fpow_pow_eq
#print axioms Analysis.truncTo_nonneg
#print axioms Analysis.fpow_mono
#print axioms Analysis.qpow_peval_le
#print axioms Analysis.Fsum_le_extend
#print axioms Analysis.exp_corner_le
#print axioms Analysis.dgeom_geom_gap_le
#print axioms Analysis.exp_artanh_rat_cleared
#print axioms Analysis.mul_div_gen
#print axioms Analysis.Fsum_smul
#print axioms Analysis.peval_twoacoef_cauchy
#print axioms Analysis.peval_twoacoef_abs_le_gpow
#print axioms Analysis.exp_artanh_recip
#print axioms Analysis.Rexp_two_artanh_via
#print axioms Analysis.two_gPow_le
#print axioms Analysis.Rexp_two_artanh_ofQ
#print axioms Analysis.tmap_nat_den
#print axioms Analysis.tmap_nat_num
#print axioms Analysis.Rexp_log_nat
#print axioms Analysis.Rexp_log_nat_Rlog

-- v0.15.2 — real powers `nᶜ = exp(c·log n)` (RealPow.lean).
#print axioms Analysis.Rnsmul_zero
#print axioms Analysis.Rnsmul_succ
#print axioms Analysis.RexpReal_nsmul
#print axioms Analysis.RexpReal_nsmul_eq
#print axioms Analysis.Rnonneg_Rmul
#print axioms Analysis.Rnonneg_of_Rle_zero
#print axioms Analysis.Rnonneg_congr
#print axioms Analysis.Rhalf_double
#print axioms Analysis.Rhalf_Radd
#print axioms Analysis.Rhalf_Rneg
#print axioms Analysis.Rhalf_Rsub
#print axioms Analysis.Rhalf_congr
#print axioms Analysis.Rhalf_le_Rhalf
#print axioms Analysis.Rhalf_nonneg
#print axioms Analysis.RexpReal_nonneg
#print axioms Analysis.RexpReal_sub_one_nonneg
#print axioms Analysis.Rnonneg_Rsub_of_Rle
#print axioms Analysis.Rle_of_Rnonneg_Rsub
#print axioms Analysis.Radd_Rsub_self
#print axioms Analysis.RexpReal_le_of_Rle
#print axioms Analysis.Rmul_ofQ_ofQ
#print axioms Analysis.RexpReal_neg_eq_recip
#print axioms Analysis.artSum_nonneg
#print axioms Analysis.Rlog_nonneg
#print axioms Analysis.Rneg_Radd
#print axioms Analysis.Rone_mul
#print axioms Analysis.Rmul_two_eq_add
#print axioms Analysis.Rmul_two_le_Rmul
#print axioms Analysis.RexpReal_neg_two_eq
#print axioms Analysis.RexpReal_neg_sigma_le
#print axioms Analysis.expSum_le_gPow
#print axioms Analysis.expSum_mul_one_sub_le
#print axioms Analysis.Rnonneg_of_Rmul_Pos
#print axioms Analysis.Pos_of_Rle_one
#print axioms Analysis.expSum_ge_one_add
#print axioms Analysis.RexpReal_ge_one_add_nonneg
#print axioms Analysis.gval_den_pos
#print axioms Analysis.gval_rel
#print axioms Analysis.tmap_two_law
#print axioms Analysis.dcoef_den
#print axioms Analysis.dcoef_zero
#print axioms Analysis.nine3w_den
#print axioms Analysis.eightT_den
#print axioms Analysis.nine3w_split
#print axioms Analysis.dcoef_cancel_scalar
#print axioms Analysis.dcoef_shift_cancel
#print axioms Analysis.dcoef_main
#print axioms Analysis.dcoef_rel
#print axioms Analysis.threeFone_den
#print axioms Analysis.eightFone_den
#print axioms Analysis.fderiv_nine3w
#print axioms Analysis.fderiv_eightT
#print axioms Analysis.dcoef_deriv_rel
#print axioms Analysis.mul9_eq_zero
#print axioms Analysis.nine3w_eval0
#print axioms Analysis.nine3w_eval_succ
#print axioms Analysis.nine3w_zero_cancel
#print axioms Analysis.fmul_nine3w_cancel
#print axioms Analysis.threeFone_eq_fsmono
#print axioms Analysis.nine3w_dderiv
#print axioms Analysis.nine3w_dsq
#print axioms Analysis.eightT_eq_fsmono
#print axioms Analysis.eightT_sq_val
#print axioms Analysis.nine3w_sq_val
#print axioms Analysis.nine3w_eightT_val
#print axioms Analysis.g2_final
#print axioms Analysis.fmul_sub_right
#print axioms Analysis.eightFone_eq_fsmul
#print axioms Analysis.eight_n_three_e
#print axioms Analysis.nine3w_8m3d
#print axioms Analysis.nine3w_M2
#print axioms Analysis.nine3w_qcomp1
#print axioms Analysis.nine3w_de
#print axioms Analysis.qcomp_den
#print axioms Analysis.nine3w_qcomp2
#print axioms Analysis.dcoef_ode
#print axioms Analysis.sacDpair_den
#print axioms Analysis.sacD_den
#print axioms Analysis.sacD_succ_succ
#print axioms Analysis.p2_den
#print axioms Analysis.p2_split
#print axioms Analysis.sacD_cancel
#print axioms Analysis.sacD_ode
#print axioms Analysis.sacoef_zero
#print axioms Analysis.sacoef_den
#print axioms Analysis.fderiv_sacoef
#print axioms Analysis.fcomp_shift1
#print axioms Analysis.fmono1_sq
#print axioms Analysis.fcomp_shift2
#print axioms Analysis.fmul_smul_left
#print axioms Analysis.fcomp_smul
#print axioms Analysis.fcomp_sub
#print axioms Analysis.fmul_fsmono_smul
#print axioms Analysis.p2_sacD
#print axioms Analysis.qcomp_add
#print axioms Analysis.composed_ode
#print axioms Analysis.mul9_cancel
#print axioms Analysis.fderiv_fcomp_sacoef
#print axioms Analysis.fcomp_sacoef_eq_acoef
#print axioms Analysis.peval_fcomp_sacoef_artSum
#print axioms Analysis.gcorner_den
#print axioms Analysis.per_m_step_gen
#print axioms Analysis.per_m_bound_gen
#print axioms Analysis.qpow_third_abs_le_one
#print axioms Analysis.dcoef_abs_le_one
#print axioms Analysis.drat_den
#print axioms Analysis.drat_rel
#print axioms Analysis.peval_nine3w
#print axioms Analysis.peval_eightT
#print axioms Analysis.nine3w_peval_dcoef
#print axioms Analysis.nine3w_peval_dcoef_sub
#print axioms Analysis.inner_eval_bound
#print axioms Analysis.dcoef_term_geo
#print axioms Analysis.inner_eval_geo
#print axioms Analysis.fpow_fabs_dcoef_bound
#print axioms Analysis.qpow_two_eq
#print axioms Analysis.qpow_mul_dist
#print axioms Analysis.fpow_fabs_dcoef_term
#print axioms Analysis.peval_dcoef_pow_gap
#print axioms Analysis.peval_dcoef_pow_cauchy
#print axioms Analysis.corner_inner_eq_gen
#print axioms Analysis.Qabs_dcoef_qpow_le
#print axioms Analysis.dcoef_corner_term
#print axioms Analysis.dcoef_gcorner_bound
#print axioms Analysis.Pos_imp_ofQ_le
#print axioms Analysis.Pos_mono
#print axioms Analysis.Rnonneg_of_Pos
#print axioms Analysis.Rnonneg_neg_of_not_Pos
#print axioms Analysis.not_Pos_of_Rnonneg_neg
#print axioms Analysis.Rneg_neg
#print axioms Analysis.Rneg_Rsub
#print axioms Analysis.RexpReal_ge_one
#print axioms Analysis.Pos_RexpReal
#print axioms Analysis.Pos_congr
#print axioms Analysis.exp_sub_exp_eq
#print axioms Analysis.Rsub_Radd_eq
#print axioms Analysis.Rle_exp_sub_one
#print axioms Analysis.Rle_self_Rmul_left
#print axioms Analysis.RexpReal_strictmono
#print axioms Analysis.RexpReal_reflects_le
#print axioms Analysis.RexpReal_inj
#print axioms Analysis.Rexp_logN
#print axioms Analysis.Rnonneg_logN
#print axioms Analysis.logN_mul
#print axioms Analysis.logN_eq_of_eq
#print axioms Analysis.logN_one
#print axioms Analysis.logN_pow_two
#print axioms Analysis.Rle_ofQ_ofQ
#print axioms Analysis.logN_mono
#print axioms Analysis.logN_ge_k_log2
#print axioms Analysis.Rmul_le_Rmul_left
#print axioms Analysis.exp_block_bound
#print axioms Analysis.Rexp_k_log2
#print axioms Analysis.Rexp_half_le
#print axioms Analysis.logN_2_ge_half
#print axioms Analysis.Rnonneg_ofQ
#print axioms Analysis.Rle_recip
#print axioms Analysis.Rexp_neg_le_ratio
#print axioms Analysis.Rmul_le_Rmul_right
#print axioms Analysis.Pos_Rmul
#print axioms Analysis.Rmul_sub_add_self
#print axioms Analysis.Rle_of_Rmul_self_le
#print axioms Analysis.Rneg_sq
#print axioms Analysis.Rcos_le_one
#print axioms Analysis.Rneg_one_le_Rcos
#print axioms Analysis.Rsin_le_one
#print axioms Analysis.Rneg_one_le_Rsin
#print axioms Analysis.Cexp_re_le
#print axioms Analysis.Cexp_re_ge
#print axioms Analysis.Cexp_im_le
#print axioms Analysis.Cexp_im_ge
#print axioms Analysis.czetaTerm_re_le
#print axioms Analysis.czetaTerm_re_ge
#print axioms Analysis.czetaTerm_im_le
#print axioms Analysis.czetaTerm_im_ge
#print axioms Analysis.Rsub_Radd_left
#print axioms Analysis.Rneg_zero
#print axioms Analysis.czeta_re_diff_le_aux
#print axioms Analysis.czeta_re_diff_le
#print axioms Analysis.czeta_re_diff_ge_aux
#print axioms Analysis.czeta_re_diff_ge
#print axioms Analysis.czeta_im_diff_le_aux
#print axioms Analysis.czeta_im_diff_le
#print axioms Analysis.czeta_im_diff_ge_aux
#print axioms Analysis.czeta_im_diff_ge
#print axioms Analysis.czetaExp_block_le
#print axioms Analysis.czetaExp_term_le
#print axioms Analysis.czetaExp_block
#print axioms Analysis.Rnonneg_Rpow
#print axioms Analysis.Rpow_ofQ
#print axioms Analysis.Rpow_mono
#print axioms Analysis.Rmul_Rnsmul
#print axioms Analysis.Rneg_Rnsmul
#print axioms Analysis.Rmul_mul_mul
#print axioms Analysis.Rpow_mul_dist
#print axioms Analysis.Radd_ofQ_ofQ
#print axioms Analysis.ofQ_congr
#print axioms Analysis.Rnsmul_eq_Rmul_ofQ
#print axioms Analysis.czetaExpB_eq_pow
#print axioms Analysis.czetaExp_block_pow
#print axioms Analysis.czeta_theta_arg_eq
#print axioms Analysis.czetaU_2u_eq
#print axioms Analysis.czetaU_2u_le_of_theta
#print axioms Analysis.czeta_theta_ge
#print axioms Analysis.czetaExp_block_geo
#print axioms Analysis.Rsub_telescope
#print axioms Analysis.geoFrom_den_pos
#print axioms Analysis.czetaExp_tail
#print axioms Analysis.geoFrom_den_pos
#print axioms Analysis.geoFrom_telescope
#print axioms Analysis.geoFrom_le
#print axioms Analysis.seq_diff_le
#print axioms Analysis.RReg_of_real_bound
#print axioms Analysis.geom_reindex
#print axioms Analysis.czetaR_facts
#print axioms Analysis.czetaExp_tail_reindex
#print axioms Analysis.czetaMidx_mono
#print axioms Analysis.czetaExp_tail_mono
#print axioms Analysis.czetaRe_tail_le
#print axioms Analysis.czetaRe_tail_ge
#print axioms Analysis.czetaIm_tail_le
#print axioms Analysis.czetaIm_tail_ge
#print axioms Analysis.Czeta_re_tendsTo
#print axioms Analysis.Czeta_im_tendsTo
#print axioms Analysis.czetaRe_RReg
#print axioms Analysis.czetaIm_RReg
#print axioms Analysis.czeta_two_theta
#print axioms Analysis.czetaExp_mono
#print axioms Analysis.czetaExp_tail_full
#print axioms Analysis.czetaRe_tail_full
#print axioms Analysis.czetaRe_tail_full_neg
#print axioms Analysis.czetaIm_tail_full
#print axioms Analysis.czetaIm_tail_full_neg
#print axioms Analysis.czetaRe_cauchy_full
#print axioms Analysis.czetaIm_cauchy_full
#print axioms Analysis.RTendsTo_to_Rle
#print axioms Analysis.RTendsTo_to_Rle_lower
#print axioms Analysis.Req_of_Rle_ofQ_all
#print axioms Analysis.czetaRe_full_tendsTo
#print axioms Analysis.czetaIm_full_tendsTo
#print axioms Analysis.Czeta_re_canonical
#print axioms Analysis.Czeta_im_canonical

-- Mangoldt (the von Mangoldt function Λ and the explicit-formula prime side; v0.15.3).
#print axioms Analysis.spfFrom_ge_one
#print axioms Analysis.one_le_spf
#print axioms Analysis.two_le_of_isPrimePow
#print axioms Analysis.spf_dvd
#print axioms Analysis.spf_two_le
#print axioms Analysis.spf_prime
#print axioms Analysis.vonMangoldt_prime
#print axioms Analysis.vonMangoldt_one
#print axioms Analysis.vonMangoldt_two
#print axioms Analysis.vonMangoldt_three
#print axioms Analysis.vonMangoldt_four
#print axioms Analysis.vonMangoldt_six
#print axioms Analysis.vonMangoldt_eight
#print axioms Analysis.vonMangoldt_nine
#print axioms Analysis.vonMangoldt_nonneg
#print axioms Analysis.primeSide_stable
#print axioms Analysis.primeTerm_zero_of_h

-- GammaOne (the first Stieltjes constant γ₁ substrate: (ln k)/k, S(N), g(N); v0.16.0).
#print axioms Analysis.lnOver_nonneg
#print axioms Analysis.lnSum_step
#print axioms Analysis.lnSum_mono
#print axioms Analysis.logN_four_ge_one
#print axioms Analysis.logN_ge_one
#print axioms Analysis.twoArtanhRecip_le
#print axioms Analysis.Rnonneg_RartanhConst
#print axioms Analysis.Rexp_twoArtanhRecip
#print axioms Analysis.deltaLog_eq_twoArtanh
#print axioms Analysis.deltaLog_upper_tight
#print axioms Analysis.qRoundUp_ge
#print axioms Analysis.qRoundUp_den_pos
#print axioms Analysis.dPlusQ_den_pos
#print axioms Analysis.logBound_den_pos
#print axioms Analysis.logN_le_logBound
#print axioms Analysis.lnSumBound_den_pos
#print axioms Analysis.lnSum_le_lnSumBound
#print axioms Analysis.ofQ_artSum_le_RartanhConst
#print axioms Analysis.deltaLog_lower_tight
#print axioms Analysis.dMinusQ_den_pos
#print axioms Analysis.qRoundDown_le
#print axioms Analysis.qRoundDown_den_pos
#print axioms Analysis.logLowBound_den_pos
#print axioms Analysis.logN_ge_logLowBound
#print axioms Analysis.Rhalf_ofQ
#print axioms Analysis.Rneg_ofQ
#print axioms Analysis.dMinusQ_num_nonneg
#print axioms Analysis.logLowBound_num_nonneg
#print axioms Analysis.gBound_den_pos
#print axioms Analysis.gSeq_le_gBound
#print axioms Analysis.gBound200_le_neg
#print axioms Analysis.Rgamma1_le_neg445
#print axioms Analysis.gBound200_T4_le_neg055
#print axioms Analysis.Rgamma1_le_neg055
#print axioms Analysis.deltaLog_upper
#print axioms Analysis.expDelta_eq
#print axioms Analysis.expRecip_le
#print axioms Analysis.Rexp_recip_le
#print axioms Analysis.deltaLog_lower
#print axioms Analysis.addsub_linear
#print axioms Analysis.sq_diff_identity
#print axioms Analysis.Rsub_le_of_le_add
#print axioms Analysis.half_combine
#print axioms Analysis.dStep_le_half_sq
#print axioms Analysis.dStep_le
#print axioms Analysis.dStep_ge
#print axioms Analysis.Rsub_Rneg_Rneg
#print axioms Analysis.gSeq_step_eq
#print axioms Analysis.Rsub_split
#print axioms Analysis.gSeq_step_le
#print axioms Analysis.gSeq_step_ge
#print axioms Analysis.Usum_den_pos
#print axioms Analysis.Qadd_Qsub_comm
#print axioms Analysis.gSeq_diff_le_U
#print axioms Analysis.Qadd_Qsub_telescope
#print axioms Analysis.Usum_step_ineq
#print axioms Analysis.Usum_tail_le
#print axioms Analysis.gSeq_diff_le
#print axioms Analysis.logN_2_le_one
#print axioms Analysis.logN_le_block
#print axioms Analysis.gSeq_step_ge_block
#print axioms Analysis.Vsum_den_pos
#print axioms Analysis.gSeq_diff_ge_block
#print axioms Analysis.Vsum_step_eq
#print axioms Analysis.Vsum_tail_le
#print axioms Analysis.Qsub_block_le
#print axioms Analysis.gSeq_block_ge
#print axioms Analysis.Wsum_den_pos
#print axioms Analysis.gSeq_diff_ge_outer
#print axioms Analysis.Qadd_Qsub_fwd
#print axioms Analysis.Wsum_tail_le
#print axioms Analysis.lt_two_pow
#print axioms Analysis.lin_le_two_pow
#print axioms Analysis.gamma_domination
#print axioms Analysis.gammaMidx_mono
#print axioms Analysis.Qunit_le
#print axioms Analysis.Qsub_unit_le
#print axioms Analysis.succ_le_two_pow_midx
#print axioms Analysis.gamma_pair_le
#print axioms Analysis.Qsub_le_left
#print axioms Analysis.gamma_T_le
#print axioms Analysis.gamma_pair_ge
#print axioms Analysis.gSeqDyadic_RReg
#print axioms Analysis.Rle_of_Rsub_le_all
#print axioms Analysis.Rle_add_of_Rsub_le
#print axioms Analysis.gSeq_le_anchor
#print axioms Analysis.Rgamma1_le_gSeq

-- ZetaTwo (the ζ(2) ≥ 1.63 lower bracket; v0.16.0, for Pos λ₂).
#print axioms Analysis.zeta_ge_partial
#print axioms Analysis.zetaSum_two_70_ge
#print axioms Analysis.zeta2_lower
#print axioms Analysis.zeta_le_partial
#print axioms Analysis.zetaU_two_70_le
#print axioms Analysis.zeta2_upper
#print axioms Analysis.zetaSum_three_70_ge
#print axioms Analysis.zeta3_lower
#print axioms Analysis.zetaU_three_70_le
#print axioms Analysis.zeta3_upper

-- GammaUpper (the γ ≤ 0.66 upper bracket, companion to Rgamma_h_lower; v0.16.0, for Pos λ₂).
#print axioms Analysis.Qabs_upper
#print axioms Analysis.Qadd_sub_cancel
#print axioms Analysis.chigh_den_pos
#print axioms Analysis.cApprox_le_chigh
#print axioms Analysis.gammaHseq_le_one
#print axioms Analysis.gammaHseq_le_chigh
#print axioms Analysis.chigh_sum_bound
#print axioms Analysis.Rgamma_h_upper

-- Bernoulli (exact rational Bernoulli numbers; v0.16.0 foundation for Euler–Maclaurin).
#print axioms Analysis.bernTable_den_pos
#print axioms Analysis.bernoulli_den_pos
#print axioms Analysis.bernoulli_zero
#print axioms Analysis.bernoulli_one
#print axioms Analysis.bernoulli_two
#print axioms Analysis.bernoulli_three
#print axioms Analysis.bernoulli_four
#print axioms Analysis.bernoulli_five
#print axioms Analysis.bernoulli_six

-- LiOne (the Bombieri–Lagarias n=1 decomposition λ₁ = λ₁^arith + λ₁^∞; v0.15.3).
#print axioms Analysis.Rhalf_two
#print axioms Analysis.Rlambda1_decomposition
#print axioms Analysis.li_decomposition_realized

-- LambdaTwo (Pos λ₂; v0.16.0 stage-B capstone).
#print axioms Analysis.Rneg_Rneg
#print axioms Analysis.parab_gen
#print axioms Analysis.Rlambda2_pos

-- EulerMaclaurin (the deterministic EM correction-term data; v0.16.0 goal B foundation).
#print axioms Analysis.Cpoch_zero
#print axioms Analysis.Cpoch_succ
#print axioms Analysis.emCoeff_den_pos
#print axioms Analysis.emCoeff_one
#print axioms Analysis.emCoeff_two
#print axioms Analysis.emCoeff_three

-- RealDiv (the real inverse law x·(1/x)=1; the Inv.lean gap, prereq for Cinv / goals A,B).
#print axioms Analysis.Qmul_Qinv_sub_one
#print axioms Analysis.Rmul_Rinv_perpoint
#print axioms Analysis.Rmul_Rinv_self

-- ComplexInv (the complex reciprocal 1/z = z̄/|z|²; prereq for 1/(s−1) and the Γ place).
#print axioms Analysis.Cmul_Cinv
#print axioms Analysis.emCorrSum_zero
#print axioms Analysis.emCorrSum_succ
#print axioms Analysis.czFinSum_zero
#print axioms Analysis.czFinSum_succ

-- BernoulliPoly (Bernoulli polynomials Bₙ(x); prereq for the periodic-Bernoulli EM remainder).
#print axioms Analysis.bernPoly_den_pos
#print axioms Analysis.bernPoly_zero
#print axioms Analysis.bernPoly_one_at_zero
#print axioms Analysis.bernPoly_two_at_zero
#print axioms Analysis.bernPoly_one_at_one
#print axioms Analysis.bernPoly_two_at_one
#print axioms Analysis.bernPoly_two_form
#print axioms Analysis.bernPoly_two_abs_le

-- EtaFunction (η(s) = Σ(−1)^{n−1}n⁻ˢ; the integration-free critical-strip route, ζ = η/(1−2^{1−s})).
#print axioms Analysis.czEtaSum_zero
#print axioms Analysis.czEtaSum_succ
#print axioms Analysis.czEtaTerm_even
#print axioms Analysis.czEtaTerm_odd

-- CosSinAddFormula (the cos/sin angle-addition foundation: antidiagonal identity → diagonal relation).
#print axioms Analysis.pairTerm_den_pos
#print axioms Analysis.binTerm_scaled_eq
#print axioms Analysis.addPow_div_antidiag
#print axioms Analysis.qpow_sq_eq
#print axioms Analysis.qpow_negsq
#print axioms Analysis.negsq_pair
#print axioms Analysis.altPair_eq
#print axioms Analysis.cosPair_eq
#print axioms Analysis.sinTerm_den_pos
#print axioms Analysis.sinPair_eq
#print axioms Analysis.cosConv_den_pos
#print axioms Analysis.sinConv_den_pos
#print axioms Analysis.cosConv_eq
#print axioms Analysis.sinConv_eq
#print axioms Analysis.altTerm_add_eq
#print axioms Analysis.Fsum_mul_Fsum
#print axioms Analysis.fsum_cauchy
#print axioms Analysis.cosCauchy_eq
#print axioms Analysis.sinCauchy_eq
#print axioms Analysis.altCorner_factored2
#print axioms Analysis.altCorner_abs_le2
#print axioms Analysis.cornerMertens2
#print axioms Analysis.sinTerm_abs_le
#print axioms Analysis.sinConv_abs_le
#print axioms Analysis.cosAdd_resid_eq
#print axioms Analysis.cornerSin_factored
#print axioms Analysis.Qabs_mul_le_MM
#print axioms Analysis.cornerSin_le
#print axioms Analysis.cosAdd_decay_le
#print axioms Analysis.cosAdd_decay_5
#print axioms Analysis.cosMul_diag_le
#print axioms Analysis.xprod_drift
#print axioms Analysis.altProd_drift
#print axioms Analysis.sinMul_diag_le
#print axioms Analysis.altSum_add_eq
#print axioms Analysis.altDiag_to_deep
#print axioms Analysis.cosMulDeep_le
#print axioms Analysis.cosAddLHS_le
#print axioms Analysis.Fsum_sinTerm_eq
#print axioms Analysis.altMulDeep_le
#print axioms Analysis.sinMulDeep_le
#print axioms Analysis.Rcos_add
#print axioms Analysis.pairTermD_den_pos
#print axioms Analysis.binTermD_scaled_eq
#print axioms Analysis.addPow_div_diag
#print axioms Analysis.Fsum_parity_split_odd
#print axioms Analysis.altPairMixed_eq
#print axioms Analysis.scPair_eq
#print axioms Analysis.csPair_eq
#print axioms Analysis.csConv_eq
#print axioms Analysis.scConv_eq
#print axioms Analysis.sinTerm_add_eq
#print axioms Analysis.sinAdd_partial_eq
#print axioms Analysis.csCauchy_eq
#print axioms Analysis.scCauchy_eq
#print axioms Analysis.sinAdd_resid_eq
#print axioms Analysis.altCorner_factored2_mixed
#print axioms Analysis.altCorner_abs_le2_mixed
#print axioms Analysis.cornerMertens2_mixed
#print axioms Analysis.cornerCs_factored
#print axioms Analysis.cornerSc_factored
#print axioms Analysis.cornerCs_le
#print axioms Analysis.cornerSc_le
#print axioms Analysis.sinAdd_decay_le
#print axioms Analysis.sinAdd_decay_5
#print axioms Analysis.csConv_den_pos
#print axioms Analysis.scConv_den_pos
#print axioms Analysis.csMul_diag_le
#print axioms Analysis.scMul_diag_le
#print axioms Analysis.RsinSelf_diag_le
#print axioms Analysis.csMulDeep_le
#print axioms Analysis.scMulDeep_le
#print axioms Analysis.sinAddLHS_le
#print axioms Analysis.Rsin_add
#print axioms Analysis.Cexp_add
#print axioms Analysis.RaltReal_congr
#print axioms Analysis.Rcos_congr
#print axioms Analysis.Rsin_congr
#print axioms Analysis.Cexp_congr
#print axioms Analysis.cpowNeg_succ
#print axioms Analysis.Rsub_RnegRneg
#print axioms Analysis.Cadd_congr
#print axioms Analysis.Cneg_congr
#print axioms Analysis.Cmul_congr
#print axioms Analysis.Csub_congr
#print axioms Analysis.Cmul_neg_right
#print axioms Analysis.cpowNeg_diff
#print axioms Analysis.cpowNeg_re_le
#print axioms Analysis.cpowNeg_re_ge
#print axioms Analysis.cpowNeg_im_le
#print axioms Analysis.cpowNeg_im_ge
#print axioms Analysis.RexpReal_neg_le_one
#print axioms Analysis.expSum_ge_one_add_four
#print axioms Analysis.RexpReal_ge_one_add_four
#print axioms Analysis.RexpReal_one_sub_neg_le
#print axioms Analysis.altSum_quad
#print axioms Analysis.RaltReal_upper_le
#print axioms Analysis.RaltReal_lower_ge
#print axioms Analysis.Rcos_one_sub_le_sq
#print axioms Analysis.RsinAux_upper_le
#print axioms Analysis.RsinAux_lower_ge
#print axioms Analysis.Rexp_RlogNat
#print axioms Analysis.Rnonneg_RlogNat
#print axioms Analysis.RlogNat_eq_logN
#print axioms Analysis.Rnonneg_deltaLogNat
#print axioms Analysis.deltaLogNat_le_recip
#print axioms Analysis.Rsub_neg_eq_add
#print axioms Analysis.Rmul_le_mul_of_abs
#print axioms Analysis.Rneg_mul_le_of_abs
#print axioms Analysis.oneSubCexp_re_upper
#print axioms Analysis.oneSubCexp_re_lower
#print axioms Analysis.oneSubCexp_im_upper
#print axioms Analysis.oneSubCexp_im_lower
#print axioms Analysis.Rmul_sub_two_sided
#print axioms Analysis.Rmul_add_two_sided
#print axioms Analysis.cpowNeg_diff_re_bound
#print axioms Analysis.cpowNeg_diff_im_bound
#print axioms Analysis.czEtaSum_two_eq_paired
#print axioms Analysis.czEtaPaired_re_diff_le
#print axioms Analysis.czEtaPaired_re_diff_ge
#print axioms Analysis.czEtaPaired_im_diff_le
#print axioms Analysis.czEtaPaired_im_diff_ge
#print axioms Analysis.cpowNeg_diff_re_tail
#print axioms Analysis.cpowNeg_diff_im_tail
#print axioms Analysis.Vterm_le_A_delta
#print axioms Analysis.etaU_le_ratio
#print axioms Analysis.A_eq_czetaExp
#print axioms Analysis.A_dyadic_le
#print axioms Analysis.Vterm_dyadic_le
#print axioms Analysis.deltaLogNat_sum_telescope
#print axioms Analysis.RsumRange_mono
#print axioms Analysis.RsumRange_smul
#print axioms Analysis.Vconst_den_pos
#print axioms Analysis.Vconst_num_nonneg
#print axioms Analysis.Vterm_block_le
#print axioms Analysis.logBlock_eq
#print axioms Analysis.Vterm_geo_block_le
#print axioms Analysis.etaB_le_geo
#print axioms Analysis.RsumRange_congr
#print axioms Analysis.EtaVSum_diff_eq_RsumRange
#print axioms Analysis.EtaVSum_block_geo_le
#print axioms Analysis.EtaVSum_tail
#print axioms Analysis.EtaVSum_tail_reindex
#print axioms Analysis.Rnonneg_Vterm
#print axioms Analysis.Rnonneg_etaVtermTerm
#print axioms Analysis.EtaVSum_mono
#print axioms Analysis.EtaVSum_tail_full
#print axioms Analysis.RsumRange_odd_le
#print axioms Analysis.etaPaired_sum_le_tail
#print axioms Analysis.czEtaPaired_re_tail
#print axioms Analysis.czEtaPaired_im_tail
#print axioms Analysis.eta_smallness_n
#print axioms Analysis.etaMidx_ge_N0
#print axioms Analysis.etaMidx_mono
#print axioms Analysis.etaMidx_two_pow
#print axioms Analysis.eta_Vconst_bound
#print axioms Analysis.etaLevel_ge_N0
#print axioms Analysis.etaMidx_ge_one
#print axioms Analysis.etaRe_tail_reindexed
#print axioms Analysis.etaIm_tail_reindexed
#print axioms Analysis.etaRe_RReg
#print axioms Analysis.etaIm_RReg
#print axioms Analysis.Ceta
#print axioms Analysis.cpowNeg_normSq
#print axioms Analysis.CnormSq_Cmul_ofReal
#print axioms Analysis.Pos_RlogNat_two
#print axioms Analysis.etaTwoPow_re
#print axioms Analysis.etaDenom_Pos_normSq
#print axioms Analysis.CzetaStrip
#print axioms Analysis.CzetaStrip_functional
#print axioms Analysis.RrpowPos
#print axioms Analysis.Pos_RrpowPos_of_nonneg
#print axioms Analysis.RrpowPos_add
#print axioms Analysis.Rnonneg_Rinv
#print axioms Analysis.Rinv_le_ofQ_Qinv
#print axioms Analysis.ofQ_le_digammaArg
#print axioms Analysis.digammaArg_witness
#print axioms Analysis.digamma_const_shift
#print axioms Analysis.digammaArg_sub_succ_eq
#print axioms Analysis.digamma_succ_mul_pos
#print axioms Analysis.digamma_Rinv_le
#print axioms Analysis.digammaPfac_bound
#print axioms Analysis.digammaTerm_abs_le
#print axioms Analysis.digamma_Rsub_Radd_left
#print axioms Analysis.digammaSum_diff_eq
#print axioms Analysis.digammaTailQ_den_pos
#print axioms Analysis.digammaTail_two_sided
#print axioms Analysis.digammaMidx_ge_one
#print axioms Analysis.digammaMidx_mono
#print axioms Analysis.digammaTailQ_Midx_le
#print axioms Analysis.digammaCore_RReg
#print axioms Analysis.Rinv_ofQ_sub_eq
#print axioms Analysis.Rnonneg_of_ofQ_le
#print axioms Analysis.Rsub_eq_mul_of_inv
#print axioms Analysis.Qsub_nat_den_pos
#print axioms Analysis.spougeSign_den_pos
#print axioms Analysis.ofQ_le_spougeBase
#print axioms Analysis.spougeBase_witness
#print axioms Analysis.etaEps_le
#print axioms Analysis.etaEps_den_pos
#print axioms Analysis.etaEps_num_pos
#print axioms Analysis.etaTau_den_pos
#print axioms Analysis.etaTau_num_pos
#print axioms Analysis.etaTau_add_num_pos
#print axioms Analysis.etaU_le_ratio_data
#print axioms Analysis.etaB_le_geo_data
#print axioms Analysis.EtaVSum_block_geo_data
#print axioms Analysis.CetaW
#print axioms Analysis.CetaW_half_wellTyped
#print axioms Analysis.CetaW_re_tendsTo
#print axioms Analysis.CetaW_im_tendsTo
#print axioms Analysis.RTendsTo_of_Req
#print axioms Analysis.CetaW_czEtaSum_re_tendsTo
#print axioms Analysis.CetaW_czEtaSum_im_tendsTo
#print axioms Analysis.etaRe_paired_tail_anchor
#print axioms Analysis.etaIm_paired_tail_anchor
#print axioms Analysis.CetaW_re_full_tendsTo
#print axioms Analysis.CetaW_im_full_tendsTo
#print axioms Analysis.CetaW_re_canonical
#print axioms Analysis.CetaW_im_canonical
#print axioms Analysis.digammaTerm_eq_factored
#print axioms Analysis.digammaTerm_one_eq_zero
#print axioms Analysis.digammaSum_one_eq_zero
#print axioms Analysis.RTendsTo_zero_of_Req_zero
#print axioms Analysis.digammaCore_one_eq_zero
#print axioms Analysis.Digamma_one_eq_neg_gamma
#print axioms Analysis.Rnonneg_RofNat
#print axioms Analysis.spougeGammaWitness
#print axioms Analysis.Pos_RrpowPos_of_nonneg_log
#print axioms Analysis.CzetaStripW
#print axioms Analysis.CzetaStripW_functional
#print axioms Analysis.etaDenom_cancel
#print axioms Analysis.CzetaStrip_half_nonvacuous
#print axioms Analysis.qpow_neg_den
#print axioms Analysis.qpow_neg_num_odd
#print axioms Analysis.qpow_neg_odd
#print axioms Analysis.Qneg_add
#print axioms Analysis.artTerm_neg
#print axioms Analysis.artSum_neg
#print axioms Analysis.artSum_le_two_arg
#print axioms Analysis.one_sub_sq_ge_half
#print axioms Analysis.artSum_ge_neg_two_arg
#print axioms Analysis.Rartanh_R_ge_two
#print axioms Analysis.Rnonneg_Rartanh_of_nonneg
#print axioms Analysis.tmap_ge_sub
#print axioms Analysis.Rnonneg_Rlog_seq_of_one_le
#print axioms Analysis.Rnonneg_Rlog_of_one_le
#print axioms Analysis.Rnonneg_RlogPos
#print axioms Analysis.Pos_RrpowPos_of_base_ge_one

-- v0.20.0 stage F, brick A1 (Square/Cohomology.lean): the canonical H¹-object.
#print axioms Square.H1_orbit
#print axioms Square.H1_universal
#print axioms Square.H1_isFree
#print axioms Square.freeFrob_unique_upto_iso
#print axioms Square.orbitShift_succ
#print axioms Square.orbit_realizes_pencil

-- v0.20.0 stage F, bricks A2 + A3 (Square/WeilLattice.lean): trace datum + forced dictionary.
#print axioms Square.zmulR_zero
#print axioms Square.zmulR_one
#print axioms Square.zmulR_negTwo
#print axioms Square.zmulR_congr_coeff
#print axioms Square.RofInt_zero
#print axioms Square.hPair_symm
#print axioms Square.vanCyc_perp_Fh
#print axioms Square.vanCyc_perp_Fv
#print axioms Square.vanCyc_selfpair_gen
#print axioms Square.vanCyc_blind
#print axioms Square.vanCyc_selfpair
#print axioms Square.vanCyc_selfpair_built
#print axioms Square.intrinsicH1_dict
#print axioms Square.genuineSpectralSquare_lam
#print axioms Square.genuineSpectralSquare_dict

-- v0.20.0 stage F, Group B (Square/Forced.lean): the forced signature, the gate reads it.
#print axioms Square.genuine_vanCyc_normal
#print axioms Square.genuine_crux_equivalent
#print axioms Square.genuine_hodgeNeg_iff
#print axioms Square.genuine_evidence_head
#print axioms Square.genuine_crux_frontier
#print axioms Square.genuine_signature_satisfiable
#print axioms Square.genuine_iff_all_upTo
#print axioms Square.genuine_crux_frontier_located

-- v0.20.0 stage F, frontier brick (Analysis/Voros.lean): the Voros growth dichotomy, exclusivity.
#print axioms Analysis.cube_le_pow2
#print axioms Analysis.quad_lt_pow2
#print axioms Analysis.tempered_not_exp
#print axioms Analysis.exp_not_tempered
#print axioms Analysis.voros_at_most_one
#print axioms Analysis.voros_exactly_one

-- v0.20.0 stage F, frontier (Analysis/GammaTwo.lean): the second Stieltjes constant γ₂ — brick 1 (substrate).
#print axioms Analysis.lnSqOver_nonneg
#print axioms Analysis.lnSqSum_step
#print axioms Analysis.lnSqSum_mono
#print axioms Analysis.logCube_nonneg
#print axioms Analysis.Rsub_sub_sub
#print axioms Analysis.g2Seq_step_eq
#print axioms Analysis.cube_diff_identity
#print axioms Analysis.tri_sum_3a2
#print axioms Analysis.Rmul_third_three
#print axioms Analysis.e2_core
#print axioms Analysis.e2_ub_identity
#print axioms Analysis.e2Step_le_quad
#print axioms Analysis.e2_lb_identity
#print axioms Analysis.e2Step_ge_quad
#print axioms Analysis.e2Step_le_num
#print axioms Analysis.e2Step_ge_num

-- v0.20.0 stage F: the Real additive-group normalizer (Analysis/RAddNF.lean) — the UOR κ-form solution.
#print axioms Analysis.RsumL_nil
#print axioms Analysis.RsumL_cons
#print axioms Analysis.RsumL_cons_congr
#print axioms Analysis.RsumL_swap_head
#print axioms Analysis.RsumL_perm
#print axioms Analysis.RsumL_cancel_head
#print axioms Analysis.RsumL_cancel_cons
#print axioms Analysis.RsumL_cancel_anywhere
#print axioms Analysis.RsumL_append
#print axioms Analysis.RsumL_singleton
#print axioms Analysis.Radd_eq_RsumL
#print axioms Analysis.Radd_eq_RsumL3
#print axioms Analysis.RsumL_perm_map
#print axioms Analysis.RsumL_map_Rneg

-- v0.20.0 stage F: γ₂ dyadic-tail regularity → Rgamma2 (Analysis/GammaTwo.lean).
#print axioms Analysis.logSq_le_block
#print axioms Analysis.Qblock_upper
#print axioms Analysis.g2Seq_step_le_block
#print axioms Analysis.g2Seq_step_ge_block
#print axioms Analysis.Csum_step_eq
#print axioms Analysis.Csum_tail_le
#print axioms Analysis.g2Seq_diff_le_block
#print axioms Analysis.g2Seq_diff_ge_block
#print axioms Analysis.g2Seq_block_le
#print axioms Analysis.g2Seq_block_ge
#print axioms Analysis.WUsum_tail_le
#print axioms Analysis.WLsum_tail_le
#print axioms Analysis.g2Seq_diff_le_outer
#print axioms Analysis.g2Seq_diff_ge_outer
#print axioms Analysis.g2_lin2
#print axioms Analysis.g2_quad_lin
#print axioms Analysis.g2_domination
#print axioms Analysis.g2_domination_U
#print axioms Analysis.g2_T_le
#print axioms Analysis.g2_TU_le
#print axioms Analysis.g2_pair_le
#print axioms Analysis.g2_pair_ge
#print axioms Analysis.g2SeqDyadic_RReg
#print axioms Analysis.Rgamma2
#print axioms Analysis.Csum_den_pos
#print axioms Analysis.WUsum_den_pos
#print axioms Analysis.WLsum_den_pos

-- v0.20.0 stage F: Lever 1 — the Li/zero growth geometry (Analysis/ZeroGeometry.lean).
#print axioms Analysis.liRatio_diff_eq
#print axioms Analysis.liRatio_on_line
#print axioms Analysis.liRatio_left_of_line
#print axioms Analysis.liRatio_right_of_line
#print axioms Analysis.Req_of_Rsub_zero
#print axioms Analysis.half_add_half
#print axioms Analysis.allOnLine_ratios_one
#print axioms Analysis.dvp_band_admits_off_line

-- v0.20.0 stage F: λ₃ closed form on the constructive γ₂ (Analysis/LambdaThree.lean).
#print axioms Analysis.Reta2
#print axioms Analysis.nsmulR_congr
#print axioms Analysis.Rlambda3_arith
#print axioms Analysis.Rlambda3
#print axioms Analysis.genuineArith_three
#print axioms Analysis.genuineLam_three
#print axioms Analysis.etaThreeSlice

-- v0.22.0 crux frontier: λ₄ closed form on the constructive γ₃ (Analysis/LambdaFour.lean).
#print axioms Analysis.Reta3
#print axioms Analysis.Rlambda4_arith
#print axioms Analysis.Rlambda4
#print axioms Analysis.genuineArith_four
#print axioms Analysis.genuineLam_four
#print axioms Analysis.etaFourSlice

-- v0.20.0 stage F: the Real multiplicative normalizer (Analysis/RMulNF.lean) — κ-form companion of RAddNF.
#print axioms Analysis.RprodL_nil
#print axioms Analysis.RprodL_cons
#print axioms Analysis.RprodL_cons_congr
#print axioms Analysis.RprodL_swap_head
#print axioms Analysis.RprodL_perm
#print axioms Analysis.RprodL_append
#print axioms Analysis.RprodL_singleton
#print axioms Analysis.Rmul_eq_RprodL
#print axioms Analysis.Rmul_eq_RprodL3
#print axioms Analysis.RprodL_perm_map
#print axioms Analysis.Rmul_pair_eq_RprodL4
#print axioms Analysis.prod_sq_reassoc
#print axioms Analysis.prod_cross_reassoc

-- v0.20.0 stage F: the Li-term modulus growth law (Analysis/LiGrowth.lean) — ring engine end-to-end.
#print axioms Analysis.Radd_pair_eq_RsumL4
#print axioms Analysis.add4_perm1
#print axioms Analysis.add4_perm2
#print axioms Analysis.cancelC
#print axioms Analysis.regroupX
#print axioms Analysis.cnormSq_mul
#print axioms Analysis.cnormSq_one
#print axioms Analysis.cnormSq_npow
#print axioms Analysis.Rnpow_nonneg
#print axioms Analysis.Rnpow_le_Rnpow
#print axioms Analysis.cnormSq_nonneg
#print axioms Analysis.liTerm_dominates

-- the RH witness (Analysis/RHWitness.lean) — the conditional sum-of-nonnegatives form of λₙ.
#print axioms Analysis.Rnpow_congr
#print axioms Analysis.Rnpow_one
#print axioms Analysis.cnormSq_Cnpow_unit
#print axioms Analysis.cnormSq_Cnpow_le_one
#print axioms Analysis.witnessTerm_nonneg
#print axioms Analysis.witnessSum_nonneg
#print axioms Analysis.onLine_is_unit_modulus
#print axioms Analysis.rh_witness
#print axioms Analysis.rh_witness_onLine

-- the constructive Cayley transform (Analysis/CayleyMap.lean) — discharges the witness's
-- on-line unit-modulus antecedent from the geometry (|1−1/ρ|² = 1 when Re ρ = ½).
#print axioms Analysis.cnormSq_congr
#print axioms Analysis.cnormSq_recip
#print axioms Analysis.cnormSq_sub_one
#print axioms Analysis.cnormSq_liRatio_on_line

-- the per-zero Li linearization (Analysis/LiLinearize.lean) — the geometric factorization
-- 1−wⁿ = (1−w)·Σwᵏ exhibiting the moment 1/ρ; the explicit-formula framework's algebraic core.
#print axioms Analysis.cadd_congr
#print axioms Analysis.cneg_congr
#print axioms Analysis.cmul_congr
#print axioms Analysis.cadd_zero
#print axioms Analysis.czero_cadd
#print axioms Analysis.cmul_czero
#print axioms Analysis.cmul_cneg
#print axioms Analysis.cone_sub_npow_factor
#print axioms Analysis.witnessTerm_eq_linear
#print axioms Analysis.witnessSum_eq_linear

-- the functional-equation reflection at the Li growth-ratio level (Analysis/Reflection.lean).
#print axioms Analysis.cnormSq_Creflect
#print axioms Analysis.csubOneNormSq_Creflect
#print axioms Analysis.mirror_both_in_disk_iff
#print axioms Analysis.onLine_mirror_in_disk
#print axioms Analysis.cnormSq_Cconj
#print axioms Analysis.csubOneNormSq_Cconj
#print axioms Analysis.inClosedDisk_Cconj
#print axioms Analysis.symmetry_orbit_in_disk_iff
#print axioms Analysis.offLine_left_not_inClosedDisk
#print axioms Analysis.inClosedDisk_iff_geom
#print axioms Analysis.double_inj
#print axioms Analysis.onLine_of_ratios_eq
#print axioms Analysis.onLine_iff_ratios_eq
#print axioms Analysis.allInClosedDisk_iff_allOnLine
#print axioms Analysis.Pos_Rnpow
#print axioms Analysis.Pos_of_Pos_Rsub_one
#print axioms Analysis.offLine_term_grows
#print axioms Analysis.witnessTerm_tempered
#print axioms Analysis.voros_term_dichotomy

-- the Bombieri–Lagarias pipeline (Square/BLPipeline.lean) — witness wired to genuine λ, RH-forward.
#print axioms Analysis.Rnonneg_Rlim
#print axioms Square.bl_rh_implies_liNonneg
#print axioms Square.bl_rh_implies_liNonneg_ofZeros
#print axioms Square.liNonneg_implies_onLine
#print axioms Square.li_criterion
#print axioms Square.li_criterion_disk
#print axioms Square.atlas_coupling_analytic_face
#print axioms Square.hodgeIndex_iff_RH
#print axioms Square.hodgeIndex_iff_closedDisk
#print axioms Analysis.riemannHypothesisStrip_iff
#print axioms Square.hodgeIndex_iff_riemannHypothesis

-- the Riemann–Siegel center-slope obstruction (Analysis/RiemannSiegel.lean) — θ′(0) < 0, the
-- non-monotonicity Connes–Consani name as the barrier to semi-local Weil positivity. Obstruction,
-- not a route through it; crux none.
#print axioms Analysis.Rnonneg_RpiTmap
#print axioms Analysis.Rnonneg_Rlogπc
#print axioms Analysis.rsCenterSlope_neg

-- the archimedean kernel Re ψ(1/4+iτ/2) ASSEMBLED at the frontier point τ=10, and the two-sided
-- non-monotonicity of the Riemann–Siegel angle (Analysis/PsiLine.lean). The obstruction completed;
-- crux none.
#print axioms Analysis.corrCore
#print axioms Analysis.corrCore_ge_twelve
#print axioms Analysis.corrP_twelve_lower
#print axioms Analysis.corrCore_lower
#print axioms Analysis.psiLineRe5
#print axioms Analysis.corrT_eq_windowTerm_gain
#print axioms Analysis.psiLineRe5_lower
#print axioms Analysis.rsLineSlope10_pos
#print axioms Analysis.rsAngle_non_monotone
-- the parameterized kernel Re ψ(1/4+iτ/2) over s ∈ [0,25] and the monotone climb (θ convex).
#print axioms Analysis.corrCoreP
#print axioms Analysis.corrCoreP_mono
#print axioms Analysis.psiLineReP
#print axioms Analysis.psiLineReP_mono
#print axioms Analysis.corrCoreP_ge_partial
#print axioms Analysis.psiLineReP_16_lower
#print axioms Analysis.rsLineSlope16_pos
#print axioms Analysis.rsAngle_increasing_on_band
#print axioms Analysis.corrCoreP_zero
#print axioms Analysis.psiLineReP_zero
-- the s=1 kernel upper bound and the kernel-sign indefiniteness h₊(2) < 0 (toward α(2) < 0).
#print axioms Analysis.corrCoreP_one_upper
#print axioms Analysis.psiLineReP_one_upper
#print axioms Analysis.archKernel_at_two_below_logpi

-- v0.21.0 frontier: α(2) < 0 — Burnol's archimedean multiplier is INDEFINITE (Analysis/BurnolAlphaTwo.lean).
-- √2 ≤ 3/2 via the exp∘log inverse (sqrt2² = 2), then |cos|≤1 + h₊(2)<0 give the pointwise sign.
#print axioms Analysis.two_seq_pos
#print axioms Analysis.sqrt2_mul_self
#print axioms Analysis.sqrt2_le_three_halves
#print axioms Analysis.sqrt2_nonneg
#print axioms Analysis.burnolAlphaTwo_neg
-- v0.22.0 Track 2: the indefiniteness capstone — α takes both signs, so pointwise single-place
-- positivity is refuted (the Sonine projection, not pointwise α ≥ 0, is the resolution).
#print axioms Analysis.burnol_multiplier_indefinite
#print axioms Analysis.burnolAlpha_not_pointwise_nonneg
#print axioms Analysis.burnolAlpha_not_pointwise_nonpos

-- v0.20.0 stage F: γ₂≥−0.02 bracket evaluators (Analysis/GammaTwoBracket.lean) — parts (A),(B).
#print axioms Analysis.lnSqSumLo_den_pos
#print axioms Analysis.lnSqSumLo_le
#print axioms Analysis.logBound_ofQ_nonneg
#print axioms Analysis.logNsq_le
#print axioms Analysis.logCube_le
#print axioms Analysis.halfSqOver_le
#print axioms Analysis.half_add_self
#print axioms Analysis.resid_regroup
#print axioms Analysis.hSeq_step_eq
#print axioms Analysis.sStep_stage1
#print axioms Analysis.two_mul_eq
#print axioms Analysis.sq_binom2
#print axioms Analysis.three_mul_eq
#print axioms Analysis.two_plus_one
#print axioms Analysis.inner_merge

-- v0.20.0 stage F: γ₂≥−0.02 bracket (C2) — the s_p decomposition keystone (GammaTwoBracket.lean).
#print axioms Analysis.half_two_cancel
#print axioms Analysis.third_three_cancel
#print axioms Analysis.mul3_pull
#print axioms Analysis.decompForm_eq_RsumL
#print axioms Analysis.sub_add_cancel_real
#print axioms Analysis.partA_eq
#print axioms Analysis.partC_distrib
#print axioms Analysis.partC1
#print axioms Analysis.partC2
#print axioms Analysis.partC3
#print axioms Analysis.partC_eq
#print axioms Analysis.lhsForm_eq_RsumL
#print axioms Analysis.decomp_generic
#print axioms Analysis.sStep_decomp
#print axioms Analysis.dPlusQ_zero_eq_mid
#print axioms Analysis.C2_nonneg
#print axioms Analysis.logN_le_self
#print axioms Analysis.deltaLog_le_mid
#print axioms Analysis.dMinusU1_le
#print axioms Analysis.Rneg_Rsub_swap
#print axioms Analysis.bd_le_one
#print axioms Analysis.bR1_lower
#print axioms Analysis.dsq_self_le
#print axioms Analysis.dcube_self_le
#print axioms Analysis.R0_lower_clean
#print axioms Analysis.sStep_lower_clean
#print axioms Analysis.cube_dom_nat
#print axioms Analysis.hBA_qle
#print axioms Analysis.hAB_qle
#print axioms Analysis.sStep_lower_tele
#print axioms Analysis.hSeq_tele
#print axioms Analysis.Rsub_sub_self
#print axioms Analysis.hSeq_lower_const
#print axioms Analysis.hSeq_le_g2Seq
#print axioms Analysis.Rgamma2_ge_hSeq

-- v0.20.0 stage F: γ₂≥−0.02 bracket — (C4) telescoping tail + (C5) limit + the certified bracket.
#print axioms Analysis.cube_dom_nat
#print axioms Analysis.hBA_qle
#print axioms Analysis.hAB_qle
#print axioms Analysis.sStep_lower_tele
#print axioms Analysis.hSeq_tele
#print axioms Analysis.Rsub_sub_self
#print axioms Analysis.hSeq_lower_const
#print axioms Analysis.hSeq_le_g2Seq
#print axioms Analysis.Rgamma2_ge_hSeq
#print axioms Analysis.Rsub_ofQ_ofQ
#print axioms Analysis.gBound2_den_pos
#print axioms Analysis.hSeq_ge_gBound2
#print axioms Analysis.gamma2_decide
#print axioms Analysis.Rgamma2_ge_neg002

-- v0.22.0 crux frontier: γ₃ UPPER bracket evaluators (Analysis/GammaThreeBracket.lean) — part (A),(B).
#print axioms Analysis.lnCubeSumUp_den_pos
#print axioms Analysis.lnCubeSum_le
#print axioms Analysis.logLowBound_ofQ_nonneg
#print axioms Analysis.logCube_ge
#print axioms Analysis.logQuartic_ge
#print axioms Analysis.lnCubeOver_ge
#print axioms Analysis.hSeq3_step_eq
#print axioms Analysis.half_three
#print axioms Analysis.quarter_six
#print axioms Analysis.quarter_four
#print axioms Analysis.three_merge
#print axioms Analysis.four_merge
#print axioms Analysis.six_merge
#print axioms Analysis.one_plus_three
#print axioms Analysis.three_plus_one
#print axioms Analysis.three_plus_three
#print axioms Analysis.Rmul_eq_RprodL4L
#print axioms Analysis.Rmul_eq_RprodL5L
#print axioms Analysis.cube_times_pair
#print axioms Analysis.pair_times_triple
#print axioms Analysis.single_times_sqpair
#print axioms Analysis.cube_binom
#print axioms Analysis.partA3_eq
#print axioms Analysis.decompForm3_eq_RsumL

-- v0.21.0 stage G, brick S (the substrate): the finite-truncation PSD predicate `WeilPSD`,
-- its additive/rank-one structure, the embedding Gram (Gate B free), and the embedding bridge.
#print axioms Square.Rmul_RsumN_left
#print axioms Square.RsumN_mul_RsumN
#print axioms Square.Radd_rearrange4
#print axioms Square.RsumN_add
#print axioms Square.RsumN_zero
#print axioms Square.indic_eq_one
#print axioms Square.indic_eq_zero
#print axioms Square.RsumN_indic_mul
#print axioms Square.WeilPSD_congr
#print axioms Square.WeilPSD_zero
#print axioms Square.weilQuad_add
#print axioms Square.WeilPSD_add
#print axioms Square.rankOne_term_reassoc
#print axioms Square.WeilPSD_rankOne
#print axioms Square.WeilPSD_gramOf
#print axioms Square.WeilPSD_diag
#print axioms Square.embeds_to_hodgeNeg
#print axioms Square.embeds_to_liNonneg
#print axioms Square.realizesDiag_genuine_iff

-- v0.21.0 stage G, brick G0b (the full primitive form): the symmetric form on the Frobenius
-- carrier, the genuine-diagonal forcing, the negative-PSD → Hodge bridge, and the inhabitants.
#print axioms Square.orbit_distinct
#print axioms Square.FullForm.diag_genuine
#print axioms Square.FullForm.negPSD_to_hodgeNeg
#print axioms Square.shiftOffDiag_symm

-- v0.21.0 stage G, brick G0a (the atlas rule + the §6 relocation): the zero-free rule type,
-- Gate B free, the growth pre-filter, and the Cayley relocation made formal at the match level.
#print axioms Square.atlasRule_gateB
#print axioms Square.atlasRule_growth_filter
#print axioms Square.Rdouble_inj
#print axioms Square.cayleyRatio_match_iff_onLine
#print axioms Square.cayley_relocation

-- v0.21.0 stage G, brick G0 (the numerical kill-test, throwaway pre-filter): the decidable
-- finite Gram-diagonal match test, with the growth-kill, the match-admission, and the §6 caveat.
#print axioms Square.killTest_admits_match
#print axioms Square.killTest_kills_wrong_growth
#print axioms Square.killTest_match_not_sufficient

-- v0.21.0 stage G, brick G1 (Gate A, the faithful match): the λ-free atlas pairing, Gate B free,
-- the match-is-RH identity, and the two-sided no-smuggling guards (satisfiable + can-fail).
#print axioms Square.atlasPair_psd
#print axioms Square.gateA_is_liNonneg
#print axioms Square.gateA_satisfiable
#print axioms Square.gateA_can_fail

-- v0.21.0 stage G, brick G2a (the E₈ seed): the ofQ-embedding-Gram reduction, and the E₈ anchor
-- (PSD free, equal to 4× the standard E₈ Cartan matrix, strictly positive diagonal).
#print axioms Square.dotQ_den_pos
#print axioms Square.gramOf_ofQ
#print axioms Square.e8_weilPSD
#print axioms Square.e8_dot_check
#print axioms Square.e8_is_cartan
#print axioms Square.e8_target_diag_pos
#print axioms Square.e8_diag_pos

-- v0.21.0 stage G, bricks G2b.0/G2b.1 (the tower carries a form; infinite definiteness): the
-- negative-diagonal obstruction, the gauge tower (E₈ inhabitant), and the hypothesized Σ indefinite.
#print axioms Square.not_WeilPSD_of_neg_diag
#print axioms Square.limit_indefinite_of_neg_signature
#print axioms Square.sigmaMetric_not_psd

-- v0.21.0 stage G, brick G3 (assembly and adjudication): the missing-object embedding route,
-- located — the §9 Localized terminal state, crux fields stay none.
#print axioms Square.stageG_frontier_located
#print axioms Square.strictRealizes_closes_crux
#print axioms Square.strictRealizes_is_liCrux

-- v0.22.0 Track 2 — the Sonine projection (Square/SonineProjection.lean): the Weil multiplier form,
-- its diagonal collapse, positivity recovered UNCONDITIONALLY on the band complement, and the Burnol
-- instance (bare pairing indefinite; positive on the Sonine complement). The crux = the band coupling.
#print axioms Square.multForm_diag
#print axioms Square.RsumN_sift
#print axioms Square.weilQuad_multForm
#print axioms Square.multForm_psd_iff
#print axioms Square.multForm_psd_on_complement
#print axioms Square.burnol_pairing_indefinite
#print axioms Square.burnol_pairing_psd_on_sonine
#print axioms Square.burnol_sonine_dichotomy
-- Burnol's correction mechanism (the sharpest UNCONDITIONAL Weil-positivity theorem, discretized):
-- a correction making the multiplier pointwise ≥ 0 and vanishing on the window ⟹ window positivity.
#print axioms Square.multForm_psd_via_correction
#print axioms Square.burnol_corrected_nonneg
#print axioms Square.burnol_pairing_psd_via_correction

-- v0.21.0 stage G — the UOR Atlas spectral operator (sourced Σ = {10,2,7,−1}, Atlas §5/§6.6):
-- verified spectrum/trace, the indefiniteness (the sourced make-or-break), and the definite norm.
#print axioms Square.blockEig_spectrum
#print axioms Square.atlasTrace_eq
#print axioms Square.atlasMult
#print axioms Square.atlasM_signature
#print axioms Square.atlasM_not_hodge_signature
#print axioms Square.atlasDim_eq
#print axioms Square.atlasM_neg_entry
#print axioms Square.atlasM_indefinite
#print axioms Square.atlasNorm_psd

-- v0.21.0 stage G — gate sanity: the crux gate discriminates (accepts/rejects/closes-on-witness).
#print axioms Square.crux_gate_faithful

-- v0.21.0 stage G — Atlas characteristics (§1/§5/§10/§11) and the connection to the crux's
-- negative direction. Understanding the Atlas and its links to established mathematics.
#print axioms Square.tower_levels
#print axioms Square.O_eq_two_pow_T
#print axioms Square.self_intersection_tower
#print axioms Square.atlas_balance
#print axioms Square.g2_dim_match
#print axioms Square.twentyFour_eq
#print axioms Square.e8_theta_E4
#print axioms Square.atlas_negative_direction

-- v0.21.0 stage G — Atlas addressing (§2/§5/§8/§10/§12): the scale-invariant tower (inverse
-- system), parametric generation, and the prime skeleton = explicit-formula prime side.
#print axioms Square.atlasModulus_values
#print axioms Square.atlasModulus_zero_factored
#print axioms Square.atlasModulus_dvd_succ
#print axioms Square.atlasBoundary_zero
#print axioms Square.atlas_parametric_generation
#print axioms Square.primality_of_bounded
#print axioms Square.atlasPrime_five_vonMangoldt
#print axioms Square.atlas_prime_skeleton

-- v0.21.0 stage G — Atlas classes & calculus (§2/§3): the class structure (index, count, stride,
-- belt extent) and the transforms as finite-order class permutations.
#print axioms Square.class_count_stride
#print axioms Square.classIndex_range
#print axioms Square.belt_extent
#print axioms Square.sigma_order_four
#print axioms Square.tau_order_eight
#print axioms Square.mu_order_two

-- v0.21.0 stage G — Atlas conservation (§4/§5): no-loss, round-trip identity, scale-invariance.
#print axioms Square.class_no_loss
#print axioms Square.atlas_roundtrip
#print axioms Square.atlas_scale_consistent

-- v0.21.0 stage G — Atlas forcing: what makes a value NOT a coincidence (parametric identity or
-- over-determination), incl. the discovery that trace = dimension is forced by T = 3.
#print axioms Square.multSum_eq_dim
#print axioms Square.traceParam_formula
#print axioms Square.trace_eq_dim_at_T3
#print axioms Square.twentyFour_overdetermined
#print axioms Square.fourteen_overdetermined
#print axioms Square.twoForty_overdetermined
#print axioms Square.eight_overdetermined

-- v0.21.0 stage G — Atlas → RH connection: addressing↔orbit↔explicit-formula weight, and the
-- three live points where the Atlas feeds the RH program.
#print axioms Square.orbitShift_one
#print axioms Square.atlas_shift_eq_weight
#print axioms Square.atlas_feeds_rh

-- v0.21.0 stage G — Lefschetz coupling: the primitive-part refinement (H²>0, vanCyc primitive) and
-- the crux as the prime–archimedean coupling sign (the ff_hodge_iff_hasse shape over ℤ).
#print axioms Square.vanCyc_perp_H
#print axioms Square.eH_sq
#print axioms Square.eH_sq_pos
#print axioms Square.genuine_crux_arch_coupling
#print axioms Square.crux_is_arithmetic_hodge

-- v0.21.0 stage G — the archimedean place: the arch(n) facet of the coupling, conquered at the
-- head and in the prime-free window (α(0)>0), open outside (the tail bound).
#print axioms Square.coupling_head_positive
#print axioms Square.coupling_window_archimedean
#print axioms Square.archimedean_center_positive
#print axioms Square.archimedean_place_status

-- v0.21.0 stage G — Atlas modular: θ_{E₈^T} = E₄³ = E₆² + 1728Δ (the 24 = dim E₈^T thread to the
-- modular discriminant Δ = η²⁴), proved by power-series convolution over ℤ.
#print axioms Square.eisenstein_coeffs_computed
#print axioms Square.e4sq_is_conv
#print axioms Square.e4cube_eq_e6sq_plus_1728delta
#print axioms Square.delta_coeffs
#print axioms Square.twentyFour_modular

-- v0.21.0 stage G — Atlas exceptional: the magic-square exceptional series (R,C,H,O → F₄,E₆,E₇,E₈),
-- the rank·(h+1) dimension law, and the connections (dim G₂ = (T−1)(O−1), 240 = E₈ roots).
#print axioms Square.exceptional_dims
#print axioms Square.magic_square_octonion_row
#print axioms Square.g2_coxeter_atlas
#print axioms Square.e8_top
#print axioms Square.twoForty_roots

-- v0.21.0 stage G — Atlas Coxeter: E₈ exponents = totatives of the Coxeter number 30; rank = φ(30)
-- = 8 = O; the 30/8/120/240/248 forced web.
#print axioms Square.e8_exponents
#print axioms Square.e8_exponent_count
#print axioms Square.e8_exponent_sum
#print axioms Square.e8_coxeter_web

-- v0.21.0 stage G — Atlas synthesis: the forced web (no coincidences) + the honest open boundary.
#print axioms Square.atlas_forced_web
#print axioms Square.atlas_web_and_open_crux

-- v0.21.0 stage G — Atlas–crux localization: the Atlas insights connected to the crux; closing
-- it reduces to the prime-archimedean coupling sign for n≥3 (the archimedean place).
#print axioms Square.atlas_crux_localization

-- v0.21.0 stage G — crux frontier n=3: the next conquerable coefficient = Pos Rlambda3.
#print axioms Square.coupling_n3_iff_pos_lambda3
#print axioms Square.crux_frontier_n3

-- v0.22.0 crux frontier n=4: the next conquerable coefficient = Pos Rlambda4 (γ₃-bearing).
#print axioms Square.coupling_n4_iff_pos_lambda4
#print axioms Square.crux_frontier_n4

-- v0.21.0 stage G — uniform closure: closure is one structural fact, not enumeration (§2 thesis).
#print axioms Square.enumeration_insufficient
#print axioms Square.uniform_fact_closes
#print axioms Square.closure_is_uniform_not_enumeration

-- v0.21.0 stage G — Coxeter candidate: a §7 named uniform-rule candidate, killed by the growth
-- pre-filter (periodic order 30 ⟹ bounded ⟹ cannot match unbounded 2λₙ ~ n log n).
#print axioms Square.coxeter_candidate_killed
#print axioms Square.coxeter_candidate_periodic

-- v0.21.0 stage G — the Single Prime Hypothesis: the Atlas as one Prime object emanating all
-- structure; unity makes crux-closure uniform (one fact, not enumeration).
#print axioms Square.single_prime_binary
#print axioms Square.single_generator_emanates
#print axioms Square.sph_closure_is_uniform

-- v0.21.0 stage G — the atlas generator (candidate): the shift-length-facet uniform-rule
-- candidate; survives the growth filter (unbounded, n log n class) that killed Coxeter.
#print axioms Square.atlasShiftDiag_mono
#print axioms Square.atlasShiftDiag_step_ge_one
#print axioms Square.atlasGenerator_survives_growth

-- v0.21.0 stage G — coherence is the closure condition: the Atlas closes by coherence across all
-- facets (zero-state laws), not a single facet.
#print axioms Square.atlas_coherent
#print axioms Square.coherent_closure_not_single_facet

-- v0.21.0 stage G — Atlas composition algebras: the multiplicative norm at the tower levels (the
-- 2-, 4-, 8-square identities, Hurwitz) — the §6.3/§9 closed positivity.
#print axioms Square.two_square
#print axioms Square.four_square
#print axioms Square.eight_square
#print axioms Square.composition_tower

-- v0.21.0 stage G — Atlas topology: the Betti signature (§6.5, reduced homology rank 1) and
-- Bott/Clifford periodicity (§10); the tower forced four ways.
#print axioms Square.betti_signature
#print axioms Square.bott_periods
#print axioms Square.tower_forced_four_ways

-- v0.21.0 stage G — Atlas calculus: the seven operators, the free-monoid Term, and the
-- catamorphism with its universal property (§3/§4) — form determines function.
#print axioms Square.op_count
#print axioms Square.term_assoc
#print axioms Square.term_unit_left
#print axioms Square.term_unit_right
#print axioms Square.cata_append
#print axioms Square.cata_unique

-- v0.21.0 stage G — the complete UOR Atlas: the roll-up of every facet formalized, crux open.
#print axioms Square.atlas_complete
#print axioms Analysis.Rmul_right_cancel
#print axioms Analysis.Rdiv_mul_cancel
#print axioms Analysis.vvalrel_alg
#print axioms Analysis.vvalReal_rel_via
#print axioms Analysis.ratio_cross_via
#print axioms Analysis.Carg_add
#print axioms Analysis.Clog_add
#print axioms Analysis.RexpReal_eq_one_imp_zero
#print axioms Analysis.RexpReal_inj_gen
#print axioms Analysis.Rexp_log_ratQ
#print axioms Analysis.reindex_Req
#print axioms Analysis.Rlog_congr
#print axioms Analysis.RlogPos_unfold
#print axioms Analysis.RlogPos_eq_Rlog
#print axioms Analysis.RlogPos_mul
#print axioms Analysis.ge1_pos_witness
#print axioms Analysis.RlogPos_congr
#print axioms Analysis.RlogPos_cnormSq_mul
#print axioms Analysis.Clog_add_bounded
#print axioms Analysis.Rartanh_neg
#print axioms Analysis.RartanhConst_neg
#print axioms Analysis.TwoArtanhConst_neg
#print axioms Analysis.Rexp_TwoArtanh_of_neg
#print axioms Analysis.Rexp_TwoArtanh_signed_rho
#print axioms Analysis.Req_add_of_exp_values_gen
#print axioms Analysis.wvalR_hg
#print axioms Analysis.TwoArtanh_add_wvalR_rho
#print axioms Analysis.RartanhConst_add_wvalR_rho
#print axioms Analysis.Rartanh_add_real_via_signed
#print axioms Analysis.tmap_abs_lt_one
#print axioms Analysis.Rlog_mul_via_signed
#print axioms Analysis.wvalR_tmap_seq_bound_signed
#print axioms Analysis.Rlog_mul_signed
#print axioms Analysis.RlogPos_mul_signed
#print axioms Analysis.pos_witness_of_mulM_ge
#print axioms Analysis.RlogPos_cnormSq_mul_signed
#print axioms Analysis.Clog_add_signed
#print axioms Analysis.geoEvenSum_le_gen
#print axioms Analysis.Rartanh_congr_gen
#print axioms Analysis.artSum_depth_recip_gen
#print axioms Analysis.Rartanh_radius_indep_gen
#print axioms Analysis.Rlog_congr_gen
#print axioms Analysis.RlogPos_eq_Rlog_gen
#print axioms Analysis.RlogPos_congr_gen
#print axioms Analysis.wval_csq_le_gen
#print axioms Analysis.wval_halfbound_gen
#print axioms Analysis.wval_inner_pos_gen
#print axioms Analysis.wval_lip1_gen
#print axioms Analysis.wval_lip2_gen
#print axioms Analysis.artSum_wval_argdiff_gen
#print axioms Analysis.Rartanh_add_real_via_gen
#print axioms Analysis.tmul_wvalReal_via_gen
#print axioms Analysis.Rlog_mul_via_gen
#print axioms Analysis.Rlog_mul_gen
#print axioms Analysis.RlogPos_mul_gen
#print axioms Analysis.RlogPos_cnormSq_mul_gen
#print axioms Analysis.Clog_add_gen

-- Argument axis: tan(π/4)=1 and the π/2 values (full-range Carg/Clog anchors).
#print axioms Analysis.sin_eq_cos_pi4
#print axioms Analysis.Rcos_pi_half
#print axioms Analysis.Rsin_pi_half
#print axioms Analysis.Rcos_pi
#print axioms Analysis.Rsin_pi
#print axioms Analysis.Rsin_add_pi
#print axioms Analysis.Rcos_add_pi
#print axioms Analysis.CargLeft_tan
#print axioms Analysis.Cneg_Cmul_left
#print axioms Analysis.CargLeft_add
#print axioms Analysis.CdigammaArg_re
#print axioms Analysis.CdigammaArg_im
#print axioms Analysis.ofQ_le_CnormSq_CdigammaArg
#print axioms Analysis.CdigammaArg_witness
#print axioms Analysis.CdigammaTerm_re
#print axioms Analysis.CdigammaTerm_im
#print axioms Analysis.Cadd_neg_eq_mul_of_inv
#print axioms Analysis.Cmul_natSucc_inv
#print axioms Analysis.CdigammaArg_sub_succ_eq
#print axioms Analysis.CdigammaTerm_factored
#print axioms Analysis.CdigammaPfac_re_eq
#print axioms Analysis.CdigammaPfac_re_bound
#print axioms Analysis.CnormSq_CdigammaArg_ge
#print axioms Analysis.CdigammaPfac_im_eq
#print axioms Analysis.CdigammaPfac_im_bound
#print axioms Analysis.CdigammaTerm_re_bound
#print axioms Analysis.CdigammaTerm_im_bound
#print axioms Analysis.genSum_diff_eq
#print axioms Analysis.genTail_two_sided
#print axioms Analysis.genSum_RReg
#print axioms Analysis.CdigammaReSum_RReg
#print axioms Analysis.CdigammaImSum_RReg
#print axioms Analysis.ofQ_le_cnormSq_CspougeBase
#print axioms Analysis.CspougeBase_cnormSq_witness
#print axioms Analysis.CspougeBase_re_witness
#print axioms Analysis.Rcos_sub
#print axioms Analysis.Rsin_pi_half_sub
#print axioms Analysis.Rcos_pi_half_sub
#print axioms Analysis.Rsin_cos_pi_half_sub_tan
#print axioms Analysis.Rsin_cos_pi_half_sub_tan_real
#print axioms Analysis.tan_pi_half_sub_arctan_eighteen
#print axioms Analysis.Carg_I
#print axioms Analysis.CargUpper_tan
#print axioms Analysis.Carg_conj
#print axioms Analysis.Rdiv_congr
#print axioms Analysis.Carg_congr
#print axioms Analysis.swapC_re
#print axioms Analysis.swapC_im
#print axioms Analysis.swapC_Cmul_Cconj
#print axioms Analysis.Rsub_radd_neg_regroup
#print axioms Analysis.CargUpper_add
#print axioms Analysis.ClogUpper_add
#print axioms Analysis.CargLower_tan
#print axioms Analysis.Cconj_Cmul
#print axioms Analysis.CargUpper_congr
#print axioms Analysis.CargLower_add
#print axioms Analysis.Cadd_congr_loc
#print axioms Analysis.Cmul_congr_loc
#print axioms Analysis.Cpow_re
#print axioms Analysis.Cpow_add_exp
#print axioms Analysis.Cpow_mul_base
#print axioms Analysis.Rcos_RarctanR_nested
#print axioms Analysis.Rsin_RarctanR_nested
#print axioms Analysis.RarctanR_value_eq
#print axioms Analysis.arctanTerm_neg
#print axioms Analysis.arctanSum_neg
#print axioms Analysis.RarctanR_neg
#print axioms Analysis.ClogUpper_re
#print axioms Analysis.ClogUpper_im
#print axioms Analysis.ClogUpper_I_im
#print axioms Analysis.addsub_linear_b
#print axioms Analysis.sq_diff_identity_b
#print axioms Analysis.add_sub_add_cancel_left
#print axioms Analysis.hSeq1_step_eq
#print axioms Analysis.step_regroup
#print axioms Analysis.WStep_ge_negDsq_gen
#print axioms Analysis.two_delta_le
#print axioms Analysis.WStep_ge_negDsq
#print axioms Analysis.WStep_ge
#print axioms Analysis.sStep1_ge
#print axioms Analysis.hSeq1_step_ge
#print axioms Analysis.hSeq1_diff_ge_U
#print axioms Analysis.hSeq1_diff_ge
#print axioms Analysis.hSeq1_lower_const
#print axioms Analysis.hSeq1_le_gSeq
#print axioms Analysis.Rgamma1_ge_hSeq1
#print axioms Analysis.lnSumLo_den_pos
#print axioms Analysis.lnSum_ge_lnSumLo
#print axioms Analysis.gBound1lo_den_pos
#print axioms Analysis.hSeq1_ge_gBound1lo
#print axioms Analysis.gamma1_lo_decide
#print axioms Analysis.Rgamma1_ge_neg0762
#print axioms Analysis.zetaSum2_perstep_ge
#print axioms Analysis.zetaSum2_tail_ge
#print axioms Analysis.zeta2_ge_partial_tail
#print axioms Analysis.zetaSum_two_70_tail_ge
#print axioms Analysis.zeta2_lower_tight
#print axioms Analysis.cLowQ_den_pos
#print axioms Analysis.cApprox_ge_cLowQ
#print axioms Analysis.gammaLoBound_den_pos
#print axioms Analysis.gammaLoBound_le_Ssum
#print axioms Analysis.Ssum_cLowQ_le_gammaHseq
#print axioms Analysis.dPlusQ_one_eq
#print axioms Analysis.gcf_le
#print axioms Analysis.gcfDen_pos
#print axioms Analysis.dPlusQ_one_le
#print axioms Analysis.Qle_sub_swap
#print axioms Analysis.cLowQ_one_tail_lower
#print axioms Analysis.cApprox_tail_lower
#print axioms Analysis.Ssum_cApprox_tail
#print axioms Analysis.gammaHseq_ge_partial_tail
#print axioms Analysis.Rgamma_h_ge_of_witness
#print axioms Analysis.gammaLo_decide
#print axioms Analysis.Rgamma_h_ge_577
#print axioms Analysis.cApprox_antitone
#print axioms Analysis.cApprox_zero_eq
#print axioms Analysis.cApprox_tail_upper
#print axioms Analysis.gammaHiBound_den_pos
#print axioms Analysis.Ssum_le_gammaHiBound
#print axioms Analysis.Ssum_cApprox_tail_upper
#print axioms Analysis.gammaHseq_le_partial_tail
#print axioms Analysis.Rgamma_h_le_of_witness
#print axioms Analysis.gammaHi_decide
#print axioms Analysis.Rgamma_h_le_578
#print axioms Analysis.Rgamma_sq_le
#print axioms Analysis.Rgamma_sq_ge
#print axioms Analysis.Rgamma_cube_ge
#print axioms Analysis.Rgamma_gamma1_ge
#print axioms Analysis.Rlog4pic_le
#print axioms Analysis.nsmulR3_le_mul3
#print axioms Analysis.archI_ge
#print axioms Analysis.archII_ge
#print axioms Analysis.archTerm2_ge
#print axioms Analysis.archTerm3_ge
#print axioms Analysis.genuineArchSeq3_ge
#print axioms Analysis.reta0_le
#print axioms Analysis.reta1_le
#print axioms Analysis.Rgamma_h_nonneg
#print axioms Analysis.archLoQ_den_pos
#print axioms Analysis.arithLoQ_den_pos
#print axioms Analysis.arithSupQ_den_pos
#print axioms Analysis.gloCubeQ_den_pos
#print axioms Analysis.half_m3xu_den_pos
#print axioms Analysis.iilq_den_pos
#print axioms Analysis.ilq_den_pos
#print axioms Analysis.m3reta1_den_pos
#print axioms Analysis.m3xu_den_pos
#print axioms Analysis.reta1UpQ_den_pos
#print axioms Analysis.reta2UpQ_den_pos
#print axioms Analysis.xuQ_den_pos
#print axioms Analysis.reta2_le
#print axioms Analysis.reta1_le_r
#print axioms Analysis.Rlambda3_arith_ge_r
#print axioms Analysis.archLoR_le
#print axioms Analysis.Rlambda3_pos
#print axioms Square.coupling_n3_positive
#print axioms Analysis.zetaSum_four_70_ge
#print axioms Analysis.zeta4_lower
#print axioms Analysis.zetaU_four_70_le
#print axioms Analysis.zeta4_upper
#print axioms Analysis.lnCubeOver_nonneg
#print axioms Analysis.lnCubeSum_step
#print axioms Analysis.lnCubeSum_mono
#print axioms Analysis.logQuartic_nonneg
#print axioms Analysis.g3Seq_step_eq
#print axioms Analysis.Rmul_left_comm3
#print axioms Analysis.quartic_diff_identity
#print axioms Analysis.Rmul_fourth_four
#print axioms Analysis.cube_mono
#print axioms Analysis.W3_ge_4b3
#print axioms Analysis.W3_le_4a3
#print axioms Analysis.quarter_diff_le
#print axioms Analysis.e3Step_ge_num
#print axioms Analysis.quarter_diff_ge
#print axioms Analysis.Rthree_mul
#print axioms Analysis.e3Step_le_num
#print axioms Analysis.logCube_le_block
#print axioms Analysis.g3Seq_step_le_block
#print axioms Analysis.g3Seq_step_ge_block
#print axioms Analysis.g3Seq_diff_le_block
#print axioms Analysis.g3Seq_diff_ge_block
#print axioms Analysis.g3Seq_block_le
#print axioms Analysis.g3Seq_block_ge
#print axioms Analysis.gamma3Midx_mono
#print axioms Analysis.g3_linU
#print axioms Analysis.g3_quad_lin
#print axioms Analysis.g3_domination_U
#print axioms Analysis.g3_TU_le
#print axioms Analysis.g3_linL
#print axioms Analysis.g3_quadincL
#print axioms Analysis.g3_cube_lin
#print axioms Analysis.g3_domination_L
#print axioms Analysis.g3_TL_le
#print axioms Analysis.WUsum3_den_pos
#print axioms Analysis.WLsum3_den_pos
#print axioms Analysis.g3Seq_diff_le_outer
#print axioms Analysis.g3Seq_diff_ge_outer
#print axioms Analysis.WUsum3_tail_le
#print axioms Analysis.WLsum3_tail_le
#print axioms Analysis.g3_pair_le
#print axioms Analysis.g3_pair_ge
#print axioms Analysis.g3SeqDyadic_RReg
#print axioms F1Square.Tropical.IntersectionPositivity.stableIntersectionMult_nonneg
#print axioms F1Square.Tropical.PIRTMBridge.gatedMult_nonneg
#print axioms F1Square.Tropical.PIRTMBridge.gatedMult_trivial_recovers
#print axioms F1Square.Tropical.PIRTMBridge.contractedMult_le_stable

-- ADR-100: The central conditional claim. The surface axioms are the open content;
-- this axiom is the governing implication of the F1-Square scaffold.
#print axioms UOR.Bridge.F1Square.Crux.F1Square_implies_RH

-- IntersectionTemplate (T3: multi-prime template surface probe)
#print axioms F1Square.IntersectionTemplate.tpair1_symm
#print axioms F1Square.IntersectionTemplate.tpair1_HV
#print axioms F1Square.IntersectionTemplate.tpair1_HH
#print axioms F1Square.IntersectionTemplate.tpair1_VV
#print axioms F1Square.IntersectionTemplate.tpair1_HD
#print axioms F1Square.IntersectionTemplate.tpair1_VD
#print axioms F1Square.IntersectionTemplate.tpair1_DD
#print axioms F1Square.IntersectionTemplate.tpair1_HG
#print axioms F1Square.IntersectionTemplate.tpair1_VG
#print axioms F1Square.IntersectionTemplate.tpair1_DG
#print axioms F1Square.IntersectionTemplate.tpair1_GG
#print axioms F1Square.IntersectionTemplate.tample1_sq_pos
#print axioms F1Square.IntersectionTemplate.tprimDG_perp_H
#print axioms F1Square.IntersectionTemplate.tprimDG_perp_V
#print axioms F1Square.IntersectionTemplate.tprimDG_sq
#print axioms F1Square.IntersectionTemplate.thasse_form_id
#print axioms F1Square.IntersectionTemplate.t1_hodge_iff_hasse
#print axioms F1Square.IntersectionTemplate.t1_signature_hasse

-- DeitmarTest (T3: candidate testing predicate)
#print axioms F1Square.DeitmarTest.testN1_passes_hasse
#print axioms F1Square.DeitmarTest.testN1_q25_a10
#print axioms F1Square.DeitmarTest.testN1_q25_a12_fails
#print axioms F1Square.DeitmarTest.deitmarTest_N1_verified
#print axioms F1Square.DeitmarTest.deitmarTest_q25_a10
#print axioms F1Square.DeitmarTest.deitmarTestN2
#print axioms F1Square.DeitmarTest.deitmarTestN3
#print axioms F1Square.DeitmarTest.deitmarTestN4
#print axioms F1Square.DeitmarTest.deitmarTestN5
#print axioms F1Square.DeitmarTest.deitmarTest_n2_q4_a2_q25_a10
#print axioms F1Square.DeitmarTest.deitmarTest_n3_q4_a2_q25_a10_q16_a6
#print axioms F1Square.DeitmarTest.deitmarTest_n4_q4_a2_q25_a10_q16_a6_q49_a14
#print axioms F1Square.DeitmarTest.deitmarTest_n5_primes
#print axioms F1Square.DeitmarTest.deitmarLift_general

-- IntersectionTemplate (T3: conditional multi-prime scaffold)
#print axioms F1Square.IntersectionTemplate.mample_vec
#print axioms F1Square.IntersectionTemplate.mprimDG_vec
#print axioms F1Square.IntersectionTemplate.multiPrime_block_signature
#print axioms F1Square.IntersectionTemplate.mample_sq_pos

-- WeilBridge (T4: Weil docking bridge)
#print axioms F1Square.WeilBridge.template_pairing_bound
#print axioms F1Square.WeilBridge.weil_finite_contribution
#print axioms F1Square.WeilBridge.deitmar_weil_bridge
#print axioms F1Square.WeilBridge.weil_coupling_sign_from_template
#print axioms F1Square.WeilBridge.primes_two_three_decisive

-- ToricBaseChange (T4b: Toric base-change consistency probe)
#print axioms F1Square.ToricBaseChange.ample_survives_basechange
#print axioms F1Square.ToricBaseChange.torus_orbit_exists_n2
#print axioms F1Square.ToricBaseChange.torus_orbit_exists_n3
#print axioms F1Square.ToricBaseChange.signature_toric_compatible
#print axioms F1Square.ToricBaseChange.blueprint_trivial_embedding
#print axioms F1Square.ToricBaseChange.toric_basechange_functor
#print axioms F1Square.ToricBaseChange.intersection_toric_fan_match_n2
#print axioms F1Square.ToricBaseChange.intersection_toric_fan_match_n3
#print axioms F1Square.ToricBaseChange.torified_witness_n2
#print axioms F1Square.ToricBaseChange.torified_witness_n3

-- SAlgebraDocking (T5: S-algebra / multi-partition docking probe)
#print axioms F1Square.SAlgebraDocking.n2_salgebra_concrete
#print axioms F1Square.SAlgebraDocking.n3_salgebra_concrete
#print axioms F1Square.SAlgebraDocking.block_positivity_sheaf
#print axioms F1Square.SAlgebraDocking.weil_partition_encoding
#print axioms F1Square.SAlgebraDocking.sheaf_positivity_implies_hodge
#print axioms F1Square.SAlgebraDocking.site_basechange_morphism

-- SAlgebraDocking (T5: S-algebra / multi-partition docking probe)
#print axioms F1Square.SAlgebraDocking.n2_salgebra_concrete
#print axioms F1Square.SAlgebraDocking.n3_salgebra_concrete
#print axioms F1Square.SAlgebraDocking.block_positivity_sheaf
#print axioms F1Square.SAlgebraDocking.weil_partition_encoding
#print axioms F1Square.SAlgebraDocking.sheaf_positivity_implies_hodge
#print axioms F1Square.SAlgebraDocking.site_basechange_morphism

-- ArakelovHodge (T7: Finite-N Arakelov pairing - algebraic negativity)
#print axioms F1Square.ArakelovHodge.arakelov_matrix
#print axioms F1Square.ArakelovHodge.archimedean_gamma
#print axioms F1Square.ArakelovHodge.archimedean_matrix
#print axioms F1Square.ArakelovHodge.full_matrix
#print axioms F1Square.ArakelovHodge.diag_vec
#print axioms F1Square.ArakelovHodge.diag_infinite_norm
#print axioms F1Square.ArakelovHodge.archimedean_vanishes_on_ortho
#print axioms F1Square.ArakelovHodge.finite_arakelov_negative
#print axioms F1Square.ArakelovHodge.n2_negative
#print axioms F1Square.ArakelovHodge.n3_negative
#print axioms F1Square.ArakelovHodge.general_finite_negative

-- SpectralGap (ADR-400: Open core documentation)
#print axioms F1Square.SpectralGap.atlas_not_hodge_signature
#print axioms F1Square.SpectralGap.spectral_eigenvalues_are_log
#print axioms F1Square.SpectralGap.spectral_gap_distinction
#print axioms F1Square.SpectralGap.coupling_open

-- GhostComponents (T6: Ghost-component probe + Witt vector diagonalization)
#print axioms F1Square.GhostComponents.ghost_diagonalization
#print axioms F1Square.GhostComponents.mobius_refinement_diagonal
#print axioms F1Square.GhostComponents.ghost_negative_definite
#print axioms F1Square.GhostComponents.theta_spectrum_critical
#print axioms F1Square.GhostComponents.ghost_explicit_formula
#print axioms F1Square.GhostComponents.n2_ghost_instance
#print axioms F1Square.GhostComponents.n3_ghost_instance
#print axioms F1Square.GhostComponents.unitary_axis_condition
#print axioms F1Square.GhostComponents.lefschetz_trace_connection

-- MOC.Resonance (axiom-clean resonance skeleton)
#print axioms MOC.Resonance.nat_sq
#print axioms MOC.Resonance.nat_cubert
#print axioms MOC.Resonance.R_sc
#print axioms MOC.Resonance.Delta_top
#print axioms MOC.Resonance.tau_R
#print axioms MOC.Resonance.tierProjector
#print axioms MOC.Resonance.fullTierProjector
#print axioms MOC.Resonance.tierResidual
#print axioms MOC.Resonance.projector_idempotent
#print axioms MOC.Resonance.tier_orthogonality
#print axioms MOC.Resonance.orthogonal_sum_zero
#print axioms MOC.Resonance.sum_proj_residual_per_value
#print axioms MOC.Resonance.sum_proj_residual_zero
#print axioms MOC.Resonance.signal_orthogonality_reduction
#print axioms MOC.Resonance.lip_bound
#print axioms MOC.Resonance.contraction_check
#print axioms MOC.Resonance.Inv
#print axioms MOC.Resonance.admissible_preserves_orthogonality
#print axioms MOC.Resonance.R1_invariant_under_projection
#print axioms MOC.Resonance.ResonanceCertificate
#print axioms MOC.Resonance.threshold_Rsc
#print axioms MOC.Resonance.meets_threshold
#print axioms MOC.Resonance.n108_certificate
#print axioms MOC.Resonance.n108_admissible
#print axioms MOC.Resonance.n108_Rsc_check
#print axioms MOC.Resonance.gaugeFix
#print axioms MOC.Resonance.gauge_preserves_Rsc
#print axioms MOC.Resonance.ResonanceClass
#print axioms MOC.Resonance.ProofByResonanceCert
#print axioms MOC.Resonance.cert_validates

-- MOC.Identity (ADR-401)
#print axioms MOC.Identity.A
#print axioms MOC.Identity.C
#print axioms MOC.Identity.D
#print axioms MOC.Identity.IdentitySystem
#print axioms MOC.Identity.PrimeMoc
#print axioms MOC.Identity.toBitL0
#print axioms MOC.Identity.persistence_law
#print axioms MOC.Identity.contraction_preserves
#print axioms MOC.Identity.toCRMF
#print axioms MOC.Identity.C2_resonance_gain
#print axioms MOC.Identity.c2_eff_bound
#print axioms MOC.Identity.C2_transport_preserves_L_eff
#print axioms MOC.Identity.C4_pmdm_sparsity
#print axioms MOC.Identity.pmdm_support_bound
#print axioms MOC.Identity.C4_lifted_support_bound
#print axioms MOC.Identity.L_eff_le_085_lifted
#print axioms MOC.Identity.functor_preserves_contraction
#print axioms MOC.Identity.spectral_gap
#print axioms MOC.Identity.prime_gap_chi2
#print axioms MOC.Identity.prime_moc_factors
#print axioms MOC.Identity.L_eff_bound
#print axioms MOC.Identity.L_eff_contraction
#print axioms MOC.Identity.L_eff_bound_verified
#print axioms MOC.Identity.n108_contractive
#print axioms MOC.Identity.crmf_lift_preserves_bound
#print axioms MOC.Identity.c2_c4_contractivity_bound
