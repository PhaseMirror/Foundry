import { GoogleGenAI } from '@google/genai';
import { NextRequest, NextResponse } from 'next/server';
import { ALL_FOUNDRY_ADRS } from '@/lib/adr-data';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const FOUNDRY_CONTEXT = ALL_FOUNDRY_ADRS.filter(a => a.status === 'Accepted').map(a =>
  `[ADR ${a.id}] ${a.title}: ${a.decision}`).join('\n');

export async function POST(req: NextRequest) {
  try {
    const { messages, papers } = await req.json();

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: 'Messages array is required' }, { status: 400 });
    }

    const papersContext = papers && papers.length > 0
      ? papers.map((p: any) => `[ID: ${p.id}] Title: "${p.title}" (${p.year}) by ${p.authors.join(', ')}. Abstract: ${p.abstract}`).join('\n\n')
      : 'No papers provided.';

    const systemInstruction = `You are ResearchLM, an expert academic research assistant operating under PrismPM and Universal Object Reference (UOR) principles. 
You answer research questions accurately, critically analyze literature, and cite specific papers from the provided context using their titles or IDs. Maintain a scholarly, precise tone.

FOUNDRY MACHINERY GOVERNANCE CONTEXT (accepted ADRs):
${FOUNDRY_CONTEXT}

CONTEXT PAPERS:
${papersContext}`;

    const formattedMessages = messages.map((m: any) => ({
      role: m.role === 'user' ? 'user' : 'model',
      parts: [{ text: m.content }]
    }));

    const chatSession = ai.chats.create({
      model: 'gemini-2.5-flash',
      config: {
        systemInstruction,
      },
      history: formattedMessages.slice(0, -1)
    });

    const lastMessage = formattedMessages[formattedMessages.length - 1].parts[0].text;
    const result = await chatSession.sendMessage({ message: lastMessage });

    return NextResponse.json({ success: true, reply: result.text });
  } catch (error: any) {
    console.error('Chat error:', error);
    return NextResponse.json({ error: error.message || 'Internal server error' }, { status: 500 });
  }
}
