import { NextRequest, NextResponse } from 'next/server';
import { readEngineRegistry, writeProposal } from '@/lib/engine-bridge';
import { ADR, ADRRegistry } from '@/lib/adr-types';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * ADR collection, wired to the UCC engine.
 *
 * GET returns the machine-checked registry (bare `ADR[]`, as the portal's
 * `fetchADRs` expects). POST routes a new proposal into the engine's `docs/adr/
 * proposed/` inbox and returns the created record plus its inbox path; when the
 * engine is read-only or unreachable it answers `accepted: false` so the client
 * can surface the boundary, per the portal's "no vendor fallback" contract.
 */
export async function GET() {
  const { adrs } = await readEngineRegistry();
  return NextResponse.json(adrs);
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as Partial<ADR>;
    const { id, title, context, decision, consequences, supersedes, links } = body;
    if (!id || !title || !decision) {
      return NextResponse.json({ error: 'id, title, and decision are required' }, { status: 400 });
    }
    const proposal: ADR = {
      id,
      title,
      status: body.status ?? 'Proposed',
      context: context ?? '',
      decision,
      consequences: consequences ?? [],
      supersedes: supersedes ?? null,
      links: links ?? [],
    };
    if (proposal.status !== 'Proposed') {
      return NextResponse.json(
        { error: 'new records enter the engine as Proposed; status transitions are gate-enforced' },
        { status: 422 },
      );
    }
    const inbox = await writeProposal(proposal);
    if (!inbox.ok) {
      return NextResponse.json(
        { error: `proposal inbox refused: ${inbox.error}`, accepted: false, proposal },
        { status: 503 },
      );
    }
    return NextResponse.json({ accepted: true, inbox: inbox.file, proposal }, { status: 201 });
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }
}