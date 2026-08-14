import { evaluateEsiRisk, EsiInputs, initWasm } from './sedonaSpine';

export interface PrimeIndexedState {
    prime: number;
    amplitude: number;
    phase: string;
}

export interface TensorNetworkState {
    riskLevel: string;
    spectralRadius: number;
    isStable: boolean;
    primeHilbertSpace: PrimeIndexedState[];
}

/**
 * Maps the Sedona Spine output (UnifiedWitness) into the Prime-Indexed Hilbert Space.
 * This integrates the ethical decision kernel directly into the Multiplicity Tensor Network.
 */
export function mapWitnessToTensorNetwork(witness: any): TensorNetworkState {
    // Helper to convert hexadecimal hashes into structural tensor amplitudes (0.0 to 1.0)
    const parseHashAmplitude = (hash: string) => {
        let sum = 0;
        if (!hash) return 0;
        for (let i = 0; i < hash.length; i++) {
            sum += hash.charCodeAt(i);
        }
        return sum / (hash.length * 255);
    };

    return {
        riskLevel: witness.compilation_result.risk_level,
        spectralRadius: witness.compilation_result.spectral_radius,
        isStable: witness.compilation_result.is_stable,
        primeHilbertSpace: [
            { 
                prime: 2, 
                amplitude: parseHashAmplitude(witness.w0_exec_hash), 
                phase: witness.w0_exec_hash || "NULL_PHASE"
            },
            { 
                prime: 3, 
                amplitude: parseHashAmplitude(witness.w1_axiom_hash), 
                phase: witness.w1_axiom_hash || "NULL_PHASE"
            },
            { 
                prime: 5, 
                amplitude: parseHashAmplitude(witness.w2_phys_hash), 
                phase: witness.w2_phys_hash || "NULL_PHASE"
            },
            { 
                prime: 7, 
                amplitude: parseHashAmplitude(witness.signature), 
                phase: witness.signature || "NULL_PHASE"
            }
        ]
    };
}

/**
 * Convenience method to execute risk evaluation and immediately map into the Hilbert tensor space.
 */
export async function evaluateAndMapTensor(inputs: EsiInputs, pFactor: number = 3, sigma: number = 2.0): Promise<TensorNetworkState> {
    const witness = await evaluateEsiRisk(inputs, pFactor, sigma);
    return mapWitnessToTensorNetwork(witness);
}
