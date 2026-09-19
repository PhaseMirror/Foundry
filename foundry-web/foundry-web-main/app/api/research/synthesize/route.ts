import { GoogleGenAI } from '@google/genai';
import { NextRequest, NextResponse } from 'next/server';
import { ALL_FOUNDRY_ADRS } from '@/lib/adr-data';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const FOUNDRY_CONTEXT = ALL_FOUNDRY_ADRS.filter(a => a.status === 'Accepted').map(a =>
  `[ADR ${a.id}] ${a.title}: ${a.decision}`).join('\n');

export async function POST(req: NextRequest) {
  try {
    const { topic, papers } = await req.json();

    if (!topic) {
      return NextResponse.json({ error: 'Research topic is required' }, { status: 400 });
    }

    const papersContext = papers && papers.length > 0 
      ? papers.map((p: any) => `- ${p.title} (${p.year}) by ${p.authors.join(', ')}: ${p.abstract}`).join('\n')
      : 'No specific local papers provided. Use general scholarly knowledge.';

    const prompt = `You are ResearchLM, an expert AI academic research assistant built on PrismPM and Universal Object Reference (UOR) principles.
You are operating under Foundry machinery governance. The following Architecture Decision Records are currently accepted and govern the system:

FOUNDRY GOVERNANCE:
${FOUNDRY_CONTEXT}

Please conduct a rigorous literature synthesis and evidence mapping on the following research topic:

TOPIC: "${topic}"

AVAILABLE LITERATURE / PAPERS:
${papersContext}

Please return your response in strict JSON format with the following keys:
{
  "overview": "A comprehensive academic overview and synthesis of the research topic (3-4 paragraphs).",
  "keyThemes": [
    {
      "theme": "Name of theme",
      "description": "Detailed breakdown of this research theme.",
      "papers": ["Relevant paper titles or authors"]
    }
  ],
  "methodologies": ["List of dominant research methods or frameworks used in this domain"],
  "researchGaps": ["Identified open questions or unexplored areas in current literature"],
  "futureDirections": ["Recommended directions for future research"]
}

Ensure the output is valid JSON only, without markdown wrapping or code blocks if possible, or inside standard JSON format.`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });

    const text = response.text || '{}';
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      // Fallback clean if markdown formatted
      const cleaned = text.replace(/```json/g, '').replace(/```/g, '').trim();
      data = JSON.parse(cleaned);
    }

    return NextResponse.json({ success: true, synthesis: data });
  } catch (error: any) {
    console.error('Synthesis error:', error);
    return NextResponse.json({ error: error.message || 'Internal server error' }, { status: 500 });
  }
}
