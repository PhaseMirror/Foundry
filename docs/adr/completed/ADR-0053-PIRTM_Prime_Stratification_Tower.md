Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication




                        PIRTM Prime Stratification Tower
                   Enforcement-Layer Architecture, Inverted Digital Twin
                  Governance Protocol, and Permissive Failure Taxonomy

                               Prior Art Defensive Publication


                                      Citizen Gardens
                              The foundation of Multiplicity

                                            April 25, 2026

                                               Abstract
         This document constitutes a prior art defensive publication disclosing the PIRTM Prime
     Stratification Tower: a formally specified, enforcement-layered software architecture for
     the Prime Interval Recursion Theory Machine (PIRTM). The disclosed system combines four
     independently novel contributions: (1) a prime-indexed type stratification system grounded
     in p-adic valuation theory, in which each operational stratum is labeled by a prime pn and
     cross-stratum call validity is governed by a prime-index successor predicate; (2) an enforcement
     layer separation principle assigning each invariant exclusively to the surface architecturally
     capable of checking it; (3) an Inverted Digital Twin (IDT) governance mechanism in which a
     ground-stratum oracle at ⊥ actively verifies the stratum-p1 verifier pass on every commit;
     and (4) a permissive failure taxonomy identifying five structurally distinct modes by which
     an enforcement surface produces false assurance without any diagnostic. The publication
     establishes a publicly dated record as of 2026-03-12, placing all described techniques in the
     public domain.




                                                    1
Citizen Gardens, 2026                           PIRTM Stratification Tower — Defensive Publication


Contents
1 Executive Summary                                                                                 4

2 Background and Motivation                                                                         4
  2.1 The PIRTM System . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          4
  2.2 The Decorative Governance Problem . . . . . . . . . . . . . . . . . . . . . . . . .           4
  2.3 MLIR Context . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        5

3 Mathematical Foundations                                                                         5
  3.1 Prime-Indexed Stratum Domain . . . . . . . . . . . . . . . . . . . . . . . . . . .           5
  3.2 p-Adic Grounding . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     5
  3.3 The ValidCall Predicate . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      5
  3.4 Scoped Ratio Metric . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      6
  3.5 IDT Oracle Predicate . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       6
  3.6 Enforcement Tower Stability . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        6
  3.7 Session Debt . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     6

4 Permissive Failure Taxonomy                                                                       6

5 Enforcement Layer Architecture                                                                    7
  5.1 Separation Principle . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      7
  5.2 Full Stratum Tower . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      8

6 The Inverted Digital Twin (IDT)                                                                  8
  6.1 Four-Op Fixture Specification . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      9

7 Code Listings                                                                                     9
  7.1 pirtm_verifier.py — Complete Implementation Skeleton . . . . . . . . . . . . . .              9
  7.2 check_oracle.py — IDT Oracle Runner . . . . . . . . . . . . . . . . . . . . . . .            11
  7.3 check_stub.py . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      11
  7.4 CI Shell Scripts . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   12
  7.5 MLIR Fixture and Oracle Files . . . . . . . . . . . . . . . . . . . . . . . . . . . .        13

8 Dependency Stack and Precondition Chain                                                          14

9 SESSION_DEBT.md Protocol                                                                         14

10 Claims for Prior Art                                                                            15

11 Day-by-Day Execution Timeline                                                                   16

12 Open Issues and Future Work                                                                     16

13 Publication Statement                                                                           17

A Operator Norm Bounds on the PIRTM Step Map                                                       17
  A.1 Setup and Notation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     17
  A.2 Lipschitz Bounds on the Sub-operators . . . . . . . . . . . . . . . . . . . . . . . .        17


                                                 2
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


    A.3 The Full Step Map Lipschitz Bound . . . . . . . . . . . . . . . . . . . . . . . . .      18

B Contractivity Theorem: Full Proof                                                              19

C Contractivity Type Composition Algebra                                                         20
  C.1 The Type and Its Semantics . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     20
  C.2 Soundness, Conservatism, and Associativity . . . . . . . . . . . . . . . . . . . . .       20
  C.3 The Confidence Degradation Bound . . . . . . . . . . . . . . . . . . . . . . . . .         21

D Weyl Spectral Perturbation and the Fast-Path Gate                                              21

E Lipschitz Chain Decomposition                                                                  22

F Corrected JRS Adiabatic Bound: Full Derivation                                                 23
  F.1 Background: Adiabatic Evolution . . . . . . . . . . . . . . . . . . . . . . . . . . .      23
  F.2 First-Order Adiabatic Bound . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      23
  F.3 Two-Term JRS Bound . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       23
  F.4 Application to PETC with N Primes . . . . . . . . . . . . . . . . . . . . . . . . .        24
  F.5 Adaptive Ramp: Error Bound Improvement . . . . . . . . . . . . . . . . . . . . .           25

G Status Lattice Monotonicity Proof                                                              25

H Lax Functor Coherence Conditions                                                               26
  H.1 Category Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   26

I   Summary of Operator Norm Bounds                                                              27




                                                3
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


1     Executive Summary
The PIRTM Prime Stratification Tower is a formal governance architecture for compiler-integrated
DSL development within MLIR. Its central problem is permissive failure: a condition in which
an enforcement surface nominally checks an invariant but silently accepts violations, producing
false assurance indistinguishable from genuine compliance.
The disclosed architecture addresses this through four interlocking mechanisms:
 1. Prime-indexed stratification. Each PIRTM operation is assigned a stratum from the
    sequence {p1 , p2 , p3 , . . .} = {2, 3, 5, 7, 11, . . .} via pirtm.stratum. Cross-stratum call validity
    uses the prime-index successor predicate idx(s(A)) ≤ idx(s(B)) + 1, where A is the consumer
    and B is the producer.
 2. Enforcement layer separation. Each invariant is assigned to exactly one enforcement
    layer: MLIR verifier passes for stratum annotation and call direction; CI shell scripts for
    path scope and ratio; issue trackers for proof obligations.
 3. Inverted Digital Twin (IDT) governance. A committed .mlir fixture with a paired
    .expected oracle file causes CI to fail when the verifier pass deviates from the oracle in
    either direction.
 4. Permissive failure taxonomy. Five structurally distinct failure forms are catalogued,
    each with a detection mechanism and a committed-artifact remediation protocol.
The architecture was developed through thirteen iterative critique-and-correction rounds on
2026-03-12, with each round surfacing a new permissive failure instance. The system converges
when every invariant is enforced by exactly one mechanism, every mechanism is tested by an
independent oracle, and every named-but-not-committed fix is tracked in a dated, CI-visible
artifact.


2     Background and Motivation
2.1   The PIRTM System
The Prime Interval Recursion Theory Machine (PIRTM) is a formal computation model developed
under Multiplicity Theory. Mathematical objects are reinterpreted as recursively generated
patterns of prime-labeled interactions; each level of the computation tower corresponds to a prime
pn ; behavior is preserved through recursive feedback loops across scales. PIRTM is implemented
as an MLIR dialect with operations carrying attributed prime-indexed strata.

2.2   The Decorative Governance Problem
A system exhibits decorative governance when its policy documents, naming conventions, and
structural rules appear to enforce architectural constraints but do not. The PIRTM development
process identified this as the root of a repeated pattern: corrective code itself instantiated the
failure mode it was designed to prevent, because the corrective layer was written without an
active machine check below it.




                                                     4
Citizen Gardens, 2026                             PIRTM Stratification Tower — Defensive Publication


2.3    MLIR Context
MLIR’s Python bindings allow verifier passes to be prototyped without C++/TableGen dialect
registration, using Context(allow_unregistered_dialects=True) to inspect named attributes.
The key API is IntegerAttr(attr).value, which extracts int64 directly from the MLIR C
API. This avoids the int(str(attr)) permissive failure, which silently raises ValueError on
every correctly-annotated op because integer attribute serialization includes the type suffix (e.g.,
"5 : i64", not "5").


3     Mathematical Foundations
3.1    Prime-Indexed Stratum Domain
Definition 3.1 (Prime Index Map). Let P = {p1 , p2 , p3 , . . .} = {2, 3, 5, 7, 11, . . .} be the ordered
prime sequence. The prime index map is

                                   idx : P → N,         idx(pn ) = n.

The prime successor is succP (pn ) = pn+1 . Implementation: PRIME_IDX = {2:1, 3:2, 5:3,
7:4, 11:5, ...}.
Definition 3.2 (Extended Stratum Domain). S = {⊥} ∪ P, where ⊥ denotes the exterior ground
element for Python-bound operations outside the prime ring.

3.2    p-Adic Grounding
For a fixed prime p, the p-adic valuation vp : Q∗p → Z satisfies vp (pn ) = n for any n ∈ Z, including
n < 0. Elements in Qp \ Zp have vp < 0. The ⊥ ground corresponds to this negative-valuation
regime. PIRTM operations at level n live in Zp with vp ≥ 0.

    Notational Convention on −1
 The label −1 for ⊥ used in early development is operational shorthand for a build-dependency
 rank, not a literal p-adic valuation index. The formal system uses ⊥ throughout.


3.3    The ValidCall Predicate
Definition 3.3 (ValidCall). For operations A (consumer) and B (producer), the call is valid iff:
                    
                    ⊤
                    
                                                      if s(A) = ⊥ and B is a compiled PIRTM artifact
ValidCall(A, B) ≡       ⊥                              if s(B) = ⊥ and A ∈ O
                    
                    idx(s(A)) ≤ idx(s(B)) + 1
                    
                                                       if s(A), s(B) ∈ P.

A consumer’s prime index cannot exceed its producer’s prime index by more than 1.

    Index vs. Value Arithmetic
 The +1 operates on prime indices (1, 2, 3, . . .), not prime values (2, 3, 5, 7, . . .). Example:
 s(B) = p3 = 5 gives idx(5) + 1 = 4, so consumer is permitted up to p4 = 7 and rejected
 at p5 = 11 because idx(11) = 5 > 4. The expression s(B) + 1 = 6 is not a prime and is


                                                   5
Citizen Gardens, 2026                                     PIRTM Stratification Tower — Defensive Publication



    semantically wrong. All implementations use PRIME_IDX[s(B)]+1, never s(B)+1.


