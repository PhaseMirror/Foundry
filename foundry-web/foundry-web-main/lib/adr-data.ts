import { ADR, ADRRegistry, ADRStatus } from './adr-types';

export const FOUNDRY_ADR_SETS: Record<string, ADR[]> = {
  core: [
    {
      id: 'ADR-001',
      title: 'Integer Jordan Bond Governance',
      status: 'Superseded',
      context: 'Floating-point non-determinism introduces drift and spoliation risk in state transitions across distributed nodes.',
      decision: 'Enforce fixed-point integer Jordan bond arithmetic scaled by N = 1024 at the kernel boundary.',
      consequences: ['Arithmetic determinism guaranteed across heterogeneous nodes', 'Floating point drift strictly eliminated'],
      supersedes: null,
      links: [
        { uri: 'PhaseMirror.Care.Scale', kind: 'LeanDeclaration', description: 'Canonical fixed-point scale N = 1024' },
        { uri: 'Care.lean', kind: 'SourceFile', description: 'Integer fixed-point operations' },
      ],
    },
    {
      id: 'ADR-002',
      title: 'Sedona Spine Retention Engine Sole Source of Truth',
      status: 'Accepted',
      context: 'Decentralized litigation hold rules risk spoliation drift if computed independently by UI or client agents.',
      decision: 'All ESI preservation risk logic must route exclusively through the Sedona Spine Rust Engine and WASM SDK.',
      consequences: ['Zero drift in litigation hold calculations', 'Mandatory provenance chain: Policy → Event → Kernel → Witness'],
      supersedes: null,
      links: [
        { uri: 'models/legalese-scopist/CONTRACT.md', kind: 'SpecificationDoc', description: 'Preservation alert protocol' },
        { uri: 'models/legalese-scopist/', kind: 'SourceFile', description: 'Rust Engine Core implementation' },
      ],
    },
    {
      id: 'ADR-003',
      title: 'Per-Triad Resonance Floors (Audit v2)',
      status: 'Accepted',
      context: 'Aggregate mean resonance floor in ADR-001 permitted averaging blind spots where individual triads could fall below viability.',
      decision: 'Strengthen viability audit to require every individual triad to meet or exceed ResFloor = 870.',
      consequences: ['Eliminates averaging blind spot proved by averaging_blind_spot theorem', 'Preserves backward compatibility with audit v1'],
      supersedes: null,
      links: [
        { uri: 'ADR/Theorems/CareViability.lean', kind: 'SourceFile', description: 'Formalization of v2 thresholds' },
        { uri: 'PhaseMirror.CareViability.phase_mirror_audit_v2', kind: 'LeanDeclaration', description: 'Per-triad binary audit' },
      ],
    },
    {
      id: 'ADR-004',
      title: 'Meet-Semilattice Partition Refinement & LCR Operator',
      status: 'Accepted',
      context: 'SPMD distributed execution requires a formal refinement order over tensor sharding states.',
      decision: 'Enforce pointwise meet operator (⊓) over logical mesh axes with idempotent, associative, commutative semantics.',
      consequences: ['Deterministic least common refinement across distributed execution paths', 'Fail-closed immediate rejection of conflicting sharding schedules'],
      supersedes: null,
      links: [
        { uri: 'specs/p2c_petc_v12.md', kind: 'SpecificationDoc', description: 'P²C PETC v1.2 Specification Section 2.3' },
        { uri: 'packages/rust/pirtm-compiler/src/sharding.rs', kind: 'SourceFile', description: 'LCR Meet Operator Implementation' },
      ],
    },
    {
      id: 'ADR-005',
      title: 'BLAKE2b-16 Personalization & Canonical Bytecode Wire Format',
      status: 'Accepted',
      context: 'Witness bytecode streams require compact, tamper-evident framing with low verification overhead.',
      decision: 'Standardize binary wire format on header magic P2CWITv2, version 0x0102, LEB128/ZigZag varints, trailer 0xAA 0x55.',
      consequences: ['Bit-flip and truncation detection at frame boundary', 'Allocation-free stack-based decoding in high-performance runtimes'],
      supersedes: null,
      links: [
        { uri: 'specs/p2c_petc_v12.md', kind: 'SpecificationDoc', description: 'P²C PETC v1.2 Binary Wire Format Section 3' },
        { uri: 'packages/rust/core/src/petc.rs', kind: 'SourceFile', description: 'Bytecode Frame Parser' },
      ],
    },
    {
      id: 'ADR-006',
      title: 'MultiContract Atomic Contraction with PartialSum Tokens',
      status: 'Accepted',
      context: 'Contraction over sharded tensor dimensions produces partial sums requiring explicit collective reductions.',
      decision: 'Standardize opcode 0x05 (MultiContract) to atomically verify dual signatures and emit PartialSum(mesh_axis) tokens.',
      consequences: ['Prevents unreduced partial sum escapes in SPMD graphs', 'Simultaneous atomic multi-axis tensor contractions in O(k) time'],
      supersedes: null,
      links: [
        { uri: 'specs/p2c_petc_v12.md', kind: 'SpecificationDoc', description: 'P²C PETC v1.2 Opcode Semantics Section 4' },
        { uri: 'packages/rust/engine/src/petc.rs', kind: 'SourceFile', description: 'MultiContract Evaluator' },
      ],
    },
    {
      id: 'ADR-007',
      title: 'Commutative Collective Transformers for Deterministic Sharding Commit',
      status: 'Accepted',
      context: 'Multi-mesh collective operations must yield identical global sharding states regardless of topological scheduling order.',
      decision: 'Define collective transformers T_m that transition axis m to Replicated, and formally verify operator commutativity.',
      consequences: ['Topology-invariant global sharding commitment', 'Eliminates deadlocks and non-determinism in multi-axis reduction pipelines'],
      supersedes: null,
      links: [
        { uri: 'specs/p2c_petc_v12.md', kind: 'SpecificationDoc', description: 'P²C PETC v1.2 Section 2.3 Collective Transformers' },
        { uri: 'lean/Multiplicity/PETC.lean', kind: 'LeanDeclaration', description: 'Collective transformer commutation' },
      ],
    },
    {
      id: 'ADR-008',
      title: 'Prime Signature Canonical Monoid as Exclusive Rust Kernel Substrate',
      status: 'Accepted',
      context: 'All multiplicity computations must share a single, deterministic representation to prevent representational drift.',
      decision: 'The only permitted representation is a finitely supported map from primes to exponents with free commutative monoid structure.',
      consequences: ['Signature equality is decidable by structural comparison', 'Multiplicity product is strictly associative and commutative', 'Foreign representations must convert at kernel boundary or be rejected'],
      supersedes: null,
      links: [
        { uri: 'PhaseMirror.PrimeSignature', kind: 'LeanDeclaration', description: 'Formal specification of signature monoid' },
        { uri: 'packages/rust/multiplicity/multiplicity-core/src/signature.rs', kind: 'SourceFile', description: 'Target Rust implementation' },
      ],
    },
    {
      id: 'ADR-009',
      title: 'Mandatory Contraction Witness & Spectral Radius Verification Before Emission Gate',
      status: 'Accepted',
      context: 'Unconstrained recurrence or agent emission can produce unbounded Lyapunov drift.',
      decision: 'No signal may pass the Emission Gate unless a machine-checkable ContractionWitness proves spectral radius < 1.',
      consequences: ['EmissionGate returns Suppress or Hold when no valid witness present', 'SpectralGovernor is sole authority to mint ContractionWitness', 'Any bypass constitutes a hard kernel violation'],
      supersedes: null,
      links: [
        { uri: 'PhaseMirror.SpectralGovernor', kind: 'LeanDeclaration', description: 'Formal contract of spectral governor' },
        { uri: 'packages/rust/ramanujan-multiplicity', kind: 'SourceFile', description: 'Witness generation site' },
      ],
    },
    {
      id: 'ADR-010',
      title: 'Axiom-Clean Kernel Boundary and Manifested Proof Debt Policy',
      status: 'Accepted',
      context: 'Unmanifested sorry, todo!, or commented-out critical paths create verification leakage.',
      decision: 'The kernel boundary must be axiom-clean. Every open proof obligation must be fully discharged or explicitly manifested.',
      consequences: ['CI rejects any increase in manifested or unmanifested sorry count', 'Kernel startup performs static honesty manifest check', 'Research surfaces may contain open obligations only when quarantined'],
      supersedes: null,
      links: [
        { uri: '.github/workflows/adr-verify.yml', kind: 'SpecificationDoc', description: 'Honesty audit workflow' },
        { uri: 'docs/CURRENT_TRUTH.md', kind: 'SpecificationDoc', description: 'Living honesty ledger' },
      ],
    },
  ],
  governance: [
    {
      id: 'ADR-0013',
      title: 'UOR Civic Infrastructure',
      status: 'Accepted',
      context: 'The Foundry DAO progresses through three strategic developmental epochs.',
      decision: 'Adopt the canonical BCS wire format for the UnsignedCrmfEnvelope, the PWEH integrity binding, the contractivity gate, and fail-closed governance.',
      consequences: ['Deterministic cross-language canonical byte streams', 'Path-dependent tamper resistance across PWEH chain', 'Fail-closed governance: unmodeled defect halts L0', 'Integer-only wire: floating point structurally excluded'],
      supersedes: null,
      links: [
        { uri: 'docs/papers/UOR Civic Infrastructure_.docx', kind: 'SourceFile', description: 'UOR Civic Infrastructure' },
        { uri: 'lean/MTPI/ADR0013.lean', kind: 'SourceFile', description: 'Canonical BCS wire format formalized as Lean 4 theorems' },
        { uri: 'packages/rust/crmf/src/canonical.rs', kind: 'SourceFile', description: 'Canonical BCS wire format (Kani-verified)' },
      ],
    },
    {
      id: 'ADR-0017',
      title: 'Reinitialization — 90-Day Operating Plan and Volunteer Talent Model',
      status: 'Accepted',
      context: 'UOR Foundation must reinitialize under volunteer-led, no-funding assumption.',
      decision: 'Adopt 90-Day Operating Plan: one primary objective, Day Zero two-week mobilization, five workstreams max.',
      consequences: ['Execution capped by WIP limits', 'No-funding assumption binding', 'Cycle either closes deliverables or fails exit rule loudly'],
      supersedes: null,
      links: [
        { uri: 'docs/papers/UOR_Final_90_Day_Operating_Plan.docx', kind: 'SourceFile', description: '90-Day Operating Plan' },
      ],
    },
    {
      id: 'ADR-0113',
      title: 'Universal Closure Calculator — Unified Kernel Surface',
      status: 'Accepted',
      context: 'The Foundry hosts several independently verified surfaces with no single accepted decision binding them.',
      decision: 'Adopt the UCC sextuple as the canonical integration surface and wire every verified Foundry surface to it.',
      consequences: ['Every closure call returns Closure, Defect, Receipt, and Levers', 'Unlawful transitions fail closed at L0', 'Proof debt is explicit and bounded', 'Integer-only wire: floating point excluded'],
      supersedes: null,
      links: [
        { uri: 'docs/specs/ucc_sextuple_v1.md', kind: 'SpecificationDoc', description: 'Canonical sextuple wire format' },
        { uri: 'contracts/universal_closure.yaml', kind: 'SpecificationDoc', description: 'Declarative associator tolerance' },
        { uri: 'ADR/Theorems/Homestead_UCC_Care_Bridge.lean', kind: 'LeanDeclaration', description: 'L0 gate soundness' },
        { uri: 'ADR/Properties.lean', kind: 'LeanDeclaration', description: 'Property/concurrency tests' },
        { uri: 'scripts/check_adr_sorry.py', kind: 'SourceFile', description: 'Manifest-aware proof-debt gate' },
      ],
    },
  ],
};

