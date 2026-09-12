import { createHash, createPublicKey } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import http from 'node:http';
import https from 'node:https';
import net from 'node:net';
import { connect as connectAmqp } from 'amqplib';
import {
  createRemoteJWKSet,
  exportJWK,
  generateKeyPair,
  importPKCS8,
  jwtVerify,
  SignJWT
} from 'jose';
import pg from 'pg';
import { historyVisibility, validOidcSubject, validateApplicationProfile } from './profile.mjs';

const { Pool } = pg;
const role = process.argv[2] ?? 'help';
const releaseRoot = process.env.PRISM_RELEASE_ROOT ?? '/opt/prism/release';
const encoder = new TextEncoder();
const decoder = new TextDecoder('utf-8', { fatal: true });
const integerPattern = /^(?:0|-[1-9][0-9]*|[1-9][0-9]*)$/;
const minimumI64 = -9223372036854775808n;
const maximumI64 = 9223372036854775807n;
let contractPromise;

function contract() {
  contractPromise ??= readFile(`${releaseRoot}/runtime-contract.json`, 'utf8').then(JSON.parse).then(validateApplicationProfile);
  return contractPromise;
}

function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value !== null && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function sha(value) {
  return createHash('sha256').update(value).digest('hex');
}

function response(res, status, value, headers = {}) {
  const bytes = Buffer.from(canonical(value));
  res.writeHead(status, {
    'cache-control': 'no-store',
    'content-length': String(bytes.length),
    'content-type': 'application/json',
    ...headers
  });
  res.end(bytes);
}

function errorResponse(res, status, code, headers = {}) {
  response(res, status, { error: { code } }, headers);
}

async function body(req, maximumBodyBytes) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > maximumBodyBytes) {
      const error = new Error('oversized-input');
      error.status = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  try {
    return JSON.parse(decoder.decode(Buffer.concat(chunks)));
  } catch {
    const error = new Error('malformed-json');
    error.status = 400;
    throw error;
  }
}

async function secret(name) {
  const file = process.env[`${name}_FILE`];
  if (!file) throw new Error(`missing secret reference ${name}_FILE`);
  return (await readFile(file, 'utf8')).replace(/\r?\n$/, '');
}

async function tcpReady(host, port) {
  await new Promise((resolve, reject) => {
    const socket = net.connect({ host, port });
    const timer = setTimeout(() => socket.destroy(new Error('probe timeout')), 2000);
    socket.once('connect', () => {
      clearTimeout(timer);
      socket.destroy();
      resolve();
    });
    socket.once('error', reject);
  });
}

async function probe(component) {
  const map = {
    api: [process.env.API_HOST ?? '127.0.0.1', Number(process.env.API_PORT ?? 8443)],
    browser: [process.env.BROWSER_HOST ?? '127.0.0.1', Number(process.env.BROWSER_PORT ?? 443)],
    issuer: [process.env.ISSUER_HOST ?? '127.0.0.1', Number(process.env.ISSUER_PORT ?? 5556)],
    worker: [process.env.DATABASE_HOST ?? 'database', 5432]
  };
  const target = map[component];
  if (!target) throw new Error(`unknown probe component ${component}`);
  await tcpReady(...target);
  if (component === 'worker') {
    await tcpReady(process.env.BROKER_HOST ?? 'broker', Number(process.env.BROKER_PORT ?? 5672));
  }
}

class Core {
  constructor(instance, contract) {
    this.instance = instance;
    this.contract = contract;
  }

  static async load() {
    const profile = await contract();
    const wasm = await readFile(`${releaseRoot}/${profile.core_artifact}`);
    const { instance } = await WebAssembly.instantiate(wasm);
    return new Core(instance, profile);
  }

  execute(operation, inputA, inputB) {
    const request = this.contract.command_encoding
      .replace('{operation}', operation)
      .replace('{inputA}', inputA)
      .replace('{inputB}', inputB);
    const bytes = encoder.encode(request);
    const pointer = this.instance.exports.holo_alloc(bytes.length);
    new Uint8Array(this.instance.exports.memory.buffer, pointer, bytes.length).set(bytes);
    const packed = this.instance.exports.holo_run(pointer, bytes.length);
    const outputLength = Number(packed & 0xffffffffn);
    const outputPointer = Number(packed >> 32n);
    const output = decoder.decode(
      new Uint8Array(this.instance.exports.memory.buffer, outputPointer, outputLength)
    );
    const fields = output.split('\t');
    if (fields[0] !== this.contract.response_version || fields.length !== 3) {
      throw new Error('invalid generated application response');
    }
    if (fields[1] === 'ok' && integerPattern.test(fields[2])) {
      return { kind: 'succeeded', result: fields[2] };
    }
    const mapped = this.contract.application_errors.find((error) => error.wire_name === fields[2])?.model_name;
    if (fields[1] === 'error' && mapped) return { error: mapped, kind: 'rejected' };
    throw new Error('unknown generated application response');
  }
}

