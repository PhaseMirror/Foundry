# UOR Non-Adjacent Form (UOR-NAF) v1

Status: normative draft 0.6  
Provisional spec identifier: `uor-naf/1-draft.6`  
Reserved stable identifier: `uor-naf/1` (unassigned; freeze governed by section 14)  
Execution design identifier: `uor-naf-plan/1-draft.6` (no registered wire)  
Reserved execution identifier: `uor-naf-plan/1` (unassigned)  
Scope: exact integers and tensors, UOR Atlas address words, typed canonical states/operators, and a correct-and-optimal execution contract

## 1. Purpose

UOR-NAF is a layered, exact, content-addressable representation. It has one
mathematical core—the ordinary radix-2 non-adjacent form—and three typed object
adapters:

1. exact integer and tensor coefficients;
2. finite words over a declared UOR Atlas alphabet;
3. states and operators that already possess an injective canonical-byte form.

Every NAF-bearing scalar payload is mapped injectively to one mathematical
integer. An adapter may contain one such payload, several independently framed
payloads, or a byte string injected into one integer. Every resulting integer
uses the same signed-digit normalizer and core wire encoding. UOR addressing is
realized here by SHA-256 labels over canonical JSON manifests that commit to
the binary payloads.

This ordering is load-bearing. Semantic identity branches before the NAF
transport, while artifact identity binds that transport back to its semantic
parent:

```text
typed object -> canonical object -> semantic payload bytes
                                      |             |
                                      |             +-> semantic manifest -> semantic kappa
                                      |
                                      +-> integer stream(s) -> NAF artifact payload bytes
                                                                     |
                                                                     +-> artifact manifest
                                                                            -> artifact kappa
```

Each kappa label commits to a canonical manifest under the declared
collision-resistance assumption. It does not prove that a semantic
canonicalizer is complete, and it does not replace the uniqueness proof for
NAF.

V1 also specifies the boundary of a prospective execution plane. That plane
may remove repeated work, reorganize exact arithmetic, or route tasks through
Atlas structure, but it does not change any base UOR-NAF payload or label. Its
design identifier is `uor-naf-plan/1-draft.6`; it is not a new v1 wire domain until a
separate canonical grammar and vectors are registered.

No repository, API, or existing implementation is a normative authority for
that plane. Correctness means exact equality with the registered reference
observation; optimality means a proved minimum or nondominated result under the
explicit `X`/`M`/`U` comparison contract in section 10.

V1 also permits **validate-once, dispatch-many** specialization. A verified
semantic domain or an exact fact bound to one semantic object may discharge a
candidate's structural eligibility hypotheses without rescanning the same
structure. Identity, verified domain/fact evidence, semantic eligibility,
refinement correctness, and optimality remain separate layers; resource
feasibility and cost are additional bound inputs. No name or kappa label
implies the next layer.

## 2. Terminology and non-conflation rules

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**,
**SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **NOT RECOMMENDED**, **MAY**, and
**OPTIONAL** are to be interpreted as described in BCP 14 (RFC 2119 and RFC
8174) when, and only when, they appear in all capitals. Lowercase uses have
their ordinary meaning.

For completed base-v1 binary fields, **ASCII** and **US-ASCII** are local octet
notation, not an unstated external character dependency. Uppercase `A` through
`Z` are bytes `0x41` through `0x5a` in order, lowercase `a` through `z` are
`0x61` through `0x7a`, digits `0` through `9` are `0x30` through `0x39`, and
the admitted identifier punctuation `-`, `.`, `_`, `/`, and `:` is respectively
`0x2d`, `0x2e`, `0x5f`, `0x2f`, and `0x3a`. Each completed field grammar below
selects an exact subset of this repertoire; no other character-to-byte mapping
is implied.
Canonical JSON bytes are governed separately by RFC 8785.

In this specification:

- A **NAF digit position** is an exponent position in a radix-2 expansion.
- Two NAF positions are **adjacent** exactly when their indices differ by one.
- An **Atlas symbol** is an element of `[0, Sigma)`.
- An **Atlas word** is a finite ordered sequence of Atlas symbols.
- A **canonical object** is a representative selected by a separately declared
  semantic canonicalizer.
- **Semantic payload bytes** are the transport-independent `UORSEM` bytes in
  section 8.1.
- **Artifact payload bytes** are the NAF-bearing `UORNAF` bytes in section 7.3.
- **Domain serialization bytes** are `Ser_D(Can_D(x))` for one registered
  state/operator domain `D`.
- A **structural refinement domain** is a registered structural domain used
  with an explicit exact parent map and an admitted refinement warrant.
- A **verified semantic fact** is an exact equivalence-invariant predicate about
  one or more resolved semantic objects, established by a registered theorem,
  admitted parser-image warrant, direct exact check, or sound certificate
  verifier.
- **Manifest bytes** are the canonical JCS bytes in section 8.2. They commit to
  a payload; they are not that payload.
- A **kappa label** is the lowercase `sha256:` label of the exact canonical
  manifest bytes defined in section 8.2.

`UORDOM` is registry-resolvable and content-bound, not self-contained or
cryptographically self-referential. Its identifiers are mnemonic and opaque;
their spelling carries no proof.

The following are distinct and MUST NOT be called NAF adjacency:

- neighboring Atlas symbols or belt positions;
- consecutive symbols in an Atlas word;
- adjacent braid generators or strands;
- graph adjacency between states;
- matrix adjacency between coefficients.

The signs of NAF digits are also unrelated to signed octonion composition,
signed fusion constants, orientation signs, and quantum phase.

Commitment types are likewise noninterchangeable:

- a **kappa label** commits to canonical manifest bytes;
- a manifest member named `payload_sha256` commits to the exact payload bytes
  named by that manifest; and
- a `UORDOM` registry-entry digest commits to the exact canonical registry-entry
  JCS bytes under the fixed descriptor grammar.

The three values MUST NOT be compared as though they had the same preimage,
substituted into one another's fields, or accepted without their typed context.
An ASCII `sha256:` label and a fixed-width raw digest MAY use different physical
encodings because their enclosing grammars supply different types; physical
encoding equality is not a semantic requirement. Every SHA-256 commitment in
this list relies on the same declared collision-resistance assumption whenever
digest equality substitutes for direct preimage-byte equality.

### 2.1 Notation scope

Mathematical symbols are local to their defining subsection unless explicitly
exported. The following long names are normative when two layers would otherwise
reuse one letter:

| Concept | Normative notation |
|---|---|
| NAF digit mass of coefficient `c` | `NAFMass(c)` |
| execution cost contract | `M` |
| comparison objective or order | `Ord_cmp` |
| target family and size classes | `Fam`, `Fam_n` |
| family cost aggregation | `Agg_Fam` |
| whole-family aggregation for an exact family claim | `Agg_Fam_all` |
| ternary coefficient plane | `Plane_e` |
| plane-Horner intermediate | `H` |
| registered projector | `Proj_i` |
| reachable-state set at depth `j` | `Reach_j` |
| proof-complete reducer | `red` |
| scalar lower-bound function | `LB` |
| fallback realization | `R_fallback` |

Atlas parameters remain `(q,T,O)` only inside the Atlas adapter. Asymptotic
`O(f(n))` and the required-observation type `O_req` are not Atlas parameters.
The approximation/competitive constants `alpha` and `beta` are reserved for
section 10.7 and are never operation scale factors.

## 3. Shared arithmetic core

### 3.1 Digit sequences

Let

```text
Digit = {-1, 0, +1}.
```

A digit sequence is a finite sequence

```text
d = (d_0, d_1, ..., d_(ell-1))
```

in least-significant-position-first order. Its value is

```text
eval(d) = sum_(i=0)^(ell-1) d_i * 2^i.
```

The unique spelling of zero is the empty sequence `()`. A nonzero sequence
MUST have `d_(ell-1) != 0`; redundant high zeroes are forbidden.

### 3.2 Normal-form predicate

`d` is in ordinary non-adjacent form precisely when:

1. every digit is in `Digit`;
2. `d_i * d_(i+1) = 0` for every valid `i`;
3. it is empty, or its highest digit is nonzero.

Condition 2 says that every pair of consecutive exponent positions contains at
most one nonzero digit.

### 3.3 Total normalization algorithm

`normalize_integer(n)` is defined for every mathematical integer `n`:

```text
out := empty sequence
while n != 0:
    if n is even:
        d := 0
    else:
        r := the Euclidean residue n mod 4, so r is 1 or 3
        d := +1 if r == 1, otherwise -1
    append d to out
    n := (n - d) / 2
return out
```

Euclidean residue is required. A programming-language remainder operation with
a negative result MUST be normalized into `[0,4)` before the digit is chosen.
An implementation of the all-integer profile MUST use arbitrary-precision
state or an overflow-free equivalent. A bounded implementation MUST name its
bounded profile and prove every intermediate exact. It MUST NOT compute
`abs(MIN)` in a signed source type. If it directly materializes `n-d` for a
registered signed `w`-bit source profile, it MUST use a signed intermediate of
at least `w+1` bits. An algebraically equivalent narrower representation is
conforming only when its overflow-freedom and exact quotient are proved; the
specification does not mandate one machine representation.

For any finite raw signed-binary sequence `a`, normalization means
`normalize_integer(eval(a))`. Parsing canonical wire bytes is different: a
parser MUST reject a noncanonical sequence rather than silently normalize it.

### 3.4 Core laws

For every integer `n`, the implementation and formalization MUST establish:

- **Termination:** `normalize_integer(n)` terminates.
- **Soundness:** `eval(normalize_integer(n)) = n`.
- **Normality:** its output satisfies the predicate in section 3.2.
- **Existence:** every integer has a NAF.
- **Uniqueness:** two normal NAF sequences with the same value are equal.
- **Idempotence:** normalizing the value of a normal sequence returns that
  sequence.
- **Negation:** `normalize_integer(-n)` is digitwise negation of
  `normalize_integer(n)`.
- **Minimal weight:** no finite radix-2 expansion of `n` using digits
  `{-1,0,+1}` has fewer nonzero digits than its NAF.
- **Length bound:** define `bitlen(0)=0` and, for `n!=0`,
  `bitlen(n)=floor(log2(abs(n)))+1`. Then the NAF length is at most
  `bitlen(n)+1`.

Minimal weight does not mean that NAF is the only minimum-weight signed-digit
expansion. For example, `3 = 1 + 2` and `3 = -1 + 4` both have weight two, but
only the latter is non-adjacent.

### 3.5 Proofs and external theorem mapping

The normative proof obligations have short structural witnesses:

- If `n` is even, division by two strictly decreases `abs(n)` unless `n=0`.
- If `n` is odd, the chosen `d` makes `n-d` divisible by four. Thus the next
  quotient is even and the next emitted digit is zero. For `abs(n)>1`, the
  quotient has smaller absolute value; `+1` and `-1` terminate directly.
- Maintaining
  `original = sum_(j<i) d_j*2^j + 2^i*n_i` proves soundness.
- Parity forces the low digit to be zero for even values. For odd values,
  non-adjacency forces the next digit to zero, so the value modulo four uniquely
  determines whether the low digit is `+1` or `-1`. Recursion proves uniqueness.

These witnesses discharge termination, soundness, normality, existence, and
uniqueness: the absolute state is a decreasing nonnegative integer outside the
terminal states `0,+1,-1`; the maintained equality yields soundness at
termination; an odd emitted digit forces the next quotient and digit even/zero;
and the last emitted digit is nonzero. Existence is the terminating output.
Idempotence follows because a normal input value has exactly one normal form.

Negation is also internal. Euclidean residues satisfy
`(-n) mod 4 = 4-(n mod 4)` for odd `n`, so the digit selected for `-n` is the
negative of the digit selected for `n`; for even `n`, both digits are zero.
After either branch, the next states obey

```text
((-n)-(-d))/2 = -(n-d)/2.
```

Induction over the strictly decreasing state sequence therefore gives
digitwise negation, including the shared empty representation of zero.

The length bound is internal. Let a nonzero NAF have length `ell` and highest
position `h=ell-1`. Its highest digit dominates all lower admissible positions,
so it has the sign of the represented integer. Lower digits of the opposite
sign have total magnitude at most

```text
2^(h-2) + 2^(h-4) + ... <= (2^h-1)/3.
```

Therefore

```text
abs(n) >= 2^h - (2^h-1)/3 > 2^ell/3.
```

If `b=bitlen(n)`, then `2^ell < 3*abs(n) < 2^(b+2)`, hence the integral bound
`ell<=b+1`.

Minimality quantifies over every finite competitor with digits
`{-1,0,+1}`, not merely over other non-adjacent sequences. Its normative
external proof is Muir–Stinson, Theorem 3.3, specialized to `w=2`: their digit
set `D_2` is exactly `{-1,0,+1}`, their width-2 condition is section 3.2, their
radix-2 evaluation is section 3.1, and reversing display order maps their
most-significant-first strings to this specification's least-significant-first
sequences without changing value or weight. Redundant high zeroes, which they
ignore as representation spelling, are forbidden here and do not affect the
theorem. This result MUST NOT be generalized to arbitrary integer digits, a
different cost metric, another radix, or another width without a theorem whose
hypotheses match that profile.

### 3.6 Derived mass and bounded-profile theorems

For a NAF coefficient `c`, define its unsigned digit mass

```text
NAFMass(c) = sum_(e : d_e(c)!=0) 2^e.
```

For every nonzero integer,

```text
NAFMass(c) <= 2*abs(c)-1.
```

Proof: by digitwise negation take `c>0`. Let `P` and `N` be the total powers at
positive and negative digit positions. The highest position `h` is positive,
so `P>=2^h`; non-adjacency gives `3*N<=2^h-1<=P-1`. Since
`c=P-N` and `NAFMass(c)=P+N`, the displayed inequality follows. Equality holds
only when both inequalities are equalities: there are no lower positive
digits, `h=2*k`, and every allowed negative position
`h-2,h-4,...,0` is occupied. Conversely that pattern attains equality, so the
equality cases are exactly

```text
c = +/-(2^(2*k+1)+1)/3,  k>=0.
```

For coefficients `c_p`, with `S=sum_p abs(c_p)` and
`t=count{p:c_p!=0}`,

```text
sum_p NAFMass(c_p) <= 2*S-t.
```

This is a schedule-independent absolute-sum bound for the ordinary logical NAF
contributions. It bounds every partial sum of a direct support walk, ordinary
plane sum, or the plane-Horner recurrence in section 10.3. It does not prove
the peaks of an algebraically transformed decomposition, epilogue, fused
lowering, or another intermediate whose terms differ; those retain their own
exact bound obligations.

For a registered two's-complement source width `w` in `{8,16,32,64}`, the NAF
length satisfies the sharper bound `ell<=w`, with equality at
`c=-2^(w-1)`. Indeed, that endpoint is the one-digit power at exponent
`w-1`; every other admitted nonzero value has `bitlen(c)<=w-1`, so section
3.5 gives `ell<=w`. During the reference normalizer,

```text
max abs(n-d) = 2^(w-1),
abs((n-d)/2) <= 2^(w-2).
```

The positive value `n-d=2^(w-1)` occurs at `n=2^(w-1)-1`, so a direct signed
materialization needs `w+1` bits; the quotient fits a signed `w`-bit state.
These are sufficiency and necessity statements about that direct
materialization, not a prohibition on another proved exact representation.

For completeness, if `n` is even then `d=0` and the bound is the source-range
bound. If `n` is odd, the selected `d` is `+1` or `-1`; the two source
endpoints adjacent to a multiple of four show that `n-d` remains in
`[-2^(w-1),2^(w-1)]`. Division by two gives the quotient bound, and the stated
positive endpoint proves the extra direct sign bit is necessary.

## 4. Adapter A: integers and tensors

### 4.1 Integer objects

An integer UOR-NAF object contains one logical integer and no mathematical
machine-width restriction. Its semantic coefficient-domain identifier is
exactly `uor-naf/integer-z/1`.

Every artifact also carries one required storage-profile identifier. V1
registers:

- `uor-naf/math-int/1`, with no source-width bound;
- `uor-naf/twos-i8/1`, `uor-naf/twos-i16/1`, `uor-naf/twos-i32/1`, and
  `uor-naf/twos-i64/1`, requiring the value to fit the named two's-complement
  source type.

This is a closed v1 list. The artifact field MUST byte-equal one of these five
identifiers; any other value is invalid rather than unresolved. For a registered
`uor-naf/twos-i{w}/1` member, the exactly decoded value `c` MUST satisfy

```text
-2^(w-1) <= c <= 2^(w-1)-1.
```

Violation is artifact-profile invalidity under that declared bounded storage
profile; the decoded integer remains a valid semantic object and may be carried
by another admitted storage profile. It is not a resource refusal. NAF length
may reject some impossible values early, but length alone MUST NOT establish
range membership.

The storage profile is artifact metadata. It does not occur in semantic
payload bytes and does not change mathematical normalization.

### 4.2 Tensor objects

A mathematical tensor object is the pair of a finite shape and its exact
index-to-value map. Its v1 semantic serialization has one canonical traversal:
row-major, with the last axis varying fastest. A tensor object consists of:

- a finite shape `(s_0, ..., s_(r-1))` with every `s_i >= 0`;
- a declared traversal order; v1 fixes this to row-major;
- exactly `product(s_i)` mathematical integer coefficients in coefficient
  domain `uor-naf/integer-z/1`;
- one required registered storage profile from section 4.1, which is part of
  artifact identity only and whose range constraint applies to every
  coefficient.

The `order=01` field asserts that canonical traversal; it is not a choice among
v1 spellings. Any future artifact traversal must decode back to the same
canonical semantic row-major sequence or use a new version whose identity law
is explicitly registered. It MUST NOT create two semantic spellings for one
tensor within the same domain.

Each coefficient is normalized independently. NAF adjacency resets at each
coefficient boundary. Two neighboring tensor elements do not share a digit
stream and cannot violate or satisfy each other's non-adjacency condition.

Rank-zero tensors contain one scalar. A shape with a zero extent contains zero
coefficients. Both cases are valid and distinct.

### 4.3 Tensor laws

The adapter MUST establish:

- shape and traversal order determine one coefficient order;
- decoding every coefficient reconstructs the tensor exactly;
- tensor encode/decode is a bijection for the declared tensor type;
- changing a storage tier without changing decoded coefficients preserves the
  mathematical tensor but MAY produce a different artifact address;
- arithmetic consumes decoded coefficients. A shift/add implementation based
  on NAF is a factorization of multiplication, not a second numerical method,
  and MUST be byte-equivalent to the exact reference result.

## 5. Adapter B: UOR Atlas address words

### 5.1 Atlas parameters and alphabet

An Atlas instance declares positive integers `(q,T,O)`. Define

```text
class_count = q*T*O
Sigma       = class_count * 2^(O-1).
```

An Atlas symbol is an integer `s` with `0 <= s < Sigma`. A word is a finite
sequence `w = (s_0, ..., s_(k-1))`, including the empty word.

When a symbol is constructed from Atlas coordinates, v1 uses:

```text
class = (T*O)*h2 + O*d + l
symbol = class_count*leaf + class
```

with `0<=h2<q`, `0<=d<T`, `0<=l<O`, and `0<=leaf<2^(O-1)`. This construction is
a source of symbols, not a replacement for the range definition above.

The exact alphabet-order identifier is `uor-atlas/belt-positional/1`:
refinement leaf is the major component, and within the class index `l` varies
fastest, then `d`, then `h2`. V1 also fixes the word-to-integer identifier
`uor-atlas/shortlex/1`. Both identifiers occur in semantic and artifact
payloads; another ordering or ranking requires a new registered identifier.

The adapter does not define how content is embedded into the carrier, how a
carrier vector selects a symbol, or whether a word is behaviorally sufficient.
Those are upstream addressing questions.

### 5.2 Shortlex bijection with the nonnegative integers

The word layer uses length-first, then lexicographic, enumeration. Define

```text
S_Sigma(k) = sum_(j=0)^(k-1) Sigma^j
```

with `S_Sigma(0)=0`, and define

```text
rank_Sigma(w)
    = S_Sigma(k)
    + sum_(j=0)^(k-1) s_j * Sigma^(k-1-j).
```

For `Sigma>1`, `S_Sigma(k)=(Sigma^k-1)/(Sigma-1)`. The summation definition is
normative because it also covers `Sigma=1`, where the unique word of length
`k` has rank `k`.

Words of length `k` occupy exactly the half-open interval

```text
[S_Sigma(k), S_Sigma(k+1)).
```

Thus the empty word maps to `0`, symbol zero is preserved, leading and trailing
zero-valued symbols are preserved, and every nonnegative integer names exactly
one finite word. No delimiter symbol is added to the Atlas alphabet.

The UOR-NAF of an Atlas word is

```text
normalize_integer(rank_Sigma(w)).
```

### 5.3 Inverse

To decode an Atlas-word UOR-NAF under `finite-word`:

1. evaluate its core NAF to an integer `N` and require `N>=0`;
2. find the unique `k` such that
   `S_Sigma(k) <= N < S_Sigma(k+1)`;
3. set `r=N-S_Sigma(k)`, so `0<=r<Sigma^k`;
4. decode `r` as exactly `k` base-`Sigma` digits, most-significant first,
   retaining leading zeroes.

Step 2 MUST return the unique `k` only after verifying both bounding
inequalities with exact integer arithmetic. An approximate estimate MAY seed an
exact search but MUST NOT decide a boundary without those checks. For
`Sigma=1`, set `k=N`.

The exact reference search for `Sigma>1` uses binary lifting. Define blocks

```text
P_i = Sigma^(2^i)
Q_i = S_Sigma(2^i)
```

from

```text
P_0=Sigma, Q_0=1
P_(i+1)=P_i^2
Q_(i+1)=Q_i*(1+P_i).
```

Generate blocks through the first `H` with `Q_H>N`. Initialize
`(k,p,q)=(0,1,0)`. For `i=H-1,...,0`, compute `q'=q+p*Q_i`; when `q'<=N`, set

```text
q:=q', p:=p*P_i, k:=k+2^i.
```

On completion, `q=S_Sigma(k)`, `p=Sigma^k`, and
`q<=N<q+p=S_Sigma(k+1)`. This uses `O(log(k+1))` exact big-integer
additions/multiplications; it makes no claim that variable-size bit operations
are unit cost. Any other proved exact search is conforming. Reconstructing an
explicit `k`-symbol word remains `Theta(k)` output work. For `Sigma=1`, the
result is the unique length-`N` word of zero symbols and MAY remain represented
canonically by its length until an explicit materialization is requested. An
input evaluating to a negative integer is not an Atlas-word object.

For each `k`, fixed-length base-`Sigma` notation is a bijection from the
length-`k` words to `[0,Sigma^k)`, including the singleton case `Sigma=1`.
Because `S_Sigma(k+1)-S_Sigma(k)=Sigma^k`, the length intervals are disjoint,
consecutive, begin at zero, and cover the nonnegative integers. This proves
both rank/inverse round trips.

### 5.4 Atlas-word laws

For the `finite-word` policy, the adapter MUST establish:

- `rank_Sigma` is a bijection from `Word(Sigma)` to the nonnegative integers;
- the inverse above is total on every nonnegative integer;
- empty word, zero-valued symbols, word order, and word length are preserved;
- `decode(encode(w)) = w`;
- parameters `(q,T,O)` are part of the typed domain and both payload types;
- the same digit stream under different parameters does not identify the two
  typed words;
- NAF non-adjacency concerns binary exponent positions in `rank_Sigma(w)`, not
  positions in `w`;
- if a nonzero rank has NAF length `ell` and `Sigma>=2`, its recovered word
  length satisfies the exact size relation

  ```text
  Sigma^(k-1) <= S_Sigma(k) <= N < 2^ell,
  ```

  hence `k<=ceil(ell/log2(Sigma))`. This is a derived bound, not permission to
  decide a boundary with approximate logarithms.

### 5.5 Profiles

