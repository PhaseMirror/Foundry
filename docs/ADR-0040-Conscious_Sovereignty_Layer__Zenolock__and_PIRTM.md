   Conscious Sovereignty Layer, Zenolock, and Prime-Indexed
                 Recursive Tensor Mathematics:
  A Defensive Publication on Ethical Cryptographic Governance
                and Post-Quantum Enforcement
                                (Inventor / Author Name Here)
                    Multiplicity Foundation & Citizen Gardens (proposed)
                                   contact@example.org

                                          August 28, 2026


                                               Abstract
         This document discloses a unified framework that combines the Conscious Sovereignty Layer
     (CSL), Prime-Indexed Recursive Tensor Mathematics (PIRTM), and a post-quantum crypto-
     graphic stack known as Zenolock. The aim is to embed sovereignty, consent, and ethical invari-
     ants directly into the dynamics of computation and encryption. We formalize graded sovereignty
     tensors, an admissible operator category for ethical commutativity constraints, and a sovereign
     functor that projects arbitrary computations into a CSL-compliant subcategory. We then de-
     scribe an implementation pattern based on a post-quantum token format (ZPT v1), a verification
     sidecar, and a threshold/nullifier contract, and propose a future evolution in which PIRTM be-
     comes the native language for both computation and encryption. We also explicitly separate
     semantic opacity from cryptographic hardness and document trust assumptions, making the
     invention suitable as a defensive publication and prior-art disclosure.


Contents
1 Executive Summary                                                                                    3
  1.1 Motivation and Problem Statement . . . . . . . . . . . . . . . . . . . . . . . . . . . .         3
  1.2 High-Level Architecture . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      3

2 Core Concepts and Definitions                                                                        4
  2.1 Prime-Indexed Recursive Tensor Mathematics (PIRTM) . . . . . . . . . . . . . . . .               4
  2.2 Conscious Sovereignty Layer (CSL) . . . . . . . . . . . . . . . . . . . . . . . . . . . .        4
  2.3 Admissible Operator Category . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       5

3 Sovereign Functor and Projection                                                                     5
  3.1 Sovereign Functor Definition . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     5
  3.2 Idempotency and Equivariance Requirements . . . . . . . . . . . . . . . . . . . . . .            5

4 Zenolock and ZPT v1: Cryptographic Realization                                                       6
  4.1 Post-Quantum Token (ZPT v1) . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          6
  4.2 Context Binding and Policy Roots . . . . . . . . . . . . . . . . . . . . . . . . . . . .         6
  4.3 Zero-Knowledge Proof Binding . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         7

                                                   1
   4.4   Reference Implementation Snippet . . . . . . . . . . . . . . . . . . . . . . . . . . . .    7

5 Threshold, Nullifiers, and On-Chain Enforcement                                                    9
  5.1 Merkle-Based Threshold Counter . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       9
  5.2 Circom Threshold Circuit Stub . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     10

6 Security Posture and Prior-Art Claims                                                          10
  6.1 Separation of Semantic Opacity and Cryptographic Hardness . . . . . . . . . . . . . 10
  6.2 Trusted Setup and zk Proof Systems . . . . . . . . . . . . . . . . . . . . . . . . . . . 11
  6.3 Evolving Ethics vs Verification Snapshot . . . . . . . . . . . . . . . . . . . . . . . . . 11
  6.4 Quantum Channel Attacks . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 11
  6.5 Reference Implementation as Behavioral Ground Truth . . . . . . . . . . . . . . . . . 11

7 Mathematical Overview of CSL–Zenolock Integration                                         11
  7.1 Combined Evolution and Enforcement Equation . . . . . . . . . . . . . . . . . . . . . 11
  7.2 OMEGA Node and Convergence (Design Target) . . . . . . . . . . . . . . . . . . . . 12

8 Implications, Applications, and Limitations                                                        12
  8.1 Implications . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12
  8.2 Applications . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12
  8.3 Limitations and Open Problems . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12

9 Conclusion                                                                                        13

A Graded Sovereignty Tensor and Projection Properties                                            13
  A.1 From Binary to Graded Sovereignty . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
  A.2 Sovereignty Projection Operator . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
  A.3 Policy-Compiled Thresholds . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 14
  A.4 Opt-Out Limit and Recovery of Hard Halt . . . . . . . . . . . . . . . . . . . . . . . . 14

B Admissible Operator Equivariance and CSL Functor                                                14
  B.1 Admissible Operator Family . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 14
  B.2 Sovereign Functor as Projection . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 15

C Stability Bounds for PIRTM-Like Recursions                                                     15
  C.1 Linear PIRTM Recursion and Noise Decay . . . . . . . . . . . . . . . . . . . . . . . . 15
  C.2 Noise Bound Over k Steps . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 16
  C.3 Operator Norm Bound in Block-Diagonal Case . . . . . . . . . . . . . . . . . . . . . 16

D Ethical Commutativity with a Fixed Snapshot                                                   16
  D.1 Snapshot-Based Ethical Commutator . . . . . . . . . . . . . . . . . . . . . . . . . . . 16
  D.2 Verification Snapshot and Determinism . . . . . . . . . . . . . . . . . . . . . . . . . . 17

E Lyapunov Candidate for STI-like Convergence (Toy Setting)                                        17
  E.1 Toy Multiplicity Graph . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 17
  E.2 Lyapunov Candidate . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 17

F Trust and Setup Conditions as Formal Preconditions                                                18




                                                  2