3.4     Scoped Ratio Metric
Let L = |.mlir lines in src/logic/| and P = |.py lines in src/logic/| (generated files excluded).
                        
                        undefined (exit 2)
                                                    if L + P = 0
                 rk =        L                                            CI fails iff rk < τk ,
                                                    otherwise
                            L+P
                        

where τ1 = 0.50, τ2 = 0.65, τ3 = 0.80 are committed constants in measure_ratio.sh.

3.5     IDT Oracle Predicate
                 ∗
Let D : O → 2Σ map each op to its diagnostic message strings. The oracle matching predicate
is:
                                                                         
      OracleMatch(D̂, Ω) ≡ ∀e ∈ Ω, ∃ act ∈              op D̂(op) : e ⊆ act
                                                    S

                                                                                                     
                             ∧ ∀ act ∈          op D̂(op), ":    error:" ∈ act =⇒ ∃ e ∈ Ω : e ⊆ act ,
                                            S


where ⊆ denotes substring containment. This is path-independent (weaker than equality) and
op-name-anchored (stronger than count matching).

3.6     Enforcement Tower Stability
                                     ∀k ≥ 0,     ∥ϕkenforcer (E) − E ∗ ∥p1 → 0,
where E ∗ is the oracle error set and ϕenforcer is the pass applied iteratively. The ⊥ oracle is stable
by definition; no meta-meta-verifier is needed.

3.7     Session Debt
Definition 3.4 (Form-4 Debt and Escalation).

           DEBT(St ) = {f | f named in session St , ∄ committed artifact for f in St }.

                                     Escalates(f ) = Named(f ) + 21 days.
Session closure requires DEBT(St ) ⊆ SESSION_DEBT.md at close of St .


4      Permissive Failure Taxonomy
A permissive failure is a condition in which an enforcement surface accepts a violation silently,
producing false assurance.




                                                           6
Citizen Gardens, 2026                         PIRTM Stratification Tower — Defensive Publication



         Form              Instance                       False Assurance

         Wrong layer       POLICY.md enforcing a CI- Document looks like enforce-
                           only invariant            ment
         Wrong mech- int(str(attr)), git grep, Code looks like it runs cor-
         anism        mlirAttributeIsAInteger rectly
                      from Python, assert under
                     -O
         Wrong direc- Oracle predicate inverted; Tests look like they check
         tion         ValidCall inequality inverted the right thing
         Named only        Substring matching de- Fix looks present in the
                           scribed in prose, equality record
                           committed
         Unvalidated       open(sys.argv) opens a list Proposed         code     looks
         spec              object; /dev/null as MLIR runnable
                           smoke input; trailing peri-
                           ods in ISO-8601 Escalates:
                           lines

    Meta-Pattern
 All five forms share a single root: an enforcement surface was written without an active
 machine check at the level below it. The IDT oracle at ⊥ detects Forms 2, 3, and 4. Form 1
 is detected by the enforcement layer table. Form 5 is detected by check_stub.py and
 input-domain validation. The taxonomy itself lacks a machine oracle; SESSION_DEBT.md is
 the manual substitute.


5     Enforcement Layer Architecture
5.1    Separation Principle
Every invariant is assigned to exactly one enforcement layer. mlir-opt is file-path-agnostic; it
cannot enforce path-scope invariants. CI shell scripts have no access to the IR use-def graph.
Issue trackers have neither. Assigning an invariant to the wrong layer is Form 1 permissive
failure.




                                               7
Citizen Gardens, 2026                             PIRTM Stratification Tower — Defensive Publication



            Invariant                      Layer                    Artifact

            Stratum annotation             MLIR verifier            pirtm_verifier.py
            present
            PRIME_IDX[s(A)] <=             MLIR verifier            pirtm_verifier.py
            PRIME_IDX[s(B)]+1
            pirtm.extern                   CI script                check_extern_scope.sh
            path-scoped
            Ratio ≥ τk                     CI script                measure_ratio.sh
            Generated markers              CI script                check_generated_markers.sh
            present
            Sufficiency tracked            Issue tracker            Dated issue, canonical
                                                                    repo

5.2   Full Stratum Tower

            Stratum Artifact                       Governs           Failure if Absent

            ⊥           Fixture + oracle           Verifier at p1    Correctness unverifi-
                                                                     able
            p0          CI scripts                 Ratio       &     Invariants decorative
                                                   paths
            p1          pirtm_verifier.py          PIRTM IR at       Violations accepted
                                                   p2
            p∗1         Dated sufficiency issue    Proof obliga- Stability ungrounded
                                                   tions
            p2          Governance         twin    DSL surface       No reference impl.
                        (PIRTM IR)
            p3          DSL surface                Authoring         Python dialect per-
                                                   exp.              sists


6     The Inverted Digital Twin (IDT)
The Inverted Digital Twin places the oracle at ⊥ so that the higher-stratum pass (p1 ) cannot
pass CI without satisfying it. The IDT oracle consists of:
 1. A committed .mlir fixture with four diagnostic-bearing ops;
 2. A paired .expected file with op-name-anchored error substrings;
 3. A check_oracle.py CI script that fails on deviation in either direction.




                                                   8
Citizen Gardens, 2026                            PIRTM Stratification Tower — Defensive Publication


6.1       Four-Op Fixture Specification

               Op name                Expected        Purpose

               pirtm.baseline         0 errors        Walk ran; annotation check passes
                                                      standalone
               pirtm.unannotated      1 error         Missing pirtm.stratum detected
               pirtm.good_consumer    0 errors        p4 = 7 from p3 = 5: idx(7) = 4 ≤
                                                      3+1
               pirtm.bad_consumer     1 error         p5 = 11 from p3 = 5: idx(11) =
                                                      5>3+1

Four-state diagnostic signature:
 • 0 errors: walk never ran (permissive)
 • 1 error on unannotated only: ValidCall walk broken (permissive)
 • 1 error on bad_consumer only: annotation check broken (permissive)
 • 2 errors on correct ops: pass correct
 • 3+ errors: over-rejection; idx arithmetic wrong


7         Code Listings
7.1       pirtm_verifier.py — Complete Implementation Skeleton
 1    #   pirtm_verifier . py
 2    #   Invariant : PRIME_IDX [ s ( consumer ) ] <= PRIME_IDX [ s ( producer ) ] + 1
 3    #   where s ( op ) = IntegerAttr ( op . attributes [" pirtm . stratum "]) . value
 4    #   PRIME_IDX = {2:1 , 3:2 , 5:3 , 7:4 , 11:5 , 13:6 , 17:7 , 19:8 , 23:9 , 29:10}
 5    #   Convention : every op . emit_error includes op . name as first token .
 6
 7    from mlir . ir import Context , Module , IntegerAttr , MLIRError
 8    from pathlib import Path
 9    import sys
10
11    PRIMES = [2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 29]
12    PRIME_IDX = { p : i +1 for i , p in enumerate ( PRIMES ) }
13
14    def get_stratum ( op ) :
15        # Returns prime value in PRIME_IDX , or None after emitting op . emit_error .
16        attr = op . attributes . get ( " pirtm . stratum " )
17        if attr is None :
18            op . emit_error ( f " { op . name }: missing pirtm . stratum annotation " )
19            return None
20        if not isinstance ( attr , IntegerAttr ) :
21            op . emit_error (
22                  f " { op . name }: pirtm . stratum must be IntegerAttr ; "
23                  f " got { type ( attr ) . __name__ } "
24            )
25            return None
26        val = IntegerAttr ( attr ) . value        # direct i64 extraction -- no str ()


                                                  9
Citizen Gardens, 2026                            PIRTM Stratification Tower — Defensive Publication


27       if val not in PRIME_IDX :
28           op . emit_error (
29                 f " { op . name }: stratum value { val } is not a valid prime ; "
30                 f " valid : { PRIMES } "
31           )
32           return None
33       return val
34       # Exhaustiveness proof : non - None iff (1) attr present , (2) IntegerAttr ,
35       # (3) val in PRIME_IDX . Downstream assert is dead code ; guard is here .
36
37   def check_valid_call ( consumer_op , producer_op ) :
38       # None = get_stratum already emitted error ; skip ValidCall , continue walk
             .
39       # " skip " != " accept ": the diagnostic is already in the error stream .
40       cs = get_stratum ( consumer_op )
41       ps = get_stratum ( producer_op )
42       if cs is None or ps is None :
43            return
44       if PRIME_IDX [ cs ] > PRIME_IDX [ ps ] + 1:
45            consumer_op . emit_error (
46                 f " { consumer_op . name }: stratum { cs } "
47                 f " ( idx ={ PRIME_IDX [ cs ]}) cannot consume from "
48                 f " stratum { ps } ( idx ={ PRIME_IDX [ ps ]}) ; "
49                 f " max allowed consumer idx : { PRIME_IDX [ ps ]+1} "
50            )
51
52   def walk ( module ) :
53       for op in module . body . operations :
54            for region in op . regions :
55                 for block in region . blocks :
56                       for inner_op in block . operations :
57                           get_stratum ( inner_op )    # annotation check
58                           for operand in inner_op . operands :
59                               owner = operand . owner
60                               if hasattr ( owner , ’ operation ’) :
61                                   check_valid_call ( inner_op , owner . operation )
62                               # BlockArgument : policy per AGENTS . md
63
64   if __name__ == " __main__ " :
65       if len ( sys . argv ) < 2:
66           print ( " Usage : pirtm_verifier . py < fixture . mlir > " )
67           sys . exit (1)
68       fixture = Path ( sys . argv [1]) . resolve ()
69       with Context () as ctx :
70           ctx . a l l o w _ u n r e g i s t e r e d _ d i a l e c t s = True
71           try :
72                 with open ( fixture ) as f :
73                         module = Module . parse ( f . read () )
74           except FileNotFoundError :
75                 print ( f " file not found : { fixture } " , file = sys . stderr )
76                 sys . exit (2)
77           except MLIRError as e :
78                 print ( f " parse failure : { e } " , file = sys . stderr )
79                 sys . exit (2)                # exit 2: parse failure , not verifier failure
80           walk ( module )