V1 defines two parameter-admission profiles:

- `atlas-parametric`: every `q,T,O >= 1`;
- `atlas-canonical-4-3-8`: exactly `(4,3,8)`.

It separately defines two word-admission policies:

- `finite-word`: every finite word;
- `context-bounded`: only words with length at most `Sigma`, with an overlong
  candidate classified `policy-out-of-domain` rather than truncated or reduced
  modulo `Sigma`.

Under `context-bounded`, the admitted words have `k<=Sigma` and the admitted
ranks are exactly

```text
[0, S_Sigma(Sigma+1)).
```

The bounded decoder MUST reject a rank at or above that upper bound. Its
rank/inverse functions are a bijection only between this bounded word set and
this bounded interval, not between all words and all nonnegative integers.
This outcome is `policy-out-of-domain`: the candidate artifact is not admitted
under its declared word policy, but the same finite word remains a valid
semantic Atlas object and may have a valid `finite-word` artifact. It is not a
malformed semantic word and not a local resource refusal.

The parameter-admission profile and word-admission policy are artifact
metadata and validation warrants, not mathematical meaning. They occur only in
artifact payload bytes. Consequently the same `(q,T,O)` and word have one
semantic payload under both admission profiles and both word policies, while
their artifacts may differ. The declared `(q,T,O)`, alphabet-order identifier,
and shortlex identifier remain semantic. A decoder MUST reject `q=0`, `T=0`,
or `O=0` before evaluating `2^(O-1)`.

For `Sigma=1`, the unique word is completely determined by its length. Section
8.1 therefore serializes only that length and omits the redundant zero-symbol
fields. This retains the total `finite-word` bijection while preventing a short
rank artifact from requiring an exponentially longer semantic preimage merely
to compute its label. A consumer that demands an explicit materialized word MAY
still apply its declared resource policy; the canonical semantic identity does
not require that materialization.

More precisely, at `Sigma=1` the variable portion of the semantic word body is
exactly `uvar(k)=uvar(N)`. Validation, reconstruction, and hashing therefore
perform work proportional to the encoded integer/frame size, not to `k`; no
loop or allocation over implicit symbols is permitted at those gates.

## 6. Adapter C: states and operators

### 6.1 Required semantic domain and functions

Every admitted domain `D` MUST pin its object kind and version, coefficient
domain and canonical basis, carrier dimension or tensor shape, coordinate
order, generator/representation identifier when applicable, composition
convention, and equivalence mode. None is inferred from payload bytes or a
default. The domain descriptor mechanism in section 6.4 binds those fields and
all dynamic instance parameters.

Let `X_D` be the exact valid carrier of `D` after every registered membership
condition, and let `Canonical_D` be a declared subset of `X_D`. Section 6.4.1
constructs this carrier explicitly for a structural domain. The adapter
requires four distinct maps/procedures followed by the shared normalizer:

```text
Can_D          : X_D -> Canonical_D
Ser_D          : Canonical_D -> ByteString
Parse_D        : ByteString -> Canonical_D or reject
InjectBytes_1  : ByteString -> positive integer
normalize_integer : integer -> CoreNAF
```

`Can_D` selects a semantic representative. `Ser_D` is an injective
serialization of that representative. `Parse_D` is its strict partial inverse.
`InjectBytes_1` is the reversible `E_Bytes` map in section 6.5. NAF is a
transport recoding. Serialization, parsing, injection, normalization, and
addressing MUST NOT be called semantic canonicalization.

For the declared semantic equivalence `~_D`, the profile MUST prove or
externally warrant:

- **Soundness:** `Can_D(x) ~_D x`.
- **Completeness:** `Can_D(x)=Can_D(y)` exactly when `x ~_D y`.
- **Idempotence:** because `Canonical_D` is a subset of `X_D`,
  `Can_D(Can_D(x))=Can_D(x)` is well typed.
- **Serialization injectivity within `D`:** `Ser_D(c1)=Ser_D(c2)` exactly when
  `c1=c2`. Cross-domain separation is supplied by the outer domain tag and the
  domain descriptor, not by `Ser_D` alone.
- **Canonical parse recognition:** the strict parser accepts `b` and returns
  `c` with complete consumption exactly when `b=Ser_D(c)`. Thus parse
  round-trip, rejection of alternate spellings, and uniqueness of the parsed
  representative all hold.
- **Exactness:** no floating tolerance, nondeterministic ordering, host layout,
  or evaluation schedule influences the representative or bytes.

If these conditions are unavailable, the object type is not admitted. Hash
agreement cannot discharge semantic completeness.

### 6.2 Exact and quotient profiles

Every state/operator profile MUST declare one of:

- `exact`: equality means equality of the exact canonical coefficients, basis,
  dimensions, and metadata;
- `ray-state`: nonzero vectors are quotiented by all nonzero scalars in a
  declared field;
- `matrix-up-to-scale`: nonzero matrices are quotiented by all nonzero field
  scalars;
- `PGL`: invertible matrices are quotiented by all nonzero field scalars;
- `PU`: unitary matrices are quotiented only by their declared exact phase
  subgroup;
- another named quotient with an explicit equivalence and canonicalizer.

For a ray-state, matrix-up-to-scale, or PGL object over a field, a permitted
canonicalizer is: flatten in the declared basis order, find the first nonzero
coefficient, and divide every coefficient by it, making that coefficient
exactly one. The zero object is excluded from those quotient profiles but
remains valid in an exact profile. For normalized input states, this pivot
representative may no longer be normalized; it remains in the declared ambient
`X_D`. A PU phase quotient is narrower than arbitrary scaling and MUST provide
a separate exact canonicalizer; the pivot rule is not automatically valid for
PU. The scalar field, conjugation where needed, phase subgroup, and canonical
coefficient encoding MUST be pinned.

An exact state serializes every coefficient in basis order. An exact operator
serializes its matrix in declared row-major basis order; a permutation operator
MAY instead use its complete image tuple. Exact symbolic profiles such as
`Q(zeta_24)` or a Laurent extension MUST pin a unique basis and reduced rational
spelling. Rounded complex values and residual tolerances are not identity
profiles.

Quantum phase, field negation, and NAF digit sign are separate structures.

### 6.3 Typed sequences and evaluated objects

The following are separate domains and MUST carry separate subtype values in
their domain descriptors:

- `operator-sequence/syntax`: the generator word itself;
- `operator/evaluated`: the canonical exact operator denoted by that word;
- `state/terminal`: the canonical final state from a declared initial state;
- `state/trajectory`: the ordered sequence of all states;

The subtype, registry-entry `kind`, and outer tag MUST satisfy this complete v1
mapping:

| Subtype | Registry `kind` | Outer tag |
|---|---|---|
| `operator-sequence/syntax` | `operator` | `05` |
| `operator/evaluated` | `operator` | `05` |
| `state/terminal` | `state` | `04` |
| `state/trajectory` | `state` | `04` |

A decoder MUST validate the subtype-to-kind row and then require that `kind`
equal the outer-tag name. It MUST NOT infer kind from a subtype prefix.

An execution trace is not a state or operator and is outside the v1 domain-tag
set. A future trace profile requires a new outer tag or version rather than
being mislabeled as a state or operator.

For column vectors and left-to-right program execution, a profile MAY declare

```text
Rep(g_0,...,g_(m-1)) = Rep(g_(m-1))*...*Rep(g_0)
s_(i+1) = Rep(g_i)*s_i.
```

If another convention is used, it MUST have another pinned profile. Different
syntax objects may have one evaluated-operator object; different operators may
produce one terminal state on a particular input.

### 6.4 Versioned domain descriptors and fixture registrations

A state/operator domain descriptor has the exact byte grammar, using the
length framing defined in section 7.1:

```text
55 4f 52 44 4f 4d 01 00
bytes(registry_id)
32 raw registry-entry SHA-256 bytes
bytes(instance_parameters)
```

The header is ASCII `UORDOM`, version byte `01`, and reserved byte `00`.
`registry_id` has this exact ASCII grammar:

```text
ALNUM       = lowercase a-z or digit 0-9
INNER       = ALNUM or "-" or "." or "_"
segment     = ALNUM, or ALNUM followed by zero or more INNER and a final ALNUM
registry_id = segment followed by zero or more ("/" segment)
```

It is one opaque identifier. Empty segments, uppercase or non-ASCII bytes,
leading/trailing punctuation, percent escapes, path normalization, and input
rewriting are invalid; no alternate spelling resolves to the same identifier.
The fixed digest field is exactly

```text
SHA-256(exact canonical registry-entry JCS UTF-8 bytes).
```

It is a typed descriptor field, not a kappa and not a payload commitment. The
registry entry MUST bind every static field listed in section 6.1, including
one subtype/kind row from section 6.3 and the exact grammar of
`instance_parameters`. Its raw digest in the descriptor makes a changed entry
a different domain. The instance parameters MUST injectively bind every
dynamic dimension and representation parameter.

The descriptor parser MUST consume the complete `bytes(domain_descriptor)`
frame. Its parameter parser MUST consume the complete
`bytes(instance_parameters)` subframe under the resolved entry's exact grammar.
Residual bytes in either frame, an alternate JCS spelling, or an alternate
parameter spelling are invalid.

Domain-contract resolution is decentralized and content-addressed. Its exact
lookup key is

```text
RegistryKey = (registry_id, registry_entry_digest).
```

A resolver returns candidate entry bytes or reports them unavailable.
Transport, discovery, caching, mirroring, and governance are outside semantic
identity. A validator first hashes returned candidate bytes and requires exact
equality with `registry_entry_digest`. A digest mismatch rejects that resolver
response and leaves the key unresolved; it does not make the committed
descriptor malformed. Digest-matching bytes establish content identity only.
They are then required to be canonical JCS satisfying the admitted registry
schema. Failure of this second gate is the `invalid` outcome. Treating the
digest as a unique content name uses the section-2 collision-resistance
assumption. If distinct byte strings with the same `RegistryKey` are actually
observed, the declared content-commitment assumption has failed. Validation
enters `commitment-failure`, fails closed, and admits neither byte string by
digest choice. This outcome does not classify the committed descriptor as
semantically malformed.

A **domain-admission context** is the exact finite map used for one validation
or execution claim. For every admitted `RegistryKey` it binds the exact entry
bytes and schema, domain-warrant roots, parser and verifier revisions,
certificate grammars, trusted-base assumptions, and explicit exclusions.
Context equality is extensional equality of these bound records. A persisted
or addressed context requires its own injective canonical grammar; v1 registers
no standalone registry-snapshot wire object. After resolution, a conforming
consumer distinguishes these states:

| State | Meaning |
|---|---|
| `invalid` | descriptor syntax, digest-matching entry JCS/schema, parameter grammar, subtype/kind, outer tag, domain value, membership, or canonicality fails |
| `unresolved` | the exact committed entry bytes are unavailable |
| `unsupported` | the entry is valid, but the consumer does not implement its declared coefficient/domain operations |
| `unadmitted` | the entry is implemented, but required domain/refinement warrants are absent, revoked, or not trusted under the local policy |
| `commitment-failure` | distinct entry byte strings have been observed for one `RegistryKey`; the content-commitment assumption required for digest-only identity has failed |
| `accepted` | exact entry bytes, descriptor, parameters, implementation capability, and required warrants are all admitted |

Only `invalid` is semantic invalidity. `commitment-failure` is a fatal failure
of a declared identity assumption. The other nonaccepted states MUST NOT be
reinterpreted as another domain. Revocation changes the local admitted-evidence
set and dependent prepared records; it never mutates the immutable entry,
descriptor, semantic payload, or kappa. The two fixture entries in section
6.4.2 are the complete unconditional v1 registry corpus. Any additional entry
is a conditional extension profile and MUST supply its complete entry schema,
domain functions, and warrants before it can reach `accepted`.

Evidence accepted under one domain-admission context MUST NOT be reused under
another unless every consumed record is present unchanged or a separately
verified admission-transition warrant proves continued admission. Resolver or
admission authentication requires a separate typed signed envelope and is
outside v1. The fixture records are bundled normative content and require no
network service; no mutable global registry is assumed.

#### 6.4.1 Structural refinement domains and verified semantic facts

A registry entry MAY define a **structural domain**. For canonical descriptor
parameters `theta`, the semantic contract binds an exact predicate on its
declared parent or ambient exact carrier:

```text
Inv_(D,theta) : X_parent -> {true,false}
X_(D,theta) = {x in X_parent | Inv_(D,theta)(x)}.
```

`Inv_(D,theta)` is semantic membership, not an optimization assertion. For
membership purposes the registry defines `~_D` on `X_parent`; the admitted
domain equivalence is its restriction to `X_(D,theta)`. Membership MUST be
saturated under that ambient relation:

```text
x ~_D y  =>  Inv_(D,theta)(x) = Inv_(D,theta)(y).
```

`Can_(D,theta)` is total only on `X_(D,theta)` and rejects values outside it;
`Canonical_(D,theta)` is its image. `Ser_(D,theta)` and `Parse_(D,theta)` are
scoped to that canonical set and satisfy the exact accepted-image law

```text
Parse_(D,theta)(b) = c with complete consumption
    iff c in Canonical_(D,theta) and b = Ser_(D,theta)(c).
```

The registry entry binds only the stable mathematical contract: the exact
membership predicate, equivalence, canonicalizer and serialization/parse
grammar, coefficient domain, basis, canonical order, and parameter semantics.
Replaceable proofs, theorem implementations, parser/verifier revisions,
certificate grammars, and trusted-base assumptions MUST NOT be placed in that
semantic entry merely to prove the contract. They belong to a separate
**domain warrant** keyed to the registry-entry digest and the exact typed
statement it proves. A warrant is either an identified normative proof in this
specification or, for an external/persisted profile, a separately content-
addressed proof or sound-verifier contract. Updating evidence without changing the
mathematical contract changes the warrant identity, not the domain descriptor
or semantic kappa.

An admitted domain warrant MUST prove the parser-image and membership laws
above and bind its hypotheses, proof or sound verifier, revisions/digests,
certificate grammar when applicable, and trusted-base assumptions. The parser
MAY enforce membership by checking a full representation or by construction—
for example, triangular canonical coordinates that can only decode to a
symmetric operator, sorted unique nonzero coordinates that construct an exact
sparse object, or a complete image tuple that constructs a permutation. If an
instance parameter asserts an object-dependent invariant, the parser MUST check
it against the value, or the grammar MUST make a violation unrepresentable. An
unchecked assertion is invalid.

Instance parameters MUST have one canonical semantic spelling. If two parameter
values induce the same carrier, membership, equivalence, canonical grammar, and
representation semantics, they MUST canonicalize to the same parameter bytes.
Slack descriptions such as multiple nonminimal upper bounds for one unchanged
object are fact statements, not distinct domain instances, unless the bound
independently changes the mathematical type requested by the application.

Every semantic fact used for dispatch MUST have an exact predicate identifier
and typed definition and be invariant under the subject domain equivalence:

```text
x ~_D y  =>  f(x,theta) = f(y,theta).
```

A domain warrant MAY prove facts universally from `Inv_(D,theta)`. A typed
instance-fact certificate MAY instead prove a fact for one object in a general
domain and binds that object's semantic kappa. Unary instance facts bind one
semantic kappa. Relational facts such as commutation, compatible sparsity, or a
shared invariant decomposition bind every participating semantic kappa and
cannot be placed in a one-operand prepared plan.

If an object-derived property does not independently change the mathematical
type, valid-input semantics, equivalence, or canonical grammar, it MUST be a
fact certificate rather than a new `UORDOM`. This prevents arbitrary domain
proliferation while preserving validate-once reuse. Artifact-layout facts bind
the artifact kappa and MUST NOT be promoted to semantic facts. Hardware
availability, memory placement, tile shape, tuning results, expected benefit,
cache warmth, and workload frequency belong to a plan, `X`, or `M`.

A **structural refinement domain** is a structural domain used with an explicit
registered refinement relation `D_s <= D_b`; names create no relation. The
relation statement binds the child and parent registry identifiers/entry
digests, a total exact parameter map

```text
parent_params_(s->b) : Theta_s -> Theta_b,
```

and, for every `theta_s`, a total exact map

```text
iota_(s->b,theta_s) : Canonical_(D_s,theta_s)
                    -> Canonical_(D_b,parent_params_(s->b)(theta_s)).
```

A separate refinement warrant, identified under the same rule as a domain
warrant, proves that this map respects
the declared equivalences and canonicalizers and is injective on semantic
classes. Each use binds a finite relation-graph snapshot/digest in its consuming
validation context, and in `X` when used by section 10. That snapshot MUST be
acyclic, and alternate paths with the same endpoints MUST have a coherence
proof or remain distinct typed conversions. Later registry edges do not
retroactively change a prior relation or semantic identity.

Operation reuse across the edge additionally binds specialized and base
profiles `P_s` and `P_b` and the caller's registered required-observation
boundary `O_req` for the invocation. `tau_s` is the registered observation map
from the specialized reference output into `O_req`. If the base reference
output has another type, `tau_b` is a total exact transport, reconstruction,
and canonicalization into that same `O_req`. The warrant proves

```text
tau_s(Ref_(P_s)(x))
    = tau_b(Ref_(P_b)(iota_(s->b,theta_s)(x))).
```

The common value MUST be exactly the observation requested by the caller,
including its canonical semantic or artifact payload bytes. When both profiles
already emit that typed observation, both transports are identity. A
noninjective quotient map is valid only when the quotient itself is the
registered requested observation; constant, lossy, or merely convenient
transports cannot justify reuse at a finer boundary. Cross-domain result/cache
reuse requires this invocation-level law; related coefficients or type names
are insufficient. Conversion work is charged unless the exact converted form
is validated initial state in `X`. A base-domain candidate cannot consume a
refined object merely because their names are related, and a refinement-only
candidate cannot consume a base object without an exact membership warrant.

Different domain descriptors remain different semantic payloads and kappas.
The refinement relation does not merge their identities. The descriptor or
instance parameters MUST NOT embed the semantic kappa of the payload that
contains that descriptor; literal self-hashing is circular and invalid. A
later plan, fact record, or certificate MAY bind the already computed semantic
kappa as the subject of its warrant.

A bare `registry_id`, matching descriptor digest, subtype string, or semantic
kappa establishes no structural fact. The descriptor, semantic payload, and
domain serialization bytes must first be resolved, rehashed, strictly parsed,
and accepted with an admitted domain warrant, or the exact previously validated
fact record must be present in `X`. The kappa identifies the subject of that
evidence; it is not the evidence.

#### 6.4.2 Fixture registrations

V1 registers two small exact fixtures so this adapter is testable without an
external quantum-domain registry.

`uor-naf.fixture/state-z-vector/1` has the following one-line JCS entry:

```json
{"basis":"standard","carrier":"integer-vector","coefficient_domain":"uor-naf/integer-z/1","composition":"none","dimensions":"instance","equivalence":"exact","kind":"state","parameter_schema":"uvar(dimension);dimension>=0","representation":"coordinates/row-major/1","schema":"uor-naf-domain-registry/1","subtype":"state/terminal"}
```

Its entry digest is
`sha256:1b317c3af3b89a3bb6af57667437dc8bbfe1323dfd722b0133a743c8a5c308f7`.
Instance parameters are `uvar(dimension)`. `Can_D` is identity and `Ser_D`
concatenates exactly `dimension` signed-integer primitives from section 8.1.

`uor-naf.fixture/operator-z-matrix/1` has the following one-line JCS entry:

```json
{"basis":"standard","carrier":"square-integer-matrix","coefficient_domain":"uor-naf/integer-z/1","composition":"column-vector/left-action/rightmost-first","dimensions":"instance","equivalence":"exact","kind":"operator","parameter_schema":"uvar(dimension);dimension>=0","representation":"matrix/row-major/1","schema":"uor-naf-domain-registry/1","subtype":"operator/evaluated"}
```

Its entry digest is
`sha256:5538cb9562d2bba20627a80cc65c94abe47d9848fff835be363e701065a5af73`.
Instance parameters are `uvar(dimension)`. `Can_D` is identity and `Ser_D`
concatenates exactly `dimension^2` signed-integer primitives in row-major
order. Both fixture parsers consume all bytes and check counts without
wraparound.

The following in-specification warrant discharges both fixture domains. Their
carriers are, respectively, all integer vectors of the declared dimension and
all square integer matrices of that dimension, with exact equality; hence the
identity canonicalizer is total, sound, complete, and idempotent. Section
8.1's signed-integer primitive is injective and prefix-decodable. Parsing
exactly `dimension` or `dimension^2` such primitives in the fixed order and
requiring end-of-frame is therefore the exact inverse image of the stated
serializer. Equal serialized bytes imply equal component sequences, and equal
component sequences serialize equally. The dimension `uvar` has one canonical
spelling, the product is computed without wraparound, and the registered
subtype/kind rows match the outer tags. Thus these two bundled entries are
admitted under their normative fixture warrant without an external resolver or
proof service.

These fixtures demonstrate the adapter contract; they are not claims that
integer vectors or matrices are the intended final UOR quantum profiles.

### 6.5 Byte-string injection

For domain serialization bytes `b = (b_0, ..., b_(m-1))`, define

```text
uint_be(b) = sum_(j=0)^(m-1) b_j * 2^(8*(m-1-j))
E_Bytes(b) = 2^(8*m) + uint_be(b).
```

The high sentinel bit preserves the byte length and every leading zero byte.
The empty byte string maps to `1`.

The UOR-NAF of a state or operator `x` is

```text
normalize_integer(E_Bytes(Ser_D(Can_D(x)))).
```

To invert it, evaluate the NAF to `N`, require `N>0`, require the highest set-bit
index to be divisible by eight, subtract that sentinel bit, and emit exactly
the indicated number of big-endian bytes before invoking the pinned `Parse_D`
parser.

### 6.6 What this layer does not claim

The arithmetic NAF core does not solve a group word problem, braid equivalence,
isotopy, projective equivalence, gauge equivalence, or operator
canonicalization. A registered adapter MAY supply such a canonicalizer only
with the separate exact contract and proof obligations in sections 6.1–6.2;
NAF then preserves its result.

A raw generator word MAY be admitted under an `exact-syntax` profile. In that
case it represents that exact word, not the operator denoted after applying
relations. Two distinct words that evaluate to the same operator remain
distinct unless an operator-level canonicalizer is explicitly selected. Exact
evaluation decides equality in the chosen representation; the reverse
implication to equality in an abstract presented group requires faithfulness or
a separate complete rewrite system and MUST NOT be assumed.

An approximate synthesis result is a typed program-plus-certificate artifact.
It is not a canonical state or operator, and a numerical tolerance MUST NOT be
promoted into an equivalence relation for identity.

## 7. Canonical digit bytes

### 7.1 Unsigned integers

`uvar(n)` is minimal unsigned LEB128:

- seven payload bits per byte, least-significant group first;
- the high bit is one exactly when another byte follows;
- zero is the single byte `00`;
- a multi-byte spelling whose final payload group is zero is forbidden.

This rule represents every nonnegative integer and imposes no mathematical
width limit.

Its exact encoded length is

```text
L_uvar(0)=1
L_uvar(n)=ceil(bitlen(n)/7),  n>0.
```

Throughout the binary grammars,

```text
bytes(b) = uvar(length_in_bytes(b)) || b.
```

The length counts bytes, not Unicode scalar values or NAF digits. Before
slicing, allocating, or iterating a `bytes` value, a parser MUST compare its
arbitrary-precision declared length with the bytes remaining in that frame. A
`bytes` parser returns exactly one field and its consumed length; its enclosing
grammar decides whether another field follows and requires complete consumption
at the applicable outer boundary.