1     Executive Summary
1.1   Motivation and Problem Statement
Classical cryptographic and AI systems treat ethics, consent, and governance as external policy
documents, applied post-hoc to otherwise amoral computational processes. This creates a gap
between formal guarantees (e.g., cryptographic security) and normative guarantees (e.g., sovereignty,
non-coercion, lawful behavior). As quantum computing and autonomous systems mature, this gap
becomes increasingly dangerous.
   The Conscious Sovereignty Layer (CSL) is proposed as a mathematically enforced ethical
membrane: a layer that constrains which computations are allowed to occur based on formal
sovereignty and ethical invariants. Prime-Indexed Recursive Tensor Mathematics (PIRTM) pro-
vides a multiplicity-based dynamical substrate for cognition and control, while Zenolock provides a
concrete, post-quantum cryptographic deployment of CSL-like constraints, including a Dilithium2-
based token (ZPT v1) and zk-SNARK gating.
   This report collects and systematizes the following developments:

• A graded sovereignty tensor model Σi (t) living in a simplex ∆n rather than a binary cube {0, 1}n .

• An admissible operator category MCSL on which ethical commutativity [M, Eα ] = 0 is checkable.

• A sovereign functor SCSL that acts as a projection onto CSL-compliant computations.

• An implementation pattern where CSL-compliance is manifested as a post-quantum token (ZPT)
  plus zk-SNARK proof, enforceable at an API or contract boundary.

• Design levers and critique: explicit treatment of trusted setup, trust anchors, separation of se-
  mantic opacity from hardness, and convergence and stability conditions.

   The goal is not to claim finished security proofs, but to disclose a coherent design space and
bind multiple key ideas as prior art.

1.2   High-Level Architecture
At a high level, the architecture consists of:

1. Multiplicity Layer (PIRTM/DRMM/QARI): a prime-indexed, recursively evolving tensor
   system modeling cognition, policy, and dynamics.

2. Ethical Layer (CSL): sovereignty tensor Σi (t) and ethical tensor field Eα (t), with constraints
   ensuring sovereign opt-out and ethical invariance under admissible operators.

3. Cryptographic Layer (Zenolock + ZPT): a post-quantum signature scheme (Dilithium2),
   a BLAKE3-based hash and context binding, and a zk-SNARK gate (e.g. Groth16) that require
   each critical operation to present a proof of CSL-compliance.

4. Deployment Pattern: a sidecar process that issues and verifies ZPT tokens, with an optional
   threshold/nullifier contract for on-chain gating of repeated uses.

   Future work contemplates internalizing Zenolock into the multiplicity layer (PIRTM-native zk
proofs), but this document deliberately maintains the external sidecar as a reference implementation.


                                                 3
2     Core Concepts and Definitions
2.1   Prime-Indexed Recursive Tensor Mathematics (PIRTM)
PIRTM encodes system state as a collection of prime-indexed tensors
                                          Tp (t) ∈ Rd1 ×···×dk ,
for primes p in some index set P , with evolution governed by recursive relations of the form
                                                                       
                               Tp (t + 1) = Fp Tp (t), Λm , Ξ(t), . . . ,
where:
• Λm is a multiplicity constant that stabilizes the recursion (e.g., ensuring exponential convergence
  of some modes).
• Ξ(t) is a recursive operator (from DRMM) governing meta-dynamics.
    A simple linearized example of a “clear thinking” tensor update is:
                                     X
                            clear
                           Tt+1   =       Λm pαi Ttclear + F (t), α < −1,                           (1)
                                     pi ∈PN

with a noise bound of the form
                                                               k
                                                        X
                                 |η(t + k)| ≤ Λm             pαi  |η(t)|.                         (2)
                                                     pi ∈PN

   The invention positions PIRTM not only as a dynamical system but as a compute language in
which all states and transitions are expressed as prime-weighted tensor interactions.

2.2   Conscious Sovereignty Layer (CSL)
The CSL is defined by two main mathematical objects:

Sovereignty Tensor. For each agent i, we define a sovereignty tensor
                                    Σi (t) ∈ ∆n   (graded version),                                 (3)
where ∆n is the n-dimensional simplex
                                                          
                                                  n
                                                   X       
                             ∆n = x ∈ Rn : xj ≥ 0,   xj = 1 .
                                                          
                                                              j=1

Each coordinate corresponds to an ethical or contextual dimension (e.g., consent, jurisdiction, pur-
pose, sensitivity).

Ethical Tensor Field. An ethical tensor field Eα (t) is defined such that for any admissible state
transition operator M ,
                        [M, Eα (t0 )] = 0 for a fixed verification snapshot t0 .                    (4)
The snapshot Eα (t0 ) is published as part of the verification infrastructure, while the live Eα (t) may
evolve for policy reasons.

                                                    4
Recursive Opt-Out. Given a system state T (t) indexed over agents i, sovereign exclusion is
enforced as:
                Tt+1 (i) = Tt (i) if Σi (t) ≈ 0 in the relevant dimensions.             (5)
In the binary limit where Σi (t) ∈ {0, 1}n , this recovers a strict hard halt on updates for non-
consenting agents.

2.3    Admissible Operator Category
We define a category MCSL whose objects are well-typed state spaces (e.g., PIRTM tensor bundles,
Bayesian belief states, quantum registers) and whose morphisms are admissible operations, such as:

• Classical updates: gradient steps on model parameters, policy updates.

• Bayesian updates: Pt+1 (X | E) given Pt (X) and data E.