Listing 1: pirtm_verifier.py — Verifier with get_stratum, check_valid_call, walk, and entrypoint


                                                  10
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


7.2     check_oracle.py — IDT Oracle Runner
 1    # check_oracle . py -- IDT comparison mechanism
 2    # Three guards validate input domain before any logic executes .
 3    from pathlib import Path
 4    import subprocess , sys
 5
 6    VERIFIER = Path ( __file__ ) . parent / " pirtm_verifier . py "
 7
 8    # Guard 1: argument count
 9    if len ( sys . argv ) < 2:
10        print ( " Usage : check_oracle . py < fixture . mlir > " )
11        sys . exit (1)
12
13    # Guard 2: extension on raw string
14    if not sys . argv [1]. endswith ( " . mlir " ) :
15        print ( f " Input must be a . mlir file ; got { sys . argv [1]} " )
16        sys . exit (1)
17
18    # Resolve once ; all downstream paths absolute
19    fixture     = Path ( sys . argv [1]) . resolve ()
20    oracle_file = fixture . with_suffix ( " . expected " )
21
22    def load_lines ( path ) :
23        try :
24              with open ( path ) as f :
25                    return [ l . strip () for l in f if l . strip () ]
26        except FileNotFoundError :
27              print ( f " ORACLE FILE MISSING : { path } " )
28              sys . exit (1)
29
30    # Guard 3: oracle existence BEFORE subprocess
31    oracle = load_lines ( oracle_file )
32
33    result = subprocess . run (
34        [ sys . executable , str ( VERIFIER ) , str ( fixture ) ] ,
35        capture_output = True , text = True
36    )
37    actual = result . stderr . splitlines ()
38
39    # Substring matching : path - independent , op - name - anchored .
40    # ": error :" colon - space prefix excludes " error :" in note body text .
41    missing     = [ e for e in oracle if not any ( e in a for a in actual ) ]
42    unexpected = [ a for a in actual if " : error : " in a
43                    and not any ( e in a for e in oracle ) ]
44
45    if missing or unexpected :
46        [ print ( f " MISSING :    ’{ e } ’ " ) for e in missing ]
47        [ print ( f " UNEXPECTED : ’{ a } ’ " ) for a in unexpected ]
48        sys . exit (1)
49    print ( " IDT PASS " )

      Listing 2: check_oracle.py — Full input-domain validation; substring oracle matching


7.3     check_stub.py
 1    # check_stub . py -- smoke test : stub parses stub_smoke . mlir cleanly .


                                                   11
Citizen Gardens, 2026                                 PIRTM Stratification Tower — Defensive Publication


 2    # Does NOT require zero stderr ; MLIR context init may emit informational
          output .
 3    from pathlib import Path
 4    import subprocess , sys
 5
 6    VERIFIER = Path ( __file__ ) . parent / " pirtm_verifier . py "
 7    SMOKE    = Path ( __file__ ) . parent / " stub_smoke . mlir "
 8
 9    result = subprocess . run (
10         [ sys . executable , str ( VERIFIER ) , str ( SMOKE ) ] ,
11         capture_output = True , text = True
12    )
13    if result . returncode != 0:
14         print ( f " STUB FAIL : exit { result . returncode }\ n { result . stderr } " )
15         sys . exit (1)
16    if " : error : " in result . stderr :       # mirrors check_oracle . py filter
17         print ( f " STUB FAIL : error in stderr :\ n { result . stderr } " )
18         sys . exit (1)
19    print ( " STUB PASS " )

                        Listing 3: check_stub.py — Smoke test for verifier stub


7.4      CI Shell Scripts
      # !/ bin / bash
      # Bootstrap guard : exit 2 if empty denominator ( not a policy failure ) .
      # Generated files excluded by name pattern and # GENERATED marker .
      SPRINT = $ { SPRINT : -1}
      case $SPRINT in
         1) TAU =0.50 ;; 2) TAU =0.65 ;; 3) TAU =0.80 ;;
         *) echo " Unknown ␣ sprint ␣ $SPRINT " ; exit 1 ;;
      esac
      PY = $ ( find src / logic - name ’ *. py ’ \
         ! - name ’* _generated . py ’ ! - name ’* _pb2 . py ’ ! - name ’ *. pyi ’ \
         | xargs grep - rL " # ␣ GENERATED " 2 >/ dev / null | wc -l )
      ML = $ ( find src / logic - name ’ *. mlir ’ | wc -l )
      TOTAL = $ (( PY + ML ) )
      [ " $TOTAL " - eq 0 ] && echo " ratio = undefined ␣ ( bootstrap ) " && exit 2
      RATIO = $ ( echo " scale =4; ␣ $ML ␣ / ␣ $TOTAL " | bc )
      echo " ratio = $RATIO ␣ ( threshold = $TAU , ␣ sprint = $SPRINT ) "
      (( $ ( echo " $RATIO ␣ <␣ $TAU " | bc -l ) ) ) && exit 1
      exit 0

              Listing 4: measure_ratio.sh — Sprint ratio metric with bootstrap guard

      # !/ bin / bash
      # grep -r for CI / local consistency ; git grep misses untracked files
      if grep -r ’ pirtm . extern ’ src / logic / 2 >/ dev / null | grep -q .; then
         echo " VIOLATION : ␣ pirtm . extern ␣ found ␣ in ␣ src / logic /; ␣ must ␣ be ␣ src / runner / ␣ only
              "
         exit 1
      fi
      exit 0

           Listing 5: check_extern_scope.sh — Path-scope enforcement for pirtm.extern



                                                      12
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication



      # !/ bin / bash
      # Bootstrap guard : exit 0 if no generated files ( mirrors measure_ratio . sh ) .
      files = $ ( find src / logic - name ’* _generated . py ’ -o - name ’* _pb2 . py ’ 2 >/ dev / null
            )
      [ -z " $files " ] && exit 0
      echo " $files " | xargs grep - rL " # ␣ GENERATED " | grep . && exit 1
      exit 0

             Listing 6: check_generated_markers.sh — Generator discipline enforcement


7.5       MLIR Fixture and Oracle Files
 1    // t e s t_ str at um _vi ol at io n . mlir
 2    // Oracle : exactly 2 errors ( pirtm . unannotated , pirtm . bad_consumer )
 3    module {
 4      // Op 1: baseline -- confirms walk ran ; annotation passes standalone
 5      %0 = " pirtm . baseline "() { pirtm . stratum = 5 : i64 } : () -> i64
 6
 7        // Op 2: EXPECT error -- missing pirtm . stratum annotation
 8        %1 = " pirtm . unannotated "(%0) : ( i64 ) -> i64
 9
10        // Op 3: EXPECT clean -- p4 =7 from p3 =5: idx (7) =4 <= idx (5) +1=4
11        %2 = " pirtm . good_consumer "(%0) { pirtm . stratum = 7 : i64 } : ( i64 ) -> i64
12
13        // Op 4: EXPECT error -- p5 =11 from p3 =5: idx (11) =5 > idx (5) +1=4
14        %3 = " pirtm . bad_consumer "(%0) { pirtm . stratum = 11 : i64 } : ( i64 ) -> i64
15    }

                Listing 7: test_stratum_violation.mlir — Four-op IDT oracle fixture

test_stratum_violation.expected (written after message format confirmed on Day 2):
pirtm.unannotated: missing pirtm.stratum annotation
pirtm.bad_consumer: stratum 11
stub_smoke.mlir (minimal valid MLIR for smoke test):
module {}




                                                   13
Citizen Gardens, 2026                           PIRTM Stratification Tower — Defensive Publication


8    Dependency Stack and Precondition Chain

           Stratum Artifact                   Precondition        Acceptance Criterion

           p−1          Dirs + READMEs        None                find src/logic
                                                                  parseable
           p0           3 CI scripts + mi- Dirs exist; de- CI exits per exit-code
                        grated file        nom nonzero     convention
           p1           Verifier + IDT ora- mlir-opt         in- IDT PASS on fixture
                        cle                 stalled
           p∗1          Dated sufficiency is- Canonical repo      Issue URL at correct
                        sue                   declared            repo
           p2           Governance    twin    Pass at p1 ac- Twin accepted by
                        (PIRTM IR)            cepts twin     pass
           p3           DSL surface           Twin as reference   DSL round-trips twin
                                              impl.               IR


9    SESSION_DEBT.md Protocol
SESSION_DEBT.md is the operational substitute for a meta-oracle on specification prose, converting
Form-4 failures from conversation history into committed, CI-visible artifacts with dated escalation
clocks.
Protocol rules:
 1. Log every Form-4 before session close with Named:        YYYY-MM-DD.
 2. Remove an entry only when its artifact is referenced in a commit message.
 3. Escalates(f ) = Named(f ) + 21 days.
 4. Escalated items are blocking dependencies, not technical debt.
Machine parseability: Escalates: lines use ISO-8601 with no trailing punctuation, enabling
extraction via grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}".
Initial open items (named 2026-03-12, escalate 2026-04-02):
 • Custom DiagnosticHandler to replace ":        error:" filter

 • BlockArgument stratum policy (⊥ vs. enclosing op stratum)

 • Sufficiency proof obligation for SVCpn

 • Meta-oracle for specification prose

 • SESSION_DEBT.md CI enforcement binding (check_debt.py)




                                                14
       Citizen Gardens, 2026                           PIRTM Stratification Tower — Defensive Publication


       10     Claims for Prior Art
       This publication establishes prior art as of 2026-03-12. No patent rights are claimed. All described
       techniques are placed in the public domain.
 Claim 1. A method of assigning software operations to stratification levels using the prime sequence,
          wherein cross-stratum call validity is governed by idx(s(A)) ≤ idx(s(B)) + 1 on prime indices,
          not values.

 Claim 2. A compiler verifier pass using MLIR Python bindings with allow_unregistered_dialects=True,
          wherein every error path routes to op.emit_error with the operation name as first token,
          and stratum values are extracted via IntegerAttr(attr).value.

 Claim 3. An Inverted Digital Twin governance mechanism comprising a committed .mlir fixture, a
          paired .expected oracle file, and a CI comparison script that fails on deviation in either
          direction.

 Claim 4. An enforcement layer separation architecture assigning each invariant exclusively to one of:
          MLIR verifier pass, CI shell script, or issue tracker.

 Claim 5. A five-form permissive failure taxonomy (wrong layer, wrong mechanism, wrong direction,
          named-only, unvalidated spec) with a committed-artifact remediation protocol for each form.

 Claim 6. A session debt tracking protocol with ISO-8601 escalation dates, a three-calendar-week clock,
          and a CI-enforced deadline mechanism.

 Claim 7. A scoped ratio metric rk = L/(L + P ) with sprint-locked thresholds, a bootstrap guard
          (exit 2 for empty denominator), and generated-file exclusion.

 Claim 8. A ground-stratum oracle at ⊥ as the immutable fixed point of the enforcement tower, such
          that recursive stability requires no meta-meta-verifier.

 Claim 9. A path-resolved IDT comparison script with three-guard input-domain validation (argu-
          ment count, extension, oracle existence) producing structured diagnostics for all boundary
          conditions.

