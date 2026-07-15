Testing the End-to-End Integration  
Let's get the servers running and verify that the UI talks to the real backend.

1\. Start the Servers  
Backend Agency Server (Node.js)  
bash  
cd /path/to/agency-server  
npm start   \# or node index.js  
Ensure it's running on port 3001 (or the configured port). Look for:

text  
Agency server running on port 3001  
Frontend Vite Dev Server  
bash  
cd /path/to/admin  
npm run dev  
It should start on port 3000 (or 5173). Open http://localhost:3000 in your browser.

2\. Test the API Endpoints Directly (curl/Postman)  
Before checking the UI, verify the backend endpoints respond correctly.

Projects  
bash  
\# List projects  
curl http://localhost:3001/v1/agency/projects

\# Create a project  
curl \-X POST http://localhost:3001/v1/agency/projects \\  
  \-H "Content-Type: application/json" \\  
  \-d '{"name":"Test Project","description":"A test project"}'  
Agents  
bash  
\# List agents  
curl http://localhost:3001/v1/agency/agents

\# Create an agent  
curl \-X POST http://localhost:3001/v1/agency/agents \\  
  \-H "Content-Type: application/json" \\  
  \-d '{"name":"Test Agent","type":"phase\_mirror","config":{"temperature":0.0}}'  
ADRs  
bash  
\# List ADRs  
curl http://localhost:3001/v1/agency/adrs

\# Verify an ADR (needs ADR ID and weight in body)  
curl \-X POST http://localhost:3001/v1/agency/adrs/ADR-003/verify \\  
  \-H "Content-Type: application/json" \\  
  \-d '{"proposed\_weight":30,"schema\_hash":"SCHEMA\_PWEH\_V1","permission\_bits":1}'  
Daemon  
bash  
curl http://localhost:3001/v1/agency/daemon/status  
curl http://localhost:3001/v1/agency/daemon/metrics  
SSE Events  
bash  
curl \-N http://localhost:3001/v1/agency/events  
You should see a stream of events (initial events and new ones as they happen).

3\. Test the Frontend UI  
Navigate to the Projects view (activity icon 📂). You should see a list of projects from the backend.

Click \+ Project to create a new project – it should appear after submission.

Navigate to the Home view (Resonance Buffer). The ADR list should load.

Click the refresh icon on an ADR row. It should call the /verify endpoint and update the status.

Open the Daemon panel. It should display metrics and a live event stream.

Open the GIK REPL and submit a prompt – it should still be mock, but we can later wire it to the real WASM.

4\. Common Pitfalls & Troubleshooting  
Issue	Possible Cause	Solution  
Frontend can't reach backend	CORS not configured	Add cors middleware in Node.js: app.use(require('cors')());  
WASM module not found	Path to phase\_mirror\_wasm.js incorrect	Ensure wasm-pkg is in the agency-server directory and the require path matches.  
Verification always fails	Permission bits or schema hash mismatch	Check the environment variables EXPECTED\_SCHEMA\_HASH and REQUIRED\_PERMISSION\_BITS.  
SSE events not appearing	Event source not set up correctly	In the browser console, check for errors; ensure the endpoint returns text/event-stream.  
Data not persisting	data.json not writable	Check file permissions; the server will create it if missing.  
5\. Required Frontend Hook Updates  
I haven't yet provided the complete updated hooks for useAgents, useAdrs, and useDaemon. Here they are:

useAgents.ts  
typescript  
import { useEffect, useState, useCallback } from 'react';  
import { api } from '../services/api';  
import { Agent, AgentType } from '../types/projectAgent';

export function useAgents() {  
  const \[agents, setAgents\] \= useState\<Agent\[\]\>(\[\]);  
  const \[loading, setLoading\] \= useState(true);

  const loadAgents \= useCallback(async () \=\> {  
    setLoading(true);  
    try {  
      const data \= await api.getAgents();  
      setAgents(data);  
    } finally {  
      setLoading(false);  
    }  
  }, \[\]);

  useEffect(() \=\> {  
    loadAgents();  
  }, \[loadAgents\]);

  const createAgent \= useCallback(async (name: string, type: AgentType, config: any) \=\> {  
    const agent \= await api.createAgent({ name, type, config });  
    setAgents(prev \=\> \[...prev, agent\]);  
    return agent;  
  }, \[\]);

  const startAgent \= useCallback(async (id: string) \=\> {  
    // In a real implementation, you'd have a POST /agents/:id/start endpoint  
    // For now, we'll mock the status change locally.  
    setAgents(prev \=\> prev.map(a \=\> a.id \=== id ? { ...a, status: 'running' } : a));  
  }, \[\]);

  const stopAgent \= useCallback(async (id: string) \=\> {  
    setAgents(prev \=\> prev.map(a \=\> a.id \=== id ? { ...a, status: 'stopped' } : a));  
  }, \[\]);

  return { agents, loading, createAgent, startAgent, stopAgent, refresh: loadAgents };  
}  
useAdrs.ts  
typescript  
import { useEffect, useState, useCallback } from 'react';  
import { api } from '../services/api';  
import { AdrMetadata } from '../types';  
import { WeightCalculator } from '../services/WeightCalculator';