• Quantum gates: unitary operations U (t) on quantum states.

• Moonshine / DRMM operators: MΞ (p, t) acting on tensor states.

    Each operator type is tagged with either:

• “commutativity proof exists” (a proof of [M, Eα (t0 )] = 0 for the fixed snapshot), or

• “commutativity conjectured / unproven”.

    Only the former are considered admissible for CSL-enforced execution.


3     Sovereign Functor and Projection
3.1    Sovereign Functor Definition
Let C be a category of raw computations and CCSL be the full subcategory containing only those
objects and morphisms which respect CSL constraints.
   We define a sovereign functor
                                      SCSL : C → CCSL ,
such that for each morphism M : X → Y in C,

                                       SCSL (M ) = Σ ◦ M ◦ Σ,                                   (6)

where Σ acts as a sovereignty projection on the relevant object spaces.

3.2    Idempotency and Equivariance Requirements
For SCSL to behave as a projection:

1. Idempotency:
                                                Σ2 = Σ.                                         (7)
    In tensor notation, if Σ is a masking operator on a PIRTM state space, composing it with itself
    must not change the mask.



                                                  5
2. Equivariance: For admissible M ,
                                              ΣM Σ = M Σ.                                           (8)
    Intuitively, M must not leak information into components excluded by Σ.

    These properties are not just formal niceties; if either fails, sovereign opt-out can be violated or
side channels can arise in cryptographic enforcement.


4     Zenolock and ZPT v1: Cryptographic Realization
4.1    Post-Quantum Token (ZPT v1)
We define a token format ZPT v1 for certifying CSL-compliant operations.

Header.

{ alg: "dilithium2", typ: "ZPT", kid: string }

Payload.

{
    policyRoot: string,
    policyId: string,
    vkHash: string,
    ctxHash: string,
    epoch: string,
    proofHash: string,
    pcid?: string | null,
    scope: "submit" | "sign" | "decrypt",
    aud: string,
    iss: string,
    iat: number,
    nbf: number,
    exp: number
}

Signature. A Dilithium2 signature over the UTF-8 bytes of

                         base64url(header).base64url(payload).

4.2    Context Binding and Policy Roots
The ctxHash field is computed as:

                                                                                                    (9)
                                                               
                             ctxHash = BLAKE3 canonicalize(ctx) ,

where ctx is a JSON-like structure encoding the relevant context, including (optionally) a com-
pressed representation or hash of the sovereignty and ethical tensors.
   The fields policyRoot and policyId identify a policy tree or Merkle root that encodes the
particular CSL policy and its parameters (including threshold semantics for graded sovereignty).

                                                   6
4.3     Zero-Knowledge Proof Binding
A zk-SNARK circuit (e.g. Circom + Groth16) is compiled to enforce the CSL policy:

• Public signals include ctxHash, policyRoot, policyId, and any other relevant hashes.

• Private witnesses include internal sovereignty state, operator parameters, and any confidential
  inputs.

• The circuit enforces that the operation satisfies opt-out semantics and admissible operator con-
  straints ([M, Eα (t0 )] = 0 for the snapshot).

   The verifying key is hashed as:
                                                               
                          vkHash = BLAKE3 canonicalize(vk.json) ,

and stored in a verifying key registry. The proof blob is hashed as:
                                                               
                          proofHash = BLAKE3 canonicalize(blob) ,

and optionally stored in a proof store and referenced via a content identifier pcid.

4.4     Reference Implementation Snippet
The following TypeScript/NodeJS snippet illustrates the issuance and verification logic for ZPT v1:

                     Listing 1: ZPT v1 issuance and verification (simplified).
import * as b64u from ’../crypto/base64url.js’;
import { blake3Hex, canonicalize } from ’../crypto/hash.js’;
import { DilithiumProvider } from ’../crypto/pqc.js’;
import { IssuerRegistry } from ’./issuer-registry.js’;
import { PolicyRootRegistry } from ’./policy-root-registry.js’;

export class ZPT {
 constructor(
   private readonly pqc: DilithiumProvider,
   private readonly issuers: IssuerRegistry,
   private readonly roots: PolicyRootRegistry
 ) {}