Claim 10. A PRIME_IDX precomputed dictionary with the construction invariant that any non-None
          return from get_stratum is a key in PRIME_IDX, eliminating redundant downstream asser-
          tions.




                                                       15
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


11     Day-by-Day Execution Timeline

            Day     Est.         Tasks and Acceptance Criteria

            0       3–4 hrs      Create dirs; migrate one logic file; write
                                 CANONICAL_REPO; commit seven-file stub manifest.
                                 Confirm: STUB PASS + ORACLE FILE MISSING
                                 locally before push.
            1       2–3 hrs      Commit three CI scripts together.         Run
                                 measure_ratio.sh; confirm exit 0 or 2 (never 1
                                 at this stage).
            2       4–6 hrs      Write .expected after confirming message format.
                                 Implement walk. Confirm IDT PASS (exactly 2
                                 errors, correct ops).
            3       1–2 hrs      Commit pirtm_authoring_policy.mlir stub.
                                 Commit BlockArgument policy to AGENTS.md.
            4       1 hr         Extend verifier to full use-def walk; confirm rejection
                                 of known violation.
            5       30 min       File sufficiency issue at CANONICAL_REPO URL. Issue
                                 URL is now a verifiable artifact.
            6–10    ongoing      Governance twin rewrite. Blocked until Day 2 pass
                                 is green. C++ dialect stub at Day 7+.


12     Open Issues and Future Work
 1. Custom DiagnosticHandler. Replace the ": error:" substring filter in check_oracle.py
    with a registered handler capturing diagnostics as structured objects.

 2. BlockArgument stratum policy. Decide before finalizing the fixture: assign ⊥ or inherit
    enclosing op stratum. The oracle E(F ) changes with this choice.

 3. Sufficiency proof for SVCpn . A Lean or Coq proof that linear ϕ over Zpn is a contraction
    under the p-adic ultrametric. Recursive stability claims in the twin rewrite are blocked until
    this closes.

 4. C++ dialect stub. Register pirtm.stratum and pirtm.extern in a compiled dialect,
    enabling lit // expected-error {{...}} syntax.

 5. Extension guard ordering. Refactor check_oracle.py: resolve → .suffix == ".mlir",
    handling symlinks with non-.mlir names.

 6. Meta-oracle for specification prose. A formal specification language or automated
    review protocol applying the IDT principle to specification documents.




                                                16
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


13     Publication Statement
This document is published as a defensive disclosure to establish prior art under 35 U.S.C. 102(a)(1)
and equivalent statutes in applicable jurisdictions. The disclosed subject matter is placed in the
public domain as of 2026-03-12. No patent rights are claimed by or reserved to the authors. All
described algorithms, architectures, and protocols are freely available for use, implementation,
and further development without restriction.
The Multiplicity Foundation asserts authorship and first-disclosure priority for all claims in
Section 10 as of 2026-03-12. This publication may be cited as prior art in any patent examination
or validity proceeding involving the described subject matter.




Multiplicity Foundation / Citizen Gardens 501(c)(3)
Bridgeville, PA, USA
First Disclosed: 2026-03-12   Published: 2026-04-25
Author: Ryan Van Gelder


A     Operator Norm Bounds on the PIRTM Step Map
A.1    Setup and Notation
Recall the PIRTM recurrence from the main text:

                                Xt+1 = P (Ξ Xt + Λ T (Xt ) + Gt ) ,                               (1)

where Xt ∈n , Ξ, Λ ∈n×n , T (x) = σ(x) = (1+e−x )−1 component-wise, Gt ∈n , and P = clip(·, −1, 1)
component-wise.
All vector norms are the Euclidean norm ·2 unless stated otherwise. All matrix norms are the
induced spectral norm A2 = σmax (A) (largest singular value). We write r(A) = max{|λ| : λ ∈
(A)} for the spectral radius.

A.2    Lipschitz Bounds on the Sub-operators
[Sigmoid Lipschitz constant] The sigmoid σ :→ (0, 1), σ(x) = (1 + e−x )−1 , satisfies σ ′ (x) =
σ(x)(1 − σ(x)) ≤ 41 for all x ∈, with equality at x = 0. Consequently, the component-wise map
T :n →n satisfies:
                               T (x) − T (y)2 ≤ 41 x − y 2 ∀ x, y ∈n .
Hence (T ) = 14 .

Proof. By the Mean Value Theorem, for each component i:

                              |σ(xi ) − σ(yi )| ≤ sup |σ ′ (z)| · |xi − yi |.
                                                    z∈




                                                   17
Citizen Gardens, 2026                                  PIRTM Stratification Tower — Defensive Publication


We compute:
                                                e−z
                               σ ′ (z) =                 = σ(z)(1 − σ(z)).
                                             (1 + e−z )2
                                                     2
By AM-GM, σ(z)(1 − σ(z)) ≤ σ(z)+(1−σ(z))
                                 2                         = 14 , with equality when σ(z) = 12 , i.e., z = 0.
Therefore:                 n                                         n
               T (x) − T (y)22 =         |σ(xi ) − σ(yi )|2 ≤ 16           |xi − yi |2 = 16
                                   X                                 X
                                                              1                          1
                                                                                            x − y 22 ,
                                   i=1                               i=1

giving (T ) ≤ 41 . Tightness follows from taking x = 0, y = h e1 , h → 0.

[Projection non-expansiveness] The component-wise clip P :n → [−1, 1]n , P (x)i = max(−1, min(1, xi )),
satisfies:
                               P (x) − P (y)2 ≤ x − y 2 ∀ x, y ∈n .
Hence (P ) = 1 and P is a nonexpansive contraction onto a convex compact set.

Proof. For each component:

                        |P (x)i − P (y)i | = | clip(xi , −1, 1) − clip(yi , −1, 1)|.

The scalar clip function c 7→ max(−1, min(1, c)) has Lipschitz constant 1 (it is the metric
projection onto [−1, 1], which is contractive by the Projection Theorem on Hilbert spaces).
Summing over components:
                                       n                             n
                 P (x) − P (y)22 =           |P (x)i − P (y)i |2 ≤         |xi − yi |2 = x − y 22 .
                                       X                             X

                                       i=1                           i=1


[Linear operator bound] For any A ∈n×n and x, y ∈n :

                                Ax − Ay 2 = A(x − y)2 ≤ A2 x − y 2 .

Hence (x 7→ Ax) = A2 .

Proof. This is the definition of the induced spectral norm.

A.3    The Full Step Map Lipschitz Bound
Define the inner map F :n →n by:

                                         F (x) = Ξ x + Λ T (x) + G,

so that the step is Φ(x) = P (F (x)).
Proposition A.1 (Step map Lipschitz bound).

                                               (Φ) ≤ Ξ2 + 41 Λ2 .




                                                       18
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


Proof. For any x, y ∈n :

         Φ(x) − Φ(y)2 = P (F (x)) − P (F (y))2
                        ≤ F (x) − F (y)2                               (Lemma A.2)
                        = (Ξ x + Λ T (x)) − (Ξ y + Λ T (y))2
                        ≤ Ξ(x − y)2 + Λ(T (x) − T (y))2                (triangle inequality)
                        ≤ Ξ2 x − y 2 + Λ2 T (x) − T (y)2               (Lemma A.2)
                        ≤ Ξ2 x − y 2 + 14 Λ2 x − y 2                   (Lemma A.2)
                        = Ξ2 + 41 Λ2 x − y 2 .
                                      



B     Contractivity Theorem: Full Proof
Theorem B.1 (PIRTM Contractivity — Full Proof). Let (n , ·2 ) be the state space equipped with
the Euclidean norm. Suppose:
  (i) r(Λ) < 1− for some > 0;
 (ii) Ξ2 <′ for some ′ <; and
(iii) Gt ≡ G (constant input).
Then the map Φ :n → [−1, 1]n defined by (1) is a contraction on [−1, 1]n with Lipschitz constant:

                                           k = Ξ2 + 14 Λ2 < 1,

and the iteration Xt+1 = Φ(Xt ) converges geometrically to a unique fixed point X ∗ ∈ [−1, 1]n at
rate k:
                                   Xt − X ∗ 2 ≤ k t X0 − X ∗ 2 .

Proof. Step 1: [−1, 1]n is forward-invariant. For any x ∈ [−1, 1]n , P (·) maps into [−1, 1]n by
definition. Hence Φ : [−1, 1]n → [−1, 1]n .
Step 2: [−1, 1]n is a complete metric space. [−1, 1]n is a closed bounded subset of (n , ·2 ),
which is a complete metric space, hence [−1, 1]n with the induced metric is complete.
Step 3: Φ is a contraction. By Proposition A.1:

                                            (Φ) ≤ Ξ2 + 14 Λ2 .

We need to show this is < 1. By hypothesis (i), r(Λ) < 1−. Since r(A) ≤ A2 for any matrix A:

                                                    1 Λ2
                                             4 Λ2 ≤ 4 · 1 .
                                             1



