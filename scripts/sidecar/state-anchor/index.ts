import { connect, StringCodec, JetStreamManager, JSONCodec } from 'nats';
import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as crypto from 'crypto';
import { runBatchAggregation, computeBatchMerkleRoot, type AttestedEvent } from './batchAggregator';

dotenv.config();

const NATS_URL = process.env.NATS_URL || 'nats://localhost:4222';
const RPC_URL = process.env.RPC_URL || 'http://localhost:8545';
const PRIVATE_KEY = process.env.PRIVATE_KEY || '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const REGISTRY_ADDRESS = process.env.ANCHOR_REGISTRY_ADDRESS || '0x0000000000000000000000000000000000000000';

const STATE_SUBJECTS = [
  'uac.state.governance',
  'uac.state.orchestrator',
  'uac.state.chemistry',
  'uac.state.proofs',
  'uac.state.attestations',
];

const CATEGORY_ORDER = ['governance', 'orchestrator', 'chemistry', 'proofs', 'attestations'] as const;
type Category = (typeof CATEGORY_ORDER)[number];

const DAILY_ANCHOR_HOUR_UTC = 0;
const GOVERNANCE_WINDOW_MS = 60 * 60 * 1000;

const sc = StringCodec();
const jc = JSONCodec();

// ABI for AnchorRegistry (subset used by the sidecar).
const ANCHOR_ABI = [
  'function submitRoot(bytes32 root, uint256 timestamp, bytes signature) external',
  'function submitRootWithDilithium(bytes32 root, uint256 timestamp, bytes ecdsaSignature, bytes dilithiumSignature) external',
  'function setSidecar(address sidecar, bool allowed) external',
  'function setDilithiumVerifier(address verifier) external',
  'function registerDilithiumKey(bytes publicKey) external',
  'function latestRoot() external view returns (bytes32)',
  'event AnchorSubmitted(bytes32 indexed root, uint256 timestamp, uint256 blockNumber)',
  'event AnchorSubmittedPQC(bytes32 indexed root, uint256 timestamp, uint256 blockNumber, bool hasDilithium)',
];

interface StateEvent {
  id: string;
  category: Category;
  payloadHash: string;
  receivedAt: number;
}

// Buffer of received state events per category. Drained on the anchor schedule.
const buffer: Record<Category, StateEvent[]> = {
  governance: [],
  orchestrator: [],
  chemistry: [],
  proofs: [],
  attestations: [],
};

// Last-24h of FeMoco `Attested` events, aggregated once/day by
// `batch_anchor` (ADR-PML-050) into the `attestations` root.
const attestationWindow: AttestedEvent[] = [];
const ATTESTATION_WINDOW_MS = 24 * 60 * 60 * 1000;

function sha256Hex(data: Buffer | string): string {
  return crypto.createHash('sha256').update(data).digest('hex');
}

// Merkle root over a category's events: leaves are SHA-256(payload), nodes hashed pairwise.
function categoryRoot(events: StateEvent[]): string {
  if (events.length === 0) return ethers.ZeroHash;
  let leaves = events.map((e) =>
    ethers.zeroPadValue(e.payloadHash.startsWith('0x') ? e.payloadHash : '0x' + e.payloadHash, 32),
  );
  while (leaves.length > 1) {
    const next: string[] = [];
    for (let i = 0; i < leaves.length; i += 2) {
      const left = leaves[i];
      const right = i + 1 < leaves.length ? leaves[i + 1] : left;
      next.push(ethers.keccak256(ethers.concat([left, right])));
    }
    leaves = next;
  }
  return leaves[0];
}

// Combined root = SHA-256(governance || orchestrator || chemistry || proofs || attestation).
function combinedRoot(roots: Record<Category, string>): string {
  const packed = ethers.concat(CATEGORY_ORDER.map((c) => roots[c]));
  return sha256Hex(packed);
}

// ADR-PML-051: sign a message hash with the Dilithium5 Rust CLI.
function signWithDilithium(msgHex: string): Promise<string> {
  const skPath = process.env.DILITHIUM_SK_PATH;
  if (!skPath) throw new Error('DILITHIUM_SK_PATH is not set');

  const candidates = [
    process.env.DILITHIUM_SIGNER_BIN,
    path.resolve(__dirname, '../../../crates/dilithium-signer/target/debug/dilithium-signer'),
    path.resolve(__dirname, '../../../crates/dilithium-signer/target/release/dilithium-signer'),
    'dilithium-signer',
  ].filter((x): x is string => Boolean(x));

  let bin = candidates.find((c) => !c.includes('dilithium-signer') && require('fs').existsSync(c)) || candidates[candidates.length - 1];

  const { execSync } = require('child_process');
  const output = execSync(`"${bin}" sign --sk-path "${skPath}" --msg-hex "${msgHex}"`, {
    encoding: 'utf8',
    stdio: ['pipe', 'pipe', 'pipe'],
  });
  const trimmed = output.trim();
  if (!trimmed.startsWith('0x')) {
    throw new Error(`Unexpected dilithium-signer output: ${trimmed}`);
  }
  return trimmed;
}

