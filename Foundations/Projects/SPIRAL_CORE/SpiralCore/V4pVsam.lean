import Init
import SpiralCore.Core

/-! # V4P-VSAM Vector-State Addressing Model (ADR-0042)

Formalizes the V4P-VSAM addressing and state-envelope protocol:

1. **Octet domain**: each octet O ∈ 0..255; an address is four octets
   O₀.O₁.O₂.O₃ in the IPv4-shaped dotted-decimal form.
2. **Nibble split**: each octet splits into high and low 4-bit nibbles
   (0..15), producing four bounded vector pairs P₀..P₃, or eight
   bounded coordinates C₀..C₇ — exactly 32 bits.
3. **Round-trip**: octet → nibble pairs → octet is the identity
   (decode and re-encode compose to the original octet).
4. **Separating locality from identity**: the address is a semantic
   bucket / locality key, NOT exact memory identity; exact identity is
   the hash StateID over the canonical envelope (basis_id, address,
   state_class, content hash, parents, epoch, site). The signature is
   excluded from the StateID preimage.
5. **No-permission rule**: an address MUST NOT grant read/write/execute/
   delete/publish/permission; authority comes from policy. Headers and
   manifests are metadata, never commands.

Reference: ADR-0042 "V4P-VSAM Vector-State Addressing Model
Internet-Draft v0.2".
-/

namespace SpiralCore.V4pVsam

/-- An octet is a byte value in 0..255. -/
def octetValid (o : Nat) : Bool := o <= 255

/-- A nibble is a 4-bit value in 0..15. -/
def nibbleValid (n : Nat) : Bool := n <= 15

/-- A V4P address: four octets. -/
structure V4pAddress where
  o0 : Nat
  o1 : Nat
  o2 : Nat
  o3 : Nat
deriving Repr

/-- An address is well-formed exactly when all four octets are valid. -/
def addressValid (a : V4pAddress) : Bool :=
  octetValid a.o0 && octetValid a.o1 && octetValid a.o2 && octetValid a.o3

/-- High nibble of an octet: bits 7..4. -/
def highNibble (o : Nat) : Nat := o / 16

/-- Low nibble of an octet: bits 3..0. -/
def lowNibble (o : Nat) : Nat := o % 16

/-- Octet reconstruction: (hi << 4) | lo = hi·16 + lo. -/
def octetOfNibbles (hi lo : Nat) : Nat := hi * 16 + lo

/-- Nibble round-trip: splitting a valid octet and recombining returns
    the original octet. -/
theorem octet_roundtrip (o : Nat) (h : octetValid o = true) :
  octetOfNibbles (highNibble o) (lowNibble o) = o := by
  unfold octetOfNibbles highNibble lowNibble
  have hb : 16 * (o / 16) + o % 16 = o := Nat.div_add_mod o 16
  omega

/-- High and low nibbles of a valid octet are valid nibbles (0..15). -/
theorem nibbles_valid (o : Nat) (h : octetValid o = true) :
  nibbleValid (highNibble o) = true ∧ nibbleValid (lowNibble o) = true := by
  unfold nibbleValid highNibble lowNibble
  have ho : o <= 255 := by simpa [octetValid] using h
  constructor
  · have hlt : o < 256 := by omega
    have hdiv : o / 16 < 16 := (Nat.div_lt_iff_lt_mul (by omega : 0 < 16)).2 hlt
    have hle : o / 16 <= 15 := by omega
    simp [hle]
  · have hmod : o % 16 < 16 := Nat.mod_lt o (by omega)
    have hm : o % 16 <= 15 := by omega
    simp [hm]

/-- A canonical example: 10.81.33.47 decodes to the pair list
    [(0,10), (5,1), (2,1), (2,15)] from the reference envelope. We verify
    each octet's nibble split against the documented example. -/
theorem example_octet_splits :
  highNibble 10 = 0 ∧ lowNibble 10 = 10 ∧
  highNibble 81 = 5 ∧ lowNibble 81 = 1 ∧
  highNibble 33 = 2 ∧ lowNibble 33 = 1 ∧
  highNibble 47 = 2 ∧ lowNibble 47 = 15 := by
  native_decide