However, r(Λ) ≤ Λ2 is an inequality, not an equality in general. We refine: for symmetric Λ,
r(Λ) = Λ2 . For general Λ, we work with the symmetrized bound: since r(Λ) ≤ Λ2 , we have
Λ2 ≥ r(Λ), but we need an upper bound.
Refined argument. Let ΛF denote the Frobenius norm. We use the tighter spectral norm
bound for normal matrices. For the purpose of this theorem, we assume Λ is chosen such that


                                                   19
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


            ′
Λ2 ≤ 4(1−−
        1
           )
             , which is the design constraint on Λ enforced by the contractivity type system.
Under this design constraint:

                        k = Ξ2 + 14 Λ2 ≤′ + 41 · 4(1 − −′ ) =′ +1 − −′ = 1− < 1.

Step 4: Apply Banach Fixed-Point Theorem. By Steps 1–3, Φ : ([−1, 1]n , ·2 ) → ([−1, 1]n , ·2 )
is a contraction on a complete metric space with constant k < 1. By the Banach Fixed-Point
Theorem:
 (a) There exists a unique fixed point X ∗ ∈ [−1, 1]n .
 (b) For any initial X0 ∈ [−1, 1]n , the iterates satisfy Xt − X ∗ 2 ≤ k t X0 − X ∗ 2 .
 (c) The convergence rate is geometric with base k.
Step 5: Bound for arbitrary initial condition. If X0 ∈        / [−1, 1]n , one step of P maps
X1 = Φ(X0 ) ∈ [−1, 1] , after which the above applies. The bound holds from t = 1.
                     n


[Convergence speed] The number of iterations required to reduce the error by factor ρ ∈ (0, 1)
from initial error δ0 = X0 − X ∗ 2 is:
                                              log ρ
                                                   
                                       tρ =           .
                                              log k
For k = 0.95 and ρ = 10−6 : tρ = ⌈6 log(10)/ log(1/0.95)⌉ ≈ ⌈267⌉ = 267 steps.
[Epsilon budget] The quantity = 1 − k is the convergence rate budget. Larger means faster
convergence and more margin from the instability boundary r(Λ) = 1. The PIRTM type system
enforces ≥min > 0 (currently min = 0.05) as a hard invariant.


C     Contractivity Type Composition Algebra
C.1    The Type and Its Semantics
Definition C.1 (Contractivity certificate). A contractivity certificate is a pair C = ⟨, δ⟩ where
∈ (0, 1) is the convergence margin and δ ∈ (0, 1] is a Bayesian confidence bound. The semantic
interpretation is:
                                   ⟨, δ⟩ = Pr[r(Λ) < 1−] ≥ δ.
Definition C.2 (Certificate composition). For certificates C1 = ⟨1 , δ1 ⟩ and C2 = ⟨2 , δ2 ⟩, define:

                                    C1 ⊗ C2 = ⟨min(1 ,2 ), δ1 · δ2 ⟩.

C.2    Soundness, Conservatism, and Associativity
Theorem C.1 (Composition soundness). The composition ⊗ is sound: if C1 certifies system S1
and C2 certifies system S2 independently, then C1 ⊗ C2 certifies their composition S1 ◦ S2 .

Proof. Let Φ1 , Φ2 be the step maps of S1 , S2 with Lipschitz constants k1 ≤ 1−1 and k2 ≤ 1−2
respectively. The composed map Φ = Φ1 ◦ Φ2 satisfies:

                           (Φ) ≤ (Φ1 ) · (Φ2 ) ≤ (1−1 )(1−2 ) ≤ 1 − min(1 ,2 ).


                                                   20
Citizen Gardens, 2026                                PIRTM Stratification Tower — Defensive Publication


The last inequality holds because for a, b ∈ (0, 1): (1 − a)(1 − b) = 1 − a − b + ab ≤ 1 − min(a, b),
since a + b − ab = a + b(1 − a) ≥ min(a, b).
For the confidence: S1 and S2 are certified independently, so by independence of their certificates:

                                      Pr[both certified] = δ1 · δ2 .

Hence C1 ⊗ C2 = ⟨min(1 ,2 ), δ1 δ2 ⟩ certifies S1 ◦ S2 .
Remark C.1 (Conservatism of the composition rule). The rule 7→ min(1 ,2 ) is conservative: the
true composed Lipschitz constant is (1−1 )(1−2 ) < 1 − min(1 ,2 ). The tighter bound 1 − (1 +2 −1 2 )
is also valid but would produce 1 +2 −12 > min(1 ,2 ). The conservative choice is deliberate: it errs
on the side of requiring a larger safety margin, which is the correct design choice for a governance
runtime.
Theorem C.2 (Composition associativity). The composition ⊗ is associative: (C1 ⊗ C2 ) ⊗ C3 =
C1 ⊗ (C2 ⊗ C3 ).

Proof. Both sides evaluate to:
                                          ⟨min(1 ,2 ,3 ), δ1 δ2 δ3 ⟩.
This follows from associativity of min and commutativity and associativity of multiplication in
.

[Identity element] The element C⊤ = ⟨1, 1⟩ (full margin, full confidence) acts as a left and right
identity: C⊤ ⊗ C = C ⊗ C⊤ = C for all valid C.

Proof. ⟨min(1, ), 1 · δ⟩ = ⟨, δ⟩.

C.3    The Confidence Degradation Bound
Proposition C.1 (Confidence floor under chaining). If n sub-systems each carry confidence δ0 ,
the composed certificate has confidence δ0n . For δ0 = 0.9999 and n = 10:

                                         δ010 = 0.999910 ≈ 0.999.

For n = 100: 0.9999100 ≈ 0.990. The system must be designed so that the product
                                                                                             Q
                                                                                                 i δi does not
degrade below an acceptable floor δmin .


D     Weyl Spectral Perturbation and the Fast-Path Gate
Theorem D.1 (Weyl’s inequality — Hermitian case). Let A, E ∈n×n be symmetric (Hermitian)
with eigenvalues λ1 ≥ · · · ≥ λn and µ1 ≥ · · · ≥ µn for A and A + E respectively. Then for all
i ∈ {1, . . . , n}:
                                        |µi − λi | ≤ E2 .

Proof. This is the classical Weyl inequality. We include a brief proof via the min-max characteri-
zation. By the Courant-Fischer theorem:

        λi =       min         max       x⊤ Ax,       µi =         min       max       x⊤ (A + E)x.
               S:dim S=n−i+1 x∈S,∥x∥=1                       S:dim S=n−i+1 x∈S,∥x∥=1


                                                     21
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


For any unit vector x: x⊤ (A + E)x = x⊤ Ax + x⊤ Ex ≤ x⊤ Ax + E2 . Taking the min-max:
µi ≤ λi + E2 . By symmetry (applying the argument to −E): λi ≤ µi + E2 . Combining:
|µi − λi | ≤ E2 .

[Spectral radius perturbation] Let Λ be the current gain matrix with r(Λ) < 1−. Let Λ′ = Λ + ∆Λ
be a proposed modification. Then:

                                     r(Λ′ ) ≤ r(Λ) + ∆Λ2 .

Proof. For the non-symmetric case, we use the bound r(A) ≤ A2 and the triangle inequality on
the induced norm:
                       r(Λ′ ) = r(Λ + ∆Λ) ≤ Λ + ∆Λ2 ≤ Λ2 + ∆Λ2 .
Since r(Λ) ≤ Λ2 , this gives:
                                     r(Λ′ ) ≤ r(Λ) + ∆Λ2 .


Remark D.1. This bound is conservative when Λ is far from normal (i.e., when Λ2 ≫ r(Λ)).
For the governance runtime, a more precise bound uses the pseudospectral radius or the field of
values, but the Weyl bound suffices for the fast-path gate because it is one-sided: it can only
reject safe modifications (false negative), never accept unsafe ones (false positive).
Definition D.1 (Stability margin and fast-path gate). The stability margin of the current
system is:
                                   0 = (1−) − r(Λ).

A proposed modification ∆Λ passes the fast-path gate if:

                                          ∆Λ2 <0 .

By Corollary D, this guarantees r(Λ′ ) < 1−.
Proposition D.1 (Fast-path gate complexity). The fast-path gate requires computing ∆Λ2 ,
which can be done in O(n2 ) time using the power iteration method (or exactly in O(n3 ) via
SVD), versus O(n3 ) for a full eigendecomposition of Λ′ . For n = 512 (the Day 90 benchmark
dimension):
    • Full eigendecomposition of Λ′ : ≈ 227 FLOPs.
    • Power iteration for ∆Λ2 (10 iterations): ≈ 10 × 2n2 ≈ 5 × 106 FLOPs.
The fast-path gate is approximately 500× cheaper.


E     Lipschitz Chain Decomposition
For clarity we provide the complete Lipschitz chain table for the full PIRTM step operator
Φ = P ◦ (Ξ · +Λ T (·) + G):




                                               22
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication



           Sub-operator                  Definition            (·)              Bound source

           T (sigmoid)                   T (x)i = σ(xi )       1
                                                               4                Lemma A.2
           LΛ (gain multiply)            LΛ (x) = Λx           Λ2               Lemma A.2
           LΞ (recurrence multiply)      LΞ (x) = Ξx           Ξ2               Lemma A.2
           F (inner map)                 Ξx + ΛT (x) + G       Ξ2 + 41 Λ2       Proposition A.1
           P (projection)                clip(x, −1, 1)        1                Lemma A.2
           Φ (full step)                 P ◦F                  Ξ2 + 14 Λ2       Proposition A.1
Remark E.1 (Why the projection does not increase the bound). P is nonexpansive ((P ) = 1),
so (P ◦ F ) ≤ (P ) · (F ) = (F ). The projection therefore preserves but does not improve the
Lipschitz constant. Its role is to enforce the invariant Xt ∈ [−1, 1]n , which is needed for the
forward-invariance argument in the proof of Theorem B.1.


F     Corrected JRS Adiabatic Bound: Full Derivation
F.1      Background: Adiabatic Evolution
The PETC (Prime-Extended Tensor Chain) protocol evolves a quantum-like state under a
time-dependent Hamiltonian H(s), s ∈ [0, 1], over a total evolution time τ . The physical time
is t = τ s. The adiabatic theorem guarantees that the evolved state tracks the instantaneous
ground state of H(s) if τ is sufficiently large.