function validInteger(value) {
  if (typeof value !== 'string' || !integerPattern.test(value)) return false;
  const integer = BigInt(value);
  return integer >= minimumI64 && integer <= maximumI64;
}

async function postOtlp(endpoint, path, payload) {
  const url = new URL(path, endpoint);
  return new Promise((resolve) => {
    const request = http.request(url, {
      headers: { 'content-type': 'application/json' },
      method: 'POST',
      timeout: 2000
    }, (result) => {
      result.resume();
      result.once('end', () => resolve(result.statusCode >= 200 && result.statusCode < 300));
    });
    request.once('error', () => resolve(false));
    request.once('timeout', () => request.destroy(new Error('telemetry timeout')));
    request.end(canonical(payload));
  });
}

async function telemetry(name, attributes) {
  const endpoint = process.env.OTEL_HTTP_ENDPOINT;
  if (!endpoint) return { logs: false, metrics: false, traces: false };
  const profile = await contract();
  const redacted = new Set(profile.redacted_fields ?? []);
  const safe = {};
  for (const [key, value] of Object.entries(attributes)) {
    if (!redacted.has(key.toLowerCase())) {
      safe[key] = String(value);
    }
  }
  const now = String(BigInt(Date.now()) * 1000000n);
  const correlation = safe[profile.command_id_field] ?? safe.event_id ?? safe.reason ?? name;
  const traceId = sha(`${profile.product_id}\0${name}\0${correlation}`).slice(0, 32);
  const spanId = sha(`${traceId}\0span`).slice(0, 16);
  const resource = {
    attributes: [
      { key: 'service.name', value: { stringValue: `${profile.product_id}-${role}` } },
      { key: 'service.version', value: { stringValue: profile.release } }
    ]
  };
  const otelAttributes = Object.entries(safe).map(([key, value]) => ({
    key,
    value: { stringValue: value }
  }));
  const logs = {
    resourceLogs: [{
      resource,
      scopeLogs: [{ logRecords: [{ attributes: otelAttributes, body: { stringValue: name }, spanId, timeUnixNano: now, traceId }] }]
    }]
  };
  const metrics = {
    resourceMetrics: [{
      resource,
      scopeMetrics: [{ metrics: [{
        name: `${profile.product_id}.${name.replaceAll('-', '_')}`,
        sum: {
          aggregationTemporality: 2,
          dataPoints: [{ asInt: '1', attributes: otelAttributes, timeUnixNano: now }],
          isMonotonic: true
        }
      }] }]
    }]
  };
  const traces = {
    resourceSpans: [{
      resource,
      scopeSpans: [{ spans: [{
        attributes: otelAttributes,
        endTimeUnixNano: now,
        kind: 2,
        name,
        spanId,
        startTimeUnixNano: now,
        status: { code: 1 },
        traceId
      }] }]
    }]
  };
  const [logReceipt, metricReceipt, traceReceipt] = await Promise.all([
    postOtlp(endpoint, '/v1/logs', logs),
    postOtlp(endpoint, '/v1/metrics', metrics),
    postOtlp(endpoint, '/v1/traces', traces)
  ]);
  return { logs: logReceipt, metrics: metricReceipt, traces: traceReceipt };
}

async function database() {
  const profile = await contract();
  const password = encodeURIComponent(await secret('DATABASE_CREDENTIALS'));
  const host = process.env.DATABASE_HOST ?? 'database';
  return new Pool({
    connectionString: `postgresql://${encodeURIComponent(profile.database_user)}:${password}@${host}/${encodeURIComponent(profile.database_name)}`,
    max: 8
  });
}

async function migrate() {
  const pool = await database();
  const sql = await readFile(`${releaseRoot}/history.sql`, 'utf8');
  try {
    await pool.query(sql);
  } finally {
    await pool.end();
  }
}

async function contractMigration() {
  const sql = await readFile(`${releaseRoot}/contract.sql`, 'utf8');
  if (!sql.trim()) throw new Error('contract migration SQL is empty');
  const pool = await database();
  try {
    await pool.query(sql);
  } finally {
    await pool.end();
  }
}