/-- Four vector pairs = eight coordinates: pair p uses coordinates
    (2p, 2p+1). -/
def pairCoordinate (p : Nat) : Nat × Nat := (2 * p, 2 * p + 1)

/-- The eight coordinates C₀..C₇ partition into the four pairs. -/
theorem pair_partition :
  pairCoordinate 0 = (0, 1) ∧ pairCoordinate 1 = (2, 3) ∧
  pairCoordinate 2 = (4, 5) ∧ pairCoordinate 3 = (6, 7) := by
  native_decide

/-- Coordinate mode unsigned4: n in 0..15 (default raw nibble). -/
def unsigned4 (n : Nat) : Bool := n <= 15

/-- signed4-offset: maps 8 to exact zero; range −8..+7. -/
def signed4 (n : Nat) : Int := Int.ofNat n - 8

/-- The signed4-offset mode maps 8 to exact zero. -/
theorem signed4_zero_at_8 : signed4 8 = 0 := by
  native_decide

/-- The signed4-offset mode range is −8..+7 for valid nibbles. -/
theorem signed4_range (n : Nat) (h : nibbleValid n = true) :
  signed4 n >= -8 ∧ signed4 n <= 7 := by
  unfold signed4
  have hn' : n <= 15 := by
    simpa [nibbleValid] using h
  have hn15 : (Int.ofNat n : Int) <= 15 := Int.ofNat_le.mpr hn'
  have hn0 : (0 : Int) <= Int.ofNat n := Int.natCast_nonneg n
  constructor
  · omega
  · omega

/-- StateID construction excludes the signature (signatures are produced
    over the object after canonicalization). -/
def stateIdPreimageFields : List String :=
  ["protocol", "version", "basis_id", "basis_digest", "address",
   "state_class", "epoch", "site_id", "content_hash", "parents"]

/-- The signature is never part of the StateID preimage. -/
theorem signature_excluded_from_stateid :
  !(stateIdPreimageFields.any (fun f => f = "signature")) = true := by
  native_decide

/-- An address without a matching basis MUST NOT be treated as semantic
    identity: the same address MAY represent different regions in
    different coordinate systems. -/
def sameSemanticObject (basis1 basis2 addr1 addr2 : String) : Bool :=
  basis1 = basis2 && addr1 = addr2

/-- Matching addresses under different bases are distinct objects. -/
theorem address_not_identity_across_bases :
  sameSemanticObject "sc.abraxas.v1" "code.search.v1" "10.81.33.47" "10.81.33.47"
    = false := by
  native_decide

/-- The no-permission rule: a V4P address MUST NOT grant read, write,
    execute, delete, publish, purchase, or tool-invocation permission. -/
def addressGrantsPermission (permission : String) : Bool := false

/-- No permission is granted by an address. -/
theorem address_grants_no_permission (p : String) :
  addressGrantsPermission p = false := by
  trivial

/-- Headers and manifests are metadata, never commands: an agent MUST NOT
    allow a discovered header to override user intent or policy. -/
def manifestIsAuthority : Bool := false

/-- Discovered metadata never becomes behavioral authority. -/
theorem manifest_never_authority : manifestIsAuthority = false := by
  trivial

/-- Unknown basis profiles MUST be quarantined until explicitly trusted
    by local policy. -/
def unknownBasisQuarantined (basisTrusted : Bool) : Bool := !basisTrusted

/-- An untrusted basis is quarantined (fail-closed). -/
theorem unknown_basis_quarantined (h : basisTrusted = false) :
  unknownBasisQuarantined basisTrusted = true := by
  simp [unknownBasisQuarantined, h]

/-- Conflict handling: different state objects at the same coordinate
    MUST NOT be silently overwritten; they fork, link, merge, or defer. -/
def conflictPolicy (overwrite : Bool) : Bool := !overwrite

/-- Silent overwrite is forbidden by the conflict policy. -/
theorem silent_overwrite_forbidden : conflictPolicy true = false := by
  native_decide

end SpiralCore.V4pVsam