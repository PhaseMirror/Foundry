/* tslint:disable */
/* eslint-disable */

/**
 * WASM SDK Entry Point
 * This is the strictly enforced boundary for the Path of Integrity.
 */
export function evaluate_esi_risk_wasm(inputs_val: any, p_factor: number, sigma: number): any;

/**
 * WASM SDK Entry Point for ACE-bound risk evaluation
 */
export function evaluate_esi_risk_with_ace_wasm(inputs_val: any, p_factor: number, sigma: number, budget_val: any): any;

export function process_collatz_chunk_wasm(start_str: string, chunk_size: number): any;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    readonly check_density_matrix_invariant: (a: number, b: number, c: number) => number;
    readonly check_rg_condition: (a: number, b: number, c: number) => number;
    readonly compute_density_matrix_eigenvalues: (a: number, b: number, c: number, d: number) => number;
    readonly compute_entropy: (a: number) => number;
    readonly compute_spectral_radius: (a: number) => number;
    readonly evaluate_esi_risk_wasm: (a: any, b: number, c: number) => [number, number, number];
    readonly evaluate_esi_risk_with_ace_wasm: (a: any, b: number, c: number, d: any) => [number, number, number];
    readonly get_dimension_rs: (a: number) => number;
    readonly process_collatz_chunk_wasm: (a: number, b: number, c: number) => [number, number, number];
    readonly __wbindgen_malloc: (a: number, b: number) => number;
    readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
    readonly __wbindgen_exn_store: (a: number) => void;
    readonly __externref_table_alloc: () => number;
    readonly __wbindgen_externrefs: WebAssembly.Table;
    readonly __externref_table_dealloc: (a: number) => void;
    readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
 * Instantiates the given `module`, which can either be bytes or
 * a precompiled `WebAssembly.Module`.
 *
 * @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
 *
 * @returns {InitOutput}
 */
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
 * If `module_or_path` is {RequestInfo} or {URL}, makes a request and
 * for everything else, calls `WebAssembly.instantiate` directly.
 *
 * @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
 *
 * @returns {Promise<InitOutput>}
 */
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