Every enclosing payload and every `bytes(...)` value is a finite frame. Before
converting any decoded count to a machine index, allocating from it, or entering
a count-controlled loop, a decoder MUST use checked or arbitrary-precision
arithmetic to prove that the minimum canonical bytes required by that count fit
in the unread part of the applicable frame. Failure of a necessary frame bound
is invalid truncation or count mismatch, not a resource refusal. Passing a
minimum bound is not acceptance; exact element parsing and complete consumption
remain mandatory. A syntactically feasible count that exceeds an explicit
local resource policy may instead produce resource refusal. A count's
mathematical value is never itself an allocation instruction; streaming parsing
and incremental hashing are conforming.

### 7.2 Packed core NAF

A core NAF sequence of length `ell` is encoded as `CoreNAFBytes`:

```text
uvar(ell) || packed_digits
```

Each digit occupies two bits:

```text
00 =  0
01 = +1
10 = -1
11 = invalid
```

Exponent positions increase through successive two-bit fields, from the low
two bits of the first byte upward. Four positions occupy one byte. Unused high
fields in the final byte MUST be zero.

A prefix decoder first decodes minimal `uvar(ell)`, proves
`ceil(ell/4)<=remaining_bytes` before allocation, then consumes exactly that
many packed bytes and returns both the value and consumed length. This permits
unambiguous concatenation of tensor coefficients. An exact-field or standalone
decoder additionally requires end-of-field or end-of-input after those
consumed bytes.

For a canonical integer `n` with NAF length `ell(n)`, the exact core size is

```text
L_core(n) = L_uvar(ell(n)) + ceil(ell(n)/4).
```

If `b=bitlen(n)`, section 3 gives the all-integer bound

```text
L_core(n) <= L_uvar(b+1) + ceil((b+1)/4).
```

For a signed `w`-bit storage profile the sharp `ell<=w` bound gives

```text
L_core(n) <= L_uvar(w) + ceil(w/4).
```

The exact worst cases for the registered profiles are:

| Profile | Raw source | Maximum `CoreNAFBytes` | Expansion factor |
|---|---:|---:|---:|
| `twos-i8` | 1 byte | 3 bytes | 3.000 |
| `twos-i16` | 2 bytes | 5 bytes | 2.500 |
| `twos-i32` | 4 bytes | 9 bytes | 2.250 |
| `twos-i64` | 8 bytes | 17 bytes | 2.125 |

The packed-core factor tends to two as `w` grows; framing prevents a claim that
every individual value is compressed.

The decoder MUST reject:

- digit code `11`;
- adjacent nonzero fields;
- a nonempty stream whose highest digit is zero;
- truncation before the payload length implied by `ell`;
- nonzero final padding;
- a non-minimal `uvar`.

Zero is `00`: a zero length and no packed payload.

### 7.3 Typed envelope

Every canonical UOR-NAF object begins with the eight bytes

```text
55 4f 52 4e 41 46 01 00
```

which are ASCII `UORNAF`, version byte `01`, and reserved byte `00`.

The next byte is exactly one domain tag:

```text
01 integer
02 tensor
03 Atlas word
04 state
05 operator
```

The domain tag is followed by `bytes(semantic_kappa)`, binding the artifact to
the semantic object defined in section 8. In v1 this field MUST contain exactly
71 lowercase ASCII bytes: `sha256:` followed by 64 lowercase hexadecimal
digits. Its `bytes(...)` length prefix is therefore the one byte `47`. No other
algorithm, raw-digest form, letter case, or label length is valid; algorithm
agility requires a new outer version. The remaining domain body MUST
contain all information required by its adapter before the packed NAF value or
values. Variable-width natural numbers use `uvar`. Variable byte/text fields
use exactly `bytes(field)` as defined in section 7.1: one `uvar` byte-length
prefix followed by the raw field bytes. Every text field in the completed v1
outer grammars is US-ASCII
and MUST byte-equal its registered spelling; therefore no general Unicode
normalization procedure is part of base v1. The more specific character rule
for `registry_id` is in section 6.4. A conditional registry-entry or
instance-parameter schema that introduces non-ASCII text MUST pin its exact
character repertoire, byte encoding, and normalization rule (including an
explicit no-normalization rule) with the corresponding versioned dependency;
those rules belong to that extension profile, not the base grammar.

V1 domain bodies are:

```text
integer:
    bytes(coefficient_domain = "uor-naf/integer-z/1")
    bytes(storage_profile)
    CoreNAFBytes

tensor:
    bytes(coefficient_domain = "uor-naf/integer-z/1")
    bytes(storage_profile)
    uvar(rank)
    uvar(shape_0) ... uvar(shape_(rank-1))
    byte(order = 01 for row-major)
    CoreNAFBytes_0 ... CoreNAFBytes_(product(shape)-1)

Atlas word:
    byte(parameter_profile = 01 parametric, 02 canonical-4-3-8)
    byte(word_policy = 01 finite-word, 02 context-bounded)
    bytes(alphabet_order = "uor-atlas/belt-positional/1")
    bytes(word_encoding = "uor-atlas/shortlex/1")
    uvar(q) || uvar(T) || uvar(O)
    CoreNAFBytes(shortlex_rank)

state/operator:
    bytes(domain_descriptor)
    CoreNAFBytes(E_Bytes(Ser_D(Can_D(x))))
```

The tensor entry count is derived from the shape and is not serialized. Before
reading extents, a decoder MUST prove from the remaining frame that at least
`rank` one-byte `uvar` fields plus the order byte can exist. It then parses the
extents streaming, computes the shape product exactly without wraparound, and
proves `product(shape)<=remaining_bytes` because each `CoreNAFBytes` occupies at
least one byte. It MUST consume exactly that many NAF values; the last tensor
axis varies fastest. No individual extent is bounded by remaining bytes when a
different extent is zero.

For integer and tensor artifacts the storage profile MUST be one of the five
closed identifiers in section 4.1, and every exactly decoded coefficient MUST
satisfy its declared range. An unknown profile or range violation is invalid.

The canonical Atlas profile MUST verify `(q,T,O)=(4,3,8)`. `Sigma` and recovered
word length are deliberately derived from the parameters and rank and are
never serialized in the artifact body. A decoder performs comparisons against

```text
Sigma=(q*T*O)*2^(O-1)
```

with checked arbitrary-precision or exact factorized arithmetic. In particular,
`bitlen(Sigma)=bitlen(q*T*O)+O-1`; a decoder SHOULD use bit-length screening and
shifted comparison rather than materializing an unnecessary `O`-bit zero tail.
A declared resource limit may refuse an operation only after preserving the
invalid/unresolved/resource distinction in section 8.3.

A state/operator decoder MUST dispatch only to a pinned profile with the
interface in section 6.1 and descriptor in section 6.4. The bounded-context
word policy MUST verify the recovered word length is at most `Sigma`. Every
decoder MUST reconstruct the semantic payload bytes and canonical semantic
manifest, recompute the semantic label, require it to byte-equal the embedded
`semantic_kappa`, and require the manifest `domain` to equal the outer-tag name
before accepting the artifact. If an external manifest is supplied, it MUST
byte-equal the reconstructed manifest.

Unknown fixed v1 version, outer-domain code, storage profile, Atlas profile
code, order code, digit code, or reserved field is an invalid UOR-NAF object. A
syntactically canonical `UORDOM` descriptor whose committed registry entry is
unavailable is instead unresolved as specified in section 6.4; a resolved
mismatch remains invalid. A future specification uses a new version or fixed
profile code; it does not reinterpret v1 bytes.

### 7.4 Universal accepted-image and complete-consumption law

For every complete canonical grammar `G`, let `Enc_G` serialize its full typed
value and let `Dec_G` be the ideal mathematical parser of one finite exact
frame, with unbounded mathematical counters and no local resource policy. The
grammar is conforming only when

```text
Dec_G(b)=x with complete consumption
    iff x is in Canonical_G and b=Enc_G(x).
```

An operational decoder MAY return the section-8.3 resource-refusal outcome for
a frame that is syntactically feasible but exceeds its declared policy. That
outcome is outside `Dec_G`; it is neither acceptance nor rejection by the ideal
grammar. Whenever the operational decoder accepts, its result and consumed
frame MUST equal `Dec_G`. A frame-impossible count remains ideal and operational
invalidity, not resource refusal.

This law applies separately to `uvar`, `bytes`, signed integers,
`CoreNAFBytes`, each semantic body, each artifact body, `UORDOM` descriptors,
instance-parameter subframes, domain serialization, and canonical manifests.
The typed artifact value includes its domain, storage/admission metadata, and
semantic-parent binding; intentionally different artifacts are not collapsed
to their decoded mathematics for this law. A syntactically canonical but
unresolved `UORDOM` descriptor may satisfy descriptor parsing while its
state/operator semantic object remains unaccepted. Every enclosing semantic or
artifact decoder MUST reject trailing bytes, alternate field order, alternate
text spelling or profile-defined normalization, alternate integer spelling, or
any other second spelling of one typed canonical value.

For the completed v1 grammars this law follows structurally. Minimal `uvar` is
injective and prefix-decodable; `bytes` adds its unique byte length and consumes
exactly that frame. The signed-integer sign codes have disjoint images, and
their nonzero magnitudes use minimal `uvar`. A canonical NAF fixes `ell`, every
two-bit digit, the final padding, and therefore one `CoreNAFBytes` image. Fixed
headers, tags, reserved bytes, field order, and exact text spellings distinguish
the envelope alternatives. Tensor rank and shape determine one exact
coefficient count and order. Atlas parameters determine the semantic grammar
branch; at `Sigma=1` length determines the sole word, and at `Sigma>1` the
length determines the exact symbol count. A resolved state/operator descriptor
uses the admitted `Parse_D` accepted-image law. Finally, each manifest is the
one RFC 8785 serialization of its fixed typed member map. Composition of these
injective, completely consumed fields proves the accepted-image law for every
completed base payload and, conditionally, for each admitted external domain.

Consequently the integer, tensor, and Atlas semantic payload encodings are
injective on their typed domains: their fixed tags and identifiers select the
domain, and the remaining fields recover the exact integer; shape and ordered
coefficient map; or parameters and finite word. State/operator semantic
injectivity is exactly the corresponding admitted `Can_D`/`Ser_D` obligation.

## 8. Semantic and artifact addressing

UOR-NAF exposes two typed labels. The semantic label names the exact typed
semantic payload independently of the `UORNAF` artifact transport and of
artifact-only storage or admission metadata. “Typed” is load-bearing: Atlas
alphabet-order and word-to-integer identifiers, and a state/operator's
`UORDOM` descriptor and registered `Ser_D`/`Parse_D` grammar, are semantic
identity. Changing one of those contracts creates another typed semantic
payload; it is not a lossless transport change. The artifact label names this
exact v1 NAF-bearing representation and binds it to its semantic parent.

### 8.1 Semantic payload bytes

Semantic bytes begin with

```text
55 4f 52 53 45 4d 01 00
```

which is ASCII `UORSEM`, version byte `01`, and reserved byte `00`, followed by
the same one-byte domain tags as section 7.3.

Define a canonical signed integer primitive:

```text
00                         zero
01 || uvar(n)              positive n, with n>0
02 || uvar(abs(n))         negative n
```

The first byte is a closed sign code. A byte other than `00`, `01`, or `02` is
invalid. Code `00` terminates the primitive and has no magnitude. Codes `01`
and `02` are followed by exactly one minimal `uvar` magnitude greater than
zero. The enclosing grammar determines whether another field follows.
Semantic domain bodies are:

```text
integer:
    bytes(coefficient_domain = "uor-naf/integer-z/1")
    signed_integer

tensor:
    bytes(coefficient_domain = "uor-naf/integer-z/1")
    uvar(rank)
    uvar(shape_0) ... uvar(shape_(rank-1))
    byte(order = 01 for row-major)
    signed_integer_0 ... signed_integer_(product(shape)-1)

Atlas word:
    bytes(alphabet_order = "uor-atlas/belt-positional/1")
    bytes(word_encoding = "uor-atlas/shortlex/1")
    uvar(q) || uvar(T) || uvar(O)
    uvar(word_length)
    if Sigma = 1: no symbol fields
    if Sigma > 1: uvar(symbol_0) ... uvar(symbol_(word_length-1))

state/operator:
    bytes(domain_descriptor)
    bytes(Ser_D(Can_D(x)))
```

The Atlas branch is determined by the already decoded positive parameters. At
`Sigma=1`, `word_length` denotes the unique word of that many zero symbols;
any per-symbol field is residual data and invalid, and validation/hashing MUST
NOT expand the word into repeated zero bytes. At `Sigma>1`, exactly
`word_length` minimal `uvar` symbols follow and each MUST be below `Sigma`.
Before entering that loop, the decoder MUST require
`word_length<=remaining_bytes`, since every symbol occupies at least one byte.
The `word_encoding` value is the typed word-to-integer law of this completed
Atlas adapter domain, not a storage-profile field; a different law is a
different semantic profile.

All lengths, shapes, orders, profiles, and trailing-byte conditions are checked
exactly. These bytes are transport-independent; in particular, they contain no
NAF digit encoding.

### 8.2 Canonical manifests and the two labels

Kappa is not computed directly over an application-specific binary payload.
First compute the lowercase ASCII payload commitment

```text
payload_sha256 = "sha256:" || lowercase_hex(SHA-256(exact payload bytes)).
```

Let `payload_bytes` be the payload length written as canonical unsigned decimal
ASCII: `0` for zero and otherwise no leading zero. Let `domain` be exactly one
of `integer`, `tensor`, `atlas-word`, `state`, or `operator` according to the
outer tag. The semantic manifest is the following one-line JSON object, with
the metavariables replaced by JSON strings:

```json
{"domain":"<domain>","kind":"semantic","payload_bytes":"<decimal length>","payload_sha256":"sha256:<64hex>","spec":"uor-naf/1-draft.6"}
```

The artifact manifest is:

```json
{"domain":"<domain>","kind":"artifact","payload_bytes":"<decimal length>","payload_sha256":"sha256:<64hex>","semantic_kappa":"sha256:<64hex>","spec":"uor-naf/1-draft.6"}
```

The displayed key order is RFC 8785 lexicographic order. All keys and admitted
values are ASCII, so no Unicode normalization step is applicable; no extra
members or whitespace are allowed in canonical manifest bytes. Unbounded
payload length is carried as a
JSON string, not an interoperably unsafe large JSON number. These manifests
have fixed shallow structure, so payload size does not increase JSON nesting.

The exact draft-0.6 equations are:

```text
semantic_manifest = manifest above for the semantic payload
semantic_kappa    = "sha256:" || lowercase_hex(SHA-256(semantic_manifest))

artifact_manifest = manifest above for the artifact payload,
                    embedding semantic_kappa
artifact_kappa    = "sha256:" || lowercase_hex(SHA-256(artifact_manifest))
```

Each result MUST be exactly 71 lowercase ASCII bytes: `sha256:` followed by 64
lowercase hexadecimal digits. The complete section-7 artifact embeds
`semantic_kappa`. A different lossless transport version MAY have a different
artifact label while retaining the same semantic label. Two registered storage
profiles that decode to the same mathematical integer or tensor have different
artifact payloads and MAY therefore have different artifact labels; because
storage profile is absent from semantic payload bytes, they MUST have the same
semantic label.

The UOR-NAF decoder—not a generic JSON addresser—MUST parse and validate the
typed binary payload, reject every noncanonical spelling, and reconstruct its
manifest. The address transform above consumes only the exact canonical
manifest bytes. Retrieval MUST verify the manifest, expected kind, payload
length, payload digest, exact payload bytes, and for an artifact the embedded
semantic label. Verification is type-directed: equality is tested only between
values of the same declared commitment type and against the exact preimage
named by that type. Equal byte length or an identical `sha256:` surface
spelling never authorizes cross-type substitution.

Normative identity statements are:

- objects in the same completed domain (or the same registered `D`) and related
  by its declared semantic equivalence have identical semantic payload bytes;
- semantic and artifact payloads each round-trip under their strict decoders;
- equal manifest bytes imply equal corresponding labels;
- different labels imply different manifest bytes;
- equal labels imply equal manifest bytes only after byte comparison or under
  the declared SHA-256 collision-resistance assumption.

Hash agreement is not the NAF uniqueness proof and does not establish semantic
canonicalizer completeness. A finite collision-free corpus establishes only
that no collision was observed in that corpus.

Domain tags prevent an integer, tensor, word, state, and operator with identical
payloads from sharing payload bytes. Domain descriptors and Atlas parameters
provide further separation. Kappa provides no authentication, authorization,
secrecy, or provenance; those require separate typed and signed envelopes.

The identifier `uor-naf/1-draft.6` is provisional and belongs to every manifest
preimage. The reserved stable identifier `uor-naf/1` remains unassigned until
the freeze conditions in section 14 are met. Draft and stable labels are
different identities and MUST NOT be relabeled, substituted, or treated as
aliases. If an externally deployed contract has already assigned
`uor-naf/1`, an incompatible successor MUST use a new stable version rather
than retroactively redefining that deployed contract.

### 8.3 Verification and resource safety

Retrieved content MUST be rehashed, strictly parsed, and checked against its
expected object kind. Child references MUST bind expected kind, domain, byte
length, and digest. Raw unframed concatenation is forbidden.

For a `UORDOM` object, verification records its exact
`(registry_id,registry_entry_digest)` key and domain-admission context.
Resolution, entry validation, local admission, strict value parsing, semantic
membership, and semantic-label verification are separate gates; success at an
earlier gate never implies success at a later gate.

A validated semantic-fact record MAY amortize domain membership or invariant
checking only when it binds the semantic kappa, object kind, exact semantic
domain/profile identity, typed fact predicate and parameters, warrant roots,
proof/parser/theorem/verifier revisions, trust assumptions, and the exact
semantic payload bytes or their declared collision-resistant commitment. For a
`UORDOM` state/operator it additionally binds the exact descriptor, registry-
entry digest, and domain serialization bytes. The record is reverified when
first accepted into `X`; thereafter its conclusion may be reused exactly within
that bound validated state. A kappa-only lookup, an unresolved tag, or an
unverified cache entry cannot authorize semantic dispatch.

All size, extent, exponent, and payload-length arithmetic MUST be checked or
arbitrary precision before allocation. A frame-impossible count is invalid
truncation or mismatch under section 7.4. A syntactically feasible object MAY
exceed an implementation's explicit streaming/resource policy; that outcome is
a local resource refusal, not semantic invalidity. A decoder MUST never convert
a mathematical count directly to a bounded machine index before proving the
frame bound, and MUST never truncate, wrap, partially accept, or reinterpret
the object.

Artifact-policy exclusion is a distinct outcome. A canonically framed
artifact whose decoded value lies outside its own registered admission policy,
such as an overlong `context-bounded` Atlas word, is
`policy-out-of-domain`. Its semantic object may remain valid and another
artifact policy may admit it. This is neither malformed-byte invalidity nor a
resource refusal. An exact storage-profile range violation is instead invalid
for that declared artifact profile as specified in section 4.1.

If a verifier actually observes distinct preimage byte strings for one typed
SHA-256 commitment, the declared content-commitment assumption has failed. It
MUST enter fatal `commitment-failure`, admit neither preimage by digest choice,
and MUST NOT classify either semantic object as malformed solely because of the
collision. This is the general form of the `RegistryKey` rule in section 6.4.

NAF length, sign, and weight can leak information. This format is neither an
encryption format nor a constant-time protocol.

## 9. Exact evaluation boundary

UOR-NAF denotes canonical values, not one implementation strategy. Every
registered operation profile follows the semantic boundary

```text
strictly decode canonical inputs -> evaluate the exact reference meaning -> emit the registered canonical observation
```

For example, an exact tensor contraction MAY factor a decoded coefficient as

```text
a * w = sum_i d_i(w) * (a * 2^i),
```

but this is only an alternative realization of the same multiplication. It is
not a second numerical method. Every such realization MUST:

- declare its complete input domain and eligibility predicate;
- prove that its actual intermediate representation, reductions, capacity, and
  reconstruction preserve `Ref_P` for every admitted input and reachable
  schedule state;
- use no undefined behavior, unintended wrap/saturation, or unproved overflow;
  any shift, fused operation, homomorphic reduction, or other primitive MUST be
  proved exact under the registered reference operation;
- evaluate the complete registered operation and emit exactly the requested
  observation bytes. Internal representations, lossless recodings, streaming,
  fusion, and encode scheduling are unconstrained when refinement is proved;
- produce the same required semantic or artifact bytes for every admitted
  input and every successful schedule/resource offer satisfying its declared
  execution contract.

A realization MAY cover only a strict subset of the mathematical domain. Its
ineligibility selects another correct realization; it does not make a valid
input invalid or authorize approximation. If no available realization fits a
local resource envelope, the outcome is a resource refusal rather than a
different mathematical result.

Verified semantic facts MAY discharge a realization's structural eligibility
hypotheses without repeating the check. A realization MAY therefore skip exact
zeros, select a sparse or spectral path, use a finite-permutation lane, or use
another structurally specialized internal representation when the accepted fact
warrant entails its eligibility predicate and its separate refinement theorem
proves the complete required observation. This is a specialized realization of
one `Ref_P`, not a specialized reference meaning.

For a pre-encode observation, the refinement equality MUST hold at the exact
pre-encode mathematical boundary. Equality only after wrap, saturation, or
rounding is usable solely when `Ref_P` itself requests that exact post-encode
observation. Input structure never authorizes an implementation to retag the
result under a refined output domain; that output domain and its invariants
must be required by the operation and proved or validated independently.

Artifact identity and mathematical identity remain distinct. Artifacts that
decode to equal objects have one semantic label under the same semantic profile
and MAY intentionally have different manifests and artifact labels.

A UOR-NAF tensor semantic label names the exact decoded mathematical tensor. A
higher-level result address MUST separately state whether it names an exact
pre-encode mathematical result or a post-encode typed output. For post-encode
meaning, the registered operation/output profile MUST bind the output element
type and encode rule, including wrap, saturation, or correctly rounded floating
behavior.

## 10. Correct and optimal execution over UOR-NAF and the UOR Atlas

UOR-NAF adopts the engineering rule **slow is smooth; smooth is fast** in a
precise sense:

- **slow** is the permanent, exact reference meaning, implemented plainly
  enough to audit;
- **smooth** is every alternative path proving the same observation across
  shapes, schedules, caches, machines, and resource offers;
- **fast** is a cost-minimal or nondominated admitted realization, when one
  exists, under an explicit operation, input, resource envelope, environment,
  candidate universe, and cost order.

Correctness is absolute with respect to the registered reference meaning.
Optimality is always relative to a declared feasible set and cost order; an
unqualified claim of “optimal” is non-conforming. Speed is never obtained by
weakening equality or changing the answer. Nothing in this section changes the
payload bytes, canonical manifest bytes, or kappa labels defined in sections
7–8.

### 10.1 Governing refinement invariant

For every registered operation profile `P`, let

```text
Ref_P : ValidInvocations_P -> RequiredObservation_P
```

be its exact one-invocation mathematical reference meaning.
`RequiredObservation_P` is either the canonical semantic payload bytes, or the
exact artifact payload bytes when the caller requests a particular transport/
storage profile. Lift this meaning to the comparison target space

```text
Targets_P = valid invocations and valid finite request sequences under P

RefTarget_P : Targets_P -> RequiredTargetObservation_P.
```

For one invocation, `RefTarget_P` is `Ref_P`. For a stateful sequence it emits
the ordered reference observation of every request plus the declared final
semantic state, with every intermediate reference state and transition defined
by `P`.

A candidate realization `R` declares a total semantic predicate

```text
Elig_R : Targets_P -> {true,false}
E_R = {z in Targets_P | Elig_R(z)}.
```

For a stateful sequence, `Elig_R(z)` covers every request, intermediate
reference state, transition invariant, and cross-request condition; independent
per-request eligibility is insufficient. `R` is semantically conforming exactly
when

```text
Elig_R(z)  =>  R(z) = RefTarget_P(z)
```

at the required target-observation boundary. It MAY change work, order, layout,
placement, batching, and traversal. It MUST NOT change:

