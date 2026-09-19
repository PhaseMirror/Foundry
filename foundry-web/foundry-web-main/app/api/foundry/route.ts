import { NextRequest, NextResponse } from 'next/server';
import {
  readEngineRegistry,
  readSingleADR,
  getEngineStatus,
  runEngineExport,
  runVerificationGate,
  runSorryCheck,
  engineInfo,
} from '@/lib/engine-bridge';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Foundry machinery route — the live bridge to the UCC/Lean engine.
 *
 * GET:
 *   - `?id=ADR-0106` — a single ADR from the engine's machine-checked registry;
 *   - otherwise the aggregate machinery status (counts, registry checks,
 *     verification summary, proof debt, export availability).
 * POST (JSON body):
 *   - `{ action: 'export' }` — run `lake build adrExport && adrExport`;
 *   - `{ action: 'verify', adr: 'ADR-0106' }` — run the per-ADR verification gate;
 *   - `{ action: 'sorry-check' }` — run the Lean sorry/admit proof-debt gate.
 */
export async function GET(req: NextRequest) {
  try {
    const idParam = req.nextUrl.searchParams.get('id');
    if (idParam) {
      const adr = await readSingleADR(idParam);
      if (!adr) {
        return NextResponse.json({ error: `ADR not found: ${idParam}` }, { status: 404 });
      }
      return NextResponse.json(adr);
    }
    const status = await getEngineStatus();
    return NextResponse.json(status);
  } catch (err) {
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const body = (await req.json().catch(() => null)) as { action?: string; adr?: string } | null;
  const action = body?.action ?? 'export';

  if (action === 'export') {
    const run = await runEngineExport();
    return NextResponse.json(run, { status: run.passed ? 200 : run.error === 'engine read-only' ? 409 : 500 });
  }
  if (action === 'verify' && body?.adr) {
    const run = await runVerificationGate(body.adr);
    return NextResponse.json(run, { status: run.passed ? 200 : 500 });
  }
  if (action === 'sorry-check') {
    const run = await runSorryCheck();
    return NextResponse.json(run, { status: run.passed ? 200 : 500 });
  }
  return NextResponse.json({ error: `unknown action: ${action}` }, { status: 400 });
}