async function authVerifier() {
  const profile = await contract();
  const issuer = process.env.OIDC_ISSUER;
  if (!issuer) throw new Error('OIDC_ISSUER is required');
  let jwks;
  return async (req) => {
    const authorization = req.headers.authorization ?? '';
    if (!authorization.startsWith('Bearer ')) throw new Error('unauthenticated');
    if (!jwks) {
      const response = await fetch(`${issuer}/.well-known/openid-configuration`);
      if (!response.ok) throw new Error('OIDC discovery failed');
      const discovery = await response.json();
      if (discovery.issuer !== issuer || typeof discovery.jwks_uri !== 'string') {
        throw new Error('OIDC discovery does not match the modeled issuer');
      }
      jwks = createRemoteJWKSet(new URL(discovery.jwks_uri), { cooldownDuration: 0 });
    }
    const { payload } = await jwtVerify(authorization.slice(7), jwks, {
      audience: profile.identity_audience,
      issuer
    });
    if (!validOidcSubject(payload.sub) || !Array.isArray(payload.roles)) {
      throw new Error('unauthenticated');
    }
    return { roles: new Set(payload.roles.filter((value) => typeof value === 'string')), subject: payload.sub };
  };
}

async function publishOutbox(pool) {
  const profile = await contract();
  let connection;
  try {
    const password = encodeURIComponent(await secret('BROKER_CREDENTIALS'));
    connection = await connectAmqp(`amqp://${encodeURIComponent(profile.broker_user)}:${password}@${process.env.BROKER_HOST ?? 'broker'}`);
    const channel = await connection.createConfirmChannel();
    await channel.assertExchange(profile.event_exchange, 'fanout', { durable: true });
    const rows = await pool.query(`SELECT event_id, event FROM ${profile.outbox_table} WHERE published = false ORDER BY sequence LIMIT 100`);
    for (const row of rows.rows) {
      channel.publish(profile.event_exchange, '', Buffer.from(canonical(row.event)), {
        contentType: 'application/cloudevents+json',
        messageId: row.event_id,
        persistent: true
      });
      await channel.waitForConfirms();
      await pool.query(`UPDATE ${profile.outbox_table} SET published = true, published_at = clock_timestamp() WHERE event_id = $1`, [row.event_id]);
    }
    await channel.close();
  } catch (error) {
    await telemetry('broker-outage', { error: error.message });
  } finally {
    if (connection) await connection.close().catch(() => {});
  }
}

function historyValue(row, contract) {
  const value = {
    outcome: row.outcome === 'succeeded'
      ? { kind: row.outcome, result: row.result_value }
      : { error: row.error_code, kind: row.outcome },
    sequence: String(row.sequence),
    subject: row.subject
  };
  value[contract.command_id_field] = row[contract.command_id_column];
  value[contract.operation_field] = row[contract.operation_column];
  value[contract.input_a_field] = row[contract.input_a_column];
  value[contract.input_b_field] = row[contract.input_b_column];
  if (contract.optional_annotation === 'optional') value[contract.annotation_field] = row[contract.annotation_column] ?? null;
  return value;
}

