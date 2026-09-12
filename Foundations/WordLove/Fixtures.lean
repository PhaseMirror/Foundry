/-
Copyright (c) 2026 Multiplicity Foundry. All rights reserved.
Released under the terms described in the repository LICENSE file.
-/
import Foundations.WordLove.Core

/-!
# Word Love Fixtures (ADR-0031)

Attr-free reference data: semantic tokens, gematria encodings, and the Pratt
certificate witnesses for the two verified large primes. This module sits in
the Rust-loaded export closure (`Core → Fixtures → FFI`), so it deliberately
contains no `initialize` blocks and applies no tag attributes — the same
artifacts remain tagged at their theorem sites in `Proofs`.

Moved here from `Proofs.lean` (reference tokens/encodings, §1) so the FFI
dylib can initialize without registering environment extensions; see
`Attrs.lean` for the full rationale.
-/

namespace Foundations.WordLove

/-! ### Reference Semantic Tokens -/

/-- Reference token for Love (Ahavah). -/
def tokenAhavah : SemanticToken :=
  { id := "ahavah", name := "Love", hebrew := "אהבה", transliteration := "ahavah",
    description := "The divine and human attribute of unconditioned love" }

/-- Reference token for One (Echad). -/
def tokenEchad : SemanticToken :=
  { id := "echad", name := "One", hebrew := "אחד", transliteration := "echad",
    description := "The theological and mathematical anchor of indivisible oneness" }

/-- Reference token for Lovingkindness / Grace (Hesed). -/
def tokenHesed : SemanticToken :=
  { id := "hesed", name := "Grace", hebrew := "חסד", transliteration := "hesed",
    description := "Covenantal grace and steadfast love" }

/-- Reference token for Truth (Emet). -/
def tokenEmet : SemanticToken :=
  { id := "emet", name := "Truth", hebrew := "אמת", transliteration := "emet",
    description := "Absolute truth and structural faithfulness" }

/-- Reference token for Peace (Shalom). -/
def tokenShalom : SemanticToken :=
  { id := "shalom", name := "Peace", hebrew := "שלום", transliteration := "shalom",
    description := "Wholeness, completeness, and systemic harmony" }

/-! ### Reference Encodings -/

/-- Standard encoding of Ahavah: 13. -/
def encAhavahStd : Encoding :=
  { token := tokenAhavah, scheme := GematriaScheme.Standard, value := 13, positive := by decide }

/-- Reduced encoding of Ahavah: 4. -/
def encAhavahRed : Encoding :=
  { token := tokenAhavah, scheme := GematriaScheme.Reduced, value := 4, positive := by decide }

/-- Standard encoding of Echad: 13. -/
def encEchadStd : Encoding :=
  { token := tokenEchad, scheme := GematriaScheme.Standard, value := 13, positive := by decide }

/-- Reduced encoding of Echad: 4. -/
def encEchadRed : Encoding :=
  { token := tokenEchad, scheme := GematriaScheme.Reduced, value := 4, positive := by decide }

/-- Standard encoding of Hesed: 72. -/
def encHesedStd : Encoding :=
  { token := tokenHesed, scheme := GematriaScheme.Standard, value := 72, positive := by decide }

/-- Standard encoding of Emet: 441. -/
def encEmetStd : Encoding :=
  { token := tokenEmet, scheme := GematriaScheme.Standard, value := 441, positive := by decide }

/-- Standard encoding of Shalom: 376. -/
def encShalomStd : Encoding :=
  { token := tokenShalom, scheme := GematriaScheme.Standard, value := 376, positive := by decide }

/-! ### Large-Prime Certificate Witnesses -/

/-- Pratt Certificate Witness for Fermat Prime $F_4 = 65537 > 2^{16}$.
    $p - 1 = 65536 = 2^{16}$, primitive root witness $g = 3$. -/
def cert65537 : PrattCertificate :=
  { p := 65537, g := 3, factors := [(2, 16)] }

/-- Pratt Certificate Witness for Mersenne Prime $M_{17} = 131071 > 2^{16}$.
    $p - 1 = 131070 = 2^1 \cdot 3^1 \cdot 5^1 \cdot 17^1 \cdot 257^1$, primitive root witness $g = 3$. -/
def cert131071 : PrattCertificate :=
  { p := 131071, g := 3, factors := [(2, 1), (3, 1), (5, 1), (17, 1), (257, 1)] }

end Foundations.WordLove
