export interface ResearchProject {
  id: string;
  title: string;
  description: string;
  domain: string;
  uorHash: string;
  createdAt: string;
  papersCount: number;
  tags: string[];
  groupId?: string;
  groupName?: string;
}

export interface ResearchPaper {
  id: string;
  projectId: string;
  title: string;
  authors: string[];
  year: number;
  journal: string;
  abstract: string;
  doi?: string;
  citationsCount: number;
  keyFindings: string[];
  uorRef: string;
  pdfUrl?: string;
  userNotes?: string;
  aiSummary?: string;
}

export interface LiteratureSynthesis {
  id: string;
  topic: string;
  overview: string;
  keyThemes: { theme: string; description: string; papers: string[] }[];
  methodologies: string[];
  researchGaps: string[];
  futureDirections: string[];
  createdAt: string;
}

export interface ChatGroup {
  id: string;
  name: string;
  description: string;
  membersCount: number;
}

export interface ChatMessage {
  id: string;
  groupId: string;
  senderName: string;
  senderAvatar: string;
  role: 'user' | 'assistant' | 'peer';
  content: string;
  timestamp: string;
  citations?: string[];
}