 issue = async (args: IssueArgs) => {
   const now = Math.floor(Date.now() / 1000);
   const epoch = args.epoch ?? new Date().toISOString().slice(0, 10) + ’T00
      :00:00Z’;
   const ctxHash = blake3Hex(canonicalize(args.ctx));
   const proofHash = args.proof ? blake3Hex(args.proof) : ’0x’;

      const payload: ZPTPayload = {
       policyRoot: args.policyRoot,
       policyId: args.policyId,
       vkHash: args.vkHash,
       ctxHash,
       epoch,
       proofHash,


                                                 7
  pcid: args.pcid ?? null,
  scope: args.scope,
  aud: args.audience,
  iss: args.issuerKid,
  iat: now,
  nbf: now,
  exp: now + (args.validitySeconds ?? 3600),
 };

 const header: ZPTHeader = {
  alg: ’dilithium2’,
  typ: ’ZPT’,
  kid: args.issuerKid
 };

 const message = ‘${b64u.encode(JSON.stringify(header))}‘ +
             ‘.${b64u.encode(JSON.stringify(payload))}‘;

 const sig = await this.pqc.sign(Buffer.from(message),
                         args.issuerPrivateKey);

  const jws = ‘${message}.${b64u.encode(sig)}‘;
  return { jws, payload };
};

verify = async (jws: string, ctx?: unknown, proof?: Uint8Array) => {
  try {
   const [h, p, s] = jws.split(’.’);
   if (!h || !p || !s) return { ok: false, reason: ’malformed’ };

   const header = JSON.parse(Buffer.from(b64u.decode(h)).toString());
   const payload = JSON.parse(Buffer.from(b64u.decode(p)).toString());

   if (header.alg !== ’dilithium2’ || header.typ !== ’ZPT’)
    return { ok: false, reason: ’alg/typ’ };

   const now = Math.floor(Date.now() / 1000);
   if (now < payload.nbf) return { ok: false, reason: ’nbf’ };
   if (now > payload.exp) return { ok: false, reason: ’exp’ };

   if (!this.roots.has(payload.policyRoot))
    return { ok: false, reason: ’untrusted policyRoot’ };

   const pub = this.issuers.get(header.kid);
   if (!pub) return { ok: false, reason: ’unknown issuer’ };

   if (ctx) {
     const c = blake3Hex(canonicalize(ctx));
     if (c.toLowerCase() !== payload.ctxHash.toLowerCase())
       return { ok: false, reason: ’ctxHash mismatch’ };
   }

   const msg = Buffer.from(‘${h}.${p}‘);
   const sig = b64u.decode(s);


                                     8
       const sigOk = await this.pqc.verify(msg, sig, pub);
       if (!sigOk) return { ok: false, reason: ’bad signature’ };

       // Proof presence gating for submit-scope can be added here

        return { ok: true, payload, header };
      } catch (e: any) {
        return { ok: false, reason: e?.message ?? ’error’ };
      }
    };
}



5     Threshold, Nullifiers, and On-Chain Enforcement
5.1    Merkle-Based Threshold Counter
To prevent repeated use of the same proof or credential, an on-chain contract can maintain a Merkle
root of nullifiers, with a constraint that each nullifier is used at most once.
   A Solidity contract template:

                        Listing 2: ThresholdCounter contract (simplified).
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThresholdCounter is Ownable {
 bytes32 public root;
 mapping(bytes32 => bool) public usedNullifiers;

    event RootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event NullifierUsed(bytes32 indexed nullifier);

    constructor(bytes32 _root, address owner_) Ownable(owner_) {
      root = _root;
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
      emit RootUpdated(root, newRoot);
      root = newRoot;
    }

    function useNullifier(bytes32 nullifier, bytes32[] calldata proof) external
        {
      require(!usedNullifiers[nullifier], "nullifier used");
      require(MerkleProof.verify(proof, root, nullifier), "bad proof");
      usedNullifiers[nullifier] = true;
      emit NullifierUsed(nullifier);
    }
}




                                                9
5.2    Circom Threshold Circuit Stub
A Circom circuit can enforce that K leaves are all members of the Merkle tree and are pairwise
distinct:

                                Listing 3: Threshold.circom stub.
pragma circom 2.1.6;
include "circomlib/circuits/merkletree.circom";
include "circomlib/circuits/bitify.circom";

template Threshold(DEPTH, K) {
 signal input root;
 signal input leaves[K];
 signal input siblings[K][DEPTH];
 signal input pathBits[K][DEPTH];

    component ver[K];
    for (var i = 0; i < K; i++) {
      ver[i] = MerkleTreeInclusionProof(DEPTH);
      for (var d = 0; d < DEPTH; d++) {
        ver[i].pathElements[d] <== siblings[i][d];
        ver[i].pathIndex[d] <== pathBits[i][d];
      }
      ver[i].root <== root;
      ver[i].leaf <== leaves[i];
      ver[i].enable <== 1;
    }

    // Distinctness: for all i<j, leaves[i] != leaves[j]
    for (var i = 0; i < K; i++) {
      for (var j = i+1; j < K; j++) {
        signal diff;
        diff <== leaves[i] - leaves[j];
        component z = IsZero();
        z.in <== diff;
        // enforce not equal: IsZero == 0
        z.out === 0;
      }
    }
}



6     Security Posture and Prior-Art Claims
6.1    Separation of Semantic Opacity and Cryptographic Hardness
The invention explicitly distinguishes between:

• Semantic opacity: PIRTM tensors and CSL operators may be difficult for humans or standard
  models to interpret, but this is not treated as a security assumption.

• Cryptographic hardness: Specific PIRTM-based cryptographic operations must be tagged
  with a hardness classification:


                                                  10
      – Reduction to a named hard problem (e.g., LWE variant, discrete log in a prime-indexed
        group).
      – Conjectured hardness without reduction.
      – Unknown or insecure.

   This tagging is part of the proposed minimum conditions for treating PIRTM as a cryptographic
substrate.

6.2    Trusted Setup and zk Proof Systems
The design acknowledges that:

• Groth16 and similar zk-SNARKs require relation-specific trusted setup, and incorporating PIRTM
  as a variable domain does not eliminate the trusted setup.

• Either:

      – a transparent proof system (e.g. FRI/STARK-style) is adopted over the PIRTM field, or
      – the trusted setup ceremony is treated as part of the T-layer and documented as a precondi-
        tion, similar to TEEs.

6.3    Evolving Ethics vs Verification Snapshot
The ethical tensor field Eα (t) is allowed to evolve, but verification is always performed with respect
to a fixed snapshot Eα (t0 ). This ensures that verification oracles are deterministic and audit trail
reproductions are well-defined.