async function api() {
  const core = await Core.load();
  const pool = await database();
  const authenticate = await authVerifier();
  const request = async (req, res) => {
    if (req.url === '/health/live' || req.url === '/health/startup') return response(res, 200, { status: 'ok' });
    if (req.url === '/health/ready') {
      try {
        await pool.query('SELECT 1');
        return response(res, 200, { status: 'ready' });
      } catch {
        return response(res, 503, { status: 'unready' });
      }
    }
    let identity;
    try {
      identity = await authenticate(req);
    } catch {
      await telemetry('authorization-failure', { reason: 'unauthenticated' });
      return errorResponse(res, 401, 'Unauthenticated', { 'www-authenticate': 'Bearer' });
    }
    const url = new URL(req.url, 'https://runtime.invalid');
    const requestPattern = new RegExp(core.contract.command_id_pattern);
    const itemPattern = new RegExp(`^${core.contract.command_path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\/(${core.contract.command_id_pattern.slice(1, -1)})$`);
    const match = url.pathname.match(itemPattern);
    try {
      if (req.method === 'POST' && url.pathname === core.contract.command_path) {
        if (!identity.roles.has(core.contract.submitter_role)) return errorResponse(res, 403, 'Forbidden');
        const contentType = (req.headers['content-type'] ?? '').toLowerCase().split(';', 1)[0].trim();
        if (contentType !== 'application/json') return errorResponse(res, 415, 'UnsupportedMedia');
        const value = await body(req, core.contract.max_request_bytes);
        if (value === null || typeof value !== 'object' || Array.isArray(value)) {
          return errorResponse(res, 400, 'MalformedJson');
        }
        const keys = Object.keys(value).sort();
        const requiredKeys = [core.contract.input_a_field, core.contract.operation_field, core.contract.command_id_field, core.contract.input_b_field];
        const allowedKeys = core.contract.optional_annotation === 'optional'
          ? new Set([...requiredKeys, core.contract.annotation_field])
          : new Set(requiredKeys);
        if (!requiredKeys.every((key) => keys.includes(key)) || !keys.every((key) => allowedKeys.has(key))) return errorResponse(res, 400, 'MalformedJson');
        const commandId = value[core.contract.command_id_field];
        const operation = value[core.contract.operation_field];
        const inputA = value[core.contract.input_a_field];
        const inputB = value[core.contract.input_b_field];
        const annotation = value[core.contract.annotation_field];
        if (!requestPattern.test(commandId) || !core.contract.command_operations.includes(operation) || !validInteger(inputA) || !validInteger(inputB)) return errorResponse(res, 400, 'MalformedJson');
        if (annotation !== undefined && (typeof annotation !== 'string' || [...annotation].length > core.contract.annotation_max_scalars || annotation !== annotation.normalize('NFC'))) return errorResponse(res, 400, 'MalformedJson');
        const input = canonical(value);
        const client = await pool.connect();
        let row;
        try {
          await client.query('BEGIN');
          await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [commandId]);
          const existing = await client.query(`SELECT * FROM ${core.contract.history_table} WHERE ${core.contract.command_id_column} = $1 FOR UPDATE`, [commandId]);
          if (existing.rowCount > 0) {
            row = existing.rows[0];
            if (row.subject !== identity.subject || row.canonical_input !== input) {
              await client.query('ROLLBACK');
              return errorResponse(res, 409, 'IdempotencyConflict');
            }
            await client.query('COMMIT');
          } else {
            const outcome = core.execute(operation, inputA, inputB);
            const inserted = core.contract.optional_annotation === 'optional'
              ? await client.query(
                `INSERT INTO ${core.contract.history_table}(subject, ${core.contract.command_id_column}, ${core.contract.operation_column}, ${core.contract.input_a_column}, ${core.contract.input_b_column}, ${core.contract.annotation_column}, canonical_input, outcome, result_value, error_code) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
                [identity.subject, commandId, operation, inputA, inputB, annotation ?? null, input, outcome.kind, outcome.result ?? null, outcome.error ?? null]
              )
              : await client.query(
                `INSERT INTO ${core.contract.history_table}(subject, ${core.contract.command_id_column}, ${core.contract.operation_column}, ${core.contract.input_a_column}, ${core.contract.input_b_column}, canonical_input, outcome, result_value, error_code) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
                [identity.subject, commandId, operation, inputA, inputB, input, outcome.kind, outcome.result ?? null, outcome.error ?? null]
              );
            row = inserted.rows[0];
            const eventId = sha(`${identity.subject}\0${commandId}`);
            const event = {
              data: historyValue(row, core.contract),
              id: eventId,
              source: core.contract.event_source,
              specversion: '1.0',
              subject: commandId,
              type: outcome.kind === 'succeeded' ? core.contract.accepted_event_type : core.contract.rejected_event_type
            };
            await client.query(`INSERT INTO ${core.contract.outbox_table}(sequence, event_id, event) VALUES($1,$2,$3)`, [row.sequence, eventId, event]);
            await client.query('COMMIT');
          }
        } catch (error) {
          await client.query('ROLLBACK').catch(() => {});
          throw error;
        } finally {
          client.release();
        }
        void publishOutbox(pool);
        await telemetry('command-outcome', { outcome: row.outcome, [core.contract.command_id_field]: row[core.contract.command_id_column] });
        return response(res, row.outcome === 'succeeded' ? 200 : 422, historyValue(row, core.contract));
      }
      if (req.method === 'GET' && match) {
        const visibility = historyVisibility(identity.roles, core.contract);
        if (visibility === null) return errorResponse(res, 403, 'Forbidden');
        const values = [match[1]];
        let sql = `SELECT * FROM ${core.contract.history_table} WHERE ${core.contract.command_id_column} = $1`;
        if (visibility === 'own-subject') {
          sql += ' AND subject = $2';
          values.push(identity.subject);
        }
        const result = await pool.query(sql, values);
        if (result.rowCount === 0) return errorResponse(res, 404, 'NotFound');
        return response(res, 200, historyValue(result.rows[0], core.contract));
      }
      if (req.method === 'GET' && url.pathname === core.contract.command_path) {
        const visibility = historyVisibility(identity.roles, core.contract);
        if (visibility === null) return errorResponse(res, 403, 'Forbidden');
        const after = url.searchParams.get('after') ?? '0';
        const limitText = url.searchParams.get('limit') ?? String(core.contract.history_default_limit);
        const canonicalUnsignedDecimal = /^(?:0|[1-9][0-9]*)$/;
        if (!canonicalUnsignedDecimal.test(after) || !canonicalUnsignedDecimal.test(limitText) || BigInt(after) > 18446744073709551615n) return errorResponse(res, 400, 'MalformedJson');
        const limit = Number(limitText);
        if (limit < 1 || limit > core.contract.history_max_limit) return errorResponse(res, 400, 'MalformedJson');
        const values = [after, limit];
        let sql = `SELECT * FROM ${core.contract.history_table} WHERE sequence > $1`;
        if (visibility === 'own-subject') {
          sql += ' AND subject = $3';
          values.push(identity.subject);
        }
        sql += ' ORDER BY sequence ASC LIMIT $2';
        const result = await pool.query(sql, values);
        return response(res, 200, { records: result.rows.map((row) => historyValue(row, core.contract)) });
      }
      return errorResponse(res, 405, 'UnsupportedMethod');
    } catch (error) {
      if (error.status) return errorResponse(res, error.status, error.message === 'oversized-input' ? 'OversizedInput' : 'MalformedJson');
      await telemetry('dependency-fault', { error: error.message });
      return errorResponse(res, 503, 'ServiceUnavailable');
    }
  };
  const port = Number(process.env.API_PORT ?? 8443);
  const server = process.env.TLS_BUNDLE_FILE
    ? https.createServer(JSON.parse(await readFile(process.env.TLS_BUNDLE_FILE, 'utf8')), request)
    : http.createServer(request);
  server.listen(port, '0.0.0.0');
  const publish = setInterval(() => void publishOutbox(pool), 1000);
  const stop = () => {
    clearInterval(publish);
    server.close(() => void pool.end().finally(() => process.exit(0)));
  };
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}

