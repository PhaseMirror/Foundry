import { ResearchProject, ResearchPaper, ChatGroup, ChatMessage } from '@/types/research';
import { ALL_FOUNDRY_ADRS, FOUNDRY_AUDIT_TRAIL } from '@/lib/adr-data';

export const INITIAL_GROUPS: ChatGroup[] = [
  { id: 'grp-1', name: 'General Research & Strategy', description: 'Cross-domain academic coordination and institutional alignment.', membersCount: 18 },
  { id: 'grp-2', name: 'Agentic LLM Architectures', description: 'Multi-agent frameworks, reasoning loops, and memory optimization.', membersCount: 12 },
  { id: 'grp-3', name: 'UOR Protocol & Semantic Web', description: 'Universal Object Reference cryptographic addressing and knowledge graphs.', membersCount: 9 },
  { id: 'grp-4', name: 'Peer Review & Attestation', description: 'Scholarly peer review, citations, and attestation receipts.', membersCount: 15 },
];

export const INITIAL_PROJECTS: ResearchProject[] = [
  {
    id: 'proj-1',
    title: 'Agentic LLM Architectures & Memory Systems',
    description: 'Investigating multi-agent coordination, long-term vector memory retrieval, and autonomous reasoning loops in large language models.',
    domain: 'Artificial Intelligence',
    uorHash: 'uor:ref:prism:ai:agentic-memory-v1',
    createdAt: '2026-01-15',
    papersCount: 4,
    tags: ['Agents', 'Memory', 'Reasoning', 'LLM'],
    groupId: 'grp-2',
    groupName: 'Agentic LLM Architectures'
  },
  {
    id: 'proj-2',
    title: 'Semantic Web & Universal Object References (UOR)',
    description: 'Decentralized knowledge representation graphs and content-derived immutable addressing for scholarly attribution.',
    domain: 'Knowledge Graphs',
    uorHash: 'uor:ref:prism:semantic:uor-core',
    createdAt: '2026-02-01',
    papersCount: 3,
    tags: ['UOR', 'Ontology', 'Semantic Web', 'Decentralized'],
    groupId: 'grp-3',
    groupName: 'UOR Protocol & Semantic Web'
  }
];

export const INITIAL_PAPERS: ResearchPaper[] = [
  {
    id: 'paper-1',
    projectId: 'proj-1',
    title: 'Reflexion: Language Agents with Verbal Reinforcement Learning',
    authors: ['Shinn, N.', 'Cassano, F.', 'Labash, B.', 'Hertzmann, A.', 'Patel, S.'],
    year: 2024,
    journal: 'NeurIPS / arXiv:2303.11366',
    abstract: 'We present Reflexion, a framework that equips language agents with dynamic memory and self-reflection to improve decision-making, coding, and reasoning tasks through trial and error feedback.',
    doi: '10.48550/arXiv.2303.11366',
    citationsCount: 1420,
    keyFindings: [
      'Introduces actor-evaluator-self-reflection loop.',
      'Achieves 91% pass rate on HumanEval coding benchmark.',
      'Significantly reduces hallucination propagation across multi-step execution.'
    ],
    uorRef: 'uor:obj:paper:reflexion-2024',
    userNotes: 'Fundamental architecture for our self-correcting prompt workflow in PrismPM.',
    aiSummary: 'Reflexion replaces standard zero-shot generation with an iterative loop where an evaluator critiques the LLM output and feeds episodic memory back into subsequent prompt iterations.'
  },
  {
    id: 'paper-2',
    projectId: 'proj-1',
    title: 'AutoGen: Enabling Next-Gen Multi-Agent Conversations',
    authors: ['Wu, Q.', 'Bashir, G.', 'Mishra, A.', 'Zhang, Y.'],
    year: 2024,
    journal: 'ICLR / arXiv:2308.08155',
    abstract: 'AutoGen is an open-source programming framework that enables the development of LLM applications using multiple autonomous agents that can converse with each other to solve complex tasks.',
    doi: '10.48550/arXiv.2308.08155',
    citationsCount: 2150,
    keyFindings: [
      'Multi-agent conversation abstraction simplifies complex orchestration.',
      'Supports customizable autonomous and human-in-the-loop workflows.',
      'Demonstrated high efficacy in automated coding and multi-step mathematics.'
    ],
    uorRef: 'uor:obj:paper:autogen-2024',
    userNotes: 'Useful reference for agent communication protocols.',
    aiSummary: 'AutoGen simplifies agent programming by modeling interactions as conversational messaging between specialized agents.'
  },
  {
    id: 'paper-3',
    projectId: 'proj-2',
    title: 'Universal Object Reference: A Computational Substrate for Open Science',
    authors: ['Foundation, U.', 'Al-Mansoor, K.', 'Vance, E.'],
    year: 2025,
    journal: 'Journal of Decentralized Computation',
    abstract: 'We introduce Universal Object Reference (UOR), a cryptographic and semantic coordinate system that assigns immutable content-derived addresses to all digital research artifacts.',
    doi: '10.1016/j.dec.2025.01.004',
    citationsCount: 310,
    keyFindings: [
      'Eliminates broken URL citations through cryptographic content hashing.',
      'Enables interoperable knowledge graphs without central authorities.',
      'Provides standard JSON-LD ontology for scientific assertions.'
    ],
    uorRef: 'uor:obj:paper:uor-substrate-2025',
    userNotes: 'Core theoretical foundation for PrismPM project management.',
    aiSummary: 'UOR solves scholarly link rot and verification challenges by binding scientific assertions directly to cryptographic content references.'
  }
];

export const INITIAL_MESSAGES: ChatMessage[] = [
  {
    id: 'msg-1',
    groupId: 'grp-1',
    senderName: 'Dr. Eleanor Vance',
    senderAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    role: 'user',
    content: 'Welcome to the general research strategy channel. Please coordinate milestone submissions here.',
    timestamp: '09:00 AM'
  },
  {
    id: 'msg-2',
    groupId: 'grp-2',
    senderName: 'Dr. Eleanor Vance',
    senderAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    role: 'user',
    content: 'Has everyone reviewed the Reflexion actor-evaluator memory loop paper? We should align our multi-agent protocol with its verification steps.',
    timestamp: '10:15 AM'
  },
  {
    id: 'msg-3',
    groupId: 'grp-2',
    senderName: 'ResearchLM Prism AI',
    senderAvatar: '',
    role: 'assistant',
    content: 'Analysis of Reflexion indicates a 91% pass rate on benchmark tasks through trial-and-error memory feedback. Would you like me to synthesize its core multi-agent takeaways for the project?',
    timestamp: '10:16 AM'
  },
  {
    id: 'msg-4',
    groupId: 'grp-3',
    senderName: 'Prof. Al-Mansoor',
    senderAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    role: 'peer',
    content: 'UOR cryptographic addressing is fully verified across the knowledge graph. All payload hashes are stable.',
    timestamp: '11:04 AM'
  }
];

export { ALL_FOUNDRY_ADRS, FOUNDRY_AUDIT_TRAIL };