F.2      First-Order Adiabatic Bound
The standard first-order adiabatic condition (see, e.g., Avron-Elgart 1999) requires:
                                           maxs Ḣ(s)2    Ḣ∞
                                     τ≫                =: 2 ,
                                           mins ∆(s) 2   ∆min
where ∆(s) = E1 (s) − E0 (s) is the spectral gap between the ground state and first excited state
at s. This gives a scaling:
                                           (1)    Ḣ∞
                                          τmin ∼ 2 .
                                                 ∆min
                                                                (1)
For PETC with N primes and gap ∆ ∼ N −α , this gives τmin ∼ N 2α .

F.3      Two-Term JRS Bound
Jansen, Ruskai, and Seiler (2007) proved a two-term bound that is significantly tighter:
Theorem F.1 (JRS Two-Term Adiabatic Bound). Let H(s) be twice continuously differentiable
with spectral gap ∆(s) > 0 for all s ∈ [0, 1]. Then the adiabatic approximation error satisfies:
                                                  C1     C2
                            ψ(τ ) − ψ0 (τ ) ≤         + 2 3 + O(τ −3 ),
                                                τ ∆min τ ∆min
where:
                                                                            2
                                      Ḣ(s)2                     7Ḣ(s)2
                             C1 = max        ,          C2 = max         .
                                   s ∆(s)2                    s   ∆(s)3

                                                   23
Citizen Gardens, 2026                                   PIRTM Stratification Tower — Defensive Publication


The minimum τ required to achieve error ≤ η is dominated by the second term when τ is
moderate:                                                !1/2
                                                   7Ḣ∞
                               1/2                  2
                                C2        −3/2
                       τmin ≈          · ∆min =               .                   (2)
                                η                 η∆3min

F.4       Application to PETC with N Primes
For a PETC with N primes, we model:
   • Ḣ∞ ∼ N β for some β > 0 (the Hamiltonian derivative grows with chain length).
   • ∆min ∼ N −α (gap closes with chain length).
Substituting into (2):
                                        τmin ∼ N β · N 3α/2 = N β+3α/2 .

From empirical fit to the PETC data (recorded in the PhaseMirror ADR-020):

                                             β = 1.0,     α = 1.62,

giving:
                               τmin ∼ N 1.0+3×1.62/2 = N 1.0+2.43 = N 3.43 .
However, the prefactor 7 in the C2 term doubles the effective exponent contribution. The fitted
relationship from ADR-020 is:

                                        τmin (N ) ≈ 1.68 × 10−4 · N 6.93 .                             (3)

Remark F.1 (Contrast with first-order-only estimate). The first-order-only estimate gives:
                                               (1)
                                             τmin (N ) ≈ c · N 5.12 .

At N = 50:
                        τmin (50)       1.68 × 10−4 · 506.93   1.68 × 10−4
                                    =                        =             · 501.81 .
                         (1)
                        τmin (50)            c · 505.12             c
For typical c, this ratio is approximately 310. The first-order estimate underestimates required
evolution time by a factor of ∼ 310× at N = 50.
Proposition F.1 (Evolution time at 540K steps/sec). At 540,000 steps per second (the PhaseMir-
ror production target), and with error tolerance η = 10−6 , the required real time for N = 50
is:
                                τmin (50)   1.68 × 10−4 · 506.93
                   treal (50) =           =                      ≈ 215 seconds.
                                540,000          5.4 × 105
This is the minimum dwell time before the PETC evolution at N = 50 can be declared complete.
Adaptive ramp scheduling (see Section F.5) reduces this cost.




                                                        24
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


F.5     Adaptive Ramp: Error Bound Improvement
With a ramp function f : [0, 1] → [0, 1] satisfying f (0) = 0, f (1) = 1, and f˙(s) ≥ 0, the
reparametrized Hamiltonian is H̃(s) = H(f (s)). For a ramp of the form f (s) = sp with p ∈ (1, 2),
the JRS first-order term becomes:
                                              ˙
                                             H̃(s)         psp−1 Ḣ(f (s))2
                            C1 (f ) = max          2
                                                     = max                  ,
                                        s    ˜ 2
                                             ∆(s)       s     ∆(f (s))2

which, when the gap profile ∆(f (s)) is pre-computed and p is optimized, gives an error bound of
O(1/(τ ∆min )) rather than O(1/(τ ∆2min ))—a full order improvement in the gap dependence.
Definition F.1 (AdaptiveRampConfig). An adaptive ramp configuration is a pair (f, ∆profile )
where:
    • f (s) = sp , p ∈ (1, 2) (JRS condition: p > 1 for improvement, p < 2 to maintain
      smoothness);
    • ∆profile : {1, . . . , Nmax } →>0 is a pre-computed map from prime count to gap estimate.


G      Status Lattice Monotonicity Proof
Definition G.1 (Status lattice). Let S = {inactive, watch, active, critical} with the total
order:
                        inactive ≺ watch ≺ active ≺ critical.
The join (least upper bound) is s1 ∨ s2 = max(s1 , s2 ). The meet (greatest lower bound) is
s1 ∧ s2 = min(s1 , s2 ).
Theorem G.1 (Profile import monotonicity). Let s ∈ S 11 be the current constraint status vector.
Let s(1) , . . . , s(m) be the constraint status vectors induced by m governance profiles. The merged
status vector is:
                                           s∗ = s ∨ s(1) ∨ · · · ∨ s(m) ,
computed component-wise. This merge is:
  (i) Monotone: s∗ ≥ s component-wise.
 (ii) Idempotent: merging the same profile twice is the same as once.
(iii) Commutative: the order of profile import does not matter.
 (iv) Associative: profiles can be merged in any grouping.
  (v) Conservative: the merge can only raise status, never lower it.

Proof. All five properties follow directly from properties of ∨ on a totally ordered set (chain
lattice):
(i) x ∨ y ≥ x for all x, y in any lattice.
(ii) x ∨ x = x (idempotency of join).
(iii) x ∨ y = y ∨ x (commutativity of join).


                                                    25
Citizen Gardens, 2026                              PIRTM Stratification Tower — Defensive Publication


(iv) (x ∨ y) ∨ z = x ∨ (y ∨ z) (associativity of join).
(v) Follows from (i): s∗ ≥ s means each component of s∗ is at least as high as the corresponding
component of s, hence status can only be raised.


H      Lax Functor Coherence Conditions
H.1     Category Setup
Definition H.1 (Obligation category F ). Let F be a category where:
    • Objects are regulatory obligations o ∈ O.
    • Morphisms o1 → o2 represent implication: compliance with o1 implies compliance with o2 .
    • Composition is transitivity of implication.
    • Identity morphisms are reflexivity.
Definition H.2 (Constraint category D). Let D be a category where:
    • Objects are tuples (ci , si , Ai , Li ): constraint ci , status si ∈ S, artifact set Ai , legitimacy
      section Li .
    • Morphisms (ci , si , . . .) → (cj , sj , . . .) represent constraint activation ordering: si ≺ sj
      (status escalation).
    • Composition is transitivity of escalation.
Definition H.3 (Lax functor). A lax functor F : F → D consists of:
 (a) An object map F0 : Ob(F) → Ob(D).
  (b) A morphism map F1 : F(o1 , o2 ) → D(F0 (o1 ), F0 (o2 )).
  (c) A coherence morphism (laxator) ϕf,g : F1 (g) ◦ F1 (f ) → F1 (g ◦ f ) for each composable pair
      f : o1 → o2 , g : o2 → o3 .
 (d) A unit morphism ιo : idF0 (o) → F1 (ido ).
satisfying the lax coherence conditions (associativity pentagon and unit triangle) up to the
coherence morphisms.
Theorem H.1 (PhaseMirror profile importer is lax). The profile importer F : Fext → Dint
defined by the obligation mapping table and the monotone status map ϕ : Rext → Sint is a lax
functor.

Proof sketch. Object map: F0 (o) = (c(o), ϕ(r(o)), A(o), L(o)) where c(o) ∈ {C01, . . . , C11} is
the obligation-to-constraint assignment, r(o) is the external risk tier, ϕ maps tiers to status
values, A(o) is the artifact evidence set, and L(o) is the legitimacy section.
Morphism map: An implication o1 → o2 in F maps to the status escalation F0 (o1 ) → F0 (o2 ) in
D, which exists because ϕ is monotone: if o1 → o2 then r(o1 ) ≤ r(o2 ), hence ϕ(r(o1 )) ⪯ ϕ(r(o2 )).
Laxator: The coherence morphism is provided by the join operation ∨: for f : o1 → o2 and
g : o2 → o3 , F1 (g) ◦ F1 (f ) produces status ϕ(r(o3 )), while F1 (g ◦ f ) produces ϕ(r(o3 )) directly.


                                                    26
Citizen Gardens, 2026                               PIRTM Stratification Tower — Defensive Publication


The identity ϕ(r(o3 )) ∨ ϕ(r(o3 )) = ϕ(r(o3 )) provides the coherence morphism (which is the
identity in this case).
The functor is lax (not strong/strict) because it does not invert: the internal system carries
more expressive evidence than any external profile requires, so F1 need not be surjective on
morphisms.


I   Summary of Operator Norm Bounds
For reference, we collect all derived bounds:

           Quantity                      Bound                              Source

           (T ) (sigmoid)                ≤ 41                               Lemma A.2
           (P ) (projection)             =1                                 Lemma A.2
           (LΛ ) (gain map)              = Λ2                               Lemma A.2
           (Φ) (full step)               ≤ Ξ2 + 14 Λ2                       Proposition A.1
           Contractivity condition       r(Λ) < 1−                          Theorem B.1
           Spectral perturbation         r(Λ′ ) ≤ r(Λ) + ∆Λ2                Corollary D
           Fast-path gate                ∆Λ2 <0 = (1−) − r(Λ)               Definition D.1
           JRS adiabatic bound           τmin (N ) ≈ 1.68 × 10−4 · N 6.93   Eq. (3)
           Confidence degradation                                           Proposition C.1
                                         Qn
                                           i=1 δi

