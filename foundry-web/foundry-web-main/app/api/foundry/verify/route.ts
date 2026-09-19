import { NextRequest, NextResponse } from 'next/server';
import { runSorryCheck, runVerificationGate, listVerificationResults } from '@/lib/engine-bridge';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Engine verification actions.
 *
 * GET returns the surviving per-ADR gate results the engine has produced.
 * POST runs an engine gate:
 *   - body `{ adrId: "ADR-0110" }` runs the full per-ADR gate
 *     (`scripts/run_adr_tests.py <adr.md>`: adr-index, sorry check, lake build,
 *     lake test, optional cargo/Kani);
 *   - body `{ sorryCheck: true }` runs only the ADR-0010 manifest-aware
 *     sorry/admit scan over the Lean build roots.
 * Gate runs are long; the response carries the full structured run result and
 * the fresh verification summary.
 */
export async function GET() {
  const results = await listVerificationResults();
  return NextResponse.json({ results, total: results.length });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    if (body && body.sorryCheck === true) {
      const run = await runSorryCheck();
      return NextResponse.json({ run, verification: await listVerificationResults() });
    }
    if (body && typeof body.adrId === 'string') {
      const run = await runVerificationGate(body.adrId);
      return NextResponse.json({ run, verification: await listVerificationResults() });
    }
    return NextResponse.json(
      { error: 'provide { adrId } to verify an ADR, or { sorryCheck: true } for the proof-debt scan' },
      { status: 400 },
    );
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
}