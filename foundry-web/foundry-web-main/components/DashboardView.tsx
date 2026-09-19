'use client';

import React, { useState } from 'react';
import PrismTesseractLogo from '@/components/PrismTesseractLogo';
import { ResearchProject, ResearchPaper, ChatGroup } from '@/types/research';
import { 
  BookOpen, 
  Sparkles, 
  Network, 
  FileText, 
  ArrowUpRight, 
  Plus, 
  FolderKanban, 
  Cpu,
  Layers,
  CheckCircle2,
  Clock,
  Users,
  Hash
} from 'lucide-react';

interface DashboardViewProps {
  projects: ResearchProject[];
  papers: ResearchPaper[];
  groups: ChatGroup[];
  setActiveTab: (tab: string) => void;
  onSelectProject: (projId: string) => void;
  onAddProject: (project: ResearchProject) => void;
}

export default function DashboardView({ 
  projects, 
  papers, 
  groups, 
  setActiveTab, 
  onSelectProject, 
  onAddProject 
}: DashboardViewProps) {
  const [selectedGroupFilter, setSelectedGroupFilter] = useState<string>('all');
  const [isNewProjectOpen, setIsNewProjectOpen] = useState(false);

  // New Project form state
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newDomain, setNewDomain] = useState('Artificial Intelligence');
  const [newGroupId, setNewGroupId] = useState(groups[0]?.id || 'grp-1');
  const [newTags, setNewTags] = useState('AI, Research');

  const filteredProjects = projects.filter(p => {
    if (selectedGroupFilter === 'all') return true;
    return p.groupId === selectedGroupFilter;
  });

  const handleCreateProject = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    const groupObj = groups.find(g => g.id === newGroupId);

    const project: ResearchProject = {
      id: `proj-${Date.now()}`,
      title: newTitle,
      description: newDesc || 'Autonomous research project tracked under UOR registry.',
      domain: newDomain,
      uorHash: `uor:ref:prism:${newDomain.toLowerCase().replace(/\s+/g, '-')}:${Date.now()}`,
      createdAt: new Date().toISOString().split('T')[0],
      papersCount: 0,
      tags: newTags.split(',').map(t => t.trim()).filter(Boolean),
      groupId: newGroupId,
      groupName: groupObj ? groupObj.name : 'General Research'
    };

    onAddProject(project);
    setIsNewProjectOpen(false);
    setNewTitle('');
    setNewDesc('');
    setNewTags('');
  };

  return (
    <div className="space-y-8 pb-12">
      
      {/* Hero Banner */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-indigo-900 via-violet-900 to-slate-900 text-white p-8 sm:p-10 shadow-xl">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(99,102,241,0.25),transparent_50%)]"></div>
        <div className="relative z-10 max-w-3xl flex flex-col md:flex-row items-start md:items-center gap-6">
          <div className="shrink-0 p-3 rounded-2xl bg-indigo-500/20 border border-indigo-400/30 backdrop-blur-md">
            <PrismTesseractLogo className="w-16 h-16" />
          </div>
          <div>
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-indigo-500/30 text-indigo-200 text-xs font-semibold mb-3 backdrop-blur-md border border-indigo-400/20">
              <Cpu className="w-3.5 h-3.5" />
              <span>The Foundry • UOR Foundation</span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white mb-2">
              Autonomous Academic Research & Group Management
            </h1>
            <p className="text-indigo-200 text-base sm:text-lg mb-6 leading-relaxed">
              Organize research domains with Universal Object References (UOR), assign projects to research chat groups, and synthesize literature with Gemini AI.
            </p>
            <div className="flex flex-wrap gap-3">
              <button
                onClick={() => setIsNewProjectOpen(true)}
                className="px-5 py-2.5 rounded-xl bg-white text-indigo-950 font-semibold text-sm hover:bg-indigo-50 transition shadow-lg flex items-center space-x-2"
              >
                <Plus className="w-4 h-4 text-indigo-600" />
                <span>New Project & Group Assignment</span>
              </button>
              <button
                onClick={() => setActiveTab('chat')}
                className="px-5 py-2.5 rounded-xl bg-indigo-800/60 text-white font-semibold text-sm hover:bg-indigo-700/60 transition backdrop-blur-md border border-indigo-600/40 flex items-center space-x-2"
              >
                <Users className="w-4 h-4" />
                <span>Open Chat Rooms</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">Managed Projects</span>
            <div className="p-2 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400">
              <FolderKanban className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-slate-900 dark:text-white">{projects.length}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Group-assigned research initiatives</p>
        </div>

        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">Active Chat Groups</span>
            <div className="p-2 rounded-xl bg-violet-50 dark:bg-violet-950/50 text-violet-600 dark:text-violet-400">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-slate-900 dark:text-white">{groups.length}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Peer & AI channels</p>
        </div>

        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">Indexed Papers</span>
            <div className="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400">
              <BookOpen className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-slate-900 dark:text-white">{papers.length}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">UOR cryptographic references</p>
        </div>
      </div>

      {/* Projects with Group Filter & Management */}
      <div className="space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold text-slate-900 dark:text-white tracking-tight">Research Projects & Group Assignments</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">Manage initiatives assigned to specific chat groups.</p>
          </div>
          <div className="flex items-center space-x-3">
            <select
              value={selectedGroupFilter}
              onChange={(e) => setSelectedGroupFilter(e.target.value)}
              className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-sm"
            >
              <option value="all">All Chat Groups ({projects.length})</option>
              {groups.map(g => (
                <option key={g.id} value={g.id}>{g.name}</option>
              ))}
            </select>
            <button
              onClick={() => setIsNewProjectOpen(true)}
              className="inline-flex items-center space-x-2 px-4 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold text-sm hover:bg-indigo-700 transition shadow-sm shrink-0"
            >
              <Plus className="w-4 h-4" />
              <span>New Project</span>
            </button>
          </div>
        </div>

        {/* Projects Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {filteredProjects.map((project) => {
            return (
              <div 
                key={project.id}
                className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm hover:border-indigo-500 transition flex flex-col justify-between"
              >
                <div className="space-y-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400 font-semibold block mb-1">
                        {project.uorHash}
                      </span>
                      <h3 className="text-lg font-bold text-slate-900 dark:text-white">
                        {project.title}
                      </h3>
                    </div>
                    {project.groupName && (
                      <span className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-violet-100 dark:bg-violet-950/60 text-violet-700 dark:text-violet-300 border border-violet-200 dark:border-violet-900 shrink-0">
                        <Hash className="w-3 h-3" />
                        <span>{project.groupName}</span>
                      </span>
                    )}
                  </div>

                  <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                    {project.description}
                  </p>

                  <div className="flex flex-wrap gap-1.5">
                    {project.tags.map(tag => (
                      <span key={tag} className="text-xs px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 font-medium">
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="pt-5 mt-6 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between text-xs text-slate-500">
                  <span>Created {project.createdAt}</span>
                  <button
                    onClick={() => onSelectProject(project.id)}
                    className="inline-flex items-center space-x-1 text-indigo-600 dark:text-indigo-400 font-semibold hover:underline"
                  >
                    <span>View Literature ({project.papersCount})</span>
                    <ArrowUpRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* New Project & Group Assignment Modal */}
      {isNewProjectOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 max-w-lg w-full p-6 shadow-2xl space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Create Project & Assign Group</h3>
              <button onClick={() => setIsNewProjectOpen(false)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>

            <form onSubmit={handleCreateProject} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Project Title</label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="e.g., Quantum Error Correction & Memory"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Assign to Chat Group</label>
                <select
                  value={newGroupId}
                  onChange={(e) => setNewGroupId(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                >
                  {groups.map(g => (
                    <option key={g.id} value={g.id}>{g.name} ({g.membersCount} members)</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Domain</label>
                  <input
                    type="text"
                    value={newDomain}
                    onChange={(e) => setNewDomain(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Tags (comma separated)</label>
                  <input
                    type="text"
                    value={newTags}
                    onChange={(e) => setNewTags(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Description</label>
                <textarea
                  rows={3}
                  value={newDesc}
                  onChange={(e) => setNewDesc(e.target.value)}
                  placeholder="Describe the research scope..."
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsNewProjectOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm"
                >
                  Create Project & Assign Group
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
