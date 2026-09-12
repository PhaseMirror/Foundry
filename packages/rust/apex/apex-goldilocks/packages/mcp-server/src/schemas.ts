import { z } from "zod";

// Validated mirrors of structural targets inside planes.rs and ace.rs  
export const AnalyzeDissonanceSchema = z.object({  
  stateVector: z.array(z.number()).describe("Real-valued input execution trace data block"),  
  constraints: z.array(z.number()).describe("Target lawfulness subspace boundary weights"),  
  spectralBallLimit: z.number().default(1.0).describe("Maximum allowable contractive radius")  
});

export const VerifyLedgerSchema = z.object({  
  historyBlocks: z.array(z.object({  
    index: z.number(),  
    payloadHash: z.string(),  
    nonce: z.number(),  
    prevHash: z.string()  
  })).describe("Dual-hash chain trace segments array")  
});

export const LatticeAuditSchema = z.object({  
  addressMappings: z.array(z.array(z.number())).describe("96x12288 coordinates cluster buffer payload")  
});

export const AepVerifySchema = z.object({
  aep_toml_path: z.string().describe("Path to the AEP TOML policy configuration"),
  w_in: z.any().describe("Witness object for verification containing fields like delta_R, footprint, etc."),
  theta: z.any().describe("Parameter object containing values like Q")
});

export const AepAceStepSchema = z.object({
  state: z.object({
    T: z.array(z.number()),
    F: z.array(z.number()),
    q: z.number(),
    step: z.number(),
    kkt_certificates: z.array(z.any()),
    contraction_history: z.array(z.any()),
    petc_ledger: z.object({
      rows: z.record(z.any()),
      commutator_budget: z.record(z.number())
    }),
    converged: z.boolean(),
    convergence_threshold: z.number()
  }).describe("Current state of the ACE Runtime"),
  w_proposal: z.array(z.number()).describe("Proposed weight update vector (integers)"),
  budgets: z.object({
    b: z.array(z.number()),
    a: z.array(z.number()),
    limit1_Q: z.number(),
    limit2_Q: z.number(),
    q: z.number()
  }).describe("Budgets for constraint limits"),
  b_norms_q: z.array(z.number()).describe("Constraint norms"),
  eps_t: z.number().describe("Operator contraction parameter gap"),
  k_t: z.array(z.array(z.number())).describe("Contraction operator matrix (integers)"),
  fail_closed: z.boolean().describe("Whether to fail closed if checks violate contractivity")
});

export const AepEthicsCommutationSchema = z.object({
  aep_dir: z.string().describe("Path to the ethics commutation AEP directory containing aep.toml and kernel.atlas")
});

export const AepSovereigntyGateSchema = z.object({
  aep_dir: z.string().describe("Path to the sovereignty gate AEP directory containing aep.toml and kernel.atlas"),
  actor_id: z.string().optional().describe("Optional override for actor ID")
});


