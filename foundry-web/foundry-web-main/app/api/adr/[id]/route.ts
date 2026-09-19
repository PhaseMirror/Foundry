import { NextRequest, NextResponse } from 'next/server';
import { readSingleADR } from '@/lib/engine-bridge';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Single ADR record, wired to the UCC engine. Reads the ADR from the
 * machine-checked registry; unknown ids yield 404.
 */
export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const adr = await readSingleADR(id);
  if (!adr) {
    return NextResponse.json({ error: `ADR not found: ${id}` }, { status: 404 });
  }
  return NextResponse.json(adr);
}