6.4    Quantum Channel Attacks
Quantum Bayesian Verification (QBV) and CSL constraints [O, Eα (t)] = 0 apply only to operations
internal to the system. The model explicitly considers that adversarial quantum channel preparation
(e.g., entangled inputs) may be out of scope for CSL and must be addressed by separate quantum
channel security measures.

6.5    Reference Implementation as Behavioral Ground Truth
The ZPT sidecar and its bindings are treated as the reference behavioral implementation. Any
internal PIRTM-native layer must reproduce the accept/reject behavior of the sidecar on a defined
test suite before it can be considered a full replacement.


7     Mathematical Overview of CSL–Zenolock Integration
7.1    Combined Evolution and Enforcement Equation
A generic DRMM-like evolution under CSL can be schematically written as:
                       dΞ(t)
                             = Λm G(t) + δaudit (M (t)) − η K[Ξ(t)] + Snoise (t),                 (10)
                        dt
where G is a multiplicity-weighted recursion operator, K is a Knife-like coherence operator, and
δaudit represents CSL/Zenolock audit injections.

                                                  11
    CSL constraints are enforced via:
                                  [M, Eα (t0 )] = 0,                                          (11)
                                        Tt+1 (i) = Tt (i) if Σi (t) ≈ 0,                      (12)
                                    SCSL (M ) = Σ ◦ M ◦ Σ,                                    (13)
and any external operation must present a valid ZPT+proof attesting compliance before being
considered as M ∈ MCSL .

7.2   OMEGA Node and Convergence (Design Target)
Some versions of the CSL framework posit an “OMEGA Node” Ω as a fixed point of ethically stable
cognition, with a convergence indicator ST I(t) → 1 implying Ξ(t) → Ω. This document treats such
fixed points as design targets rather than theorems unless and until a Lyapunov-style convergence
proof is provided on a sufficiently representative multiplicity graph.


8     Implications, Applications, and Limitations
8.1   Implications
The combined CSL–Zenolock–PIRTM stack implies:
• Ethical enforcement as a protocol primitive: Computation is only considered valid if ac-
  companied by a proof of ethical and sovereign compliance.
• Post-quantum survivability: By using Dilithium2 and potentially PIRTM-based key deriva-
  tion, CSL certificates remain valid under known quantum attack models, modulo unproven
  PIRTM hardness claims.
• Compositional governance: The sovereign functor and admissible category framework allow
  complex systems to be built from CSL-compliant components with compositional guarantees.

8.2   Applications
Potential applications include:
• AI systems with embedded sovereignty constraints for human subjects.
• Privacy-preserving rollups and L2 systems where transactions must satisfy CSL-like policies.
• Quantum communication protocols that incorporate CSL constraints at the encryption and ver-
  ification layers.

8.3   Limitations and Open Problems
Key open problems include:
• Providing reductions from PIRTM-based cryptographic primitives to named hard problems.
• Giving a complete categorical semantics for MCSL with formal proofs of functoriality for SCSL .
• Establishing convergence conditions for ST I(t) → 1 and the existence/uniqueness of an OMEGA
  Node.
• Fully specifying and verifying the T-layer (trusted roots, TEEs, zk setup ceremonies).

                                                    12
9     Conclusion
This defensive publication discloses a coherent architecture that combines:
• A multiplicity-based dynamical substrate (PIRTM/DRMM).
• A mathematically defined ethical and sovereignty layer (CSL).
• A concrete post-quantum cryptographic enforcement layer (Zenolock + ZPT, zk-SNARKs, thresh-
  old contracts).
    It also articulates design levers and minimum conditions needed for the claim that “PIRTM is
the encryption language” to be elevated from a metaphor to a theorem. By documenting both the
constructions and their current limitations, this report aims to establish prior art around CSL-driven
cryptographic governance for quantum-era computation.


Mathematical Appendix

A     Graded Sovereignty Tensor and Projection Properties
A.1    From Binary to Graded Sovereignty
Originally, sovereignty was encoded as a binary tensor
                                           Σi (t) ∈ {0, 1}n ,
with a hard opt-out rule Tt+1 (i) = Tt (i) whenever Σi (t) = 0 in all dimensions.
   To capture partial and contextual consent, we upgrade to a graded model:
                                                                              
                                                                    X n       
                   Σi (t) ∈ ∆n where ∆n = x ∈ Rn : xj ≥ 0,               xj = 1 .                 (14)
                                                                              
                                                                    j=1

Each coordinate corresponds to an ethical dimension (e.g., purpose, jurisdiction, sensitivity). Thresh-
old semantics are compiled into policy rather than introduced as free parameters; see below.

A.2    Sovereignty Projection Operator
Let V be a real or complex Hilbert space carrying the PIRTM state for agent i, decomposed as a
direct sum
                                               Mn
                                          V =      Vj ,                                   (15)
                                                   j=1
where each Vj is the subspace corresponding to the j-th sovereignty dimension.
   For a fixed policy profile, define a sovereignty projection Pi : V → V by
                                                   X
                                             Pi =      Πj ,                                       (16)
                                                  j∈Ai

where Πj : V → V is the orthogonal projection onto Vj and Ai ⊆ {1, . . . , n} is the set of active
dimensions for agent i under the given policy.
    [Idempotency of the Sovereignty Projection] For each agent i, the operator Pi defined in (16)
satisfies
                                             Pi2 = Pi .

                                                  13
