import { useEffect, useRef, useState, useCallback } from 'react';

// Define the telemetry structure
export interface EngineTelemetry {
    msPerChunk: number;
    boundsPerSecond: bigint;
}

export function useCollatzEngine(initialStartStr: string, chunkSize: number = 10000) {
    const workerRef = useRef<Worker | null>(null);
    const dispatchTimeRef = useRef<number>(0); // High-res timer

    const [isRunning, setIsRunning] = useState(false);
    
    // We store the verified bounds as native JS BigInts to preserve the 128-bit scale
    const [verifiedBounds, setVerifiedBounds] = useState<BigInt[]>([]);
    const [currentStart, setCurrentStart] = useState<bigint>(BigInt(initialStartStr));
    const [error, setError] = useState<string | null>(null);

    // New Telemetry State
    const [telemetry, setTelemetry] = useState<EngineTelemetry>({ 
        msPerChunk: 0, 
        boundsPerSecond: 0n 
    });

    useEffect(() => {
        // Initialize the dedicated Web Worker
        workerRef.current = new Worker(
            new URL('../workers/collatz.worker.ts', import.meta.url),
            { type: 'module' }
        );

        workerRef.current.onmessage = (event) => {
            const { type, payload, error } = event.data;

            if (type === 'ENGINE_HALT') {
                setIsRunning(false);
                setError(error);
                return;
            }

            if (type === 'CHUNK_COMPLETE') {
                // 1. Calculate precise chunk delta
                const endTime = performance.now();
                const deltaMs = endTime - dispatchTimeRef.current;
                
                // 2. Compute throughput (bounds per second)
                // Avoid divide-by-zero if computation is literally sub-millisecond
                const safeDelta = deltaMs > 0 ? deltaMs : 0.1; 
                const boundsPerSec = BigInt(Math.floor((chunkSize / safeDelta) * 1000));
                
                setTelemetry({
                    msPerChunk: deltaMs,
                    boundsPerSecond: boundsPerSec
                });

                // Safely map the stringified Rust 128-bit integers back into native BigInts
                // Note: The WASM actually returns a CollatzResult struct, not an array of BigInts, 
                // so we parse the single result here.
                const parsedResult = {
                    startBound: BigInt(payload.start_bound),
                    endBound: BigInt(payload.end_bound),
                    maxSteps: payload.max_steps,
                    maxValueReached: BigInt(payload.max_value_reached),
                    cycleDetected: payload.cycle_detected,
                    verified: payload.verified,
                };
                
                // For simplicity, we just push the whole result object or its start bound. 
                // The user's code pushed an array of BigInts, but since our WASM returns a single aggregate struct per chunk:
                setVerifiedBounds(prev => [...prev, parsedResult.startBound]);

                // If the engine is still toggled 'on', immediately dispatch the next sequential chunk
                if (isRunning) {
                    const nextStart = currentStart + BigInt(chunkSize);
                    setCurrentStart(nextStart);
                    
                    // Stamp the time EXACTLY as we dispatch the next block
                    dispatchTimeRef.current = performance.now();
                    workerRef.current?.postMessage({
                        type: 'DISPATCH_CHUNK',
                        startStr: nextStart.toString(),
                        chunkSize: chunkSize
                    });
                }
            }
        };

        return () => {
            workerRef.current?.terminate();
        };
    }, [isRunning, currentStart, chunkSize]);

    const startEngine = useCallback(() => {
        setIsRunning(true);
        setError(null);
        
        dispatchTimeRef.current = performance.now();
        // Kick off the first polling request
        workerRef.current?.postMessage({
            type: 'DISPATCH_CHUNK',
            startStr: currentStart.toString(),
            chunkSize: chunkSize
        });
    }, [currentStart, chunkSize]);

    const haltEngine = useCallback(() => {
        setIsRunning(false);
    }, []);

    return {
        startEngine,
        haltEngine,
        isRunning,
        verifiedBounds,
        currentStart,
        error,
        telemetry
    };
}