async function submitAnchor(wallet: ethers.Wallet, contract: ethers.Contract) {
  const roots = {} as Record<Category, string>;
  for (const c of CATEGORY_ORDER) {
    roots[c] = categoryRoot(buffer[c]);
  }

  if (attestationWindow.length > 0) {
    try {
      console.log(`[batch] aggregating ${attestationWindow.length} attestations...`);
      const result = runBatchAggregation(attestationWindow);
      const tsRoot = computeBatchMerkleRoot(attestationWindow);
      if (tsRoot.toLowerCase() !== result.batchRoot.toLowerCase()) {
        throw new Error(
          `batch root drift: ts=${tsRoot} bin=${result.batchRoot}`,
        );
      }
      roots.attestations = result.batchRoot;
      console.log(`[batch] batchRoot=${result.batchRoot} apoRoot=${result.aggregateRoot}`);
    } catch (err) {
      console.warn('[batch] aggregation failed; using buffered root:', (err as Error).message);
      roots.attestations = categoryRoot(buffer.attestations);
    }
  }

  const root = combinedRoot(roots);
  const timestamp = Math.floor(Date.now() / 1000);

  const msgHash = ethers.solidityPackedKeccak256(['bytes32', 'uint256'], [root, timestamp]);
  const signature = await wallet.signMessage(ethers.getBytes(msgHash));

  const dilithiumEnabled = process.env.DILITHIUM_ENABLED === 'true';
  let dilithiumSignature = '';
  let pqcEnabled = dilithiumEnabled;
  if (pqcEnabled) {
    try {
      dilithiumSignature = await signWithDilithium(ethers.hexlify(ethers.getBytes(msgHash)));
    } catch (err) {
      console.warn('[dilithium] signing failed; falling back to ECDSA-only:', (err as Error).message);
      pqcEnabled = false;
    }
  }

  console.log(`[submitAnchor] root=${root} ts=${timestamp} categories=${CATEGORY_ORDER.length} pqc=${pqcEnabled}`);
  const tx = pqcEnabled && dilithiumSignature
    ? await contract.submitRootWithDilithium(root, timestamp, signature, dilithiumSignature)
    : await contract.submitRoot(root, timestamp, signature);
  const receipt = await tx.wait();
  console.log(`[submitAnchor] anchored in tx=${receipt.hash} block=${receipt.blockNumber}`);

  for (const c of CATEGORY_ORDER) buffer[c] = [];
}

async function ensureStream(nc: any) {
  try {
    const jsm = await nc.jetstream().manager() as JetStreamManager;
    await jsm.streams.add({
      name: 'UAC_STATE',
      subjects: STATE_SUBJECTS,
      retention: 'WorkQueuePolicy' as any,
      storage: 'File' as any,
      max_age: 7 * 24 * 60 * 60 * 1_000_000_000,
    });
    console.log('[nats] ensured JetStream stream UAC_STATE (at-least-once delivery)');
  } catch (e: any) {
    if (e.message && e.message.includes('already')) return;
    console.warn('[nats] stream ensure warning:', e.message);
  }
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const contract = new ethers.Contract(REGISTRY_ADDRESS, ANCHOR_ABI, wallet);

  console.log(`[state-anchor] connecting to NATS at ${NATS_URL}`);
  const nc = await connect({ servers: NATS_URL });
  await ensureStream(nc);

  // Subscribe with JetStream durable consumer for at-least-once delivery.
  const js = nc.jetstream();
  for (const subject of STATE_SUBJECTS) {
      const sub = await js.subscribe(subject, { durable: 'state-anchor', ack_wait: 30_000 } as any);
    (async () => {
      for await (const m of sub) {
        try {
          const obj = jc.decode(m.data) as any;
          const category = subject.split('.').pop() as Category;
          const payloadHash = obj.hash
            ? obj.hash
            : sha256Hex(Buffer.from(sc.encode(JSON.stringify(obj))));
          buffer[category].push({
            id: obj.id || crypto.randomUUID(),
            category,
            payloadHash,
            receivedAt: Date.now(),
          });

          // ADR-PML-050: capture FeMoco `Attested` events into the
          // 24h window that `batch_anchor` aggregates daily.
          if (category === 'attestations') {
            const ev: AttestedEvent = {
              digest: obj.digest,
              timestamp: obj.timestamp,
              consentCommitment: obj.consentCommitment,
              nullifier: obj.nullifier,
            };
            if (ev.digest && ev.nullifier) {
              attestationWindow.push(ev);
            }
          }
          // Prune the 24h window.
          const cutoff = Date.now() - ATTESTATION_WINDOW_MS;
          while (
            attestationWindow.length > 0 &&
            attestationWindow[0].timestamp * 1000 < cutoff
          ) {
            attestationWindow.shift();
          }

          m.ack();
        } catch (err) {
          console.error('[state-anchor] failed to ingest event:', err);
        }
      }
    })();
  }

  console.log('[state-anchor] subscriptions active; scheduling anchors');

  // Hourly governance roll + daily comprehensive anchor at UTC 00:00.
  const tick = setInterval(async () => {
    try {
      const now = new Date();
      const isDailyBoundary =
        now.getUTCHours() === DAILY_ANCHOR_HOUR_UTC &&
        now.getUTCMinutes() === 0;
      const governanceStale =
        buffer.governance.length > 0 &&
        Date.now() - buffer.governance[buffer.governance.length - 1].receivedAt > GOVERNANCE_WINDOW_MS;

      if (isDailyBoundary || governanceStale) {
        await submitAnchor(wallet, contract);
      }
    } catch (err) {
      console.error('[state-anchor] anchor tick failed (will retry next tick):', err);
    }
  }, 60 * 1000);

  process.on('SIGINT', () => {
    clearInterval(tick);
    nc.close();
  });
}

// Only auto-run when executed directly, not when imported by tests.
if (require.main === module) {
  main().catch(console.error);
}

export { signWithDilithium, submitAnchor, categoryRoot, combinedRoot };