export const ALL_FOUNDRY_ADRS: ADR[] = [
  ...FOUNDRY_ADR_SETS.core,
  ...FOUNDRY_ADR_SETS.governance,
];

export function countByStatus(adrs: ADR[], status: ADRStatus): number {
  return adrs.filter(a => a.status === status).length;
}

export function buildADRRegistry(adrs: ADR[]): ADRRegistry {
  const claims = adrs
    .filter(a => a.status === 'Accepted')
    .map(a => ({ owner: a.id, claim: `decision:${a.decision.substring(0, 80)}...` }));
  return { adrs, claims };
}

export const FOUNDRY_AUDIT_TRAIL: Array<{ ADR_ID: string; Action: string; Timestamp: string; Status: string; Author: string }> = [
  { ADR_ID: 'ADR-001', Action: 'Superseded', Timestamp: '2026-03-01T10:00:00Z', Status: 'Superseded', Author: 'PhaseMirror' },
  { ADR_ID: 'ADR-002', Action: 'Accepted', Timestamp: '2026-01-15T14:30:00Z', Status: 'Accepted', Author: 'Foundry Council' },
  { ADR_ID: 'ADR-003', Action: 'Accepted', Timestamp: '2026-02-01T09:00:00Z', Status: 'Accepted', Author: 'Foundry Council' },
  { ADR_ID: 'ADR-004', Action: 'Accepted', Timestamp: '2026-02-15T11:00:00Z', Status: 'Accepted', Author: 'P²C PETC Committee' },
  { ADR_ID: 'ADR-005', Action: 'Accepted', Timestamp: '2026-02-20T16:00:00Z', Status: 'Accepted', Author: 'P²C PETC Committee' },
  { ADR_ID: 'ADR-006', Action: 'Accepted', Timestamp: '2026-03-01T08:00:00Z', Status: 'Accepted', Author: 'P²C PETC Committee' },
  { ADR_ID: 'ADR-007', Action: 'Accepted', Timestamp: '2026-03-05T12:00:00Z', Status: 'Accepted', Author: 'Sharding Working Group' },
  { ADR_ID: 'ADR-008', Action: 'Accepted', Timestamp: '2026-03-10T15:00:00Z', Status: 'Accepted', Author: 'Multiplicity Team' },
  { ADR_ID: 'ADR-009', Action: 'Accepted', Timestamp: '2026-03-15T10:00:00Z', Status: 'Accepted', Author: 'SpectralGovernor' },
  { ADR_ID: 'ADR-010', Action: 'Accepted', Timestamp: '2026-03-20T14:00:00Z', Status: 'Accepted', Author: 'Foundry Council' },
  { ADR_ID: 'ADR-0013', Action: 'Accepted', Timestamp: '2026-04-01T09:00:00Z', Status: 'Accepted', Author: 'Civic Infrastructure Team' },
  { ADR_ID: 'ADR-0113', Action: 'Accepted', Timestamp: '2026-05-01T12:00:00Z', Status: 'Accepted', Author: 'UCC Integration Committee' },
];
