import { NextRequest, NextResponse } from 'next/server';
import { ADR, ADRStatus } from '@/lib/adr-types';

export async function POST(req: NextRequest) {
  try {
    const { adrId, fromStatus, toStatus, supersedes } = await req.json();
    if (!adrId || !fromStatus || !toStatus) {
      return NextResponse.json({ error: 'adrId, fromStatus, and toStatus are required' }, { status: 400 });
    }
    const validTransitions: Record<ADRStatus, ADRStatus[]> = {
      Proposed: ['Accepted', 'Deprecated'],
      Accepted: ['Superseded', 'Deprecated'],
      Deprecated: [],
      Superseded: [],
    };
    const allowed = validTransitions[fromStatus] ?? [];
    if (!allowed.includes(toStatus)) {
      return NextResponse.json({
        valid: false,
        reason: `Transition ${fromStatus} → ${toStatus} is forbidden. Allowed: ${allowed.join(', ') || 'none'}`,
      });
    }
    if (fromStatus === 'Accepted' && toStatus === 'Superseded' && !supersedes) {
      return NextResponse.json({
        valid: false,
        reason: 'Accepted ADR must specify a successor ID when superseding',
      });
    }
    return NextResponse.json({ valid: true });
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
}