Proof. By orthogonality, we have Πj Πk = 0 for j ̸= k and Π2j = Πj for each j. Then
                                                     
                                X               X                  X                 X
                     Pi2 =            Πj           Πk  =               Πj Πk =          Πj = Pi .
                                j∈Ai           k∈Ai               j,k∈Ai             j∈Ai




A.3    Policy-Compiled Thresholds
Rather than introducing free thresholds θj per dimension, we let the policy determine Ai based on
the graded sovereignty vector Σi (t):
    [Policy-Compiled Activity Set] Given a graded sovereignty vector Σi (t) and a policy profile P,
the activity set is                                
                                  Ai = Ai Σi (t), P ⊆ {1, . . . , n},
computed by a known function (e.g., a table or circuit) that is part of the policy definition.
    The key point is that the policy, not the mathematical framework, introduces any effective
thresholds; they appear as fixed parameters inside a zk circuit or policy tree, and not as new free
constants at the CSL level.

A.4    Opt-Out Limit and Recovery of Hard Halt
Consider the scaled-activity model where, for each j, the scalar weight wj (Σi (t), P) ∈ [0, 1] encodes
effective participation of dimension j. Define
                                                      n
                                                      X
                                           Pisoft =         wj (Σi (t), P)Πj .
                                                      j=1

In the binary limit where
                                         wj (Σi (t), P) ∈ {0, 1} for all j,
we recover Pi as in (16) and thus the hard opt-out behavior. In particular, if Σi (t) maps to all
weights zero, then Pi = 0 and the update rule
                                                      raw
                                       Tt+1 (i) = Pi Tt+1 (i) + (I − Pi )Tt (i)

reduces to Tt+1 (i) = Tt (i).


B     Admissible Operator Equivariance and CSL Functor
B.1    Admissible Operator Family
Let MCSL be a family of operators M : V → VLthat are considered admissible for CSL-enforced
execution. We require that M respect the V = j Vj decomposition in the following sense.
    [Block-Diagonal Admissible Operators] An operator M : V → V is block-diagonal with respect
to the decomposition (15) if
                                             Xn
                                        M=      Mj Πj ,
                                                            j=1

where each Mj : Vj → Vj .

                                                             14
   [Equivariance of Pi for Block-Diagonal M ] If M is block-diagonal and Pi is defined as in (16),
then
                                        Pi M Pi = M Pi .
Proof. We compute
                                                        !      
                                X             n
                                              X              X        X
                 Pi M Pi =            Πj          Mk Π k    Πℓ  =   Π j Mk Π k Π ℓ .
                                j∈Ai          k=1               ℓ∈Ai         j,k,ℓ

By orthogonality, Πk Πℓ = 0 if k ̸= ℓ and Πk Πk = Πk , so the sum reduces to
                                                                        
                X                 X                X               X
                     Π j Mℓ Π ℓ =     Π ℓ Mℓ Π ℓ =   Mℓ Π ℓ = M      Πℓ  = M Pi .
                j,ℓ∈Ai             ℓ∈Ai                  ℓ∈Ai                ℓ∈Ai




B.2    Sovereign Functor as Projection
Define the sovereign functor at the operator level by
                                              SCSL (M ) = Pi M Pi .                             (17)
    [Projection Property] If M is block-diagonal with respect to the decomposition (15), then
                                        SCSL (SCSL (M )) = SCSL (M ).
Proof. We have
               SCSL (SCSL (M )) = Pi (Pi M Pi )Pi = (Pi2 )M (Pi2 ) = Pi M Pi = SCSL (M ),
using idempotency Pi2 = Pi and associativity of composition.


C     Stability Bounds for PIRTM-Like Recursions
C.1    Linear PIRTM Recursion and Noise Decay
Consider the scalar linear recursion
                                                         
                                                X
                             xt+1 = Λm                 pαi  xt + u(t),   α < −1,              (18)
                                               pi ∈PN

where PN is a finite set of primes and u(t) is a forcing term (e.g., input or noise). Define
                                                          X
                                   κ(Λm , α, PN ) := Λm       pαi .
                                                                  pi ∈PN

    [Sufficient Condition for Exponential Stability] If
                                              |κ(Λm , α, PN )| < 1,
then the homogeneous recursion
                                                    xt+1 = κxt
is exponentially stable.
Proof. The solution is xt = κt x0 . If |κ| < 1, then |xt | ≤ |κ|t |x0 | and κt → 0 as t → ∞.

                                                          15
C.2    Noise Bound Over k Steps
Let η(t) be the deviation from the noiseless trajectory. For simplicity, assume u(t) is zero-mean
noise with bounded magnitude |u(t)| ≤ δ. Then the induced noise at time t + k satisfies
                                             k−1
                                             X            1 − |κ|k       δ
                              |η(t + k)| ≤       |κ|j δ ≤          δ≤         .               (19)
                                                          1 − |κ|     1 − |κ|
                                             j=0

In particular, for moderate k and |κ| ≪ 1, we obtain a strong suppression of noise.
    This is the scalar prototype of the more general operator inequality

                                       ∥η(t + k)∥ ≤ ∥Ak ∥∥η(t)∥

when the PIRTM dynamics are represented as Xt+1 = AXt +U (t), where A encodes the multiplicity-
weighted contribution of prime-indexed blocks.

C.3    Operator Norm Bound in Block-Diagonal Case
Assume that the full PIRTM evolution is linearized as

                                                Xt+1 = AXt ,

where A is block-diagonal with blocks Ap corresponding to prime indices:
                                               M
                                         A=        Ap .
                                                     p∈PN