- the mathematical valid-input domain;
- the semantic equivalence or canonicalizer;
- the requested output type or encoding rule;
- any required output byte;
- whether a mathematically valid input is semantically accepted.

Let `Gamma(z)` be the exact facts established for the complete target `z` from
strictly verified domain instances, instance-fact certificates, relational
fact certificates, and registered entailment theorems. Its fact roots and
entailment environment MUST be jointly coherent. If both `Elig_R(z)` and its
negation are derivable, evidence validation fails; `R` is neither admitted nor
pruned from that inconsistent fact set. Otherwise eligibility reasoning is
three-valued:

```text
Gamma(z) entails Elig_R(z)       structural eligibility is discharged
Gamma(z) entails not Elig_R(z)   R may be pruned for z
otherwise                        eligibility is unknown
```

“Unknown” means that neither judgment is derivable. It MUST be resolved by a
direct exact check or additional certificate, or the specialized realization
is not admitted. A check-plus-fallback path is a distinct composite realization
`R'=dispatch(check,R,R_fallback)` with its own identity, total `Elig_(R')`, refinement
theorem, run semantics, and cost. It is available only when already included in
`U` by that universe's declared closure grammar; every check, dispatch,
specialized branch, and fallback branch is charged. Unknown eligibility for
`R` alone never admits it. Absence of a matching fact or domain identifier is
not proof of ineligibility.

A fact about one operand discharges only the corresponding conjunct of an
invocation-wide predicate; counterpart relationships, operation parameters,
output mode, sequence state, and all other conjuncts remain.

A domain-to-eligibility theorem MAY prove that every validated member of one
domain instance satisfies a declared conjunct of `Elig_R`. Its use avoids a repeated
topology scan, but domain membership discharges neither realization refinement,
realization fidelity, resource feasibility, cost, nor optimality. A generic
candidate whose eligibility contains the refined domain remains a candidate.

`Elig_R` contains semantic value and operation conditions only. Machine capacity,
available memory, cache contents, worker count, and scheduling feasibility
belong to `X` and admission. A useful but nonmandatory factorization is

```text
Elig_R(z) = Elig_(R,domain)(z) and Elig_(R,residual)(z),
```

where verified domain facts discharge the first factor while magnitudes,
counterpart relations, and other invocation-specific facts remain in the
second. Neither factor discharges feasibility under `X`.

A proved failure of `Elig_R` selects another exact realization. Lack of a
reusable proof may instead cause the predicate to be checked by a realization
whose semantics already include that check. Neither condition makes the input
invalid. A local resource refusal remains a resource-policy outcome, not a
different answer.

The reference evaluator is permanent audit infrastructure. A conforming system
MUST retain a route that bypasses the selected candidate and the result
caches being tested. Kappa agreement alone is insufficient evidence: the
corresponding manifest and bytes MUST be verified, or reliance on SHA-256
collision resistance MUST be explicit.

### 10.2 Execution plans are artifacts, not meaning

`uor-naf-plan/1-draft.6` is the provisional design identifier for an optional execution-plan
profile. Plan data is derived only from strictly validated inputs and changes
how their meaning is computed, never what they mean. Two reusable types MUST
remain distinct:

- a **prepared-operand plan** binds one source operand semantic kappa, its
  domain/shape/canonical order, derivation revision, refinement warrant, and
  the other-input/operation constraints and `X`-compatibility requirements
  under which it may be used;
  it intentionally does not bind one particular counterpart operand;
- an **execution-plan instantiation** binds the complete ordered invocation,
  every prepared-operand plan it consumes, requested output contract, chosen
  complete system `R`, internal plan universe `V_R`, selected realization/
  combination/lowering, execution contract `X`, cost model `M`, certified
  cost, stable selection policy, resources, and correctness/selection
  warrants. If it participates in an outer optimality claim, it also binds the
  distinct complete-system universe `U_sys` and that claim's coverage warrant.

Every descriptor MUST bind, where applicable:

- its total `Elig_R` predicate and separate `X`-feasibility requirements;
- every coefficient, exponent, depth, coordinate, range, scale, intermediate,
  and intermediate-state capacity or reconstruction bound;
- derivation, realization, implementation, parser, and verifier revisions; and
- every typed theorem, proof, certificate verifier, hypothesis, and assumption
  warranting its eligibility, refinement equality, safety, cost, coverage, and
  claimed optimality.

When a descriptor consumes a registered state/operator domain, it also binds
every consumed `RegistryKey`, the exact domain-admission-context identity, and
the domain/refinement warrant roots used by the plan. A plan admitted under one
context is reusable under another only through unchanged record inclusion or a
verified admission-transition warrant. Exclusion or revocation makes dependent
plan evidence inapplicable; it does not alter the source semantic object.

Any table, tile, transform, or other node depending on a counterpart input is a
fully bound intermediate artifact of an execution-plan instantiation; it MUST
additionally bind every input semantic identity and the exact ranges/scales
specified in section 10.5.

A prepared-operand plan MAY bind reusable unary facts from a validated
structural domain or an instance-fact certificate. It MUST bind the source
semantic kappa, exact domain/profile identity, fact identifiers and parameters,
parser or certificate-verifier revision, and the entailment chain from verified
semantic payload bytes to each fact. For `UORDOM` it also binds descriptor and
registry-entry digests. A relation involving another input is not a unary
operand fact; it belongs to a fully bound execution-plan instantiation and
binds every participating semantic kappa.

A plan may use a structural fact only through an operation-specific theorem
showing that the fact entails the relevant eligibility and refinement
hypotheses. The UOR-native warrant chain is acyclic and typed:

```text
semantic kappa
    -> verified descriptor, semantic payload bytes, and domain membership
    -> verified semantic facts
    -> realization eligibility and RefTarget_P refinement
    -> comparison-contract-bound cost completeness or dominance
    -> scoped optimality
```

Each arrow requires its own registered theorem, certificate, or exact check.
The subject identity can index and amortize this chain; it does not prove any
arrow. In particular, no semantic object or domain fact is an optimality
certificate. A domain-wide optimal selector theorem MAY be reused, but it is a
separate warrant binding the complete `X`, `M`, applicable `U_sys` or `V_R`,
objective/order, and competitor coverage.

Conceptually, warrant conclusions are typed as domain membership, cross-domain
refinement, object property, invocation eligibility, semantic refinement
`R(z)=RefTarget_P(z)`, safety/resource feasibility, certified cost, universe
coverage/dominance, or optimality. Composition is valid only when a parent
conclusion exactly matches a child hypothesis. Combining these types in one
stored container does not collapse their logical conclusions. This conceptual
typing adds no v1 payload tag; an interoperable persisted warrant still needs
the separate grammar and vectors required below.

Operand order is significant unless the operation profile explicitly defines a
canonical commutative ordering. Time, randomness, mutable state, or external
environment data that affects `Ref_P` MUST be supplied as addressed inputs or
the invocation is not eligible for semantic memoization. Factors affecting only
feasibility or cost belong to `X`, not semantic identity.

For every input position `i` whose verified domain descriptor declares an
equivalence `~_(D_i)`, the registered operation MUST be extensional at the
required semantic observation, with every other input fixed:

```text
x_i ~_(D_i) y_i
    => Ref_P(...,x_i,...) = Ref_P(...,y_i,...).
```

If that extensionality is not independently proved, exactly one of three
boundaries MUST apply:

- evaluation and cache-key construction first use the same registered
  canonicalizer `Can_(D_i)`, thereby defining the reference on the canonical
  representative and proving that it factors through `Can_(D_i)`; or
- the operation registers a finer exact semantic input domain, such as
  `operator-sequence/syntax`, in which the distinctions it observes are part of
  mathematical meaning. It MAY cache by that finer domain's semantic kappa,
  but MUST NOT collapse through the coarser equivalence or reuse across domains
  without the exact section-6.4.1 observation bridge; or
- the operation is explicitly artifact-sensitive and binds every exact input
  artifact identity and verified artifact bytes. It is ineligible for semantic-
  result caching and cross-tier reuse.

A semantic cache MUST NOT collapse inputs under an equivalence through which
its registered `Ref_P` does not factor. Exact-syntax semantic identity and
artifact identity remain distinct.

A realization-refinement warrant is either a theorem covering every admitted
target or an instance certificate with a pinned verifier satisfying

```text
Verify(target, result, certificate) = accept
    => result = RefTarget_P(target).
```

Verifier grammar, trusted base, hypotheses, and revisions MUST be bound. A
probabilistic verifier MUST state its error bound and assumptions and cannot by
itself discharge unconditional exact admission; it supports only a
probabilistic/conditional claim unless a separate zero-error verification is
performed. An algorithm-level theorem does not by itself prove that one
compiler output or binary implements that algorithm; realization-level
differential evidence remains required unless the executable is itself covered
by the proof.

Seven identities are distinct:

```text
semantic invocation identity = the exact mathematical request
artifact request identity = semantic invocation plus requested output artifact profile
artifact-sensitive invocation identity = representation-sensitive request plus exact ordered input artifact identities and requested output artifact profile when applicable
fact/warrant identity = a typed statement about bound semantic subject(s) plus evidence
prepared identity    = reusable structure for one semantic operand
execution-plan identity = one realization of the complete invocation
result identity      = the verified semantic or artifact output
```

Many execution-plan identities MAY implement one invocation and produce one
result. Hardware, thread count, scratch layout, tuning data, and cache placement
belong to plan/artifact identity only. A semantic invocation identity excludes
the requested transport/storage artifact profile so semantic results can be
reused across tiers. A finer exact-syntax semantic invocation remains semantic
within its own registered domain. An artifact-sensitive invocation does not
enter that semantic namespace. An invocation identity names a request, not its
answer, and cannot by itself prove that a returned result is correct.

A persisted interoperable fact/warrant, plan, invocation, result record, or
certificate MUST receive its own canonical grammar, strict decoder, and golden
vectors. Until that registration exists, `uor-naf-plan/1-draft.6`, the reserved
`uor-naf-plan/1`, or any fact profile MUST NOT be improvised as a new domain
tag or reinterpretation of `uor-naf/1-draft.6` bytes or later frozen base
bytes.

Plan and fact/warrant objects are declarative data only. Implementation,
eligibility, realization, predicate, verifier, and certificate identifiers MUST
resolve through a locally admitted registry entry whose canonical digest is
bound by the consuming object. Unknown or digest-mismatched entries are
rejected before execution. Such an object MUST NOT directly supply executable
code, dynamic-library paths, commands, URLs, native addresses, or an arbitrary
predicate.

### 10.3 Exact NAF execution plans

The concrete candidate families in this subsection use a registered rank-2
exact matrix-product profile with `A` of shape `(m,k)`, integer coefficient
matrix `W` of shape `(k,n)`, and raw product `Y=A*W` of shape `(m,n)`. Another
tensor rank or contraction map requires its own registered index semantics and
refinement, but may use the same principles. When the registered operation has
scaling, an initial object, or an epilogue, its whole reference meaning is
written

```text
Z = s_prod * (A*W) + s_acc * C_0
Out_P = Epi_P(Z)
Ref_P(A,W,C_0,s_prod,s_acc,...) = Observe_P(Out_P).
```

The profile fixes whether each term exists. `C_0`, when present, is an exact
initial object whose coefficient domain and shape are fixed by `P`; `s_prod`
and `s_acc` are exact registered scalars; `Epi_P` is a registered total exact
map from `Z` to the profile's exact output object; and `Observe_P` is the
registered total canonical map from that object to `RequiredObservation_P`.
No scale, accumulator term, epilogue, or observation encoding is inferred from
an unstated convention. The raw-product profile has `s_prod=1`, no `C_0` term,
and identity `Epi_P`; `Observe_P` still emits the requested canonical
observation. Every scale, intermediate, canonicalization, and output encoding
remains inside the refinement and safety proof.

This equation is used only when those typed operations exist. The profile MUST
fix left/right scalar action and evaluation order whenever its coefficient
algebra is noncommutative; commutativity is never inferred from the notation.

Let `d_e(w)` be the unique NAF digit of coefficient `w` at exponent `e`, and
define the complete support set

```text
S_W = {(p,j,e,s) | s=d_e(W[p,j]) and s!=0}.
```

For one coefficient, `support(w)={(e,d_e(w)) | d_e(w)!=0}`.

A support-decomposition plan MUST carry a logical coverage witness. Expansion
of all dictionary indices and output-path edges produces a multiset over
`S_W`; that multiset MUST equal the support set with every member having
multiplicity exactly one. Under that warrant, no logical contribution may be
missing, duplicated, assigned the wrong sign/exponent, or applied to the wrong
tensor coordinate, while physical table/DAG nodes MAY be shared and fan out. A
transformed, cancelled, fused, or otherwise algebraically different plan
MAY instead carry a sound certificate proving its complete result equals the
registered reference operation; it need not preserve the physical or logical
occurrence structure of `S_W`. The following are exact candidate families.
They are neither exhaustive nor presumed optimal.

**Direct support walk.** For every output element,

```text
Y[i,j] = sum_p sum_((e,s) in support(W[p,j]))
             s * A[i,p] * 2^e.
```

Each logical contribution MUST be incorporated into an exact
information-preserving intermediate state. A realization MAY fuse or share
physical work when its coverage and refinement witnesses remain valid. No
primitive may invoke undefined behavior, unintended wrap/saturation, or
unproved overflow; a signed shift,
negation, or fused scaled-add is allowed only where its exactness—including at
signed extrema—is proved. Zero digits issue no logical contribution.

**Exponent planes.** Define the exact ternary planes

```text
Plane_e[p,j] = d_e(W[p,j]) in {-1,0,+1}.
```

Then

```text
A*W = sum_e 2^e * (A*Plane_e).
```

Each plane is an exact ternary product. Planes MAY be sparse, tabulated,
vectorized, transformed, fused, or evaluated in parallel under any refinement
warrant proving that the emitted observation equals the registered reference
result.

If no plane is active, the raw product contribution `Y=A*W` is the exact zero
matrix; every declared `s_acc*C_0`, `Epi_P`, `Observe_P`, and output rule remains part of
`Ref_P`, with no prescribed physical execution count or order.
Otherwise, for active exponents `e_0>e_1>...>e_r`, an exact plane-Horner plan
MAY set

```text
H := A*Plane_(e_0)
H := 2^(e_(t-1)-e_t)*H + A*Plane_(e_t)  for t=1..r
Y := 2^(e_r)*H.
```

It MUST prove the peak intermediate bound for this exact order.

**Dictionary/tabulation.** A plan MAY partition the reduction into fixed
blocks, canonically dictionary the distinct NAF meanings of those blocks, build
one exact partial-sum table entry per distinct block, and gather through the
index stream. Its coverage witness MUST expand every index occurrence and prove
that the dictionary entry at that index has exactly the required block meaning.
A scalar NAF code with block size one has no automatic reuse and MUST NOT be
claimed to repay its table build merely because it is NAF.

**Content-addressed arithmetic DAG.** NAF is canonical meaning, not a command to
evaluate every coefficient independently. Prepared-operand data MAY contain any
exact derived structure whose bytes depend only on the bound operand and
registered public profile parameters; its refinement and bounds MUST be proved.
An execution-plan DAG MAY additionally share counterpart-dependent scaled
values, additions/subtractions, repeated structures, transforms, and exact
partials across outputs or calls within its bound invocation. Every such node
MUST bind all input semantic kappas and its exact coordinate/range, shape,
scale, and operation profile. Every node MUST be typed, bind its ordered
children, carry a sound bound, and satisfy either its selected occurrence-
coverage warrant or a sound algebraic refinement certificate. A cached partial
MUST have registered semantics and verification sufficient for the full
refinement proof. Its physical encoding, residue system, or exact
reconstruction strategy is unconstrained; it MUST NOT be reinterpreted as a
final output or silently lose information required by `Ref_P`.

The bound for an expanded NAF schedule is not determined only by decoded
coefficient magnitude. Section 3.6 proves

```text
NAFMass(w) <= 2*abs(w)-1  for w!=0.
```

For example, `3=4-1` has `NAFMass(3)=5`. Define for column `j`

```text
AbsSum_j  = sum_p abs(W[p,j])
Nonzero_j = number of p with W[p,j] != 0.
```

For this next capacity corollary only, assume `A[i,p]` and the displayed live
states are mathematical integers and `B_a` is a nonnegative integer with
`abs(A[i,p])<=B_a`. An ordinary direct-support, exponent-plane, or plane-Horner
schedule whose live states are partial sums or scaled prefixes of the declared
contributions then has the safe raw-product absolute bound

```text
Peak_j = B_a * sum_p NAFMass(W[p,j])
       <= B_a * (2*AbsSum_j-Nonzero_j).
```

For `Peak_j>0`, `1+bitlen(Peak_j)` signed two's-complement bits suffice; the
construction-only bound `bitlen(B_a)+bitlen(AbsSum_j)+2` also suffices when
both factors are positive. For `Peak_j=0`, one signed zero bit suffices. A
realization still proves its actual partial-order peak; transformed, residue,
carry-save, fused, or otherwise different intermediate representations retain
their own exact capacity/reconstruction obligations. The whole-operation proof
additionally covers `s_prod`, `s_acc*C_0`, `Epi_P`, `Observe_P`, canonicalization, and the
requested output boundary.

Individual NAF minimal weight does not imply a globally minimal addition DAG,
fewer machine instructions, lower memory traffic, lower energy, or lower wall
time. Those remain selection and measurement questions.

### 10.4 Atlas-derived execution structure

NAF adjacency creates no Atlas locality. Appending one Atlas symbol can change
many binary positions in the shortlex rank. Implementations MUST NOT infer word
prefix, belt, spectral, storage, or hardware locality from NAF digit support.

The Atlas does provide exact structure that an execution profile may consume.
Every consuming plan MUST bind the precise validated domain, refinement, or
instance-fact warrant and the operation-specific theorem that uses it. One
universally quantified warrant MAY cover a whole family of generators, blocks,
or edges; duplicate per-instance certificates are unnecessary when the theorem
already has the required scope. These facts establish eligibility or a proved
operation census, not optimality.

**Fixed-depth prefix intervals.** For a prefix
`u=(u_0,...,u_(p-1))`, define

```text
val_Sigma(u) = sum_(j=0)^(p-1) u_j*Sigma^(p-1-j).
```

For every target length `k>=p`, the length-`k` words with prefix `u` occupy the
exact shortlex interval

```text
[
  S_Sigma(k) + val_Sigma(u)*Sigma^(k-p),
  S_Sigma(k) + (val_Sigma(u)+1)*Sigma^(k-p)
).
```

This follows by writing each word uniquely as `u||v`; it also holds for
`Sigma=1`. At one target length, common-depth prefix ranges are disjoint,
ordered, and cover the complete length band. They therefore provide exact
non-overlapping shards and a canonical merge order. Descendants across several
target lengths form one interval per length, not one global interval. A
realization MAY materialize observed prefixes, stream a frontier, or use
another exact traversal; `X` and `M` decide among them.

**Belt pages.** From

```text
symbol = class_count*leaf + class,
```

one leaf is the contiguous page

```text
[class_count*leaf, class_count*(leaf+1)).
```

This contiguity follows from the v1 alphabet order. A registered generator MAY
claim page invariance only after proving the lift law

```text
g_class : [0,class_count) -> [0,class_count)
g(symbol) = class_count*leaf(symbol) + g_class(class(symbol)).
```

The range condition plus the lift law proves that `leaf(g(symbol))` is
unchanged. `g_class` MUST additionally be bijective before the table or
generator is called a permutation. Such a generator permits a realization to
reuse one class table across all pages and shard without cross-page writes. The
canonical instance has 128 pages of 96
symbols. Cache, NUMA, device-transfer, and wall-time benefits remain measured.
Atlas refinement-leaf signs and NAF digit signs remain unrelated.

**Spectral dependency graph.** A registered Atlas state/operator domain MAY
bind a finite exact projector family `{Proj_i | 0<=i<m}` whose members are
idempotent, pairwise annihilating, and sum to the identity. For an exact linear
operator `A`, create an edge `j->i`
exactly when

```text
Proj_i*A*Proj_j != 0.
```

Then

```text
A*x = sum_i sum_j Proj_i*A*Proj_j*x.
```

Nonzero edges MAY run independently and recombine in canonical block order. An
edge MAY be omitted only by exact proof that its block map is zero; numerical
smallness is insufficient. A domain-wide theorem, parameter-instantiated
theorem, or instance-fact certificate MAY discharge several zero edges at once
when it proves exactly those equations. Membership in a finite-permutation or
other named domain does not imply spectral zeroes without that theorem. If `A`
commutes with every projector, only diagonal edges remain. No such independence
follows automatically for nonlinear operations or unregistered operators.

**Exact finite-permutation lane.** A finite-sector profile MAY register states
as complete image tuples of `n` slots and every token as a slot permutation.
A direct image-tuple realization of a word of length `L` uses `n` live slot
indices and exactly `nL` dense slot updates, and the evaluated state can be
serialized by emitting `n` canonical indices independent of syntax length.
These are profile-proved operation/storage counts for that realization in the
registered slot-word model; the domain invariant does not prescribe it, and
byte complexity also includes the profile's index width. They do not apply to
generic state-vector simulation, amplitude extraction, or a dense universal
sector.

Prefix intervals and page contiguity are derived from this document. Generator
lifts, spectral sparsity, and finite-permutation evaluation are valid only for
registered profiles carrying their exact proofs. None is a universal speed
claim.

### 10.5 Content-addressed computation and cache collapse

Reusable exact work has a conceptual dependency DAG of typed invocations;
physical materialization as a graph is optional. A canonical invocation binds
at least:

```text
operation profile and exact parameters
ordered input semantic kappas and domain descriptors, including C_0 when read
coefficient domain, basis, shape, and canonical tensor/index order
s_prod, s_acc, Epi_P, Observe_P, and composition convention when applicable
exact pre-encode mathematical result versus post-encode result semantics
semantic output type and encode mode when post-encode output is the meaning
```

A semantic invocation uses the displayed semantic identities, including a
finer exact-syntax semantic identity when that is the registered input domain.
An artifact request extends this semantic invocation with the exact requested
output artifact profile. An artifact-sensitive invocation instead binds the
representation-sensitive operation and every exact ordered input artifact
kappa, expected kind/domain, verified artifact payload bytes, and requested
output artifact profile when applicable; it is not a semantic invocation.
Execution traversal and schedule never occur in any invocation identity;
`canonical tensor/index order` above is the input's mathematical coordinate
order.

A mutable discovery index MAY map a semantic or artifact-sensitive invocation
identity to candidate immutable result records. Each result record binds the
typed invocation, output semantic kappa when applicable, optional artifact
kappa, and refinement warrant/certificate. The index is routing metadata, not
semantic truth.

Five cache key domains MUST remain logically domain-separated, although one
physical store MAY hold all five:

- validated semantic facts/warrants, keyed by every ordered subject semantic
  kappa, exact domain/profile identity, typed fact statement/parameters,
  parent-warrant identities, parser/theorem/verifier revisions, and the
  applicable domain-admission-context identity; a `UORDOM` subject additionally
  binds its descriptor and registry-entry digests;
- semantic results, keyed by the complete semantic invocation identity;
- artifact-sensitive results, keyed by the complete artifact-sensitive
  invocation identity and never promoted into the semantic-result namespace;
- artifacts/transcodes, keyed by semantic identity plus exact artifact profile;
- machine plans, keyed by a semantic plan plus target ABI/ISA, realization/lane/
  layout family, and tuning-set revision.

Wire parse/index plans depend on the source artifact kappa and parser revision.
Semantic prepared-operand plans depend on source semantic kappa, domain,
shape/order, plan-derivation revision, and every fact/refinement warrant they
consume. Every counterpart-dependent intermediate MUST additionally bind all
relevant semantic identities, exact coordinates/ranges, shape, scale,
operation profile, and relational warrants; one operand kappa is insufficient.

