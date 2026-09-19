import { NextRequest, NextResponse } from 'next/server';
import { readAuditTrail, appendAudit } from '@/lib/engine-bridge';
import { FoundryAuditEntry } from '@/lib/adr-types';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Audit trail, wired to the UCC engine.
 *
 * GET returns the engine `audit_trail/` events merged with per-ADR verification
 * runs. POST appends a typed audit event to the engine's `audit_trail/`
 * directory; in read-only deployments it answers `accepted: false` without
 * pretending to persist.
 */
export async function GET() {
  const trail = await readAuditTrail();
  return NextResponse.json(trail);
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const adrId = typeof body.adrId === 'string' ? body.adrId : typeof body.ADR_ID === 'string' ? body.ADR_ID : 'UNKNOWN';
    const action = typeof body.action === 'string' ? body.action : 'Unknown';
    const status = typeof body.status === 'string' ? body.status : 'Pending';
    const author = typeof body.author === 'string' ? body.author : 'Unknown';
    const entry: FoundryAuditEntry = {
      ADR_ID: adrId,
      Action: action,
      Timestamp: new Date().toISOString(),
      Status: status,
      Author: author,
    };
    const result = await appendAudit(entry);
    if (!result.ok) {
      return NextResponse.json({ ...entry, accepted: false, error: result.error }, { status: 503 });
    }
    return NextResponse.json({ ...entry, accepted: true, file: result.file }, { status: 201 });
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
}