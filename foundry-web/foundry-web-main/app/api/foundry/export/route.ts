import { NextRequest, NextResponse } from 'next/server';
import { runEngineExport, lastExportTime } from '@/lib/engine-bridge';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Engine export action.
 *
 * GET reports the last engine export timestamp without running anything.
 * POST runs `lake build adrExport && adrExport`, regenerating
 * `docs/adr/{README.md,registry.json,ADR-*.{md,html,json}}` from the
 * machine-checked Lean registry. Deterministic and CI-safe; fails closed in
 * read-only or `FOUNDRY_SKIP_EXPORT` deployments.
 */
export async function GET() {
  return NextResponse.json({ lastExport: await lastExportTime() });
}

export async function POST(_req: NextRequest) {
  const run = await runEngineExport();
  const status = run.ok ? 200 : 500;
  return NextResponse.json({ run, lastExport: await lastExportTime() }, { status });
}