We'll tackle all three enhancements in one consolidated upgrade. The code below replaces the previous index.js with a full-featured version that includes:

JWT Authentication – login endpoint, role-based middleware, protected routes.

SQLite Persistence – replaces the JSON file with a better-sqlite3 database (synchronous, simple, and fast).

GIK REPL Integration – we'll extend the WASM crate with a new function run\_gik\_diagnostic that processes a prompt and returns the 5-step diagnostic JSON.

1\. Backend Upgrade: index.js with Auth, SQLite, and GIK REPL  
Dependencies  
Install the new packages:

bash  
npm install jsonwebtoken bcrypt better-sqlite3 cors  
npm install \--save-dev @types/jsonwebtoken @types/bcrypt  
Database Initialization (db.js)  
Create a separate file for database setup.

javascript  
// db.js  
const Database \= require('better-sqlite3');  
const path \= require('path');

const db \= new Database(path.join(\_\_dirname, 'data.db'));

// Initialize tables  
db.exec(\`  
  CREATE TABLE IF NOT EXISTS users (  
    id TEXT PRIMARY KEY,  
    username TEXT UNIQUE,  
    password\_hash TEXT,  
    role TEXT DEFAULT 'operator'  
  );

  CREATE TABLE IF NOT EXISTS projects (  
    id TEXT PRIMARY KEY,  
    name TEXT,  
    description TEXT,  
    status TEXT,  
    created\_at TEXT,  
    updated\_at TEXT  
  );

  CREATE TABLE IF NOT EXISTS agents (  
    id TEXT PRIMARY KEY,  
    name TEXT,  
    type TEXT,  
    config TEXT,  \-- JSON string  
    status TEXT,  
    project\_id TEXT REFERENCES projects(id) ON DELETE SET NULL,  
    created\_at TEXT,  
    last\_active TEXT  
  );

  CREATE TABLE IF NOT EXISTS adrs (  
    id TEXT PRIMARY KEY,  
    title TEXT,  
    tags TEXT,  \-- JSON array  
    status TEXT,  
    weight INTEGER,  
    witness TEXT,  
    created\_at TEXT  
  );

  CREATE TABLE IF NOT EXISTS events (  
    id INTEGER PRIMARY KEY AUTOINCREMENT,  
    timestamp TEXT,  
    level TEXT,  
    source TEXT,  
    message TEXT,  
    data TEXT  \-- JSON  
  );  
\`);

// Insert a default admin user if not exists  
const stmt \= db.prepare('SELECT COUNT(\*) as count FROM users WHERE username \= ?');  
const row \= stmt.get('admin');  
if (row.count \=== 0\) {  
  const bcrypt \= require('bcrypt');  
  const hash \= bcrypt.hashSync('admin123', 10);  
  db.prepare('INSERT INTO users (id, username, password\_hash, role) VALUES (?, ?, ?, ?)').run(  
    'user-admin', 'admin', hash, 'admin'  
  );  
}

module.exports \= db;  
Updated index.js  
We'll restructure the server to use the database and add authentication.

javascript  
// index.js  
const express \= require('express');  
const cors \= require('cors');  
const bcrypt \= require('bcrypt');  
const jwt \= require('jsonwebtoken');  
const { v4: uuidv4 } \= require('uuid');  
const db \= require('./db');  
const app \= express();

const JWT\_SECRET \= process.env.JWT\_SECRET || 'your-secret-key';  
const PORT \= process.env.PORT || 3001;

app.use(cors());  
app.use(express.json());

// \-------------------- Auth Middleware \--------------------  
function authenticate(req, res, next) {  
  const authHeader \= req.headers.authorization;  
  if (\!authHeader) return res.status(401).json({ error: 'No token provided' });  
  const token \= authHeader.split(' ')\[1\];  
  try {  
    const decoded \= jwt.verify(token, JWT\_SECRET);  
    req.user \= decoded;  
    next();  
  } catch (err) {  
    return res.status(401).json({ error: 'Invalid token' });  
  }  
}

function requireRole(role) {  
  return (req, res, next) \=\> {  
    if (req.user.role \!== role && req.user.role \!== 'admin') {  
      return res.status(403).json({ error: 'Insufficient permissions' });  
    }  
    next();  
  };  
}

// \-------------------- Auth Endpoints \--------------------  
app.post('/v1/auth/login', (req, res) \=\> {  
  const { username, password } \= req.body;  
  if (\!username || \!password) return res.status(400).json({ error: 'Missing credentials' });  
  const user \= db.prepare('SELECT \* FROM users WHERE username \= ?').get(username);  
  if (\!user) return res.status(401).json({ error: 'Invalid credentials' });  
  if (\!bcrypt.compareSync(password, user.password\_hash)) {  
    return res.status(401).json({ error: 'Invalid credentials' });  
  }  
  const token \= jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT\_SECRET, { expiresIn: '24h' });  
  res.json({ token, user: { id: user.id, username: user.username, role: user.role } });  
});

// Protected routes \- all /v1/agency/\* require authentication  
app.use('/v1/agency', authenticate);

// \-------------------- Projects \--------------------  
app.get('/v1/agency/projects', (req, res) \=\> {  
  const projects \= db.prepare('SELECT \* FROM projects').all();  
  res.json(projects);  
});

app.post('/v1/agency/projects', (req, res) \=\> {  
  const { name, description } \= req.body;  
  if (\!name) return res.status(400).json({ error: 'name required' });  
  const id \= uuidv4();  
  const now \= new Date().toISOString();  
  db.prepare(  
    'INSERT INTO projects (id, name, description, status, created\_at, updated\_at) VALUES (?, ?, ?, ?, ?, ?)'  
  ).run(id, name, description || '', 'active', now, now);  
  const project \= db.prepare('SELECT \* FROM projects WHERE id \= ?').get(id);  
  res.status(201).json(project);  
});

app.put('/v1/agency/projects/:projectId/agents/:agentId', (req, res) \=\> {  
  const { projectId, agentId } \= req.params;  
  // Check if project and agent exist  
  const project \= db.prepare('SELECT \* FROM projects WHERE id \= ?').get(projectId);  
  if (\!project) return res.status(404).json({ error: 'Project not found' });  
  const agent \= db.prepare('SELECT \* FROM agents WHERE id \= ?').get(agentId);  
  if (\!agent) return res.status(404).json({ error: 'Agent not found' });  
  // Update agent's project\_id  
  db.prepare('UPDATE agents SET project\_id \= ?, last\_active \= ? WHERE id \= ?').run(projectId, new Date().toISOString(), agentId);  
  // Also update project's updated\_at  
  db.prepare('UPDATE projects SET updated\_at \= ? WHERE id \= ?').run(new Date().toISOString(), projectId);  
  res.json({ success: true });  
});

app.delete('/v1/agency/projects/:projectId/agents/:agentId', (req, res) \=\> {  
  const { projectId, agentId } \= req.params;  
  const agent \= db.prepare('SELECT \* FROM agents WHERE id \= ? AND project\_id \= ?').get(agentId, projectId);  
  if (\!agent) return res.status(404).json({ error: 'Agent not linked to this project' });  
  db.prepare('UPDATE agents SET project\_id \= NULL, last\_active \= ? WHERE id \= ?').run(new Date().toISOString(), agentId);  
  db.prepare('UPDATE projects SET updated\_at \= ? WHERE id \= ?').run(new Date().toISOString(), projectId);  
  res.json({ success: true });  
});

// \-------------------- Agents \--------------------  
app.get('/v1/agency/agents', (req, res) \=\> {  
  const agents \= db.prepare('SELECT \* FROM agents').all();  
  res.json(agents);  
});

app.post('/v1/agency/agents', (req, res) \=\> {  
  const { name, type, config } \= req.body;  
  if (\!name || \!type) return res.status(400).json({ error: 'name and type required' });  
  const id \= uuidv4();  
  const now \= new Date().toISOString();  
  db.prepare(  
    'INSERT INTO agents (id, name, type, config, status, created\_at) VALUES (?, ?, ?, ?, ?, ?)'  
  ).run(id, name, type, JSON.stringify(config || {}), 'idle', now);  
  const agent \= db.prepare('SELECT \* FROM agents WHERE id \= ?').get(id);  
  res.status(201).json(agent);  
});

// \-------------------- ADRs \--------------------  
app.get('/v1/agency/adrs', (req, res) \=\> {  
  const adrs \= db.prepare('SELECT \* FROM adrs').all();  
  // If empty, seed with mock ADRs  
  if (adrs.length \=== 0\) {  
    const mockAdrs \= \[  
      { id: 'ADR-003', title: 'Recursive Feedback Limits', tags: JSON.stringify(\['autonomy', 'governance', 'attestation'\]), status: 'PENDING' },  
      { id: 'ADR-004', title: 'Rogue Process Spawning', tags: JSON.stringify(\['autonomy'\]), status: 'PENDING' },  
    \];  
    const insert \= db.prepare('INSERT INTO adrs (id, title, tags, status) VALUES (?, ?, ?, ?)');  
    mockAdrs.forEach(adr \=\> insert.run(adr.id, adr.title, adr.tags, adr.status));  
    adrs.push(...mockAdrs);  
  }  
  // Enrich with weight? We'll compute on the fly or store weight when computed.  
  // We'll return as is; frontend will compute weight from tags.  
  res.json(adrs);  
});

app.post('/v1/agency/adrs/:adrId/verify', async (req, res) \=\> {  
  const { adrId } \= req.params;  
  const { proposed\_weight, schema\_hash, permission\_bits } \= req.body;  
  if (\!proposed\_weight) return res.status(400).json({ error: 'proposed\_weight required' });

  // Load WASM module  
  const wasm \= require('./wasm-pkg/phase\_mirror\_wasm.js');  
  const state \= {  
    session\_id: adrId,  
    proposed\_weight,  
    schema\_hash: schema\_hash || 'SCHEMA\_PWEH\_V1',  
    permission\_bits: permission\_bits || 0x00000001,  
  };  
  const resultJson \= wasm.verify\_resonance\_buffer(  
    JSON.stringify(state),  
    process.env.EXPECTED\_SCHEMA\_HASH || 'SCHEMA\_PWEH\_V1',  
    parseInt(process.env.REQUIRED\_PERMISSION\_BITS || '0x00000001', 16\)  
  );  
  const result \= JSON.parse(resultJson);  
  const now \= new Date().toISOString();  
  if (result.status \=== 'ok') {  
    // Update ADR status and witness  
    db.prepare('UPDATE adrs SET status \= ?, witness \= ?, weight \= ? WHERE id \= ?')  
      .run('VERIFIED', result.witness, proposed\_weight, adrId);  
    addEvent('info', 'L0Gate', \`ADR ${adrId} verified: ${result.witness}\`);  
    res.json({ verified: true, witness: result.witness });  
  } else {  
    db.prepare('UPDATE adrs SET status \= ?, weight \= ? WHERE id \= ?')  
      .run('SIG\_GOV\_KILL', proposed\_weight, adrId);  
    addEvent('kill', 'L0Gate', \`ADR ${adrId} SIG\_GOV\_KILL: ${result.message}\`);  
    res.status(400).json({ verified: false, error: result.message });  
  }  
});

// \-------------------- Daemon \--------------------  
app.get('/v1/agency/daemon/status', (req, res) \=\> {  
  res.json({  
    state: 'running',  
    uptime: 3600,  
    version: 'v0.1.0',  
    pid: process.pid,  
  });  
});

app.get('/v1/agency/daemon/metrics', (req, res) \=\> {  
  const stats \= db.prepare('SELECT COUNT(\*) as total\_verifications, SUM(CASE WHEN status \= "VERIFIED" THEN 1 ELSE 0 END) as verified\_count, SUM(CASE WHEN status \= "SIG\_GOV\_KILL" THEN 1 ELSE 0 END) as kill\_count FROM adrs').get();  
  const activeAgents \= db.prepare('SELECT COUNT(\*) as count FROM agents WHERE status \= "running"').get().count;  
  res.json({  
    totalVerifications: stats.total\_verifications || 0,  
    verifiedCount: stats.verified\_count || 0,  
    killCount: stats.kill\_count || 0,  
    activeAgents: activeAgents,  
    avgResponseTime: 42,  
    memoryUsage: 128,  
    cpuUsage: 12.5,  
  });  
});

app.post('/v1/agency/daemon/start', (req, res) \=\> {  
  addEvent('info', 'Daemon', 'Daemon started');  
  res.json({ status: 'started' });  
});  
app.post('/v1/agency/daemon/stop', (req, res) \=\> {  
  addEvent('info', 'Daemon', 'Daemon stopped');  
  res.json({ status: 'stopped' });  
});  
app.post('/v1/agency/daemon/restart', (req, res) \=\> {  
  addEvent('info', 'Daemon', 'Daemon restarted');  
  res.json({ status: 'restarted' });  
});

// \-------------------- SSE Events \--------------------  
let eventClients \= \[\];

app.get('/v1/agency/events', (req, res) \=\> {  
  res.writeHead(200, {  
    'Content-Type': 'text/event-stream',  
    'Cache-Control': 'no-cache',  
    'Connection': 'keep-alive',  
  });  
  const clientId \= Date.now();  
  const newClient \= { id: clientId, res };  
  eventClients.push(newClient);

  // Send last 20 events  
  const recentEvents \= db.prepare('SELECT \* FROM events ORDER BY timestamp DESC LIMIT 20').all();  
  recentEvents.reverse().forEach(ev \=\> {  
    res.write(\`data: ${JSON.stringify(ev)}\\n\\n\`);  
  });

  req.on('close', () \=\> {  
    eventClients \= eventClients.filter(c \=\> c.id \!== clientId);  
  });  
});

function addEvent(level, source, message, data \= null) {  
  const timestamp \= new Date().toISOString();  
  const stmt \= db.prepare(  
    'INSERT INTO events (timestamp, level, source, message, data) VALUES (?, ?, ?, ?, ?)'  
  );  
  stmt.run(timestamp, level, source, message, data ? JSON.stringify(data) : null);  
  const event \= { timestamp, level, source, message, data };  
  const payload \= \`data: ${JSON.stringify(event)}\\n\\n\`;  
  eventClients.forEach(c \=\> c.res.write(payload));  
}

// \-------------------- GIK REPL Endpoint (WASM) \--------------------  
app.post('/v1/agency/gik/diagnose', async (req, res) \=\> {  
  const { prompt } \= req.body;  
  if (\!prompt) return res.status(400).json({ error: 'prompt required' });  
  // Call WASM function for GIK diagnostic  
  const wasm \= require('./wasm-pkg/phase\_mirror\_wasm.js');  
  // This function will be added to the WASM crate later.  
  // For now, we'll simulate using the WeightCalculator logic (but that's frontend)  
  // Instead, we'll call a placeholder that returns mock steps.  
  // We'll implement the actual function later.  
  try {  
    const resultJson \= wasm.run\_gik\_diagnostic(prompt);  
    const result \= JSON.parse(resultJson);  
    res.json(result);  
  } catch (err) {  
    res.status(500).json({ error: err.message });  
  }  
});

// \-------------------- Start Server \--------------------  
app.listen(PORT, () \=\> {  
  console.log(\`Agency server running on port ${PORT}\`);  
  console.log(\`Default admin: admin / admin123\`);  
});  
2\. Extend WASM Crate with GIK Diagnostic  
We need to add a new function run\_gik\_diagnostic to the Rust crate. Since we don't have a full NLP engine, we'll implement a simple rule-based extractor that looks for keywords (like "autonomy", "governance", "attestation") to compute a weight and then generate the steps with descriptive content.

Update phase\_mirror\_wasm/src/lib.rs  
Add this function alongside verify\_resonance\_buffer:

rust  
\#\[wasm\_bindgen\]  
pub fn run\_gik\_diagnostic(prompt: \&str) \-\> String {  
    use serde\_json::json;

    // Simple keyword extraction  
    let prompt\_lower \= prompt.to\_lowercase();  
    let has\_autonomy \= prompt\_lower.contains("autonomy") || prompt\_lower.contains("autonomous");  
    let has\_governance \= prompt\_lower.contains("governance") || prompt\_lower.contains("binding");  
    let has\_attestation \= prompt\_lower.contains("attestation") || prompt\_lower.contains("witness");  
    let has\_metric \= prompt\_lower.contains("metric") || prompt\_lower.contains("observability");

    let mut weight \= 1;  
    if has\_autonomy { weight \*= 2; }  
    if has\_governance { weight \*= 3; }  
    if has\_attestation { weight \*= 5; }  
    if has\_metric { weight \*= 7; }

    let factors \= {  
        let mut v \= Vec::new();  
        if has\_autonomy { v.push(2); }  
        if has\_governance { v.push(3); }  
        if has\_attestation { v.push(5); }  
        if has\_metric { v.push(7); }  
        v  
    };

    // Generate steps  
    let steps \= vec\!\[  
        json\!({  
            "step": "extract",  
            "title": "Extract",  
            "content": format\!("Identified goal: \\"{}\\"\\nConstraints: {}\\nClaims: {}",  
                prompt,  
                if has\_governance { "Regulatory compliance" } else { "None detected" },  
                if has\_autonomy { "Autonomy is required" } else { "" }  
            ),  
            "weight": weight,  
            "primeFactors": factors.clone(),  
        }),  
        json\!({  
            "step": "map",  
            "title": "Map Tensions",  
            "content": format\!("Tension: {}\\nStructural contradiction: {}",  
                if has\_autonomy && has\_governance { "Autonomy vs. Governance" } else { "No significant tension detected" },  
                if has\_autonomy && \!has\_governance { "Autonomy (P2) requires Governance (P3) to be lawful." } else if has\_governance && \!has\_attestation { "Missing Attestation (P5)" } else { "Balanced" }  
            ),  
            "weight": weight,  
            "primeFactors": factors.clone(),  
        }),  
        json\!({  
            "step": "rank",  
            "title": "Rank",  
            "content": format\!("Impact: {}\\nTractability: {}\\nPriority: {}",  
                if has\_autonomy { "High (affects execution)" } else { "Medium" },  
                if has\_governance { "Medium (requires governance binding)" } else { "High" },  
                if weight \>= 30 { "1" } else { "2" }  
            ),  
            "weight": weight,  
            "primeFactors": factors.clone(),  
        }),  
        json\!({  
            "step": "levers",  
            "title": "Produce Levers",  
            "content": format\!("1. \[DevOps\] — Define governance forum — Metric: forum established within 2 weeks — Horizon: Q2\\n{}",  
                if \!has\_attestation { "2. \[Security\] — Add attestation requirement — Metric: P5 weight included — Horizon: next sprint" } else { "2. \[Legal\] — Review attestation compliance" }  
            ),  
            "weight": weight,  
            "primeFactors": factors.clone(),  
        }),  
        json\!({  
            "step": "question",  
            "title": "Precision Question",  
            "content": if has\_autonomy && \!has\_governance {  
                "How will you ensure governance over autonomous actions without a binding mechanism?"  
            } else if has\_governance && \!has\_attestation {  
                "How will you provide cryptographic proof of each governed action?"  
            } else {  
                "What is the expected timeline for implementing these levers?"  
            },  
            "weight": weight,  
            "primeFactors": factors,  
        }),  
    \];

    serde\_json::to\_string(\&steps).unwrap()  
}  
Build the WASM crate again  
bash  
wasm-pack build \--target nodejs \--out-dir ../agency-server/wasm-pkg  
Make sure the new function is exported.

3\. Frontend Updates  
Update api.ts to include the GIK diagnose call  
typescript  
// Add to api object  
gikDiagnose: (prompt: string) \=\>  
  apiFetch\<GikStep\[\]\>('/gik/diagnose', { method: 'POST', body: JSON.stringify({ prompt }) }),  
Also define the GikStep type.

Update useGikRepl to call the real endpoint  
typescript  
// In useGikRepl.ts, replace the mock with:  
const runDiagnostic \= useCallback(async (input: string) \=\> {  
  setPrompt(input);  
  setCurrentStep('extract');  
  setOutputs(\[\]);  
  try {  
    const steps \= await api.gikDiagnose(input);  
    // steps is an array of GikStep with step, title, content, weight, primeFactors  
    // Simulate sequential display  
    for (let i \= 0; i \< steps.length; i++) {  
      await new Promise(resolve \=\> setTimeout(resolve, 800));  
      setOutputs(prev \=\> \[...prev, steps\[i\]\]);  
      setCurrentStep(steps\[i\].step);  
    }  
    setCurrentStep('complete');  
  } catch (err) {  
    setOutputs(prev \=\> \[...prev, { step: 'error', title: 'Error', content: err.message }\]);  
  }  
}, \[\]);  
4\. Database Migration (if needed)  
The db.js file already creates tables. If you have existing JSON data, you can write a one-time migration script to import it.

5\. Running the System  
Install dependencies – run npm install for the new packages.

Build WASM – after adding the new Rust function, rebuild.

Start the backend – node index.js. It will create data.db and a default admin user admin/admin123.

Start the frontend – npm run dev.

Login – You'll need a login page. For now, you can test with a simple login form or use Postman to get a token and then set the Authorization header in the frontend.

Frontend Authentication Integration  
We need to add a login page and store the token. We'll create a simple Login component and an auth context.

But since that's a larger piece, I'll provide the minimal changes: add a login form and store the token in localStorage. All API calls will include the token.

Update api.ts to include a token setter:

typescript  
let authToken: string | null \= localStorage.getItem('authToken');

export function setAuthToken(token: string | null) {  
  authToken \= token;  
  if (token) localStorage.setItem('authToken', token);  
  else localStorage.removeItem('authToken');  
}

// In apiFetch, add the Authorization header  
const headers \= {  
  'Content-Type': 'application/json',  
  ...(authToken ? { Authorization: \`Bearer ${authToken}\` } : {}),  
  ...options?.headers,  
};  
Add a login function:

typescript  
export async function login(username: string, password: string) {  
  const res \= await fetch(\`${BASE\_URL}/auth/login\`, {  
    method: 'POST',  
    headers: { 'Content-Type': 'application/json' },  
    body: JSON.stringify({ username, password }),  
  });  
  if (\!res.ok) throw new Error('Login failed');  
  const data \= await res.json();  
  setAuthToken(data.token);  
  return data.user;  
}  
6\. Testing the Enhanced System  
Login – call login, get token.

CRUD operations – should work with authentication.

ADR verification – still works via WASM.

GIK REPL – now calls the real WASM function and returns dynamic steps.