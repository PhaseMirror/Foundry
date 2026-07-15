import init, { process_collatz_chunk_wasm } from '../../../pkg/legalese_scopist';

let wasmInitialized = false;

self.onmessage = async (event: MessageEvent) => {
    const { type, startStr, chunkSize } = event.data;

    if (type !== 'DISPATCH_CHUNK') return;

    try {
        // Ensure WASM memory is booted (only runs once)
        if (!wasmInitialized) {
            await init();
            wasmInitialized = true;
        }

        // Execute the pure mathematical bounds check.
        // Rust takes the CPU to 100% here, but the main UI thread remains untouched.
        const resultsAsStrings = process_collatz_chunk_wasm(startStr, chunkSize);

        // Pass the stringified array back to the React environment
        self.postMessage({ 
            type: 'CHUNK_COMPLETE', 
            payload: resultsAsStrings 
        });

    } catch (error) {
        // Catch any SIG_GOV_KILL or panic states bubbled up from Rust
        self.postMessage({ 
            type: 'ENGINE_HALT', 
            error: String(error) 
        });
    }
};