Cache contents are untrusted until expected kind, domain, manifest, length,
digest, exact semantic or artifact payload bytes appropriate to that kind,
embedded semantic label, and any required certificate are verified. Hashing a
result or certificate commits only to byte identity
under the declared collision-resistance assumption; it does not prove that the
result implements the invocation. A cache hit is authorized by a pinned sound
certificate/refinement warrant or reference recomputation—not by kappa,
signature, source identity, provenance, or attestation alone. A registered
trusted-computation attestation MAY establish that a named evaluator produced
the bytes, but correctness then remains explicitly conditional on that
evaluator and attestation mechanism as trusted-base assumptions. Corrupt or
mismatched entries are discarded/quarantined and MAY trigger exact
recomputation.

Because every invocation binds its child semantic identities, records remain
valid for exactly the identities they name. In a new evaluation, a
replacement with the same verified semantic identity in the same domain—
normally the same semantic kappa—invalidates nothing. A cross-domain refinement
is not identity equality and requires the invocation-level bridge from section
6.4.1. Otherwise only nodes whose bound child identities changed and their
reverse-dependents require new lookup or computation. Unchanged sub-DAG
identities retain their verified results. This permits incremental recomputation
and cross-run/machine common-subproblem elimination without making physical
placement semantic.

A changed domain-contract digest creates a different domain and semantic
identity. A changed domain/refinement or instance-fact warrant, verifier
admission/revision, `X`, `M`, applicable `U_sys` or `V_R`, or selection policy
leaves the immutable source semantic object unchanged but makes dependent fact,
prepared-plan, selection, or optimality records inapplicable. Revoking a
verifier does not mutate stored bytes; it removes that warrant from the locally
admitted evidence set. Only reverse-dependents of the changed content-addressed
proof root require new validation, lookup, or computation.

A registered UOR quotient profile MAY likewise compute once per exact orbit.
For a group action `G` and operation `F`, representative reuse requires a
complete orbit canonicalizer and the proof

```text
F(g*x) = F(x)  for every admitted g and x.
```

If `F` is merely equivariant, the profile MUST instead bind and prove the exact
output transport; it cannot return the representative's output unchanged.
Canonical-byte identity, semantic quotient identity, and behavioral equality
remain separate. Canonicalization cost and observed orbit collapse remain
measured.

For state transition reuse, a registered deterministic transition

```text
delta_D : State_D x Token_D -> State_D
```

MUST be extensional under the declared equivalence:

```text
x ~_D y and a ~_Token b
    => delta_D(x,a) ~_D delta_D(y,b).
```

Here `~_Token` is the registered token equivalence, or byte/value equality when
`Token_D` has no quotient semantics.

The state must contain everything on which future transitions depend. Then two
histories reaching the same verified canonical state may merge, and applying
the same suffix produces the same result by induction. If the token alphabet
has size `a` and `Reach_j` is the set of reachable canonical states after `j`
tokens, quotient-frontier discovery through depth `K` needs at most

```text
a * sum_(j=0)^(K-1) |Reach_j|
```

transition calls. Emitting one output per syntax word still has the
corresponding enumeration cost.

An Atlas-word semantic kappa names exact syntax. It MUST NOT merge different
words merely because an unregistered evaluator is believed to give them the
same state/operator. Such collapse requires the registered evaluated-state or
evaluated-operator domain, its complete canonicalizer, and the transition or
composition extensionality proof above.

Content addressing alone proves no useful collapse ratio. A memoizing plan is
admissible only through the semantic equivalence and cache-verification laws
above. It may be claimed cost-optimal only after canonicalization, lookup,
verification, miss handling, and retained-state costs are included and the
complete requirements of section 10.7 are discharged. A finite-sector
observation MUST NOT be generalized to another domain or workload without a
proof covering that domain or a separately scoped claim.

### 10.6 Deterministic parallel and distributed execution

A support, plane, tile, spectral-edge, Atlas-prefix, or transformed
decomposition MAY run in parallel only under a sound refinement warrant. An
occurrence-coverage warrant establishes:

- complete coverage of the reference index/multiset;
- no omitted or duplicated contribution;
- registered semantics and bounds for every partial result;
- a combination proof yielding the exact reference result;
- equality of the emitted observation with the registered canonical result.

A transformed decomposition MAY replace occurrence coverage with an exact
algebraic certificate for the full parallel computation and combination. It
need not preserve the reference index/multiset physically.

If combination is exact, associative, and commutative over every reachable
partial value, partition, reduction tree, worker count, completion order,
migration, retry, and successful resource offer admitted by `X` MAY vary
without changing output bytes. A
protocol using occurrence coverage MUST still give every logical contribution
exactly-once inclusion despite retries. If combination is associative but not commutative,
the plan MUST preserve a canonical logical operand order and merge; only
parenthesization may vary. Capacity is proved for the total and the actual
partial schedule; safe-looking individual shards do not discharge the combined
bound.

Early reduction, compression, canonicalization, or encoding is permitted only
when a registered proof shows that the full emitted observation still equals
`Ref_P`. A wrapping-ring homomorphism is one sufficient warrant for modular
reduction. Saturation and correctly rounded output MUST NOT discard information
needed for the final decision; an exact information-preserving representation
or equivalent reconstruction proof is required. Quotient-state representatives MUST NOT be canonicalized
independently per shard unless a registered proof shows that canonicalization
commutes with combination.

Speculative workers MAY race. Only a fully validated result may be published.
Two accepted candidates for one invocation must produce identical required
observation bytes; disagreement is an integrity/conformance failure, never a
"first writer wins" choice. Scheduling traces may differ. If a trace is itself
requested, schedule and trace grammar belong to that separate semantic domain.

Atlas prefix ranks, semantic kappas, or plan identities MAY route and shard
work. They do not establish authorization, trusted execution, network
proximity, or physical locality. Retrieval and publication still perform the
full verification in sections 8.3 and 10.5.

### 10.7 Admission and optimal selection

**Admission** is exclusively a correctness decision. It is derived from
validated domains, exact bounds, logical coverage or algebraic refinement,
intermediate-representation safety/capacity/reconstruction, combination law,
canonicalization, and output encoding. A timing, heuristic,
unverified plan field, or favorable measurement MUST NOT admit arithmetic.

The comparison target `z` is an element of `Targets_P` from section 10.1. A
family claim binds a target set `Fam` and one rule deriving the per-target
contract `X_z`; it MUST NOT silently choose unrelated rules per target.

`U` is the outer compared system universe, written `U_sys` when it must be
distinguished from an internal plan universe. It MUST bind an exact candidate
grammar and semantics, revision/digest, closure rules, and claimed completeness
boundary. Two universes with different permitted primitives, transforms,
preprocessing, scheduling, or lowerings are different optimization problems.
`Adm_U`, `OPTcost_(U,M)`, and `Argmin_(U,M)` below therefore range over complete
systems; `Adm_(U_sys)` is the same notation with the role made explicit.

`X` MUST bind the abstract machine/environment, hard resource envelope,
exact primitive and run semantics, available parallelism, allowed outcome space
`Omega_X` for scheduling/randomness, exact initial persistent/cache artifacts
and their identities, permitted preprocessing, retained-state transition,
information available to offline or online selection, side-channel and failure
policies, and—when work is amortized—the exact batch, horizon, sequence, or
distribution. An expectation or quantile contract MUST additionally bind a
probability measure `mu_X` over `Omega_X`; adversarial/worst-case contracts need
only the allowed outcome set.
Input-dependent state absent from the declared initial state MUST be
constructed, verified, stored, and charged. Undeclared advice, future requests,
oracle answers, and mutable external state are forbidden.

At an end-to-end accounting boundary, each `R` in `U_sys=U` is a complete
compared selector-plus-executor system, not an already chosen leaf kernel. It
begins from the exact initial state in `X` and includes every `R`-dependent
input parse, validation, fact derivation, candidate generation/reduction, proof
verification, dispatch, fallback, plan selection, execution, and output action
it performs.

A system `R` that selects among internal plans binds a separate internal
candidate universe `V_R`, its exact grammar, eligibility/refinement rules,
feasibility contract, and selection policy as part of `R`'s own semantics.
Members of `V_R` are leaf plans of that already fixed system; they are not
members of `U_sys` merely by being selectable, and `R` is not a member of its
own `V_R`. Searching `V_R` is work performed by `R` and occurs inside
`Run_X(R,...)`. An internal optimum over `V_R` does not imply an optimum over
`U_sys` without a separate bridge theorem comparing the complete systems.

An analyst's comparison or proof search over `U_sys` is external evidence
production: it selects which complete system to deploy and never executes
recursively inside that selected system. If the deployed system itself repeats
such search, that search is instead represented in its `V_R` semantics and run
trace. If plan derivation happened before the run boundary, the exact selected
plan and accepted artifacts are initial state in `X` and the comparison uses
the prepared boundary below.

For every allowed scheduling or randomness choice `omega`, define the complete
run

```text
Run_X(R,z,omega) = (observation, final_state, trace).
```

`R` belongs to `Adm_U(z,X)` exactly when `R` is in `U`, `Elig_R(z)` holds for
the whole target, and every allowed run:

1. terminates within the hard resource envelope without refusal;
2. has observation exactly `RefTarget_P(z)` byte-for-byte;
3. produces a final state satisfying `X`; and
4. uses only declared inputs, information, primitives, and state.

Eligibility is target-specific and independent of `omega`; the four run
conditions quantify over every allowed outcome.

A specialized route that may refuse is not by itself a complete compared
realization. Its fallback and dispatch MUST be included in `R`, and every path
is charged. Randomness MAY change cost or schedule but MUST NOT change
correctness.

`M` MUST assign costs to the trace actions permitted by `X` and bind units,
accounting boundary, aggregation, and order. Every trace action is charged or
explicitly free. Primitive cost MUST account for operand sizes; unbounded
integer, memory, oracle, or communication operations cannot be unit-cost unless
`X` proves a bound. The accounting boundary includes parsing, validation, plan
derivation, enumeration, selection, failed probes, canonicalization, hashing,
verification, cache handling, movement, communication, synchronization,
execution, output production, and retained-state effects.

End-to-end comparison includes all those activities. A plan-only comparison is
conforming only when `X` starts with that exact plan and every required prepared
artifact already bound in its initial state; it MUST be labeled
`prepared-plan`, and excluded construction/reverification cost MUST be
explicit. Prevalidated state does not make runtime lookup, dispatch, movement,
or execution free; every performed action remains charged or explicitly free
under `M`. For multiple runs, `M` states whether aggregation is worst-case,
expected, quantile, amortized, or another exact functional:

```text
Cost_M(R;z,X)
  = Aggregate_M((cost_M(trace_omega))_(omega in Omega_X), mu_X if required)
  in K_M.
```

Costs with different `M` or unrelated `X` are not comparable. A family or
competitive comparison MAY relate `X` instances only through a registered
common comparison embedding that preserves primitive semantics, units,
accounting boundary, resource meaning, initial-state policy, and required
observation while naming the permitted target- or information-specific
differences. Scalar optimality classes
require a declared nonnegative, lower-is-better objective

```text
J_M : K_M -> nonnegative reals union {+infinity}.
```

Define

```text
OPTcost_(U,M)(z,X)
  = inf {J_M(Cost_M(R;z,X)) | R in Adm_U(z,X)}

Argmin_(U,M)(z,X)
  = {R in Adm_U(z,X) |
       J_M(Cost_M(R;z,X)) = OPTcost_(U,M)(z,X)}.
```

If `Adm_U(z,X)` is empty, there is no feasible realization. If it is nonempty
but `Argmin_(U,M)(z,X)` is empty, the infimum is unattained and there is no
exact scalar optimum.

For a lower-is-better vector cost, `c` strictly dominates `d` exactly when

```text
c_i <= d_i for every component i
and c_j < d_j for at least one component j.
```

A realization is Pareto-optimal when no admitted realization strictly
dominates it. A nonempty infinite feasible set need not have a scalar minimum
or a Pareto member. A reproducible scalar selection policy MUST be total and
deterministic on the complete `Argmin` set and independent of enumeration,
completion order, or physical placement. A policy selecting from a Pareto
frontier is a declared preference policy, not a tie-break, and MUST satisfy the
same stability rule.

For a family `Fam`—and, asymptotically, size classes `Fam_n` with
`Fam=union_n Fam_n`—one comparison embedding, one declared family aggregation
`Agg_Fam`, and uniform competitors define the quantifier order. `Agg_Fam` MUST bind its
numeric codomain/order and consume the indexed cost family without discarding
multiplicity; averages, expectations, and quantiles additionally bind exact
weights or a measure `nu_n` on each `Fam_n`:

```text
Adm_U(Fam,X_rule) = intersection_(z in Fam) Adm_U(z,X_z)

UniformClassEnvelopeCost_(U,M,Fam)(z)
  = inf {J_M(Cost_M(Q;z,X_z)) | Q in Adm_U(Fam,X_rule)}

FamilyCost_M(R,n)
  = Agg_Fam((J_M(Cost_M(R;z,X_z)))_(z in Fam_n), nu_n if required)

UniformFamilyEnvelopeCost_(U,M,Fam)(n)
  = inf {FamilyCost_M(Q,n) | Q in Adm_U(Fam,X_rule)}.
```

An exact `family-optimal` claim additionally binds one scalar, lower-is-better
whole-family functional `Agg_Fam_all`, including its measure/weights when
required, and defines

```text
WholeFamilyCost_M(R;Fam)
  = Agg_Fam_all((J_M(Cost_M(R;z,X_z)))_(z in Fam))

WholeFamilyOPT_(U,M,Fam)
  = inf {WholeFamilyCost_M(Q;Fam) | Q in Adm_U(Fam,X_rule)}

WholeFamilyArgmin_(U,M,Fam)
  = {Q in Adm_U(Fam,X_rule) |
       WholeFamilyCost_M(Q;Fam) = WholeFamilyOPT_(U,M,Fam)}.
```

If this `Argmin` is empty, no exact family optimum exists. This whole-family
functional is distinct from the size-indexed family used by an asymptotic
claim unless the contract explicitly proves their relation.

Every comparator admitted to either infimum is one uniform realization correct
on all of `Fam`. The infimum is nevertheless a pointwise analytic lower envelope:
different whole-domain-correct comparators MAY attain it at different `z` or
`n`. That envelope is not itself an executable selector. Any realization that
performs such switching MUST belong to `Adm_U(Fam,X_rule)` and charge its
selection/advice. `UniformFamilyEnvelopeCost` uses `inf_Q Agg_Fam(cost_Q)`, not
`Agg_Fam(inf_Q cost_Q)`; a partial or hard-coded per-target comparator is excluded
from both envelopes.

Every optimality claim MUST state the target/family, `X`, `M`, `U`, objective or
dominance order, uniformity rule, and evidence class. The permitted exact claim
classes are below. In every class the claimed realization MUST first belong to
`Adm_U` on the full stated scope: `Adm_U(z,X)` for one target,
`Adm_U(Fam,X_rule)` for a family/asymptotic claim, and `Adm_U(reqs,X_online)` for
every sequence in an online claim. The cost relation never substitutes for
admission.

For the asymptotic classes, `n` ranges over the declared unbounded natural-size
index. The comparison functions and `f(n)` MUST be finite nonnegative reals
eventually, with `f(n)>0` eventually. Normatively,

```text
g(n) in O(f(n))
    iff there exist c>0 and n_0 such that
        g(n) <= c*f(n) for every declared n>=n_0;

h(n) in Omega(f(n))
    iff there exist c>0 and n_0 such that
        h(n) >= c*f(n) for every declared n>=n_0.
```

The witnesses are uniform constants independent of `n`; target aggregation
has already occurred inside `FamilyCost`. A contract with only finitely many
declared size indices cannot make an asymptotic claim.

- **global-optimal:** `U` is proved to be the complete realization universe for
  the declared abstract machine and the candidate belongs to the applicable
  per-target `Argmin`, whole-family `Argmin`, or nondominated vector class over
  all of it;
- **family-optimal:** exhaustive enumeration or a completeness/lower-bound
  proof covers the entire named `U`, and the candidate belongs to
  `WholeFamilyArgmin_(U,M,Fam)` for the declared scalar functional; a vector
  claim uses the Pareto class instead, and decidability alone is insufficient;
- **exact per-target optimal:** the candidate is a member of the complete
  `Argmin_(U,M)(z,X)`;
- **`(alpha,beta)`-instance-optimal on `Fam`:** one uniform realization `R`
  admitted for every target in `Fam`, with dimensionless `alpha>=1` and
  `beta>=0` in the objective's units, finite candidate cost, and
  `0<=UniformClassEnvelopeCost_(U,M,Fam)(z)<+infinity`, satisfies

  ```text
  J_M(Cost_M(R;z,X_z))
      <= alpha*UniformClassEnvelopeCost_(U,M,Fam)(z) + beta
  ```

  for every `z` in `Fam`; exact instance optimality has `(alpha,beta)=(1,0)`;
- **Pareto-optimal:** the candidate is nondominated under the declared vector
  order; this does not make it unique or scalar-optimal;
- **asymptotically order-optimal:** one uniform realization and size map prove
  `FamilyCost_M(R,n) in O(f(n))` and
  `UniformFamilyEnvelopeCost_(U,M,Fam)(n) in Omega(f(n))` under the same family
  aggregation, `X`, `M`, and `U`;
- **asymptotically ratio-optimal against the uniform-family envelope:** the
  same scalar setup, with finite candidate numerator and
  `0 < UniformFamilyEnvelopeCost_(U,M,Fam)(n) < +infinity` eventually,
  proves the defined quotient

  ```text
  limsup_(n->infinity)
      FamilyCost_M(R,n)/UniformFamilyEnvelopeCost_(U,M,Fam)(n) = 1;
  ```

- **online `(alpha,beta)`-competitive:** with dimensionless `alpha>=1` and
  `beta>=0` in the objective's units, one causal realization proves for every
  admitted request sequence `reqs` that both its cost and the offline optimum
  are finite and

  ```text
  J_M(Cost_M(R;reqs,X_online))
      <= alpha*OPTcost_(U_offline,M)(reqs,X_offline) + beta,
  ```

  with both contracts and the offline comparator's candidate universe,
  information, preprocessing, initial/final state, and cost boundary bound. A
  competitive comparison contract MUST prove their common comparison embedding;
  only the explicitly declared information privilege may differ.

A nonuniform family of specialized realizations MUST be labeled nonuniform and
charge or bind its generator/advice. A ratio claim requires a finite scalar
numerator and an eventually finite positive scalar denominator. An affine
instance-optimal or competitive claim has no denominator, but it requires the
finite lower-is-better scalar quantities stated above; an infinite comparator
bound cannot make the claim vacuously true. Vector, signed, or higher-is-better
costs require a declared valid scalar transformation before any of these
scalar formulas is used.

A lower-bound warrant `LB` is sound only when it proves

```text
LB(z,X) <= J_M(Cost_M(R;z,X)) for every R in Adm_U(z,X).
```

An admitted candidate with certified cost `LB(z,X)` is exact-optimal. A claimed
optimizer is not independent evidence unless its verifier proves exhaustive
coverage or the lower-bound relation over all of `U`.

#### 10.7.1 Proof-complete domain-directed reduction

A domain-indexed candidate registry is discovery metadata, not the candidate
universe, and is distinct from the section-6.4 domain resolver. Every domain-
derived fact in `Gamma(z)` and every persisted reducer result binds the exact
domain-admission context under which it was accepted. A resolver hit has no
candidate-admission force, and a resolver or candidate-index miss has no
pruning force.

At the end-to-end boundary, `U` in this subsection is `U_sys` and its members
are complete systems. An internal reducer over one `V_R` requires the separate
`PlanAdm_(R,V_R)` contract of section 10.9.2; substituting `V_R` into an outer-
system theorem proves nothing. A reducer `red` MAY use `Gamma(z)`, but its
retained set and theorem are explicitly scoped. The three progressively
stronger outer forms are

```text
C^E_(red,U)(z,Gamma)                                semantic-eligibility screen
C^A_(red,U,X)(z,Gamma)                              full-admission screen
C^cost_(red,U,X,M,Ord_cmp,claim,pi)(z,Gamma)        cost/claim/policy reduction.
```

The reducer MUST bind its grammar/semantics, revision/digest, input fact roots,
every displayed argument applicable to its form, and its completeness theorem.
A competitive reducer additionally binds both online and offline comparison
contracts. `Ord_cmp` is the complete comparison objective/order: scalar `J`, vector
dominance relation, family functional, or competitive relation as applicable.
A persisted result with different `U`, `X`, `M`, `Ord_cmp`, claim class, or policy
`pi` is a different result. An identifier match or missing index entry has no
pruning force.

Facts entailing eligibility avoid repeated checking; facts entailing
ineligibility may remove a candidate; unknown candidates remain to be checked
or covered by a stronger exact warrant. Generic and superdomain candidates
remain whenever they are admitted. A structural screen proves

```text
R in U \ C^E  =>  not Elig_R(z),
```

while a full-admission screen may instead prove

```text
R in U \ C^A  =>  R notin Adm_U(z,X).
```

Cost-directed reduction MAY omit an admitted realization only under a claim-
specific proof. Write `C` for the fully scoped retained set in that proof. One
sufficient scalar coverage law is

```text
for every R in Adm_U(z,X) \ C,
there exists Q in Adm_U(z,X) intersect C such that
    J_M(Cost_M(Q;z,X)) <= J_M(Cost_M(R;z,X)).
```

This law preserves the scalar infimum; by itself it proves neither attainment,
the complete `Argmin`, nor stable-policy selection. For an attained result, let
`Q_B` be retained and admitted and prove

```text
B = J_M(Cost_M(Q_B;z,X))
  = min {J_M(Cost_M(Q;z,X)) |
         Q in Adm_U(z,X) intersect C}.
```

If every omitted admitted `R` has a certified lower bound `LB_R>=B`, then `Q_B`
belongs to the full `Argmin`; `LB_R>B` excludes that omitted candidate from
`Argmin`, while equality permits a tie. The complete `Argmin` retains every
equal-cost identity. Canonical scalar selection first preserves the optimum and
then proves

```text
pi(Argmin_full) = pi(Argmin_retained).
```

A pairwise priority proof is sufficient only when `pi` is induced by the bound
fixed total order. Lower policy rank never permits omission of a cheaper
candidate.

For one Pareto-optimal candidate, retained comparison plus the pruning warrant
MUST prove that no retained or omitted admitted candidate dominates it. For a
complete realization frontier, the retained frontier is computed and every
omitted admitted identity is strictly dominated by a retained member; equal
cost vectors do not erase distinct realization identities. Policy selection
first preserves the frontier/no-dominator result and then proves

```text
pi(Frontier_full) = pi(Frontier_retained).
```

Lower policy rank never permits omission of a dominator.

Per-target coverage does not preserve a uniform family claim. For a family
scope define one retained `C_Fam` and

```text
A = Adm_U(Fam,X_rule).
```

Every omitted `R` and covering `Q` MUST be uniform members of `A`, and the
claim-scoped theorem proves, for every claimed size `n`,

```text
R in A \ C_Fam
  => exists Q in A intersect C_Fam:
         FamilyCost_M(Q,n) <= FamilyCost_M(R,n),
```

or directly proves equality of the exact family functional/envelope being
claimed. For `UniformClassEnvelopeCost(z)`, both candidates likewise belong to
`Adm_U(Fam,X_rule)`. Pointwise witnesses that select unrelated covering
candidates per target do not preserve a nonlinear family aggregation, a
uniform comparator, an asymptotic claim, or an online/competitive scope.

A domain-instantiated theorem MAY directly establish a lower bound over all of
`Adm_U(z,X)` and exhibit an admitted realization attaining it. That theorem
permits immediate proof-directed selection without runtime enumeration. The
domain facts discharge its structural hypotheses; the separate theorem binds
`z`, `X`, `M`, `U`, objective, realization, and competitor coverage. This is
the exact UOR-native short circuit: search is discharged by a reusable proof,
not by silently narrowing `U`.

