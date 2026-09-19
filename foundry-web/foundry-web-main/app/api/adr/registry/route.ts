import { NextRequest, NextResponse } from 'next/server';
import { getEngineStatus, readEngineRegistry } from '@/lib/engine-bridge';
import { registryChecks } from '@/lib/engine-invariants';
import { ADR } from '@/lib/adr-types';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Registry, wired to the UCC engine.
 *
 * GET returns the aggregated engine status (the same shape as `/api/foundry`),
 * plus `adrs`/`claims` for clients that expect an `ADRRegistry`. POST validates
 * an arbitrary ADR set against the engine's registry invariants (unique ids,
 * acyclic supersession, no conflicting accepted decisions).
 */
export async function GET() {
  const status = await getEngineStatus();
  const { adrs } = await readEngineRegistry();
  const claims = adrs
    .filter((a) => a.status === 'Accepted')
    .map((a) => ({ owner: a.id, claim: `decision:${a.decision.substring(0, 80)}…` }));
  return NextResponse.json({ ...status, adrs, claims });
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as { adrs?: ADR[] };
    const adrs = body.adrs;
    if (!adrs || !Array.isArray(adrs)) {
      return NextResponse.json({ error: 'adrs array is required' }, { status: 400 });
    }
    const checks = registryChecks(adrs);
    const valid = checks.uniqueIds && checks.acyclic && checks.noConflicts;
    return NextResponse.json({ valid, checks });
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
}