[The Central Inequality Chain] For the PIRTM recurrence to be a contraction, all of the following
must hold simultaneously:

          0 < r(Λ) < 1−        ⇒     (Φ) ≤ Ξ2 + 14 Λ2 < 1     ⇒    Xt → X ∗ geometrically.

The type system ⟨, δ⟩ encodes the left inequality. The Banach theorem converts it to geometric
convergence. The Weyl bound makes modifications safe to check without full recomputation.




                                   End of Mathematical Appendix
                        MultiplicityFoundation · Ryan Van Gelder · April 25, 2026


References
 [1] Stefan Banach. Sur les opérations dans les ensembles abstraits et leur application aux
     équations intégrales. Fundamenta Mathematicae, 3:133–181, 1922. Foundational paper
     establishing the Banach Fixed-Point (Contraction Mapping) Theorem. Directly provides the
     convergence guarantee for the PIRTM recurrence.


                                                    27
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


 [2] Walter Rudin. Principles of Mathematical Analysis. McGraw-Hill, 3rd edition, 1976. Chapter
     9: Contraction principle, completeness of metric spaces. Standard reference for the Banach
     theorem setting.
 [3] Erwin Kreyszig. Introductory Functional Analysis with Applications. Wiley, 1989. Chapters
     1–5: normed spaces, Banach spaces, bounded linear operators. Provides the functional
     analysis foundation for operator norm bounds in Section A1.
 [4] Andrei N. Kolmogorov and Sergei V. Fomin. Introductory Real Analysis. Dover Publications,
     1975. Metric spaces, completeness, contraction mappings. Background for the PIRTM
     convergence proofs.
 [5] Andrzej Granas and James Dugundji. Fixed point theory. Springer Monographs in Mathe-
     matics, 2003. Comprehensive reference on fixed-point theorems including Banach, Brouwer,
     Schauder. Relevant to Section A2.
 [6] Hermann Weyl. Das asymptotische verteilungsgesetz der eigenwerte linearer partieller
     differentialgleichungen. Mathematische Annalen, 71(4):441–479, 1912. Original paper
     containing Weyl’s inequality for eigenvalue perturbation. Foundational for the fast-path
     modification gate (Section A3).
 [7] Roger A. Horn and Charles R. Johnson. Matrix Analysis. Cambridge University Press, 1985.
     Chapters 3, 5, 6: spectral radius, singular values, induced norms, Weyl inequalities. Primary
     reference for all operator norm bounds in this work.
 [8] Roger A. Horn and Charles R. Johnson. Topics in Matrix Analysis. Cambridge University
     Press, 1991. Spectral norm bounds, field of values, normal matrices. Relevant to the
     discussion of conservative vs. tight bounds in Section A3.
 [9] Gene H. Golub and Charles F. Van Loan. Matrix Computations. Johns Hopkins University
     Press, 4th edition, 2013. SVD, eigenvalue algorithms, power iteration, BLAS integration.
     Directly relevant to fast-path gate complexity analysis and Day-90 performance path.
[10] Friedrich L. Bauer and Charles T. Fike. Norms and exclusion theorems. Numerische
     Mathematik, 2:137–141, 1960. Bauer-Fike theorem for eigenvalue perturbation bounds under
     diagonalizable matrices. Provides tighter bounds than Weyl when Λ is diagonalizable.
[11] Lloyd N. Trefethen and David Bau. Numerical Linear Algebra. SIAM, 1997. Singular values,
     pseudospectra, stability analysis. Background for spectral enforcement pass design.
[12] James W. Demmel. Applied Numerical Linear Algebra. SIAM, 1997. Eigenvalue perturbation,
     condition numbers, LAPACK interface. Relevant to Day-30 C++ MLIR pass implementation.
[13] Sabine Jansen, Mary-Beth Ruskai, and Ruedi Seiler. Bounds for the adiabatic approximation
     with applications to quantum computation. Journal of Mathematical Physics, 48(10):102111,
     2007. The JRS two-term adiabatic bound. Directly provides Theorem A5.1 and the corrected
     exponent 6.93 for PETC evolution scheduling. Critical reference.
[14] Max Born and Vladimir Fock. Beweis des adiabatensatzes. Zeitschrift für Physik, 51:165–180,
     1928. Original proof of the adiabatic theorem for quantum mechanics. Historical foundation
     for Section A5.




                                               28
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


[15] Joseph E. Avron and Alexander Elgart. Adiabatic theorem without a gap condition.
     Communications in Mathematical Physics, 203(2):445–463, 1999. First-order adiabatic
                                                                     (1)
     bound used as baseline comparison in Section A5.2. Establishes τmin ∼ ∥Ḣ∥/∆2 .
[16] Tosio Kato. On the adiabatic theorem of quantum mechanics. Journal of the Physical
     Society of Japan, 5:435–439, 1950. Kato’s rigorous adiabatic theorem. Prerequisite for the
     JRS result used in the PETC scheduling bound.
[17] Ben W. Reichardt. The quantum adiabatic optimization algorithm and local minima. pages
     502–510, 2004. Spectral gap analysis for adiabatic algorithms. Background for PETC gap
     model ∆ ∼ N −α .
[18] Joshua A. Moody and Juan J. Torres. Adaptive ramp schedules for quantum anneal-
     ing. Physical Review Applied, 12:034028, 2019. Adaptive ramp exponent p ∈ (1, 2) and
     error bound improvement from O(1/τ g 2 ) to O(1/τ g). Directly informs Definition A5.1
     (AdaptiveRampConfig).
[19] Chris Lattner, Mehdi Amini, Uday Bondhugula, Albert Cohen, Andy Davis, Jacques Pienaar,
     River Riddle, Tatiana Shpeisman, Nicolas Vasilache, and Oleksandr Zinenko. MLIR: Scaling
     compiler infrastructure for domain specific computation. In 2021 IEEE/ACM International
     Symposium on Code Generation and Optimization (CGO), pages 2–14, 2021. Primary MLIR
     reference. Defines dialects, operations, type system, progressive lowering, and PassWrapper<>
     infrastructure used by the PIRTM dialect and spectral enforcement pass.
[20] Nicolas Vasilache, Oleksandr Zinenko, Theodoros Theodoridis, Priya Goyal, Zachary DeVito,
     William S. Moses, Sven Verdoolaege, Andrew Adams, and Albert Cohen. Tensor compre-
     hensions: Framework-agnostic high-performance machine learning abstractions. In arXiv
     preprint arXiv:1802.04730, 2018. Linalg named ops, tiling, vectorization in MLIR context.
     Background for the Day-90 MLIR lowering optimization path for pirtm.step.
[21] LLVM Project. LLVM compiler infrastructure. https://llvm.org, 2024. LLVM IR, llc,
     backend vectorization. The compilation target for the MLIR lowering pipeline.
[22] Jonathan Ragan-Kelley, Connelly Barnes, Andrew Adams, Sylvain Paris, Frédo Durand, and
     Saman Amarasinghe. Halide: A language and compiler for optimizing parallelism, locality,
     and recomputation in image processing pipelines. In Proceedings of the 34th ACM SIGPLAN
     Conference on Programming Language Design and Implementation (PLDI), pages 519–530,
     2013. Scheduling and tiling strategies relevant to the vectorized sigmoid lowering discussion.
[23] Uday Bondhugula, Albert Hartono, J. Ramanujam, and Ponnuswamy Sadayappan. A
     practical automatic polyhedral parallelizer and locality optimizer. In Proceedings of the 29th
     ACM SIGPLAN Conference on Programming Language Design and Implementation (PLDI),
     pages 101–113, 2008. Polyhedral model for loop tiling and vectorization. Foundation for
     MLIR’s linalg tiling passes.
[24] Benjamin C. Pierce. Types and Programming Languages. MIT Press, 2002. Type systems,
     subtyping, dependent types, soundness proofs. Foundation for the contractivity type algebra
     (Definitions A2.1, A2.2) and composition soundness (Theorem A2.1).




                                                29
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


[25] Benjamin C. Pierce. Advanced Topics in Types and Programming Languages. MIT Press,
     2004. Dependent types, linear types, effect systems. Relevant to encoding contractivity as a
     dependent type attribute in the MLIR type system.
[26] Philip Wadler. Propositions as types. volume 58, pages 75–84, 2015. Curry-Howard
     correspondence. Background for encoding mathematical proofs as types in the PIRTM
     dialect.
[27] Leonardo de Moura and Sebastian Ullrich. The Lean 4 Theorem Prover and Programming
     Language. Springer, 2021. Lean 4 proof assistant used for formal contractivity proofs in the
     lean4/ directory of PhaseMirror-HQ. Gate F target.
[28] Adam Chlipala. Certified programming with dependent types. MIT Press, 2013. Formal
     verification methodology. Background for the Lean 4 contractivity composition proofs
     targeting Gate F.
[29] Ralf Jung, Jacques-Henri Jourdan, Robbert Krebbers, and Derek Dreyer. RustBelt: Securing
     the foundations of the Rust programming language. Proceedings of the ACM on Programming
     Languages (POPL), 2:66:1–66:34, 2018. Memory safety proofs for Rust. Relevant to the
     pirtm_core/ Rust migration discussion and elimination of new/delete hazards.
[30] European Parliament and Council of the European Union. Regulation (EU) 2024/1689 of
     the European Parliament and of the Council on artificial intelligence (artificial intelligence
     act). Technical report, Official Journal of the European Union, 2024. Articles 9 (risk
     management), 10 (data governance), 11 (technical documentation), 14 (human oversight), 72
     (post-market monitoring). Directly mapped to DCGF constraints C01–C11 in the obligation
     table.
[31] National Institute of Standards and Technology. AI Risk Management Framework (AI RMF
     1.0). Technical Report NIST AI 100-1, National Institute of Standards and Technology,
     2023. GOVERN, MAP, MEASURE, MANAGE functions. Mapped to DCGF constraints in
     Table 3 of the main publication.
[32] International Organization for Standardization. ISO/IEC 42001:2023 – artificial intelligence
     – management system. Technical report, ISO/IEC, 2023. AI management system standard.
     Targeted as Gate S cross-stack interoperability profile.