A deliberately restricted `U_D` is permitted only as a separately identified
universe with its own digest and claim scope. Optimality over `U_D` says
nothing about an omitted parent universe unless an eligibility, lower-bound,
dominance, and policy bridge proves the corresponding claim over that parent.
Validation, fact lookup, reducer/selector dispatch, and warrant verification
performed by the compared `R` are charged by `M`. Exact accepted records in
`X` may exclude their prior construction or reverification only at an
explicitly prepared/amortized boundary; every lookup, dispatch, movement, or
other runtime action actually performed remains charged or explicitly free. A
reducer used only by an external proof author to establish which design is
optimal is evidence-production work, not a hidden action in `Run_X`; any
certificate verification performed by `R` remains in its trace.

A benchmark, autotuner, incomplete search, or predictor establishes only
**measured-best-among-tested**, **heuristic-selected**, or **best-known** with
its exact scope. Candidate generation MAY use recomputed NAF/Atlas structure,
semantic degeneracy, resources, proved costs, and measurements, but an exact
selector first forms `Adm_U`, then proves the claimed minimum or nondominance.
Unavailable resources or a cache miss changes `X` or cost and triggers a new
optimization problem; it cannot change semantics.

NAF length, exponent distribution, cache behavior, and adaptive choice leak
structure. A side-channel constraint belongs to `X`; when it requires a
fixed/public route, forbidden adaptive plans are absent from `Adm_U` rather
than treated as cheaper alternatives.

### 10.8 Correctness and optimality gates

A candidate realization passes these gates in order before becoming a
preferred route:

1. **Specified:** descriptor, eligibility, observation boundary, bounds,
   resource behavior, and failure behavior are complete.
2. **Warranted:** domain membership, consumed semantic facts, eligibility,
   refinement equality, and safety obligations are separately proved, cited
   with matching hypotheses, or discharged by sound registered certificate
   verifiers whose typed conclusions match the next hypotheses.
3. **Realized:** strict parsing, extrema, malformed-plan, adversarial, and
   differential tests agree with the uncached reference.
4. **Deterministic:** parity holds across admitted schedules, shards, worker
   counts, offers, cache states, and substrates.
5. **Hardened:** corrupt caches, invalid certificates, missing children,
   overflow attempts, oversized inputs, and resource exhaustion cannot cause
   reinterpretation or silent wrong output.
6. **Accounted:** the cost model charges the complete declared boundary,
   including planning, routing, canonicalization, verification, cache misses,
   data movement, communication, execution, and retained state.
7. **Selected:** an exact-optimal route satisfies one exact class from section
   10.7 for the bound invocation/workload, execution contract, cost model, and
   candidate universe. A route lacking that proof may still be selected only
   under its honest measured-best, heuristic-selected, or best-known label and
   exact scope.
8. **Promoted:** selection MAY prefer the route only within the scope for which
   its correctness and stated selection-evidence claims hold; audit/reference
   execution and immediate demotion remain available.

Promotion changes selection policy only. It changes no semantic or artifact
identity and may be revoked without invalidating canonical UOR objects.

Evidence classes are self-contained and noninterchangeable:

- **proved:** a theorem with matching hypotheses or a sound proof certificate;
- **realized:** evidence that a particular construction implements its
  specified identity, including strict and differential tests;
- **measured:** empirical cost evidence under a bound environment/workload;
- **hypothesized:** an extrapolation not yet proved or measured.

Only proved evidence discharges a universally quantified correctness or exact
optimality claim. Realized evidence tests a construction; measured evidence can
rank tested realizations only within its statistical scope.

Each execution claim MUST name its method: proof, certificate, exhaustive test,
property test, exact operation/instruction census, benchmark, or hypothesis.
Examples are deliberately distinct:

- ordinary NAF has minimum Hamming weight over all finite
  `{-1,0,+1}` radix-2 representations: proved representation theorem, not an
  execution-optimality claim;
- an internal plan minimizes an exact cost over one exhaustively enumerated
  `V_R`: proved internal plan-selection certificate, not outer system
  optimality;
- a complete system minimizes an exact cost over an exhaustively covered
  `U_sys`: proved system-optimality certificate at its exact claim scope;
- a particular emitted loop contains no multiply: realized/census, not an
  optimality claim;
- a named realization is fastest among tested candidates on one environment:
  measured/measured-best-among-tested;
- Atlas placement improves physical locality: hypothesized until proved or
  measured under a declared model.

A measured-cost report MUST bind realization revision, abstract and physical
environment, toolchain, workload/data distribution, shapes, cache state,
verification cost, statistic, uncertainty method, sample count, and date. It
SHOULD report cold and warm results, unique semantic objects, collapse ratio,
work avoided, planning/hash/verification time, bytes moved, peak memory, and
byte parity with the cache-disabled reference. Measurement can validate or
calibrate `M`; it cannot enlarge a proved optimality scope.

Every exact selection certificate MUST bind the invocation/workload scope;
every consumed domain/refinement/fact-warrant root; its comparison boundary,
objective/order, claim class, stable policy, reducer and coverage theorem;
certified cost trace or symbolic upper bound; resource-feasibility and lower-
bound, exhaustive-enumeration, or no-dominator proof; certificate grammar; and
verifier revision.

An **outer system-optimality certificate** MUST additionally bind canonical
digests of `X`, `M`, and `U_sys`, plus the selected complete system's identity,
semantics/revision, total eligibility, correctness/refinement warrant, and
end-to-end cost. Its selected member belongs to `Adm_(U_sys)`, never merely to
an internal plan set.

An **internal plan-selection certificate** MUST instead bind the already fixed
complete system `R`, `V_R`, `PlanAdm_(R,V_R)`, its plan-level cost model `M_R`
and objective/order `Ord_R`, and the selected plan identity and correctness
warrant. It proves only the stated internal claim. A container MAY carry both
certificate types, but their typed conclusions remain separate and neither
record may substitute its selected member into the other's universe.

Acceptance MUST imply semantic admissibility and the claimed cost relation at
the certificate's own boundary. A benchmark record alone is not an optimality
certificate. When a canonical selected member is claimed, the certificate
first preserves the applicable full scalar optimum or proves the applicable
no-dominator/Pareto-frontier obligation, then proves equality of the full and
retained policy selections as specified in section 10.7.1 or the registered
internal analogue. Lower policy rank never excuses an omitted cheaper member
or Pareto dominator. Attaining a scalar lower bound proves membership in the
applicable `Argmin`; by itself it does not prove which equal-cost member the
policy selects.

### 10.9 Construction-independent optimization procedures

No repository, API, element width, accumulator representation, table layout,
parallel decomposition, instruction set, or hardware target constrains the
meaning of UOR-NAF. Optimization has two nonrecursive levels. The outer level
compares complete systems in `U_sys=U`; the inner level is runtime plan
selection by one already fixed system `R` over its own `V_R`. One universe MUST
NOT be substituted for the other.

#### 10.9.1 Certification and selection of a complete system

An external optimizer, proof author, or certificate verifier MAY establish
which complete selector-plus-executor system to deploy:

1. bind the operation profile `P`, target or uniform family, required-
   observation rule, execution contract `X`, cost model `M`, outer system
   universe `U_sys`, exact initial-state rule, objective/order, claim class,
   stable scalar-selection or Pareto-preference policy, and the exact domain-
   admission context used by semantic validation;
2. resolve and strictly verify every semantic object, domain/refinement
   warrant, fact certificate, and relation-graph snapshot consumed by the
   proof under that context. Derive a coherent `Gamma(z)` only from those
   accepted roots. A kappa or mnemonic identifier alone adds no fact;
3. enumerate `U_sys`, or apply a proof-complete reducer satisfying section
   10.7.1. Domain facts may discharge eligibility premises and remove proved-
   ineligible systems; every generic or specialized system not soundly covered
   remains. The reducer does not change `U_sys`;
4. establish admission and complete `Cost_M` for retained systems, including
   each system's own runtime validation, internal `V_R` search, dispatch,
   fallback, execution, and output behavior. Prove that every omitted system
   cannot affect the claimed scalar bound, family functional, Pareto result,
   or stable-policy selection;
5. when a domain-instantiated theorem gives a sound lower bound over all of
   `Adm_(U_sys)(z,X)` and an admitted system attains it, select that system
   without enumeration. Otherwise select only from the proved complete
   `Argmin` set or Pareto frontier when the required member exists; and
6. emit a system-selection certificate binding `z` or the uniform family,
   `X`, `M`, unchanged `U_sys`, the domain-admission-context identity and every
   consumed entry/warrant record, reducer and coverage warrants, selected
   complete system, certified cost, policy, and exact claim class. A context
   change requires the inclusion/transition proof of section 6.4.

Comparison, synthesis, and proof search over `U_sys` are evidence-production
work outside `Run_X` of the selected system. They are charged only when the
declared comparison contract explicitly includes design/certification work or
when the deployed system performs or verifies them. Any selected plan or
certificate used during deployment is available without reconstruction only
when its exact identity and accepted state are bound in `X`; runtime lookup,
verification, movement, and dispatch remain charged or explicitly free.
The certificate proves a claim about a fixed selected system; it is not itself
an executable per-request selector. If an online or target-dependent process
uses such certificates to choose among systems, that process plus its selected
branches is a new complete system in `U_sys`, and its generation, verification,
selection, and dispatch occur in its run trace.

#### 10.9.2 Runtime plan selection inside one fixed system

Fix one `R in U_sys` before its run begins. If `R` selects plans dynamically,
it binds an internal universe `V_R`. For an internal exact-selection claim it
also binds a plan-level decision boundary, feasibility relation,
`PlanAdm_(R,V_R)(z,X)`, internal trace/cost model `M_R`, objective/order `Ord_R`,
coverage warrant, and stable policy. Those definitions are part of `R`; they
do not redefine outer `Adm_(U_sys)` or `Cost_M`.

Within `Run_X(R,z,omega)`, `R` may:

1. resolve, rehash, strictly validate, and canonicalize the request inputs,
   thereby binding `z` and every required state transition under
   `RefTarget_P`;
2. derive a coherent `Gamma(z)` from accepted domain/refinement warrants and
   exact instance or relational facts;
3. enumerate `V_R`, or apply a plan-level proof-complete reducer whose theorem
   is scoped to the exact `R`, `V_R`, `z`, `X`, internal objective/order,
   claim, and policy. Direct, plane/Horner, dictionary, shared-DAG, quotient,
   Atlas-structured, dense, transformed, sequential, parallel, distributed,
   and other exact plans are candidates only when the registered `V_R` admits
   them; none is privileged by representation or origin;
4. use verified facts to discharge matching eligibility hypotheses or remove
   proved-ineligible plans. An unknown plan is checked or certified before
   selection, or remains unavailable. A guarded check/dispatch/fallback is
   usable only when that composite behavior is already part of `R` and `V_R`;
5. reject every retained plan lacking complete eligibility, exact refinement,
   intermediate-state/reconstruction, resource, and required-observation
   warrants. A support decomposition may use occurrence coverage; a
   transformed plan may instead use a sound algebraic equivalence certificate;
6. compute or certify internal plan costs and cover every omitted member as
   required by the internal claim. A lower bound over all of
   `PlanAdm_(R,V_R)(z,X)` attained by one admitted plan permits direct internal
   selection without enumerating `V_R`; and
7. apply the bound stable policy, execute the selected plan, and emit exactly
   `RefTarget_P(z)`, while retaining the independent reference route for audit.

Every target-dependent action in this inner procedure—including validation,
fact lookup, reduction, failed probes, proof verification, selection, dispatch,
execution, and output—is part of `Run_X(R,...)` and therefore the outer
`Cost_M(R;z,X)`. If internal derivation or selection happened before the run
boundary, the exact selected plan and accepted evidence are initial state in
`X`, and the complete compared system is labeled prepared-plan,
prepared-state, or amortized as applicable. Internal optimality over `V_R`
never proves outer optimality over `U_sys` without a separate theorem covering
the complete systems and their end-to-end costs.

The candidate families in sections 10.3–10.5 are useful derivations, not an
exhaustive catalog; they may define leaves in `V_R` or components of systems in
`U_sys`. A global-optimal claim over `U_sys` MUST include every complete system
allowed by its declared abstract machine or prove that omitted systems cannot
improve the bound. If plan synthesis, equivalence, or global optimization is
undecidable or computationally infeasible for the chosen universe, correctness
remains mandatory while the strongest honest selection label is
family-optimal, Pareto-optimal, measured-best-among-tested,
heuristic-selected, or best-known with its exact scope. Computational
difficulty never licenses an unqualified optimum claim.

An exact operation census is a cost proof only for a model that prices exactly
those counted operations. Wall time, energy, locality, and communication remain
separate cost models and MUST be measured or proved at their own declared
boundaries while equality with the reference observation is checked.

## 11. Capability-scoped conformance

Conformance is claimed for explicitly named capabilities, not for this document
as one indivisible feature set. Every claim MUST identify the exact
specification identifier, the claimed capabilities, and every domain or
operation profile on which it depends. It MUST satisfy every applicable
requirement ID in that capability and all dependency capabilities.

Absence of an unclaimed optional capability is not a failure of a lower layer.
Execution correctness or optimality does not imply a serialized-plan
capability. No serialized `uor-naf-plan` capability exists until a separate
canonical grammar, strict decoder, and vectors are registered.

Requirement IDs are stable mnemonic references, not wire values, addresses,
certificates, or proofs. An ID MUST NOT change meaning or be reused. Retired IDs
remain retired. If a requirement is split, the original ID retains its original
core obligation and new obligations receive new IDs.

| Capability | Required dependencies |
|---|---|
| `core` | none |
| `address` | none; the pure section-8.2 manifest/hash transform consumes already validated typed payload bytes |
| `integer` | `core` |
| `tensor` | `integer` |
| `atlas-word` | `core` |
| `domain(registry_id,digest)` | `core` and the exact admitted domain contract/warrant |
| `address-binding(K)` | `address` and exactly one typed object capability `K` from the four rows above |
| `execution(P)` | every object and `address-binding` capability used by the serialized inputs/outputs of `P` |
| `optimality(P,X,M,U,claim)` | `execution(P)` and the exact comparison contract named by the claim |

The pure `address` capability proves only the deterministic manifest/hash
transform on typed payloads supplied by its caller. Type-directed parsing,
semantic-parent reconstruction, domain/tag agreement, and accepted-image checks
belong to `address-binding(K)` and therefore depend on `K`. A complete addressed
UOR-NAF artifact claim MUST name both its object capability and the matching
`address-binding(K)`; this separation prevents a dependency-free hash transform
from claiming that it validated an object's grammar.

Tests are falsifiability evidence. They do not by themselves prove a statement
quantified over every integer, finite word, schedule, system, or candidate
universe. A conformance report MUST cite the section-14 obligation for every
theorem or external assumption it consumes.

### Core capability

- **NAF-CORE-001 — Termination.** Matching section-14 evidence proves that
  `normalize_integer` terminates for every mathematical integer.
- **NAF-CORE-002 — Arbitrary-precision evidence.** A conformance report cites
  the all-integer section-14 obligations and reproduces every applicable fixed
  section-12 boundary, including `2^200`. Any additional finite stress corpus
  binds its exact bit-length/value ranges, pattern generator, seed, and sample
  count and is reported as realized evidence rather than a universal proof.
- **NAF-CORE-003 — Bounded arithmetic.** Every claimed bounded normalizer
  accepts both signed endpoints and proves every intermediate exact, including
  the direct `w+1`-bit `n-d` case when used.
- **NAF-CORE-004 — Evidence typing.** Exhaustive bounded searches are tests and
  MUST NOT substitute for any all-integer theorem.
- **NAF-CORE-005 — Strict primitives.** Minimal `uvar`, signed-integer, and
  `CoreNAFBytes` parsing rejects truncation, overlong spelling, unknown sign or
  digit codes, nonzero padding, adjacency, high zeroes, zero magnitudes, and
  residual bytes at a complete-field boundary.
- **NAF-CORE-006 — Frame preflight.** Counts and packed lengths are proved to
  fit the unread frame before allocation or count-controlled iteration, without
  wraparound; frame-impossible input is invalid and feasible policy-large input
  is a resource refusal.
- **NAF-CORE-007 — Derived bounds.** Any use of `NAFMass`, core-size, or
  bounded-width bounds agrees with sections 3.6 and 7.2 and is not extended to
  an unproved transformed intermediate.
- **NAF-CORE-008 — Primitive boundaries.** The section-12 boundary and
  rejection vectors reproduce exactly, including `uvar` transition points and
  the `2^200` core value.
- **NAF-CORE-009 — Soundness.** Matching section-14 evidence proves that the
  emitted digit sequence evaluates to the input integer.
- **NAF-CORE-010 — Normality.** Matching section-14 evidence proves that every
  emitted sequence satisfies the section-3.2 normal-form predicate.
- **NAF-CORE-011 — Existence.** Matching section-14 evidence proves that every
  mathematical integer has a finite NAF.
- **NAF-CORE-012 — Uniqueness.** Matching section-14 evidence proves that two
  normal NAFs with the same value are identical.
- **NAF-CORE-013 — Idempotence.** Matching section-14 evidence proves that
  normalizing the value of a normal NAF returns that NAF.
- **NAF-CORE-014 — Negation.** Matching section-14 evidence proves digitwise
  negation, including the unique empty zero.
- **NAF-CORE-015 — Minimum weight.** Matching section-14 evidence proves the
  all-integer minimum-Hamming-weight theorem over every finite declared
  competitor, not merely a tested bounded set.
- **NAF-CORE-016 — Length.** Matching section-14 evidence proves the exact
  section-3.5 length bound.

### Integer capability

- **NAF-INT-001 — Exact integer adapter.** Every mathematical integer maps to
  and from its exact signed semantic primitive and unique CoreNAF without a
  mathematical width restriction.
- **NAF-INT-002 — Storage-profile closure.** Only the five exact v1 identifiers
  are admitted. Every bounded profile accepts both signed endpoints and rejects
  the two adjacent out-of-range mathematical values at its artifact gate.

### Tensor capability

- **NAF-TENSOR-001 — Shape edges.** Rank zero, zero extents, empty coefficient
  storage, and unit extents round-trip with their distinct declared meanings.
- **NAF-TENSOR-002 — Shape/count agreement.** The exact shape product is
  computed without wraparound; impossible rank/shape/count frames and every
  coefficient-count mismatch are rejected before unsafe allocation.
- **NAF-TENSOR-003 — Canonical order.** Row-major with the final axis varying
  fastest is the only v1 semantic traversal.
- **NAF-TENSOR-004 — Storage profiles.** All five exact identifiers are
  accepted; aliases are rejected; every coefficient satisfies its exact range,
  including both endpoints and the two adjacent out-of-range values.
- **NAF-TENSOR-005 — Tier parity.** Different admitted storage tiers decoding
  to the same tensor produce identical semantic bytes and may produce distinct
  artifact bytes.

### Atlas-word capability

- **NAF-ATLAS-001 — Parametric bijection.** Shortlex rank and exact inverse
  satisfy the section-5 bijection for every positive admitted `(q,T,O)`.
- **NAF-ATLAS-002 — Exact search.** The inverse verifies both
  `S_Sigma(k)<=N` and `N<S_Sigma(k+1)` exactly; approximation never decides a
  boundary. Boundary cases at adjacent length intervals agree with a simple
  exact oracle, and the binary-lifting search uses logarithmically many blocks.
- **NAF-ATLAS-003 — Word preservation.** Empty words, length, order, repeated
  symbols, and leading or trailing zero-valued symbols are preserved.
- **NAF-ATLAS-004 — Validity.** A negative rank, zero parameter, or symbol
  outside `[0,Sigma)` is rejected.
- **NAF-ATLAS-005 — Context bound.** `context-bounded` accepts exactly its
  declared image and returns `policy-out-of-domain` for an overlong word without
  truncation or modular reduction.
- **NAF-ATLAS-006 — Degenerate alphabet.** At `Sigma=1`, semantic parsing and
  hashing use the canonical length-only representation and reject residual
  symbol fields. Validation of a rank at least `2^128-1` performs no allocation,
  hashing, byte emission, or loop proportional to the logical word length.
- **NAF-ATLAS-007 — Layer separation.** Parameter profile and word-admission
  policy remain artifact metadata; alphabet order, word-to-integer law,
  parameters, and word remain semantic.
- **NAF-ATLAS-008 — Evidence scope.** A conformance report cites the all-domain
  bijection/search obligations and reproduces the fixed section-12 boundaries.
  Every additional exhaustive or property-test claim binds exact parameter,
  rank, and word-length ranges plus generator, seed, sample count, and pass
  criterion; finite testing is realized evidence, not proof of the parametric
  domain.

### State/operator domain capability

Each claim below is scoped to one exact `RegistryKey` unless it explicitly
quantifies over several domains.

- **NAF-DOM-001 — Canonicalizer laws.** `Can_D` satisfies soundness,
  completeness, idempotence, and its declared equivalence.
- **NAF-DOM-002 — Exact serialization.** `Ser_D` is injective on
  `Canonical_D`, and `Parse_D` accepts exactly its image with complete
  consumption.
- **NAF-DOM-003 — Exact coefficient forms.** Every claimed rational,
  cyclotomic, Laurent, vector, matrix, permutation, ray, scale quotient, PGL, or
  PU form has one exact registered spelling.
- **NAF-DOM-004 — Quotient separation.** Exact and quotient profiles remain
  distinct and no broader equivalence is inferred.
- **NAF-DOM-005 — Byte preservation.** Empty and leading-zero domain
  serialization bytes round-trip through `E_Bytes`.
- **NAF-DOM-006 — Outcome partition.** `invalid`, `unresolved`, `unsupported`,
  `unadmitted`, `commitment-failure`, and `accepted` are distinguished exactly;
  only the state whose complete predicate holds is returned.
- **NAF-DOM-007 — Descriptor binding.** Registry digest, exact identifier
  grammar, subtype/kind/outer-tag row, canonical parameters, and complete
  descriptor/subframe consumption are checked without input normalization.
- **NAF-DOM-008 — Membership saturation.** Structural membership is invariant
  under the declared ambient equivalence.
- **NAF-DOM-009 — Membership enforcement.** A structural parser rejects a
  value violating its invariant; a mnemonic name or kappa never supplies
  membership.
- **NAF-DOM-010 — Constructive membership.** A constructive specialized
  grammar may avoid a redundant scan only when its parser-image warrant proves
  the invariant.
- **NAF-DOM-011 — Parameter canonicality.** Parameters with identical semantic
  effect have one spelling; slack object facts are not alternate domains.
- **NAF-DOM-012 — Refinement graph.** Edges bind exact endpoints, parameter
  maps, value maps, and a finite acyclic graph snapshot; alternate paths are
  coherent or remain distinct conversions.
- **NAF-DOM-013 — Identity separation.** Generic and refined encodings retain
  distinct semantic kappas.
- **NAF-DOM-014 — Observation transport.** Cross-domain reuse proves equality
  at the caller's exact required observation; a constant, lossy, or coarsening
  transport never proves a finer observation.
- **NAF-DOM-015 — Fact invariance.** Every semantic dispatch fact is invariant
  under subject equivalence; layout and machine facts remain artifact/plan
  facts.
- **NAF-DOM-016 — Typed objects.** Exact syntax words, evaluated operators,
  terminal states, and trajectories remain distinct; all registered empty,
  composition, concatenation, and transition laws are checked.
- **NAF-DOM-017 — Evidence revision.** Replacing or revoking a warrant changes
  its domain-admission context and dependent records, not an unchanged entry,
  semantic payload, or kappa.
- **NAF-DOM-018 — Fixture closure.** Both fixture entries resolve and admit
  offline and satisfy the in-specification warrant in section 6.4.2.