async function worker() {
  const profile = await contract();
  const pool = await database();
  const password = encodeURIComponent(await secret('BROKER_CREDENTIALS'));
  const connection = await connectAmqp(`amqp://${encodeURIComponent(profile.broker_user)}:${password}@${process.env.BROKER_HOST ?? 'broker'}`);
  const channel = await connection.createChannel();
  await channel.assertExchange(profile.event_exchange, 'fanout', { durable: true });
  const queue = await channel.assertQueue(profile.audit_queue, { durable: true });
  await channel.bindQueue(queue.queue, profile.event_exchange, '');
  await channel.consume(queue.queue, async (message) => {
    if (!message) return;
    try {
      const event = JSON.parse(decoder.decode(message.content));
      if (event.specversion !== '1.0' || typeof event.id !== 'string') throw new Error('invalid CloudEvent');
      await pool.query(`INSERT INTO ${profile.audit_table}(event_id, event) VALUES($1,$2) ON CONFLICT(event_id) DO NOTHING`, [event.id, event]);
      channel.ack(message);
      await telemetry('audit-event', { event_id: event.id });
    } catch (error) {
      channel.nack(message, false, false);
      await telemetry('audit-event-rejected', { error: error.message });
    }
  }, { noAck: false });
  const stop = async () => {
    await channel.close();
    await connection.close();
    await pool.end();
    process.exit(0);
  };
  process.on('SIGTERM', () => void stop());
  process.on('SIGINT', () => void stop());
}