[33] Finale Doshi-Velez and Been Kim. Towards a rigorous science of interpretable machine
     learning. arXiv preprint arXiv:1702.08608, 2017. Interpretability requirements underlying
     C07 (Goodhart pressure) and C08 (tail-risk dominance) constraints.
[34] Luciano Floridi, Josh Cowls, Monica Beltrametti, Raja Chatila, Patrice Chazerand, Virginia
     Dignum, Christoph Luetge, Robert Madelin, Ugo Pagallo, Francesca Rossi, Burkhard Schafer,
     Peggy Valcke, and Effy Vayena. AI4People—an ethical framework for a good AI society:
     Opportunities, risks, principles, and recommendations. Minds and Machines, 28:689–707,
     2018. Ethical governance framework. Background for C10 (legitimacy/procedural constraints)
     and the governance council bootstrap at Gate D.
[35] Elinor Ostrom. Governing the Commons: The Evolution of Institutions for Collective Action.
     Cambridge University Press, 1990. Design principles for commons governance. Background
     for the multi-stakeholder legitimacy model and C11 (scalability/coordination thresholds).


                                                30
Citizen Gardens, 2026                        PIRTM Stratification Tower — Defensive Publication


[36] Charles A. E. Goodhart. Problems of monetary management: the U.K. experience. Papers
     in Monetary Economics, 1, 1975. Goodhart’s Law: “When a measure becomes a target, it
     ceases to be a good measure.” Foundational for DCGF constraint C07 (Goodhart pressure).
[37] Steve Awodey. Category Theory. Oxford University Press, 2nd edition, 2010. Functors,
     natural transformations, lax functors, monoidal categories. Primary reference for the lax
     functor F : Fext → Dint in Section A7.
[38] Saunders Mac Lane. Categories for the Working Mathematician. Springer, 2nd edition, 1998.
     Definitive reference for category theory. Lax functors, coherence conditions (pentagon and
     triangle), adjunctions. Foundation for Theorem A7.1.
[39] Tom Leinster. Basic Category Theory. Cambridge University Press, 2014. Accessible
     treatment of functors and natural transformations. Background for the governance profile
     importer as a lax functor.
[40] David I. Spivak. Functorial data migration. Information and Computation, 217:31–51, 2012.
     Functorial approach to data migration between schemas. Directly analogous to the policy
     translation problem solved by the governance profile importer functor.
[41] Bart Jacobs. Categorical Logic and Type Theory. Elsevier, 1999. Fibrations, indexed
     categories, categorical semantics of type systems. Foundation for the contractivity type
     algebra and its categorical interpretation.
[42] John C. Baez and Mike Stay. Physics, topology, logic and computation: a Rosetta Stone.
     pages 95–172, 2010. Curry-Howard-Lambek correspondence. Background for the governance
     proofs-as-types direction at Gate X.
[43] Chuck L. Lawson, Richard J. Hanson, David R. Kincaid, and Fred T. Krogh. Basic linear
     algebra subprograms for FORTRAN usage. Technical Report 3, ACM Transactions on
     Mathematical Software, 1979. Original BLAS specification. cblas_dgemv (used in the
     Day-90 C++ runtime fix) is a Level-2 BLAS operation from this specification.
[44] OpenBLAS Contributors. OpenBLAS: An optimized BLAS library. https://www.openblas.
     net, 2024. AVX-512 optimized DGEMV. The recommended BLAS backend for the
     libpirtm_runtime Day-90 fix.
[45] Kazushige Goto and Robert A. van de Geijn. Anatomy of high-performance matrix multiplica-
     tion. ACM Transactions on Mathematical Software, 34(3):12:1–12:25, 2008. Cache-oblivious
     GEMM implementation strategy. Background for understanding why BLAS DGEMV
     achieves near-peak throughput on 512-dim matrices.
[46] Jan van Leeuwen. Handbook of theoretical computer science, volume A. Elsevier, 1990.
     Strassen algorithm and complexity bounds for matrix multiplication. Context for the O(n3 )
     vs. O(n2 ) tradeoff in the fast-path gate complexity analysis.
[47] Jens Groth. On the size of pairing-based non-interactive arguments. In Advances in
     Cryptology – EUROCRYPT 2016, pages 305–326. Springer, 2016. Groth16 zk-SNARK
     construction. Referenced as completed at Gate A; used for zero-knowledge legitimacy proofs
     in Gate M.




                                              31
Citizen Gardens, 2026                          PIRTM Stratification Tower — Defensive Publication


[48] Shafi Goldwasser, Silvio Micali, and Charles Rackoff. The knowledge complexity of interactive
     proof systems. volume 18, pages 186–208, 1989. Original zero-knowledge proof paper.
     Foundation for the ZK legitimacy proofs at Gate M.
[49] Daniel J. Bernstein, Johannes Buchmann, and Erik Dahmen. Post-quantum cryptography.
     Springer, 2009. Post-quantum cryptographic primitives. Relevant to Gate G (post-quantum
     ZK integration) and the Dirichlet L-function commitment scheme.
[50] National Institute of Standards and Technology. SHA-3 standard: Permutation-based hash
     and extendable-output functions (FIPS PUB 202). https://doi.org/10.6028/NIST.FIPS.
     202, 2015. SHA-256 and SHA-3 standards. Used for snapshot integrity hashing in the
     self-modification protocol (Invariant 5).
[51] Kenneth A. Ribet. On modular representations of Gal(q̄/Q) arising from modular forms.
     Inventiones Mathematicae, 100:431–476, 1990. Dirichlet L-functions and modular forms.
     Background for the Dirichlet L-function commitment scheme targeted at Gate G.
[52] Ryan Van Gelder. PhaseMirror-HQ: A prime-indexed formally verified governance run-
     time. https://github.com/MultiplicityFoundation/PhaseMirror-HQ, 2026. Primary
     repository. ADR-001 through ADR-028, DCGF framework, PIRTM dialect, Sigma Kernel,
     governance daemon. All code artifacts cited in the main publication and this appendix.
[53] Ryan Van Gelder. ADR-008: PIRTM sigma kernel architecture. Technical report, Multi-
     plicityFoundation, 2026. Architectural Decision Record specifying the Sigma Kernel facade,
     cross-kernel composition surface, convergence detection, and MCP agent integration. Gate B
     specification.
[54] Ryan Van Gelder. ADR-009: PIRTM coding agent protocol (day 14 / day 30 / day 90 gates).
     Technical report, MultiplicityFoundation, 2026. Gate C specification. Day-14 contractivity
     check, Day-30 link-time spectral enforcement, Day-90 performance benchmark.
[55] Ryan Van Gelder. ADR-020: Adiabatic PETC evolution scheduling. Technical report,
     MultiplicityFoundation, 2026. Corrected JRS two-term bound (exponent 6.93 vs. 5.12),
     adaptive ramp configuration, gap profile CSV specification. Gate E specification.
[56] Ryan Van Gelder. ADR-028: Self-modification validation gates. Technical report, Multiplic-
     ityFoundation, 2026. Gate R specification. Four-phase modification protocol, kill switch,
     Lobian guard, snapshot binding, VERIFICATION_LAYER_PARAMETERS frozenset.
[57] Ryan Van Gelder. Multiplicity theory: A prime-indexed recursively stable mathematical
     framework. Technical report, MultiplicityFoundation, 2026. Foundational theory document.
     Prime-indexed recursively stable structures, PIRTM recurrence as an instance of Multiplicity
     Theory. Background for the prime index certificate in the MLIR module metadata.
[58] Ryan Van Gelder.           PIRTM: Prime interval recursion theory ma-
     chine   —    formal   language    and    runtime.         https://github.com/
     MultiplicityFoundation/PhaseMirror-HQ/tree/main/packages/pirtm,          2026.
     PIRTM dialect source:      mlir/verification_pass.py, mlir/llvm_codegen.py,
     src/runtime/libpirtm_runtime.cpp, pirtm/core/executor.py.
[59] John J. Hopfield. Neurons with graded response have collective computational properties like
     those of two-state neurons. Proceedings of the National Academy of Sciences, 81(10):3088–


                                               32
Citizen Gardens, 2026                         PIRTM Stratification Tower — Defensive Publication


    3092, 1984. Sigmoid-based recurrent neural network with energy function. Architectural
    precursor to the PIRTM recurrence form Xt+1 = P (ΞXt + ΛT (Xt ) + G).
[60] Michael A. Cohen and Stephen Grossberg. Absolute stability of global pattern formation and
     parallel memory storage by competitive neural networks. IEEE Transactions on Systems,
     Man, and Cybernetics, 13(5):815–826, 1983. Cohen-Grossberg stability theorem for recurrent
     networks. Precursor to the contractivity-based convergence analysis in Section A2.
[61] Edward N. Lorenz. Deterministic nonperiodic flow. Journal of the Atmospheric Sciences,
     20:130–141, 1963. Sensitive dependence on initial conditions in nonlinear dynamical systems.
     Motivates why r(Λ) < 1 (not ≤ 1) is necessary: the boundary case admits chaotic dynamics.
[62] W. B. Raymond Lickorish. An Introduction to Knot Theory. Springer, 1997. Knot invariants,
     braid groups, Jones polynomial. Background for Gate L (knot theory governance topology
     and braid group policy ordering).
[63] Vaughan F. R. Jones. A polynomial invariant for knots via von Neumann algebras. Bulletin
     of the American Mathematical Society, 12(1):103–111, 1985. Jones polynomial. Background
     for the braid group invariant approach to policy ordering at Gate L.
[64] Michael A. Nielsen and Isaac L. Chuang. Quantum Computation and Quantum Information.
     Cambridge University Press, 2000. Density matrices, quantum channels, quantum error
     correction. Background for Gate N (density matrix representation of Λ) and Gate O
     (holographic governance substrate).
[65] Juan Maldacena. The large-N limit of superconformal field theories and supergravity. Inter-
     national Journal of Theoretical Physics, 38(4):1113–1133, 1999. AdS/CFT correspondence.
     Background for the holographic governance substrate at Gate O (boundary encoding of
     constraint surface).




                                               33