export function useAdrs() {  
  const \[adrs, setAdrs\] \= useState\<AdrMetadata\[\]\>(\[\]);  
  const \[loading, setLoading\] \= useState(true);

  const loadAdrs \= useCallback(async () \=\> {  
    setLoading(true);  
    try {  
      const data \= await api.getAdrs();  
      // Enrich with computed weights (or the backend could do this)  
      const enriched \= data.map(adr \=\> {  
        const metadata \= WeightCalculator.fromAdrObject(adr);  
        const weight \= WeightCalculator.computeWeight(metadata);  
        const factors \= WeightCalculator.getPrimeFactors(weight);  
        return {  
          ...adr,  
          weight,  
          factors,  
          p3: weight % 3 \=== 0,  
          p5: weight % 5 \=== 0,  
        };  
      });  
      setAdrs(enriched);  
    } finally {  
      setLoading(false);  
    }  
  }, \[\]);

  useEffect(() \=\> {  
    loadAdrs();  
  }, \[loadAdrs\]);

  const verifyAdr \= useCallback(async (adr: AdrMetadata) \=\> {  
    if (\!adr.weight) throw new Error('No weight computed');  
    const response \= await api.verifyAdr(adr.id, {  
      session\_id: adr.id,  
      proposed\_weight: adr.weight,  
      schema\_hash: 'SCHEMA\_PWEH\_V1',  
      permission\_bits: 0x00000001,  
    });  
    // Update the local ADR status  
    setAdrs(prev \=\>  
      prev.map(a \=\>  
        a.id \=== adr.id  
          ? {  
              ...a,  
              status: response.verified ? 'VERIFIED' : 'SIG\_GOV\_KILL',  
              witness: response.witness,  
            }  
          : a  
      )  
    );  
    return response;  
  }, \[\]);

  return { adrs, loading, verifyAdr, refresh: loadAdrs };  
}  
useDaemon.ts  
typescript  
import { useEffect, useState, useCallback } from 'react';  
import { api } from '../services/api';  
import { DaemonStatus, DaemonMetrics, DaemonEvent } from '../types/daemon';  
import { subscribeToEvents } from '../services/api';

export function useDaemon() {  
  const \[status, setStatus\] \= useState\<DaemonStatus | null\>(null);  
  const \[metrics, setMetrics\] \= useState\<DaemonMetrics | null\>(null);  
  const \[events, setEvents\] \= useState\<DaemonEvent\[\]\>(\[\]);  
  const \[loading, setLoading\] \= useState(true);

  const fetchStatus \= useCallback(async () \=\> {  
    try {  
      const data \= await api.getDaemonStatus();  
      setStatus(data);  
    } catch (e) { /\* ignore \*/ }  
  }, \[\]);

  const fetchMetrics \= useCallback(async () \=\> {  
    try {  
      const data \= await api.getDaemonMetrics();  
      setMetrics(data);  
    } catch (e) { /\* ignore \*/ }  
  }, \[\]);

  useEffect(() \=\> {  
    fetchStatus();  
    fetchMetrics();  
    setLoading(false);  
  }, \[fetchStatus, fetchMetrics\]);

  // SSE events  
  useEffect(() \=\> {  
    const source \= subscribeToEvents((event) \=\> {  
      setEvents(prev \=\> \[event, ...prev\].slice(0, 50));  
    });  
    return () \=\> source.close();  
  }, \[\]);

  const startDaemon \= useCallback(async () \=\> {  
    await api.startDaemon();  
    await fetchStatus();  
  }, \[fetchStatus\]);

  const stopDaemon \= useCallback(async () \=\> {  
    await api.stopDaemon();  
    await fetchStatus();  
  }, \[fetchStatus\]);

  const restartDaemon \= useCallback(async () \=\> {  
    await api.restartDaemon();  
    await fetchStatus();  
  }, \[fetchStatus\]);

  return { status, metrics, events, loading, startDaemon, stopDaemon, restartDaemon };  
}  
6\. After Testing  
Once all endpoints are verified and the UI shows live data, we can proceed to:

Add authentication – secure the endpoints.

Enhance GIK REPL – call the WASM engine for real reasoning.