async function acceptance() {
  const profile = await contract();
  const apiUrl = `http://127.0.0.1:${Number(process.env.API_PORT ?? 8443)}`;
  const issuerUrl = process.env.OIDC_ISSUER;
  if (!issuerUrl) throw new Error('OIDC_ISSUER is required');
  const checked = [];
  const request = async (path, options, expectedStatus, expectedCode) => {
    const started = performance.now();
    const result = await fetch(`${apiUrl}${path}`, options);
    const elapsedMillis = Math.ceil(performance.now() - started);
    const text = await result.text();
    const value = text ? JSON.parse(text) : null;
    if (result.status !== expectedStatus) {
      throw new Error(`acceptance status ${result.status}, expected ${expectedStatus}`);
    }
    if (expectedCode && value?.error?.code !== expectedCode) {
      throw new Error(`acceptance error ${value?.error?.code}, expected ${expectedCode}`);
    }
    checked.push({ elapsed_millis: elapsedMillis, expected_status: expectedStatus, path });
    return value;
  };
  const token = async (sub, roles, conformance) => {
    const result = await fetch(`${issuerUrl}/token`, {
      body: canonical({ ...(conformance ? { conformance } : {}), roles, sub }),
      headers: { 'content-type': 'application/json' },
      method: 'POST'
    });
    if (!result.ok) throw new Error('conformance issuer rejected a modeled identity');
    return (await result.json()).access_token;
  };
  const user = await token('acceptance-user', [profile.submitter_role]);
  const other = await token('acceptance-other', [profile.submitter_role]);
  const auditor = await token('acceptance-auditor', [profile.observer_role]);
  const denied = await token('acceptance-denied', []);
  const auth = (value) => ({ authorization: `Bearer ${value}` });
  const jsonHeaders = (value) => ({ ...auth(value), 'content-type': 'application/json' });
  const commandPath = profile.command_path;
  await request(`${commandPath}?after=0&limit=1`, {}, 401, 'Unauthenticated');
  await request(`${commandPath}?after=0&limit=1`, { headers: auth(denied) }, 403, 'Forbidden');
  for (const conformance of ['expired', 'unknown-key', 'wrong-audience', 'wrong-issuer']) {
    const invalid = await token('acceptance-invalid', [profile.submitter_role], conformance);
    await request(`${commandPath}?after=0&limit=1`, { headers: auth(invalid) }, 401, 'Unauthenticated');
  }
  const release = profile.release.toLowerCase();
  const requestId = `acceptance-${release}`;
  const bodyValue = {
    [profile.input_a_field]: profile.acceptance_error_input_a,
    [profile.operation_field]: profile.acceptance_error_operation,
    [profile.command_id_field]: requestId,
    [profile.input_b_field]: profile.acceptance_error_input_b,
    ...(profile.optional_annotation === 'optional' ? { [profile.annotation_field]: 'Café' } : {})
  };
  const first = await request(commandPath, {
    body: canonical(bodyValue), headers: jsonHeaders(user), method: 'POST'
  }, 422);
  if (first.outcome?.error !== profile.acceptance_expected_error) throw new Error('modeled application error was not preserved');
  const repeat = await request(commandPath, {
    body: canonical(bodyValue), headers: jsonHeaders(user), method: 'POST'
  }, 422);
  if (canonical(first) !== canonical(repeat)) throw new Error('idempotent retry changed its response');
  await request(commandPath, {
    body: canonical({ ...bodyValue, [profile.input_b_field]: profile.acceptance_conflict_input_b }), headers: jsonHeaders(user), method: 'POST'
  }, 409, 'IdempotencyConflict');
  await request(commandPath, {
    body: canonical(bodyValue), headers: jsonHeaders(other), method: 'POST'
  }, 409, 'IdempotencyConflict');
  await request(`${commandPath}/${requestId}`, { headers: auth(other) }, 404, 'NotFound');
  await request(`${commandPath}/${requestId}`, { headers: auth(auditor) }, 200);
  await request(commandPath, {
    body: canonical({ ...bodyValue, [profile.command_id_field]: `auditor-${release}` }),
    headers: jsonHeaders(auditor), method: 'POST'
  }, 403, 'Forbidden');
  await request(commandPath, {
    body: '{', headers: jsonHeaders(user), method: 'POST'
  }, 400, 'MalformedJson');
  await request(commandPath, {
    body: canonical({ ...bodyValue, [profile.command_id_field]: `media-${release}` }),
    headers: auth(user), method: 'POST'
  }, 415, 'UnsupportedMedia');
  await request(commandPath, { headers: auth(user), method: 'PUT' }, 405, 'UnsupportedMethod');
  await request(`${commandPath}?after=0&limit=0`, { headers: auth(user) }, 400, 'MalformedJson');
  await request(`${commandPath}?after=01&limit=1`, { headers: auth(user) }, 400, 'MalformedJson');
  await request(`${commandPath}?after=0&limit=01`, { headers: auth(user) }, 400, 'MalformedJson');
  await request(commandPath, {
    body: ' '.repeat(profile.max_request_bytes + 1), headers: jsonHeaders(user), method: 'POST'
  }, 413, 'OversizedInput');
  if (profile.optional_annotation === 'optional') {
    await request(commandPath, {
      body: canonical({ ...bodyValue, [profile.annotation_field]: 'e\u0301', [profile.command_id_field]: `nfc-${release}` }),
      headers: jsonHeaders(user), method: 'POST'
    }, 400, 'MalformedJson');
  }
  const concurrentId = `concurrent-${release}`;
  const concurrentBody = canonical({
    [profile.input_a_field]: profile.acceptance_success_input_a,
    [profile.operation_field]: profile.acceptance_success_operation,
    [profile.command_id_field]: concurrentId,
    [profile.input_b_field]: profile.acceptance_success_input_b,
    ...(profile.optional_annotation === 'optional' ? { [profile.annotation_field]: 'concurrent' } : {})
  });
  const concurrent = await Promise.all(Array.from({ length: 12 }, () => fetch(`${apiUrl}${commandPath}`, {
    body: concurrentBody, headers: jsonHeaders(user), method: 'POST'
  })));
  if (concurrent.some((result) => result.status !== 200)) throw new Error('concurrent idempotency failed');
  const page = await request(`${commandPath}?after=0&limit=${profile.history_max_limit}`, { headers: auth(user) }, 200);
  const concurrentRows = page.records.filter((row) => row[profile.command_id_field] === concurrentId);
  if (concurrentRows.length !== 1 || concurrentRows[0].outcome?.result !== profile.acceptance_expected_result) {
    throw new Error('concurrent request produced a duplicate or wrong result');
  }
  if (!page.records.every((row, index, rows) => index === 0 || BigInt(rows[index - 1].sequence) < BigInt(row.sequence))) {
    throw new Error('history is not in ascending sequence order');
  }
  const pool = await database();
  let outboxLagP99Millis = 0;
  try {
    const deadline = Date.now() + 10000;
    while (Date.now() < deadline) {
      const state = await pool.query(
        `SELECT (SELECT count(*) FROM ${profile.outbox_table} WHERE event_id IN (SELECT event_id FROM ${profile.audit_table})) AS audited, (SELECT count(*) FROM ${profile.history_table} WHERE ${profile.command_id_column} = $1) AS concurrent`,
        [concurrentId]
      );
      if (Number(state.rows[0].audited) >= 2 && Number(state.rows[0].concurrent) === 1) break;
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    const state = await pool.query(
      `SELECT (SELECT count(*) FROM ${profile.outbox_table} WHERE published = true) AS published, (SELECT count(*) FROM ${profile.audit_table}) AS audited, (SELECT count(*) FROM ${profile.history_table} WHERE ${profile.command_id_column} = $1) AS concurrent, (SELECT COALESCE(percentile_cont(0.99) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (published_at - committed_at)) * 1000), 0) FROM ${profile.outbox_table} WHERE published_at IS NOT NULL) AS outbox_lag_p99_millis`,
      [concurrentId]
    );
    if (Number(state.rows[0].published) < 2 || Number(state.rows[0].audited) < 2 || Number(state.rows[0].concurrent) !== 1) {
      throw new Error('transactional outbox or deduplicated audit acceptance failed');
    }
    outboxLagP99Millis = Math.ceil(Number(state.rows[0].outbox_lag_p99_millis));
    if (!Number.isFinite(outboxLagP99Millis) || outboxLagP99Millis > profile.outbox_lag_threshold_millis) {
      throw new Error('modeled outbox-lag SLO failed');
    }
  } finally {
    await pool.end();
  }
  const redactionAttributes = Object.fromEntries(
    profile.redacted_fields.map((field) => [field, 'PRISMPM-REDACTION-CANARY'])
  );
  redactionAttributes[profile.command_id_field] = concurrentId;
  const telemetryReceipt = await telemetry('acceptance-signal', redactionAttributes);
  if (!Object.values(telemetryReceipt).every(Boolean)) {
    throw new Error('OpenTelemetry Collector did not accept every modeled signal');
  }
  const maximumLatencyMillis = Math.max(...checked.map((row) => row.elapsed_millis));
  process.stdout.write(`${canonical({
    availability_millionths: 1000000,
    check_count: checked.length,
    concurrent_requests: concurrent.length,
    maximum_latency_millis: maximumLatencyMillis,
    outbox_lag_p99_millis: outboxLagP99Millis,
    release: profile.release,
    schema: 'prismpm/runtime-acceptance/1',
    status: 'passed',
    telemetry_receipt: telemetryReceipt
  })}\n`);
}

async function issuer() {
  const profile = await contract();
  const issuerUrl = process.env.OIDC_ISSUER ?? 'http://issuer:5556';
  const privateKeyPem = await secret('OIDC_SIGNING_KEY');
  const privateKey = await importPKCS8(privateKeyPem, 'RS256');
  const publicJwkMaterial = await exportJWK(createPublicKey(privateKeyPem));
  if (publicJwkMaterial.kty !== 'RSA' || typeof publicJwkMaterial.n !== 'string' || Buffer.from(publicJwkMaterial.n, 'base64url').length < 256) {
    throw new Error('OIDC_SIGNING_KEY must be an RSA PKCS#8 key of at least 2048 bits');
  }
  const publicJwk = {
    ...publicJwkMaterial,
    alg: 'RS256',
    kid: sha(canonical({ e: publicJwkMaterial.e, kty: publicJwkMaterial.kty, n: publicJwkMaterial.n })),
    use: 'sig'
  };
  const server = http.createServer(async (req, res) => {
    if (req.method === 'GET' && req.url === '/.well-known/openid-configuration') return response(res, 200, { issuer: issuerUrl, jwks_uri: `${issuerUrl}/jwks.json`, token_endpoint: `${issuerUrl}/token` });
    if (req.method === 'GET' && req.url === '/jwks.json') return response(res, 200, { keys: [publicJwk] });
    if (req.method === 'GET' && req.url === '/healthz') return response(res, 200, { status: 'ok' });
    if (req.method === 'POST' && req.url === '/token') {
      const value = await body(req, profile.max_request_bytes).catch(() => null);
      if (!value || !validOidcSubject(value.sub) || !Array.isArray(value.roles)) return errorResponse(res, 400, 'MalformedJson');
      if (!value.roles.every((role) => [profile.observer_role, profile.submitter_role].includes(role))) return errorResponse(res, 400, 'MalformedJson');
      const conformance = value.conformance;
      if (conformance !== undefined && !['expired', 'unknown-key', 'wrong-audience', 'wrong-issuer'].includes(conformance)) return errorResponse(res, 400, 'MalformedJson');
      const signingKey = conformance === 'unknown-key'
        ? (await generateKeyPair('RS256', { modulusLength: 2048 })).privateKey
        : privateKey;
      const token = await new SignJWT({ roles: value.roles })
        .setProtectedHeader({ alg: 'RS256', kid: conformance === 'unknown-key' ? 'unknown-conformance-key' : publicJwk.kid })
        .setIssuer(conformance === 'wrong-issuer' ? `${issuerUrl}/wrong` : issuerUrl)
        .setAudience(conformance === 'wrong-audience' ? 'wrong-audience' : profile.identity_audience)
        .setSubject(value.sub)
        .setIssuedAt()
        .setExpirationTime(conformance === 'expired' ? 1 : '5m')
        .sign(signingKey);
      return response(res, 200, { access_token: token, expires_in: 300, token_type: 'Bearer' });
    }
    return errorResponse(res, 404, 'NotFound');
  });
  server.listen(Number(process.env.ISSUER_PORT ?? 5556), '0.0.0.0');
  const stop = () => server.close(() => process.exit(0));
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}

async function browser() {
  const profile = await contract();
  const mime = { '.css': 'text/css', '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm' };
  const proxy = (req, res, host, port, rewrittenPath) => {
    const forwarded = http.request({
      headers: { ...req.headers, host: `${host}:${port}` },
      host,
      method: req.method,
      path: rewrittenPath,
      port
    }, (upstream) => {
      res.writeHead(upstream.statusCode ?? 502, upstream.headers);
      upstream.pipe(res);
    });
    forwarded.on('error', () => errorResponse(res, 503, 'ServiceUnavailable'));
    req.pipe(forwarded);
  };
  const request = async (req, res) => {
    if (req.url.startsWith('/v1/')) {
      return proxy(req, res, process.env.API_HOST ?? 'api', Number(process.env.API_PORT ?? 8443), req.url);
    }
    if (req.url === profile.token_path) {
      return proxy(req, res, process.env.ISSUER_HOST ?? 'issuer', Number(process.env.ISSUER_PORT ?? 5556), '/token');
    }
    const path = req.url === '/' ? '/index.html' : new URL(req.url, 'http://browser').pathname;
    if (!/^\/[A-Za-z0-9._-]+$/.test(path)) return errorResponse(res, 404, 'NotFound');
    try {
      const productionPath = `${releaseRoot}/production-browser${path}`;
      const bytes = await readFile(productionPath).catch(() => readFile(`${releaseRoot}/browser${path}`));
      const extension = path.slice(path.lastIndexOf('.'));
      res.writeHead(200, { 'content-length': String(bytes.length), 'content-type': mime[extension] ?? 'application/octet-stream', 'x-content-type-options': 'nosniff' });
      res.end(bytes);
    } catch {
      errorResponse(res, 404, 'NotFound');
    }
  };
  const server = process.env.TLS_CERTIFICATE_FILE
    ? https.createServer(JSON.parse(await readFile(process.env.TLS_CERTIFICATE_FILE, 'utf8')), request)
    : http.createServer(request);
  server.listen(Number(process.env.BROWSER_PORT ?? 8080), '0.0.0.0');
  const stop = () => server.close(() => process.exit(0));
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}

if (role === 'probe') {
  await probe(process.argv[3]);
} else if (role === 'migrate') {
  await migrate();
} else if (role === 'contract') {
  await contractMigration();
} else if (role === 'api') {
  await api();
} else if (role === 'worker') {
  await worker();
} else if (role === 'issuer') {
  await issuer();
} else if (role === 'browser') {
  await browser();
} else if (role === 'acceptance') {
  await acceptance();
} else {
  process.stderr.write('usage: runtime.mjs acceptance|api|browser|contract|issuer|migrate|worker|probe COMPONENT\n');
  process.exitCode = 64;
}