Then the operator norm satisfies
                                             ∥A∥ = max ∥Ap ∥.
                                                     p∈PN

If each Ap is scaled by Λm pα , i.e.
                                               Ap = Λm pα Bp ,
with ∥Bp ∥ ≤ 1, then
                                             ∥A∥ ≤ Λm max pα .
                                                           p∈PN

For α < 0 this is bounded by
                                              ∥A∥ ≤ Λm pαmin ,
where pmin is the smallest prime in PN . Thus a sufficient condition for stability is

                                                Λm pαmin < 1.


D     Ethical Commutativity with a Fixed Snapshot
D.1    Snapshot-Based Ethical Commutator
Let Eα (t) be a time-varying ethical operator in some operator algebra on V . For verifiability, we
pick a fixed snapshot E ∗ := Eα (t0 ) and enforce

                             [M, E ∗ ] = 0 for all admissible M ∈ MCSL .                      (20)

  [Spectral Decomposition under Commutativity] If E ∗ is diagonalizable and [M, E ∗ ] = 0, then
M preserves each eigenspace of E ∗ .

                                                      16
Proof. Let v be an eigenvector of E ∗ with eigenvalue λ:

                                               E ∗ v = λv.

Then
                                 E ∗ (M v) = M (E ∗ v) = M (λv) = λM v,
so M v is also an eigenvector with eigenvalue λ (or zero). Thus each eigenspace is invariant under
M.

    This lemma justifies verification schemes that interpret admissible operations as those that pre-
serve the decomposition induced by E ∗ , e.g., by checking that proof objects lie in specific eigenspaces.

D.2       Verification Snapshot and Determinism
Let Vλk be the eigenspaces of E ∗ with eigenvalues λk . If we require that a proof object z associated
with a proposed operation lie in a designated Vλk , then verification with respect to E ∗ is deterministic
and reproducible:
                                     verify(z) = 1 ⇐⇒ z ∈ Vλk .                                      (21)
Time-varying Eα (t) can still influence internal dynamics, but external verification is always per-
formed using E ∗ .


E       Lyapunov Candidate for STI-like Convergence (Toy Setting)
E.1       Toy Multiplicity Graph
Consider a finite multiplicity graph G = (V, E) where each node v ∈ V has a state xv (t), and the
evolution is                                                         
                                  xv (t + 1) = fv xv (t), {xu (t)}u∼v ,
with u ∼ v ranging over neighbors. Suppose the system is designed to converge to a “stable ethical”
configuration x∗ , and define a scalar stability indicator ST I(t) ∈ [0, 1], with ST I(t) = 1 indicating
perfect alignment.

E.2       Lyapunov Candidate
Define
                                           V (t) = 1 − ST I(t).
Assuming a differentiable (or discrete difference) model, we seek conditions such that

                                          V (t + 1) − V (t) ≤ 0,

i.e.
                                         ST I(t + 1) ≥ ST I(t).
       In a toy model where ST I(t) is defined as
                                                       ∥x(t) − x∗ ∥
                                       ST I(t) = 1 −                ,
                                                            C
for some normalization constant C > 0, the condition

                                     ∥x(t + 1) − x∗ ∥ ≤ ∥x(t) − x∗ ∥

                                                    17
is sufficient to ensure ST I(t + 1) ≥ ST I(t). For linear dynamics xt+1 = Axt + b, this reduces to
∥A∥ ≤ 1 (in a consistent norm) and b chosen such that x∗ is a fixed point.
     This toy analysis does not yet prove convergence in the full PIRTM/DRMM architecture, but
it illustrates the type of norm and fixed-point conditions needed to claim a Lyapunov-style mono-
tonicity of ST I(t).


F    Trust and Setup Conditions as Formal Preconditions
For completeness, we state key trust and setup requirements as explicit preconditions:

• T-layer assumptions:

    – The post-quantum signature implementation (e.g. Dilithium2) is sound and properly instan-
      tiated.
    – Hash functions (e.g. BLAKE3) behave as collision-resistant and preimage-resistant.
    – The sidecar code and registries execute in an environment with integrity (e.g. TEEs or
      reproducible builds).

• zk setup assumptions:

    – For Groth16 or similar systems, a trusted setup ceremony has been executed correctly and
      toxic waste destroyed, or a transparent proof system is used instead.
    – The verifying keys registered via vkHash correctly correspond to the intended circuits.

• PIRTM hardness assumptions:

    – Any use of PIRTM in key derivation or encryption is tagged as:
         ∗ reduced to a known hard problem,
         ∗ conjecturally hard, or
         ∗ insecure/experimental.

  This completes the set of mathematical and formal appendices intended to accompany the main
CSL–Zenolock–PIRTM publication.


