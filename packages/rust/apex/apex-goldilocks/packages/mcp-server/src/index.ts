import { Server } from "@modelcontextprotocol/sdk/server/index.js";  
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";  
import {  
  CallToolRequestSchema,  
  ListToolsRequestSchema,  
} from "@modelcontextprotocol/sdk/types.js";  
import { callRustEngine } from "./bridge.js";  
import {  
  AnalyzeDissonanceSchema,  
  VerifyLedgerSchema,  
  LatticeAuditSchema,  
  AepVerifySchema,
  AepAceStepSchema,
  AepEthicsCommutationSchema,
  AepSovereigntyGateSchema,
} from "./schemas.js";

const server = new Server(  
  {  
    name: "phase-mirror-governance-engine",  
    version: "1.0.0",  
  },  
  {  
    capabilities: {  
      tools: {},  
    },  
  }  
);

// Define the discovery registry mapping our architectural guards  
server.setRequestHandler(ListToolsRequestSchema, async () => {  
  return {  
    tools: [  
      {  
        name: "analyze_dissonance",  
        description: "Runs Adaptive Constraint Enforcement (ACE) weighted ℓ₁ projection and checks KKT conditions.",  
        inputSchema: {  
          type: "object",  
          properties: {  
            stateVector: { type: "array", items: { type: "number" } },  
            constraints: { type: "array", items: { type: "number" } },  
            spectralBallLimit: { type: "number" }  
          },  
          required: ["stateVector", "constraints"]  
        }  
      },  
      {  
        name: "verify_audit_ledger",  
        description: "Validates dual-hash chain tracking continuity (SHA-256 interleaved with Blake2b-32).",  
        inputSchema: {  
          type: "object",  
          properties: {  
            historyBlocks: { type: "array" }  
          },  
          required: ["historyBlocks"]  
        }  
      },  
      {  
        name: "audit_lattice_confinement",  
        description: "Enforces spatial confinement boundaries against the 96x12,288 orbit coordinate layout.",  
        inputSchema: {  
          type: "object",  
          properties: {  
            addressMappings: { type: "array" }  
          },  
          required: ["addressMappings"]  
        }  
      },
      {
        name: "aep_verify_claim",
        description: "Parses AEP TOML policy configuration and evaluates decision predicates for witness verification.",
        inputSchema: {
          type: "object",
          properties: {
            aep_toml_path: { type: "string" },
            w_in: { type: "object" },
            theta: { type: "object" }
          },
          required: ["aep_toml_path", "w_in", "theta"]
        }
      },
      {
        name: "aep_ace_step",
        description: "Executes a single step of the integer-based ACERuntime and outputs updated state and Cauchy convergence certificate.",
        inputSchema: {
          type: "object",
          properties: {
            state: { type: "object" },
            w_proposal: { type: "array", items: { type: "integer" } },
            budgets: { type: "object" },
            b_norms_q: { type: "array", items: { type: "integer" } },
            eps_t: { type: "integer" },
            k_t: { type: "array", items: { type: "array", items: { type: "integer" } } },
            fail_closed: { type: "boolean" }
          },
          required: ["state", "w_proposal", "budgets", "b_norms_q", "eps_t", "k_t", "fail_closed"]
      },
      {
        name: "aep_ethics_commutation",
        description: "Validates commutation relations and forbidden channel writes under the ethics policy.",
        inputSchema: {
          type: "object",
          properties: {
            aep_dir: { type: "string" }
          },
          required: ["aep_dir"]
        }
      },
      {
        name: "aep_sovereignty_gate",
        description: "Enforces identity sovereignty and access control.",
        inputSchema: {
          type: "object",
          properties: {
            aep_dir: { type: "string" },
            actor_id: { type: "string" }
          },
          required: ["aep_dir"]
        }
      }
    ]  
  };  
});

// Structural dispatch route resolving runtime actions  
server.setRequestHandler(CallToolRequestSchema, async (request) => {  
  const { name, arguments: args } = request.params;

  try {  
    switch (name) {  
      case "analyze_dissonance": {  
        const validated = AnalyzeDissonanceSchema.parse(args);  
        const result = await callRustEngine("ace_project", validated);  
        return { content: [{ type: "text", text: result }] };  
      }  
      case "verify_audit_ledger": {  
        const validated = VerifyLedgerSchema.parse(args);  
        const result = await callRustEngine("ledger_verify", validated);  
        return { content: [{ type: "text", text: result }] };  
      }  
      case "audit_lattice_confinement": {  
        const validated = LatticeAuditSchema.parse(args);  
        const result = await callRustEngine("lattice_check", validated);  
        return { content: [{ type: "text", text: result }] };  
      }  
      case "aep_verify_claim": {
        const validated = AepVerifySchema.parse(args);
        const result = await callRustEngine("aep_verify_claim", validated);
        return { content: [{ type: "text", text: result }] };
      }
      case "aep_ace_step": {
        const validated = AepAceStepSchema.parse(args);
        const result = await callRustEngine("aep_ace_step", validated);
        return { content: [{ type: "text", text: result }] };
      }
      default:  
        throw new Error(`Unsupported tool mapping request: ${name}`);  
    }  
  } catch (err: any) {  
    return {  
      isError: true,  
      content: [{ type: "text", text: err.message || "Internal schema validation failure." }]  
    };  
  }  
});

// Bind transport channel execution vectors safely over standard I/O streams  
async function run() {  
  const transport = new StdioServerTransport();  
  await server.connect(transport);  
  console.error("Phase Mirror Governance MCP Layer online via Stdio Transport.");  
}

run().catch((error) => {  
  console.error("MCP Lifecycle failure:", error);  
  process.exit(1);  
});
