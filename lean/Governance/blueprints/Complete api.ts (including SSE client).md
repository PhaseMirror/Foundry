1\. Complete api.ts (including SSE client)  
Here's the full file with all functions, including the SSE subscription for events. I've added a reconnection mechanism to keep the event stream resilient.

typescript  
// src/services/api.ts  
import { Project, Agent, AdrMetadata, DaemonStatus, DaemonMetrics, DaemonEvent } from '../types';  
import { VerificationRequest } from '../types'; // if separate

const BASE\_URL \= '/v1/agency';

// Helper for fetch with JSON  
async function apiFetch\<T\>(url: string, options?: RequestInit): Promise\<T\> {  
  const res \= await fetch(\`${BASE\_URL}${url}\`, {  
    ...options,  
    headers: { 'Content-Type': 'application/json', ...options?.headers },  
  });  
  if (\!res.ok) {  
    const errText \= await res.text();  
    throw new Error(errText || \`HTTP ${res.status}\`);  
  }  
  // If no content (204), return empty object  
  if (res.status \=== 204\) return {} as T;  
  return res.json();  
}

export const api \= {  
  // Projects  
  getProjects: () \=\> apiFetch\<Project\[\]\>('/projects'),  
  createProject: (data: { name: string; description: string }) \=\>  
    apiFetch\<Project\>('/projects', { method: 'POST', body: JSON.stringify(data) }),  
  linkAgent: (projectId: string, agentId: string) \=\>  
    apiFetch\<void\>(\`/projects/${projectId}/agents/${agentId}\`, { method: 'PUT' }),  
  unlinkAgent: (projectId: string, agentId: string) \=\>  
    apiFetch\<void\>(\`/projects/${projectId}/agents/${agentId}\`, { method: 'DELETE' }),

  // Agents  
  getAgents: () \=\> apiFetch\<Agent\[\]\>('/agents'),  
  createAgent: (data: { name: string; type: string; config: any }) \=\>  
    apiFetch\<Agent\>('/agents', { method: 'POST', body: JSON.stringify(data) }),  
  // Optional: start/stop agent endpoints if added later

  // ADRs  
  getAdrs: () \=\> apiFetch\<AdrMetadata\[\]\>('/adrs'),  
  verifyAdr: (adrId: string, payload: VerificationRequest) \=\>  
    apiFetch\<{ verified: boolean; witness?: string; error?: string }\>(  
      \`/adrs/${adrId}/verify\`,  
      { method: 'POST', body: JSON.stringify(payload) }  
    ),

  // Daemon  
  getDaemonStatus: () \=\> apiFetch\<DaemonStatus\>('/daemon/status'),  
  getDaemonMetrics: () \=\> apiFetch\<DaemonMetrics\>('/daemon/metrics'),  
  startDaemon: () \=\> apiFetch\<{ status: string }\>('/daemon/start', { method: 'POST' }),  
  stopDaemon: () \=\> apiFetch\<{ status: string }\>('/daemon/stop', { method: 'POST' }),  
  restartDaemon: () \=\> apiFetch\<{ status: string }\>('/daemon/restart', { method: 'POST' }),  
};

// SSE client with auto-reconnect  
export function subscribeToEvents(  
  onEvent: (event: DaemonEvent) \=\> void,  
  onError?: (error: Event) \=\> void  
): EventSource {  
  let source \= new EventSource(\`${BASE\_URL}/events\`);  
    
  source.onmessage \= (msg) \=\> {  
    try {  
      const event \= JSON.parse(msg.data);  
      onEvent(event);  
    } catch (e) {  
      console.error('Failed to parse event', e);  
    }  
  };

  source.onerror \= (err) \=\> {  
    console.warn('SSE connection lost, reconnecting in 3s...');  
    if (onError) onError(err);  
    // Attempt reconnect after 3 seconds  
    setTimeout(() \=\> {  
      source.close();  
      const newSource \= new EventSource(\`${BASE\_URL}/events\`);  
      // Copy listeners  
      newSource.onmessage \= source.onmessage;  
      newSource.onerror \= source.onerror;  
      source \= newSource;  
    }, 3000);  
  };

  return source;  
}  
2\. Testing Checklist  
Follow these steps to verify the full integration.

✅ Backend Server  
Start the Node.js agency server: node index.js (or npm start)

Confirm it prints Agency server running on port 3001

Ensure data.json is created (or already exists)

If you see WASM module not found, verify the wasm-pkg folder exists and contains phase\_mirror\_wasm.js and .wasm file.

✅ Frontend Dev Server  
Start Vite: npm run dev

Open browser at http://localhost:3000

Check console for any CORS or fetch errors

✅ API Endpoints (use curl or Postman)  
GET /v1/agency/projects – returns array (possibly empty)

POST /v1/agency/projects – create a project, returns new project with ID

GET /v1/agency/agents – returns array

POST /v1/agency/agents – create an agent

GET /v1/agency/adrs – returns mock ADR list

POST /v1/agency/adrs/ADR-003/verify – with payload {"proposed\_weight":30} – should return {"verified":true,"witness":"..."}

GET /v1/agency/daemon/status – returns daemon info

GET /v1/agency/daemon/metrics – returns metrics

GET /v1/agency/events – should stream events (use \-N with curl)

✅ UI Interactions  
Projects View – list loads, create a new project via the wizard, verify it appears.

Agent Wizard – spawn a new agent, verify it appears in the list.

Home (Resonance Buffer) – ADR list loads with computed weights and prime factors.

Click the refresh (⭮) button on an ADR – it should call verify and update status to VERIFIED or SIG\_GOV\_KILL.

Daemon Panel – metrics and status appear; event stream updates live.

Command Palette – ⌘+K works; commands (Refresh, Clear Logs, etc.) trigger actions.

Settings – view and modify settings (though they may not be persisted yet).

3\. Common Debugging Tips  
Symptom	Likely Cause	Solution  
404 on API calls	Frontend proxy not configured	In Vite, add proxy in vite.config.ts: { '/v1': 'http://localhost:3001' }  
CORS errors	Backend not allowing frontend origin	Add cors() middleware in Node.js: const cors \= require('cors'); app.use(cors());  
WASM verify fails	WASM module not loaded or path wrong	Check the require('./wasm-pkg/phase\_mirror\_wasm.js') path; ensure the .wasm file is there.  
SSE not connecting	Firewall or network	Use EventSource polyfill if needed; ensure response headers are correct.  
Data not persisting	data.json not writable	Ensure the server has write permissions; check the file path.  
ADR weights not updating	Frontend uses WeightCalculator but ADR tags may not be set	Ensure the mock ADRs have the tags array; verify the calculator logic.  