References
 [1] Ryan Van Gelder. Conscious sovereignty layer: A mathematical framework for ethical auton-
     omy. Preprint, Citizen Gardens / Multiplicity Foundation, 2026. Defensive publication.

 [2] Ryan Van Gelder. Zenolock: A recursive, prime-encoded, post-quantum cryptographic frame-
     work with cognitive tensor enforcement. Preprint, Citizen Gardens, 2025. Defensive publication.

 [3] Peter W. Shor. Polynomial-time algorithms for prime factorization and discrete logarithms on
     a quantum computer. SIAM Journal on Computing, 26(5):1484–1509, 1997.

 [4] Lov K. Grover. A fast quantum mechanical algorithm for database search. Proceedings of the
     28th Annual ACM Symposium on Theory of Computing, pages 212–219, 1996.

 [5] Oded Regev. On lattices, learning with errors, random linear codes, and cryptography. In
     Proceedings of the 37th Annual ACM Symposium on Theory of Computing, pages 84–93, 2005.

                                                18
 [6] Vadim Lyubashevsky, Chris Peikert, Oded Regev, et al. CRYSTALS-Dilithium: A lattice-based
     digital signature scheme. In 2018 IEEE European Symposium on Security and Privacy, 2018.
     NIST PQC candidate.

 [7] Jens Groth. On the size of pairing-based non-interactive arguments. Advances in Cryptology –
     EUROCRYPT 2016, pages 305–326, 2016.

 [8] Alin Tomescu. Groth16. https://alinush.github.io/groth16, 2025. Accessed 2026-
     04-25.

 [9] Nethermind      Research.          Zk circuit  security:   A   guide  for  en-
     gineers      and       architects.            https://www.nethermind.io/blog/
     zk-circuit-security-a-guide-for-engineers-and-architects, 2025.            Ac-
     cessed 2026-04-25.

[10] Ethereum Foundation. Zero-knowledge rollups. https://ethereum.org/developers/
     docs/scaling/zk-rollups/, 2026. Accessed 2026-04-25.

[11] Michael A. Nielsen and Isaac L. Chuang. Quantum Computation and Quantum Information.
     Cambridge University Press, 10th anniversary edition, 2010.

[12] John Milnor. On manifolds homeomorphic to the 7-sphere. Annals of Mathematics, 64(2):399–
     405, 1956.

[13] James Eells and Nicolaas H. Kuiper. Manifolds which are homeomorphic but not diffeomorphic.
     Publications Mathématiques de l’IHÉS, 14:5–26, 1962.

[14] Edward Frenkel. Langlands program and its physics connections. https://arxiv.org/
     abs/math/0402120, 2004.

[15] Jean-Pierre Serre. Propriétés galoisiennes des points d’ordre finis des courbes elliptiques. In-
     ventiones Mathematicae, 15:259–331, 1972.

[16] Yi-Zhi Huang. Tensor categories and the mathematics of rational and logarithmic conformal
     field theory. Journal of Physics A: Mathematical and Theoretical, 46(49):494009, 2013.

[17] nLab Authors.    Tensor category.          https://ncatlab.org/nlab/show/tensor+
     category, 2026. Accessed 2026-04-25.

[18] Jutho Haegeman. Tensor categories in tensorkit.jl documentation. https://github.com/
     Jutho/TensorKit.jl/blob/master/docs/src/man/categories.md, 2017.                  Ac-
     cessed 2026-04-25.

[19] Wikipedia contributors. Idempotent (ring theory). https://en.wikipedia.org/wiki/
     Idempotent_(ring_theory), 2025. Accessed 2026-04-25.

[20] Various Authors. Category theory in machine learning – bibliography. https://github.
     com/bgavran/Category_Theory_Machine_Learning, 2020. Accessed 2026-04-25.

[21] Citizen Gardens.         Csl:   Math-based ethical governance for lawful com-
     putation.                  https://www.linkedin.com/posts/citizen-gardens_
     conscious-sovereignty-layer-csl-solver-activity-7415346637507764224-NUQX,
     2026. Accessed 2026-04-25.

                                                 19
[22] Multiplicity Foundation.  Introducing prime-indexed recursive tensor mathematics for
     self-referential systems.     https://www.linkedin.com/posts/multiplicity_
     deepinvent4good-inventathon-activity-7364106803887894528-0d1A,                 2025.
     Accessed 2026-04-25.

[23] The Zero Knowledge Blog. Groth16. https://www.zeroknowledgeblog.com/index.
     php/groth16, 2023. Accessed 2026-04-25.

[24] Delendum Research. zk-knowledge: A curated collection of zk references. https://github.
     com/delendum-xyz/zk-knowledge, 2022. Accessed 2026-04-25.

[25] Anonymous. A unified kill chain model for quantum machine learning security. https:
     //arxiv.org/html/2507.08623v1, 2025. Accessed 2026-04-25.

[26] Meta     AI.              Introducing   the   ground   truth  maturity  frame-
     work.                              https://research.facebook.com/blog/2022/8/
     -introducing-the-ground-truth-maturity-framework-for-assessing-and-improving-gr
     2022. Accessed 2026-04-25.

[27] Mojtaba Bisheh et al. Threat model for securing dilithium implementations against side-channel
     attacks. https://github.com/chipsalliance/adams-bridge/blob/main/docs/
     AdamsBridgeSCA.md, 2025. Accessed 2026-04-25.

[28] Yuancheng Liu. Network pqc attack resistance evaluator. https://github.com/
     LiuYuancheng/Network_PQC_Attack_Resistance_Evaluator, 2022. Accessed 2026-
     04-25.

[29] Jake Kitchen. Cv-qkd wave attack simulation. https://github.com/JakeKitchen/
     CV-QKD-Wave-Attack, 2024. Accessed 2026-04-25.

[30] AWS Samples. Sample bb84 qkd on amazon braket. https://github.com/aws-samples/
     sample-BB84-qkd-on-amazon-braket, 2025. Accessed 2026-04-25.

[31] Koray D. Quantum attack simulator for bb84. https://github.com/koraydns/
     quantum-attack-simulator, 2024. Accessed 2026-04-25.




                                                20