- **NAF-DOM-019 — Resolver classification.** Wrong-digest resolver bytes leave
  the key unresolved; digest-matching noncanonical or schema-invalid bytes are
  invalid.
- **NAF-DOM-020 — Registry commitment failure.** Observed distinct entry
  preimages for one `RegistryKey` cause fatal `commitment-failure`; neither is
  admitted by digest choice.
- **NAF-DOM-021 — Revocation boundary.** Revocation changes the applicable
  admission context and its dependent evidence, not immutable registry content
  or semantic identity.

### Address-transform capability

- **NAF-ADDR-001 — Deterministic labels.** Identical canonical semantic or
  artifact payload bytes produce identical corresponding labels.
- **NAF-ADDR-005 — Commitment typing.** Kappa labels, payload commitments, and
  registry-entry digests are never substituted or compared as if they had one
  preimage.
- **NAF-ADDR-007 — Hash non-oracle.** A label is never an oracle for NAF
  uniqueness, semantic equality, canonicalizer completeness, provenance,
  authorization, or domain admission.
- **NAF-ADDR-009 — Commitment failure.** If two distinct preimages are
  observed for one typed SHA-256 commitment, verification fails closed with
  `commitment-failure`; neither preimage is selected by digest and neither is
  declared semantically malformed solely from the collision.

### Typed address-binding capability

Each requirement in this subsection is claimed as `address-binding(K)` for one
exact object capability `K`.

- **NAF-ADDR-002 — Tier-stable semantics.** Equal decoded objects in one
  semantic profile retain one semantic label across artifact tiers.
- **NAF-ADDR-003 — Parent verification.** An artifact's embedded semantic
  label and reconstructed semantic manifest/domain are recomputed and
  byte-compared before acceptance.
- **NAF-ADDR-004 — Complete commitment.** Every field belonging to the typed
  payload under `K` changes that payload's canonical preimage when it changes.
- **NAF-ADDR-006 — Canonical typed input.** `K`'s exact ASCII identifiers—or an
  extension profile's pinned text repertoire, encoding, and normalization
  rule—plus accepted-image, trailing-byte, RFC 8785 member-order, payload-
  length, digest, kind, and domain rules are checked without input repair.
- **NAF-ADDR-008 — Golden reproduction.** Payload lengths, payload digests,
  manifest bytes, embedded semantic labels, and both kappa classes reproduce
  every section-12 vector applicable to `K` for this exact provisional
  identifier.

### Execution-correctness capability

These requirements apply only to a claim of `execution(P)`. They define
behavioral/proof conformance, not a serialized plan object.

- **NAF-EXEC-001 — Reference parity.** Every admitted route, cache state, and
  cache-disabled audit route emits exactly `RefTarget_P`.
- **NAF-EXEC-002 — Coverage.** A support-preserving plan proves its expanded
  occurrence multiset equals `S_W` with multiplicity one; a transformed plan
  instead proves complete algebraic refinement.
- **NAF-EXEC-003 — Intermediate safety.** Actual partial-order, scale,
  `C_0`, epilogue, canonicalization, and encoding bounds cover every admitted
  extremum.
- **NAF-EXEC-004 — Complete binding.** Every required source identity, domain,
  shape, order, operation, observation, revision, target, domain-admission
  context, `X`, `M`, applicable `V_R`, applicable `U_sys`, cost, policy, and
  warrant is bound and checked.
- **NAF-EXEC-005 — Namespace separation.** Wire-parse, semantic prepared,
  invocation-bound, machine-lowering, and result identities are not
  interchanged.
- **NAF-EXEC-006 — Evidence before dispatch.** A name, kappa, signature,
  provenance, or attestation alone never unlocks a structural route.
- **NAF-EXEC-007 — Three-valued facts.** Missing evidence remains unknown;
  proved positive and negative facts have only their typed effects.
- **NAF-EXEC-008 — Coherence.** Contradictory fact roots fail validation and
  neither admit nor prune a candidate.
- **NAF-EXEC-009 — Sequence eligibility.** Stateful eligibility covers every
  request, intermediate reference state, transition, and cross-request
  condition.
- **NAF-EXEC-010 — Composite fallback.** Check/dispatch/fallback is usable only
  as an already declared composite in the applicable universe, with every path
  charged.
- **NAF-EXEC-011 — Relational facts.** Counterpart-dependent facts bind every
  participating semantic identity and cannot appear as unary facts.
- **NAF-EXEC-012 — Observation boundary.** Pre-encode equality is proved
  before encoding; post-encode equality is used only when registered; input
  refinement never retags output.
- **NAF-EXEC-013 — Prepared accounting.** Cached facts avoid repeated checking
  only from exact accepted state; runtime lookup, movement, dispatch, and
  verification remain charged or explicitly free.
- **NAF-EXEC-014 — Atlas prefix partition.** Prefix shards prove exact union,
  disjointness, interval bounds, and deterministic merge at their declared
  target lengths.
- **NAF-EXEC-015 — Parallel determinism.** Every admitted schedule, retry,
  migration, and resource offer preserves the observation; noncommutative
  combine preserves canonical operand order.
- **NAF-EXEC-016 — Cache rejection.** Corrupt, stale, truncated, wrong-domain,
  poisoned, or certificate-invalid records are never returned.
- **NAF-EXEC-017 — Stateful memoization.** Transition extensionality and
  suffix substitution are proved before reuse.
- **NAF-EXEC-018 — Differential disagreement.** Accepted routes that disagree
  cause conformance failure.
- **NAF-EXEC-019 — Route census.** A claimed census demonstrates the route
  executed and reports its counted operations.
- **NAF-EXEC-020 — Promotion scope.** Promotion records bind evidence method,
  revisions, workload, comparison contract, environment, cache state,
  uncertainty, date, and revocation scope.
- **NAF-EXEC-021 — Result invariance.** Changing plan, schedule, host, cache,
  or promotion policy changes no requested result byte across admitted
  successful executions with identical `P`, target, requested observation, and
  applicable `X` semantics. A changed feasibility/refusal outcome is outside
  this equality and remains governed by `X`.
- **NAF-EXEC-022 — Atlas generator lift.** A page-invariance route binds and
  verifies the exact class range/lift law, and any claimed class permutation is
  additionally bijective.
- **NAF-EXEC-023 — Spectral omission.** Every omitted spectral edge carries an
  exact zero-block warrant for the registered finite projector family.
- **NAF-EXEC-024 — Syntax/artifact cache boundary.** A finer exact-syntax
  semantic operation may cache by its own semantic kappa but does not collapse
  through a coarser or cross-domain equivalence without a bridge. An artifact-
  sensitive operation binds every ordered input artifact identity and any
  requested output artifact profile and never enters the semantic-result cache.

### Optimality-claim capability

These requirements apply only to the exact
`optimality(P,X,M,U,claim)` capability asserted.

- **NAF-OPT-001 — Outer certificate.** It binds `X`, `M`, `U_sys`, selected
  complete system, initial state, cost boundary, claim, coverage/lower-bound or
  no-dominator evidence, and stable policy.
- **NAF-OPT-002 — Internal certificate.** It binds fixed `R`, `V_R`,
  `PlanAdm`, `M_R`, objective/order, selected plan, correctness, coverage, and
  policy and asserts no outer conclusion.
- **NAF-OPT-003 — Universe separation.** Finite toy universes recover their
  respective true minima while a `V_R` optimum produces no `U_sys` optimum;
  neither universe contains its own selector recursively.
- **NAF-OPT-004 — Unattained infimum.** A universe with costs `1+1/n` has
  infimum `1` and empty `Argmin`; exact-optimum claims are rejected.
- **NAF-OPT-005 — Pareto semantics.** Nondominated members are retained,
  dominated members rejected, and no unique scalar result asserted without a
  scalar objective/policy.
- **NAF-OPT-006 — Feasibility and totality.** A cheaper system outside the
  resource envelope is excluded; a partial/refusing route is absent unless its
  complete fallback is included and charged.
- **NAF-OPT-007 — Complete trace.** Parsing, validation, derivation, selection,
  hashing, verification, cache behavior, movement, output, and retained state
  are charged or explicitly free.
- **NAF-OPT-008 — Prepared boundary.** Excluded preparation is permitted only
  when exact artifacts are initial state in `X` and the comparison is labeled.
- **NAF-OPT-009 — Run boundary.** Every target-dependent action performed by a
  system occurs in its `Run_X` trace; undeclared advice and future requests are
  rejected.
- **NAF-OPT-010 — Stable selection.** Enumeration/completion order does not
  change selection; incomplete or forged coverage evidence is rejected.
- **NAF-OPT-011 — Generic preservation.** A refined target retains every
  admitted generic or superdomain system.
- **NAF-OPT-012 — Proof-complete reduction.** A candidate is omitted only
  under the exact eligibility, scalar, Pareto, family, and policy coverage law
  applicable to the claim.
- **NAF-OPT-013 — Lower-bound short circuit.** Selection without enumeration
  requires an attained bound over the complete admitted universe; a domain fact
  alone is insufficient.
- **NAF-OPT-014 — Contract scoping.** Selection results under different `X`,
  `M`, `U_sys`, `V_R`, objective, or admission context are not interchanged.
- **NAF-OPT-015 — Policy after optimality.** Scalar policy follows preservation
  of the full optimum; Pareto policy follows the no-dominator/frontier proof.
- **NAF-OPT-016 — Universe revision.** Expanding `U_sys` or `V_R` leaves an old
  certificate applicable only to its original universe.
- **NAF-OPT-017 — Scalar-formula validity.** Ratio claims reject nonpositive or
  nonfinite denominators and nonfinite numerators. Affine instance/competitive
  claims reject nonfinite candidate or comparator values. Every scalar claim
  rejects an invalid codomain, sign, or optimization direction absent a valid
  transformation.
- **NAF-OPT-018 — Family aggregation.** Multiplicity and required weights or
  measures are preserved; retained and covering systems are uniform family
  members and preserve the claimed functional.
- **NAF-OPT-019 — Nonuniform specialization.** Per-target specialization
  requires declared generator/advice/fallback whose work is admitted and
  charged.
- **NAF-OPT-020 — Envelope nonexecutability.** A pointwise analytic envelope is
  not an executable selector; a system performing switching is separately
  admitted and charged.
- **NAF-OPT-021 — Honest empirical scope.** Benchmark-only evidence supports
  only measured/best-tested claims.
- **NAF-OPT-022 — Evidence revision.** A changed domain contract changes
  semantic identity; a changed warrant, verifier, reducer, context, or universe
  leaves source bytes unchanged and makes exactly its dependents inapplicable.

## 12. Normative vectors

Spaces and line breaks in displayed hex are editorial only; hex decoders
concatenate the digits. Every JSON manifest block is one line with no trailing
newline and is the exact RFC 8785/JCS preimage. Every address chain in this
section uses provisional identifier `uor-naf/1-draft.6`.

### 12.1 Arithmetic, framing, and adapter-local vectors

Digits are least-significant first.

| Integer | NAF digits | Nonzero-power form | `CoreNAFBytes` |
|---:|---|---|---|
| `0` | `()` | `0` | `00` |
| `1` | `(+1)` | `1` | `01 01` |
| `-1` | `(-1)` | `-1` | `01 02` |
| `2` | `(0,+1)` | `2` | `02 04` |
| `-2` | `(0,-1)` | `-2` | `02 08` |
| `3` | `(-1,0,+1)` | `4-1` | `03 12` |
| `-3` | `(+1,0,-1)` | `1-4` | `03 21` |
| `7` | `(-1,0,0,+1)` | `8-1` | `04 42` |
| `11` | `(-1,0,-1,0,+1)` | `16-4-1` | `05 22 01` |
| `42` | `(0,+1,0,+1,0,+1)` | `32+8+2` | `06 44 04` |
| `127` | `-1 at 0; +1 at 7` | `128-1` | `08 02 40` |
| `-128` | `-1 at 7` | `-128` | `08 00 80` |

Minimal `uvar` boundaries are:

| Value | Hex |
|---:|---|
| `0` | `00` |
| `1` | `01` |
| `127` | `7f` |
| `128` | `80 01` |
| `201` | `c9 01` |
| `16383` | `ff 7f` |
| `16384` | `80 80 01` |

For `n=2^200`, `ell=201` and the 53-byte core encoding is:

```text
c901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
```

The framing transition `bytes(128 zero bytes)` is `80 01` followed by exactly
128 zero bytes; `bytes(127 zero bytes)` begins with `7f`.

For the canonical Atlas profile, `Sigma=12288`:

| Atlas word | Shortlex rank | NAF nonzero positions | `CoreNAFBytes` |
|---|---:|---|---|
| `()` | `0` | none | `00` |
| `(0)` | `1` | `0:+1` | `01 01` |
| `(1)` | `2` | `1:+1` | `02 04` |
| `(12287)` | `12288` | `12:-1, 14:+1` | `0f 00 00 00 12` |
| `(0,0)` | `12289` | `0:+1, 12:-1, 14:+1` | `0f 01 00 00 12` |
| `(0,1)` | `12290` | `1:+1, 12:-1, 14:+1` | `0f 04 00 00 12` |
| `(1,0)` | `24577` | `0:+1, 13:-1, 15:+1` | `10 01 00 00 48` |

For canonical byte injection:

| Bytes | `E_Bytes` |
|---|---:|
| empty | `1` |
| `00` | `256` |
| `01` | `257` |
| `00 00` | `65536` |

### 12.2 Complete semantic and artifact address chains

The following five chains include every payload, exact manifest, payload
commitment, embedded parent label, and resulting kappa.

#### Integer `3`

Semantic payload (31 bytes):

```text
554f5253454d01000113756f722d6e61662f696e74656765722d7a2f310103
```

Semantic manifest and kappa:

```json
{"domain":"integer","kind":"semantic","payload_bytes":"31","payload_sha256":"sha256:be329674625f0bce5e4e06e7b223767e42e5ce2fc12d29a835b5507c81054940","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:be329674625f0bce5e4e06e7b223767e42e5ce2fc12d29a835b5507c81054940
semantic_kappa = sha256:84deea1b24435e7ebc365b35ab466053ad88217a6e24041b154b8b93fea308e7
```

Artifact payload (122 bytes):

```text
554f524e4146010001477368613235363a3834646565613162323434333565376562633336356233356162343636303533616438383231376136653234303431623135346238623933666561333038653713756f722d6e61662f696e74656765722d7a2f3112756f722d6e61662f6d6174682d696e742f310312
```

Artifact manifest and kappa:

```json
{"domain":"integer","kind":"artifact","payload_bytes":"122","payload_sha256":"sha256:93296c0d8c0ebdf81e57f83bb6b733da281158ecc54290e8393d3d8cb7e358ff","semantic_kappa":"sha256:84deea1b24435e7ebc365b35ab466053ad88217a6e24041b154b8b93fea308e7","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:93296c0d8c0ebdf81e57f83bb6b733da281158ecc54290e8393d3d8cb7e358ff
artifact_kappa = sha256:666852ad6d1902690b7075c4891de4d5d4e6d014db085cbd97b2cb678067e545
```

#### Tensor shape `(2)`, row-major values `(0,-1)`

Semantic payload (35 bytes):

```text
554f5253454d01000213756f722d6e61662f696e74656765722d7a2f31010201000201
```

Semantic manifest and kappa:

```json
{"domain":"tensor","kind":"semantic","payload_bytes":"35","payload_sha256":"sha256:55dc5ffb7021d0385929ba7d048b26f6b7f4fee40499e39d8dd15fb2d4748a9f","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:55dc5ffb7021d0385929ba7d048b26f6b7f4fee40499e39d8dd15fb2d4748a9f
semantic_kappa = sha256:423cd7e8f5b9c8df367ad957f66490f4ba34d164a7cd6b7c2ba6cd60c268c75f
```

Artifact payload (126 bytes):

```text
554f524e4146010002477368613235363a3432336364376538663562396338646633363761643935376636363439306634626133346431363461376364366237633262613663643630633236386337356613756f722d6e61662f696e74656765722d7a2f3112756f722d6e61662f6d6174682d696e742f31010201000102
```

Artifact manifest and kappa:

```json
{"domain":"tensor","kind":"artifact","payload_bytes":"126","payload_sha256":"sha256:77093c5fbcac55f0c8cbc714faffb59434d8fb471e0737899f8e2dde8b09ef27","semantic_kappa":"sha256:423cd7e8f5b9c8df367ad957f66490f4ba34d164a7cd6b7c2ba6cd60c268c75f","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:77093c5fbcac55f0c8cbc714faffb59434d8fb471e0737899f8e2dde8b09ef27
artifact_kappa = sha256:88e492d5de9db4bc1e825de3c8bc6ff5f7dfa433e0b0923f97d115ac7ee1b248
```

#### Canonical Atlas word `(0)`

Semantic payload (63 bytes):

```text
554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310403080100
```

Semantic manifest and kappa:

```json
{"domain":"atlas-word","kind":"semantic","payload_bytes":"63","payload_sha256":"sha256:223dce37ec26af45bf16bfdac95d247f9931ca48cb60abd318020039fa6fe3ee","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:223dce37ec26af45bf16bfdac95d247f9931ca48cb60abd318020039fa6fe3ee
semantic_kappa = sha256:e3c3e584cb6a8f9cde606131c189acb7409fb13faa35325461706b7749543a87
```

Artifact payload (137 bytes):

```text
554f524e4146010003477368613235363a6533633365353834636236613866396364653630363133316331383961636237343039666231336661613335333235343631373036623737343935343361383702011b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310403080101
```

Artifact manifest and kappa:

```json
{"domain":"atlas-word","kind":"artifact","payload_bytes":"137","payload_sha256":"sha256:75dc99c3584bd6739d3ee1333fd6f73756576e9ac1d439e823b40f9d09ee6929","semantic_kappa":"sha256:e3c3e584cb6a8f9cde606131c189acb7409fb13faa35325461706b7749543a87","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:75dc99c3584bd6739d3ee1333fd6f73756576e9ac1d439e823b40f9d09ee6929
artifact_kappa = sha256:87022cfdeb3bd3e5cf87f91583bda1281c8050db6d3ec7e361daf7cfe8399d74
```

#### Fixture state `(1)` in dimension one

Semantic payload (88 bytes):

```text
554f5253454d0100044b554f52444f4d010020756f722d6e61662e666978747572652f73746174652d7a2d766563746f722f311b317c3af3b89a3bb6af57667437dc8bbfe1323dfd722b0133a743c8a5c308f70101020101
```

Semantic manifest and kappa:

```json
{"domain":"state","kind":"semantic","payload_bytes":"88","payload_sha256":"sha256:f8a373d65bf1209f2540a78134b353602a81bb76159801760c2d42e0c3c93f9f","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:f8a373d65bf1209f2540a78134b353602a81bb76159801760c2d42e0c3c93f9f
semantic_kappa = sha256:2a34bffc7c93399149fec012ba611e7f979f9c981b56326f529a9dab52a1679d
```

Artifact payload (163 bytes):

```text
554f524e4146010004477368613235363a326133346266666337633933333939313439666563303132626136313165376639373966396339383162353633323666353239613964616235326131363739644b554f52444f4d010020756f722d6e61662e666978747572652f73746174652d7a2d766563746f722f311b317c3af3b89a3bb6af57667437dc8bbfe1323dfd722b0133a743c8a5c308f70101110100010001
```

Artifact manifest and kappa:

```json
{"domain":"state","kind":"artifact","payload_bytes":"163","payload_sha256":"sha256:89b30aea1ddefefbe8053e23cc1dd403614cea8ec6b7475e6c8605be9d919c44","semantic_kappa":"sha256:2a34bffc7c93399149fec012ba611e7f979f9c981b56326f529a9dab52a1679d","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:89b30aea1ddefefbe8053e23cc1dd403614cea8ec6b7475e6c8605be9d919c44
artifact_kappa = sha256:de6ac5758b1880da64119306026e2bff074db33375a11638d3afea2cf1d9b3ef
```

#### Fixture operator `[[1]]` in dimension one

Semantic payload (91 bytes):

```text
554f5253454d0100054e554f52444f4d010023756f722d6e61662e666978747572652f6f70657261746f722d7a2d6d61747269782f315538cb9562d2bba20627a80cc65c94abe47d9848fff835be363e701065a5af730101020101
```

Semantic manifest and kappa:

```json
{"domain":"operator","kind":"semantic","payload_bytes":"91","payload_sha256":"sha256:96d30760fb8d3b1194374693faa2e2debf74f2671503934b0a06f4cb4e6a0e78","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:96d30760fb8d3b1194374693faa2e2debf74f2671503934b0a06f4cb4e6a0e78
semantic_kappa = sha256:da959e7e23097a25a232495d4b06474f56c03e68dbe546d7f37e26288cacae9d
```

Artifact payload (166 bytes):

```text
554f524e4146010005477368613235363a646139353965376532333039376132356132333234393564346230363437346635366330336536386462653534366437663337653236323838636163616539644e554f52444f4d010023756f722d6e61662e666978747572652f6f70657261746f722d7a2d6d61747269782f315538cb9562d2bba20627a80cc65c94abe47d9848fff835be363e701065a5af730101110100010001
```

Artifact manifest and kappa:

```json
{"domain":"operator","kind":"artifact","payload_bytes":"166","payload_sha256":"sha256:0bc5aace37c584dad02b4711ef6c2a1740f32c3d743ddb7b080520e34861100a","semantic_kappa":"sha256:da959e7e23097a25a232495d4b06474f56c03e68dbe546d7f37e26288cacae9d","spec":"uor-naf/1-draft.6"}
```

```text
payload_sha256 = sha256:0bc5aace37c584dad02b4711ef6c2a1740f32c3d743ddb7b080520e34861100a
artifact_kappa = sha256:0a0b7489a0e151c26d2a97d2b1ad8df64efc8591686f21d3f68659819e1d53e8
```

For both fixture objects, `Ser_D=01 01`, `E_Bytes(Ser_D)=65793`, and
`CoreNAFBytes=11 01 00 01 00 01`.

### 12.3 Degenerate Atlas, tensor-edge, and storage-range chains

For `(q,T,O)=(1,1,1)`, `Sigma=1`. For each displayed `k=0,1,2,3`, the semantic
payload is 62 bytes and ends immediately after minimal `uvar(k)`; in general
its length is `61+L_uvar(k)`. It contains no repeated zero-symbol fields. The
artifact rows use `parameter_profile=01`; the two artifact policies have the
same semantic row for a common word.

| `k` | Semantic payload hex | Payload SHA-256 | Semantic kappa |
|---:|---|---|---|
| 0 | `554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010100` | `sha256:025a1f374c098997a0174d05cc2a7bf63e58416c3a69dccc2731fb6031c92bbf` | `sha256:e7e3f677069292eb8a7d14854248473e0b81bb0b9e286a5b1ff78af9c29194f6` |
| 1 | `554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010101` | `sha256:2bc382f5ec71bb7eac0598e2be922070f7c346d2b0466848356bb36ee8f24ccc` | `sha256:96e9baf1163e18883befa8cda07d995ab9ee0e189a8a3ad40819d3ede03c1bc7` |
| 2 | `554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010102` | `sha256:47c7d5dc759694fe725d4c581a6d05f7b5b131e89b877047bc76d93d412098a6` | `sha256:86fbf021edd86738330c2d1183da79d7e4b336450da0df498c6f7f49c0849549` |
| 3 | `554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010103` | `sha256:1179ee2ca798c7ce2c0c47c3b23c9f6ff478a884c77d9ac6a9458f586321dace` | `sha256:70c44a540a4651b83eeae1e84b9e4482a1f4164693aa3af33b088cad12e50034` |

Artifact-policy results are:

| `k` | Policy | Result | Payload bytes | Artifact payload hex | Payload SHA-256 | Accepted artifact kappa / would-be artifact-manifest hash |
|---:|---|---|---:|---|---|---|
| 0 | finite | accept | 136 | `554f524e4146010003477368613235363a6537653366363737303639323932656238613764313438353432343834373365306238316262306239653238366135623166663738616639633239313934663601011b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010100` | `sha256:43ab51a378849e60d88140b9fe0690aecf3cea734170e13794c75d494eccf92d` | `sha256:d8b51c619277c7cd187af907772d99e2ed9b199be2202f961503b65a830292ad` |
| 0 | context | accept | 136 | `554f524e4146010003477368613235363a6537653366363737303639323932656238613764313438353432343834373365306238316262306239653238366135623166663738616639633239313934663601021b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f3101010100` | `sha256:ff5d79e08ab75e08bf8059a5e37ece978e77e06f23f6c756b83e52b22e235dd8` | `sha256:9c1227472fc87fdd9a3e1530b9dbc25f97b5d12e29928928d5e910ecf623f161` |
| 1 | finite | accept | 137 | `554f524e4146010003477368613235363a3936653962616631313633653138383833626566613863646130376439393561623965653065313839613861336164343038313964336564653033633162633701011b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010101` | `sha256:348ce90043ece0c692d290778d200764f13a4e66551b31aa8bf64a3b00ee7970` | `sha256:1643116270bd2f461de56eab8b33489ec689cb8587d55cef825ba910a192ef8d` |
| 1 | context | accept | 137 | `554f524e4146010003477368613235363a3936653962616631313633653138383833626566613863646130376439393561623965653065313839613861336164343038313964336564653033633162633701021b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010101` | `sha256:4b958e4857fad595745522ca88298e7566b2b5005ec1d8cba01b2f16fcf79ccf` | `sha256:06e17a2428abf71c07f26baa17a8b605d17c01845247b27293381e0e296b18e2` |
| 2 | finite | accept | 137 | `554f524e4146010003477368613235363a3836666266303231656464383637333833333063326431313833646137396437653462333336343530646130646634393863366637663439633038343935343901011b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010204` | `sha256:fe3cd653c1788c198880144a43fe267be4ae7adcbbce6253860e714cb5a782e9` | `sha256:534436dd249cfe09e9d2521cec47d76e075ab67e94b3745f011409d3df841b6b` |
| 2 | context | policy-out-of-domain | 137 | `554f524e4146010003477368613235363a3836666266303231656464383637333833333063326431313833646137396437653462333336343530646130646634393863366637663439633038343935343901021b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010204` | `sha256:72e9ff99320bc8c621155a53960fa3c7ed3b7bfa68678c789b3102128d63a722` | `sha256:c6a3f1ca3e3d4681ac3651ccd6f298b98b70805b2f84f101b07c41718cc0df7d` |
| 3 | finite | accept | 137 | `554f524e4146010003477368613235363a3730633434613534306134363531623833656561653165383462396534343832613166343136343639336161336166333362303838636164313265353030333401011b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010312` | `sha256:d5f17bef1d7a299da7eedca3935db4d7a2bbb5752938ded793cac37a842b01b5` | `sha256:7e345de9354ef2a7c8fe259360cfa6b89926098068176e42880aa6d7779271f6` |
| 3 | context | policy-out-of-domain | 137 | `554f524e4146010003477368613235363a3730633434613534306134363531623833656561653165383462396534343832613166343136343639336161336166333362303838636164313265353030333401021b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010312` | `sha256:1fabd741301202a57389b68354cd705be7043f6d3f094779ed0686e3867b9df7` | `sha256:551fe294484783be84a3675fd1d79c17e77947be5ede4ec4aab335a43b241d1d` |

For accepted rows the last value is an artifact kappa. For policy-out-of-domain
rows it is SHA-256 of the exact would-be artifact-manifest bytes obtained by
substituting that row's candidate payload length, payload SHA-256, semantic
kappa, domain, kind, and draft identifier into the section-8.2 template. It is
not SHA-256 of the candidate payload and MUST NOT be presented as an admitted
artifact identity or kappa. The old redundant semantic
spelling for `k=1`, shown below, is rejected for trailing bytes:

```text
554f5253454d0100031b756f722d61746c61732f62656c742d706f736974696f6e616c2f3114756f722d61746c61732f73686f72746c65782f310101010100
```

Tensor edge artifacts use `storage_profile="uor-naf/math-int/1"`. The edge
cases are:

| Object | Semantic payload hex | Semantic kappa | Artifact payload SHA-256 | Artifact kappa |
|---|---|---|---|---|
| rank-zero scalar `0` | `554f5253454d01000213756f722d6e61662f696e74656765722d7a2f31000100` | `sha256:4ecdd91587ad5bf3ca86af5695c166b4380f0cb748e5d231df1c1955e81ff552` | `sha256:01dda1c0461fe901e0fd2fa00dd0d32268f6a2a5f1610ee3800f1ed415147f4b` | `sha256:02842d82aaa8395ff32fd66d5b82bfb232db3812104c7b3e2461dde8c8c31c1f` |
| shape `(0)`, empty | `554f5253454d01000213756f722d6e61662f696e74656765722d7a2f31010001` | `sha256:8fd5c9172af1ee4671113d5f9e286c6a2083ac878b2c1b5c97664383b98580a9` | `sha256:58839315f311cc705835d5883215f2c309d27cc4e2d31eebcb924b356c22d706` | `sha256:3ac29d8826f47d264c5dceb25606e063103124b2c85c03ce52da7da348bf8387` |
| shape `(1)`, value `0` | `554f5253454d01000213756f722d6e61662f696e74656765722d7a2f3101010100` | `sha256:242c82dcec733ea705059fddeb3f3a9281f2a48ec04f41c98ee666e885e3b015` | `sha256:38eaea8e144632313b9513bf2a0dff7a3bb2091a6752491f531c4d984e02cffb` | `sha256:c71863eb51f10a8f39cfd19163abdd6479ad9dcb68bf32ba246c444632ba41f8` |

The `twos-i8` range-isolation vectors are:

| Value | `CoreNAFBytes` | Result | Semantic kappa | Artifact payload SHA-256 | Accepted artifact kappa / would-be artifact-manifest hash |
|---:|---|---|---|---|---|
| `-128` | `08 00 80` | accept | `sha256:dcc5ea3fc3371c224a0d224aa209ac2a295a8cce2afc738f7245dea0727dca69` | `sha256:aaae86bf5eb04632c39647db18f30f19352a38b8f6fbd8c00c55ba1817ec90c3` | `sha256:dc5be480c30f38cf7b4de3f990113cceedd1fe00cd40fe9e4dd4d901512d2e58` |
| `127` | `08 02 40` | accept | `sha256:0258db2cab57d84ed7ef8c2fabec6d5de11a5fd55f92c1d0ddf039c8c31322c2` | `sha256:bc8b76217f96ab7f9ee82ed4b804019ddc9c3a938b8606cc1514786bc71700d5` | `sha256:882359b9a87a98ac133fccd92e5148ad8c6e74c95bed9f093d512fe94fed184a` |
| `-129` | `08 02 80` | reject: storage-range | `sha256:1c6d4d90cf5d6389d6757c4a6a6751198d88040d01d773803ae2b90ecaa571b3` | `sha256:ba87f24c5ecce7b80c0b49b88c0000b046c265a3fd255af7c17f75a5bbcd3070` | `sha256:c4400173912e31201970d6286bd279b570216f443c70327b3c8d91696c0d263a` |
| `128` | `08 00 40` | reject: storage-range | `sha256:83b3882b50c44505d9fef01235c9623572cd8db4370e2389db2b0001c68e7d94` | `sha256:5ac663fa3a32fb939a76c4d757bf9d08b02ca5810ef2e5525fac2fb34b9a2ab7` | `sha256:769d5d24fd089aedfc4650948cb13cf54a69be0d09e1a5158d13c7f39bdff52d` |

The two rejection rows are deliberately canonical semantic integers and
internally framed artifact candidates. For accepted rows the final value is an
artifact kappa. For rejection rows it is SHA-256 of the exact would-be
artifact-manifest bytes obtained by substituting that row's candidate payload
length, payload SHA-256, semantic kappa, domain, kind, and draft identifier into
the section-8.2 template. It is not SHA-256 of the candidate payload and MUST
NOT be presented as an admitted artifact identity or kappa. Rejection occurs
solely at the closed `uor-naf/twos-i8/1` storage-profile range gate.

### 12.4 Mandatory rejection corpus

| Layer | Hex/input | Required result |
|---|---|---|
| `uvar` | `(empty)` | reject: `truncated-uvar` |
| `uvar` | `80` | reject: `truncated-uvar` |
| `uvar` | `8000` | reject: `nonminimal-uvar` |
| `uvar` | `ff00` | reject: `nonminimal-uvar` |
| `uvar` | `808000` | reject: `nonminimal-uvar` |
| signed integer | `03` | reject: `invalid-sign-code` |
| signed integer | `0100` | reject: `zero-magnitude-with-sign` |
| signed integer | `0200` | reject: `zero-magnitude-with-sign` |
| signed integer | `0000` | reject: `trailing-bytes` |
| `CoreNAFBytes` | `0100` | reject: `zero-top-digit` |
| `CoreNAFBytes` | `0205` | reject: `adjacent-nonzero` |
| `CoreNAFBytes` | `0103` | reject: `invalid-digit-code` |
| `CoreNAFBytes` | `0105` | reject: `nonzero-padding` |
| `CoreNAFBytes` | `8000` | reject: `nonminimal-uvar` |
| `CoreNAFBytes` | `0000` | reject: `trailing-bytes` |

In addition, every sign byte `03` through `ff` is invalid; any rewritten or
aliased fixed identifier, non-ASCII base-v1 identifier, text violating a
conditional profile's exact pinned rule, malformed `registry_id`, a
subtype/kind/tag contradiction, residual descriptor
or parameter bytes, frame-impossible counts, a manifest/domain/kind/length or
digest mismatch, an embedded semantic-kappa mismatch, and cross-type commitment
substitution MUST be rejected at their typed gates. Unavailable registry content
is `unresolved`, a valid but unadmitted domain is not relabeled `invalid`, and
observed distinct preimages for one typed commitment cause fatal
`commitment-failure` rather than digest-based selection.

A resolved valid entry whose declared operations are not implemented is
`unsupported`; an implemented valid entry lacking admitted required warrants is
`unadmitted`. Together, the concrete vectors above and the normative
classification rules in sections 6.4, 7.4, and 8.3 distinguish canonical
acceptance, artifact-policy exclusion, storage-range rejection, malformed
bytes, unresolved domain content, unsupported domains, unadmitted domains,
commitment failure, and local resource refusal; none is substituted for
another.

## 13. Non-claims

UOR-NAF v1 does not claim:

- that an Atlas address captures behavioral, gauge, or semantic equivalence;
- that the Atlas symbol alphabet itself is a signed-digit alphabet;
- that non-adjacent exponent support implies non-adjacent Atlas support;
- that NAF recoding compresses every artifact;
- that NAF is the unique minimum-weight signed-digit representation;
- that a hash is injective over arbitrary inputs;
- that raw braid/generator words become canonical operators;
- that float approximations are acceptable canonical coefficients;
- that optimization permits any specialized realization to return a different
  required observation;
- that minimum NAF weight guarantees fewer instructions or lower wall time;
- that direct support, planes, Horner, dictionaries, DAG sharing, Atlas
  sharding, caching, or any other named plan family is universally optimal;
- that an incomplete search, benchmark winner, or best-known plan proves an
  optimum outside its declared `U`, `X`, and `M`;
- that one universally fastest realization exists across inputs, objectives,
  resource envelopes, or abstract machines;
- that Pareto-optimal means uniquely optimal, or that asymptotic optimality
  implies per-instance or constant-factor superiority;
- that cold, warm, prepared-state, online, offline, and amortized comparisons
  are interchangeable;
- that NAF exponent adjacency implies Atlas word, page, cache, network, or
  physical locality;
- that content addressing proves a cached result implements its invocation;
- that a `registry_id`, subtype string, descriptor digest, or semantic kappa
  alone proves domain membership or a structural property;
- that registry resolution proves schema validity, domain admission, trust, or
  realization eligibility; that failure to resolve proves malformed bytes; or
  that later exclusion mutates an immutable entry or semantic identity;
- that absence of a cached property warrant proves that property false;
- that structural-domain membership or eligibility proves realization
  correctness, resource feasibility, cost, or optimality;
- that a specialized domain removes otherwise admitted generic realizations
  from `U`, or that a domain-index miss is a completeness proof;
- that exact selection within one system's internal `V_R` proves that system
  optimal among the complete systems in `U_sys`;
- that input refinements automatically propagate to output refinements;
- that equality after a constant, lossy, or coarsening transport proves
  equality at a finer caller-requested observation boundary;
- that a registered cross-domain refinement makes the two semantic kappas
  equal;
- that replacing a proof or verifier changes an unchanged mathematical domain
  identity, or that changing the mathematical domain contract leaves its kappa
  unchanged;
- that a semantic label remains invariant across a change of domain identifier,
  descriptor, canonicalizer, equivalence, or `Ser_D`/`Parse_D` contract merely
  because an external relation connects the old and new objects;
- that prevalidated initial state makes runtime lookup, dispatch, movement, or
  execution free;
- that per-target dominance witnesses automatically preserve a uniform family,
  nonlinear aggregate, asymptotic, or competitive optimum;
- that content addressing makes lookup, verification, movement, or production
  free;
- that finite-sector cache collapse generalizes to dense or universal sectors;
- that spectral blocks are independent for an operator lacking an exact block
  dependency proof;
- that parallelism or memoization changes an underlying complexity lower bound;
- that finite-permutation invariant evaluation provides generic amplitude
  extraction or evades a #P-hard contraction boundary;
- that `uor-naf-plan/1-draft.6` or reserved `uor-naf-plan/1` is already a
  registered wire format or executable-plan profile;
- that an algorithm theorem alone verifies a compiled realization or binary;
- that any repository, API, accumulator width, storage layout, or hardware
  target constrains UOR-NAF semantics;
- that Atlas routing confers trust, authorization, or guaranteed physical
  locality.

## 14. Proof, completeness, and freeze status

Completeness is statement-scoped. It does not mean that every optional domain,
specialized realization, machine lowering, plan artifact, optimizer, or optimum
exists. Ledger status has exactly these meanings:

- **definition:** fixed by a normative grammar or equation;
- **proved-in-document:** the specification contains a complete argument from
  earlier definitions;
- **proved-by-cited-result:** an external theorem is cited with an exact
  hypothesis mapping;
- **external-assumption:** explicitly assumed rather than proved;
- **conditional-profile-obligation:** required only from a profile that claims
  the corresponding extension;
- **open:** not discharged; an unconditional open row blocks assignment of the
  reserved stable identifier.

| Obligation | Exact statement and scope | Status | Evidence or dependency | Stable-v1 effect |
|---|---|---|---|---|
| `NAF-OBL-001` | normalization terminates for every integer | proved-in-document | §3.3–§3.5 decreasing absolute state and terminal cases | clear |
| `NAF-OBL-002` | normalization is sound | proved-in-document | §3.5 maintained evaluation invariant | clear |
| `NAF-OBL-003` | normalization produces a normal NAF, establishing existence | proved-in-document | §3.5 odd-step divisibility, forced following zero, nonzero final digit | clear |
| `NAF-OBL-004` | normal NAF is unique | proved-in-document | §3.5 parity/mod-four recursion | clear |
| `NAF-OBL-005` | normalization is idempotent | proved-in-document | `NAF-OBL-002`–`004` | clear |
| `NAF-OBL-006` | normalization commutes with negation | proved-in-document | §3.5 residue and quotient-state induction | clear |
| `NAF-OBL-007` | ordinary NAF has globally minimum Hamming weight among finite radix-2 `{-1,0,+1}` expansions | proved-by-cited-result | Muir–Stinson Theorem 3.3, mapped in §3.5 | clear |
| `NAF-OBL-008` | `ell<=bitlen(n)+1` | proved-in-document | §3.5 leading-digit domination | clear |
| `NAF-OBL-009` | `NAFMass(c)<=2*abs(c)-1` and the stated equality cases are exact | proved-in-document | §3.6 positive/negative power decomposition and equality conditions | clear |
| `NAF-OBL-010` | registered signed-`w` profiles satisfy `ell<=w` and the direct-intermediate bounds | proved-in-document | §3.6 | clear |
| `NAF-OBL-011` | tensor coefficientwise normalization preserves shape, order, and exact values | proved-in-document | §4 and §7 framing | clear |
| `NAF-OBL-012` | shortlex rank/inverse is a bijection for every positive `Sigma` | proved-in-document | §5.2–§5.3 interval partition and fixed-length base representation | clear |
| `NAF-OBL-013` | binary lifting returns the unique shortlex length in logarithmically many exact big-integer block steps | proved-in-document | §5.3 maintained `S_Sigma(k)`/`Sigma^k` invariants | clear |
| `NAF-OBL-014` | `context-bounded` has exactly its stated image | proved-in-document | §5.5 restriction of `NAF-OBL-012` | clear |
| `NAF-OBL-015` | `Sigma=1` semantic identity is length-only and needs no expanded zero sequence | definition | §§5.5, 8.1 | clear |
| `NAF-OBL-016` | `E_Bytes` is injective and has the stated inverse image | proved-in-document | §6.5 sentinel-bit construction | clear |
| `NAF-OBL-017` | the two fixture domains satisfy their canonicalizer/parser/domain laws | proved-in-document | bundled entries and fixture warrant in §6.4.2 | clear |
| `NAF-OBL-018` | every completed base grammar satisfies accepted-image and complete-consumption canonicality | proved-in-document | compositional proof in §7.4 | clear |
| `NAF-OBL-019` | integer, tensor, and Atlas semantic payloads are injective on their typed domains | proved-in-document | §7.4 field recovery proof | clear |
| `NAF-OBL-020` | an additional state/operator domain is conforming only if its exact entry, domain functions, grammar, equivalence, and required warrants satisfy sections 6–8 | conditional-profile-obligation | exact entry, domain functions, grammar, equivalence, and admitted warrant | does not block the unconditional corpus |
| `NAF-OBL-021` | semantic/artifact manifests and labels are canonical for their exact payloads | proved-in-document | fixed grammar in §8.2, RFC 8785 canonicalization, §7.4 | clear |
| `NAF-OBL-022` | equality of any SHA-256 commitment identifies its typed preimage without direct byte comparison | external-assumption | declared SHA-256 collision resistance; direct comparison remains unconditional | clear as an explicit assumption |
| `NAF-OBL-023` | fixed-depth Atlas prefix intervals are exact, disjoint, and complete | proved-in-document | §10.4 prefix/suffix decomposition | clear |
| `NAF-OBL-024` | belt pages are contiguous in the registered alphabet order | proved-in-document | §10.4 quotient/remainder decomposition | clear |
| `NAF-OBL-025` | an execution-conformance claim for any realization, specialized or generic, is conforming only if an admitted warrant proves `Elig_R(z) => R(z)=RefTarget_P(z)` throughout the claimed scope and binds every eligibility/refinement hypothesis | conditional-profile-obligation | exact eligibility and realization-refinement theorem/certificate | does not block base |
| `NAF-OBL-026` | an optimality claim is conforming only if its exact `P`, target, `X`, `M`, universe, claim class, feasibility, cost, coverage, and policy obligations are discharged | conditional-profile-obligation | the complete section-10.7/10.8 warrant applicable to that claim | does not block base |
| `NAF-OBL-027` | v1 registers no serialized `uor-naf-plan` format | definition | §§10.2 and 11 require a future grammar, decoder, and vectors before such registration | clear |
| `NAF-OBL-028` | the displayed Draft 0.6 corpus is the normative vector set for `uor-naf/1-draft.6` | definition | §12; independent recomputation checks consistency and is a publication gate rather than a theorem | clear |

There is no unconditional mathematical or grammar obligation marked `open` in
Draft 0.6. Conditional third-party domains and execution/optimality claims do
not weaken the base: they simply remain outside conformance until their own
warrants are supplied.

Section 10 defines the necessary semantic, correctness, accounting, and
evidence schema for scoped execution and optimality claims. It asserts neither
the existence of a specialized realization nor an optimizer, optimum, or
serialized plan artifact. A verified domain fact may remove a repeated
eligibility scan; only a complete refinement warrant authorizes the
realization, and only comparison-complete evidence authorizes an optimality
claim.

The reserved stable identifier `uor-naf/1` remains unassigned in this draft. A
freeze publication MUST:

1. retain no unconditional `open` ledger row;
2. verify uniqueness of every section-11 requirement ID and coverage of every
   claimed capability;
3. independently reproduce every section-12 payload, manifest, embedded parent
   label, digest, and kappa;
4. resolve all editorial placeholders and complete external normative
   references; and
5. change the provisional manifest identifier to the chosen stable identifier
   and then regenerate and independently reproduce every address chain one
   final time.

Independent reproduction is a release gate, not a mathematical theorem.
Changing a plan, proof implementation, verifier, cost model, or selection policy
never changes base semantic identity unless it changes a mathematical domain
contract or canonical byte rule.

## 15. Dependency boundary

UOR-NAF is defined by the mathematics, byte grammars, equations, and registered
standards stated in this specification. It inherits no semantic domain,
algorithm, accumulator width, manifest implementation, API, cost model, or
optimization criterion from a software project. Unversioned supplied documents
and experimental reports are motivation only, not normative dependencies.

The normative external standards are:

- RFC 2119, *Key words for use in RFCs to Indicate Requirement Levels*, and
  RFC 8174, *Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words*,
  together BCP 14;
- RFC 8785, *JSON Canonicalization Scheme (JCS)*; and
- NIST FIPS 180-4, Update 1 (August 2015), *Secure Hash Standard*, for the
  exact SHA-256 function used by section 8.

The exact ordinary-NAF theorem dependency is identified below. No other
external paper, registry service, network endpoint, mutable namespace head,
software package, or benchmark is normative.

For

```text
w = sum_e d_e(w)*2^e,
```

integer distributivity gives

```text
a*w = sum_e d_e(w)*(a*2^e).
```

That identity follows from integer arithmetic. Every execution profile derives
its correctness from its registered `Ref_P`, and every optimality claim derives
from `X`, `M`, `U`, and its warrant; no implementation supplies or constrains
either fact.

The structural-specialization bridge is content-addressed but not circular:
the exact semantic payload and manifest bytes determine semantic identity;
verified domain contracts and fact certificates establish exact predicates
about that subject; refinement
theorems establish execution correctness; and comparison warrants establish
optimality. Later evidence may reference earlier identities, but no label,
domain, theorem, or proof graph is allowed to warrant itself.

The Atlas alphabet, shortlex mapping, prefix intervals, and page contiguity used
here are defined and derived in sections 5 and 10.4. Any additional Atlas state,
operator, quotient, spectral, locality, or execution claim requires its own
registered domain and correctness/optimality evidence. Experimental collapse
ratios are evidence records, not specification dependencies.

The fixture registry entries are bundled normative records. A third-party
state/operator profile supplies its exact content-addressed entry and warrants
through section 6.4's domain-admission context. Resolver implementation and
transport remain non-normative.

Section 8 fully defines its shallow RFC 8785 canonical JSON manifests and
SHA-256 label equations. Compatibility with another UOR addressing profile is
a separately testable profile relation; it is not inherited from a library
function or repository.

The sole external arithmetic theorem used normatively is the global-minimum-
weight result of James A. Muir and Douglas R. Stinson, *Minimality and Other
Properties of the Width-w Nonadjacent Form*, Mathematics of Computation 75
(2006), 369–384, Theorem 3.3, DOI
`10.1090/S0025-5718-05-01769-2`. Section 3.5 gives the exact `w=2` hypothesis
mapping. All other core laws claimed by this draft are proved internally.

This draft fixes ordinary NAF (`w=2`). A width-w extension requires a new
profile identifier, its larger odd digit set, a new canonical digit encoding,
and its own conformance vectors. It MUST NOT reinterpret
`uor-naf/1-draft.6` bytes or bytes under a later frozen stable identifier.
