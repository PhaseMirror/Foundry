// TypeScript wrapper for Sedona Spine WASM
// Conforms to the PRESERVATION ALERT Agent Contract

export interface EsiInputs {
    spoliation_potential: number;
    preservation_urgency: number;
    volume_estimate_gb: number;
    lambda_m?: number;
    l_g?: number;
    gamma?: number;
    norm_s?: number;
    histogram?: number[];
    fidelity?: number;
    entropy_rate?: number;
    zeta_truncation?: number;
    derivation_hash?: string;
}

let wasmModule: any = null;

export async function initWasm() {
    if (!wasmModule) {
        wasmModule = await import('../../pkg/legalese_scopist.js');
        await wasmModule.default();
    }
    return wasmModule;
}

export async function evaluateEsiRisk(inputs: EsiInputs, pFactor: number = 3, sigma: number = 2.0): Promise<any> {
    const wasm = await initWasm();
    try {
        const witness = wasm.evaluate_esi_risk_wasm(inputs, pFactor, sigma);
        return witness;
    } catch (e) {
        console.error("WASM execution failed, halting evaluation:", e);
        throw e;
    }
}

