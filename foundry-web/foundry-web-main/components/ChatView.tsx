'use client';

import React, { useState } from 'react';
import { ResearchPaper, ChatMessage, ChatGroup } from '@/types/research';
import { INITIAL_GROUPS, INITIAL_MESSAGES } from '@/lib/mock-data';
import { MessageSquareText, Send, Sparkles, User, Bot, Plus, Users, Hash, ShieldCheck } from 'lucide-react';

interface ChatViewProps {
  papers: ResearchPaper[];
}

export default function ChatView({ papers }: ChatViewProps) {
  const [groups, setGroups] = useState<ChatGroup[]>(INITIAL_GROUPS);
  const [activeGroupId, setActiveGroupId] = useState<string>(INITIAL_GROUPS[0].id);
  const [messages, setMessages] = useState<ChatMessage[]>(INITIAL_MESSAGES);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);

  // New Group Modal state
  const [isNewGroupOpen, setIsNewGroupOpen] = useState(false);
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupDesc, setNewGroupDesc] = useState('');

  const activeGroup = groups.find(g => g.id === activeGroupId) || groups[0];
  const activeMessages = messages.filter(m => m.groupId === activeGroupId);

  const handleCreateGroup = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;

    const newGroup: ChatGroup = {
      id: `grp-${Date.now()}`,
      name: newGroupName,
      description: newGroupDesc || 'Custom research discussion group.',
      membersCount: 1
    };

    setGroups(prev => [...prev, newGroup]);
    setActiveGroupId(newGroup.id);
    setIsNewGroupOpen(false);
    setNewGroupName('');
    setNewGroupDesc('');
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      groupId: activeGroupId,
      senderName: 'Dr. Eleanor Vance',
      senderAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      role: 'user',
      content: input,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    const updatedMessages = [...messages, userMsg];
    setMessages(updatedMessages);
    setInput('');
    setLoading(true);

    try {
      // If message mentions AI or is in AI group, get AI reply
      const res = await fetch('/api/research/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: updatedMessages, papers })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to get chat response');

      const assistantMsg: ChatMessage = {
        id: `msg-${Date.now() + 1}`,
        groupId: activeGroupId,
        senderName: 'ResearchLM Prism AI',
        senderAvatar: '',
        role: 'assistant',
        content: data.reply,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };

      setMessages([...updatedMessages, assistantMsg]);
    } catch (err: any) {
      const errorMsg: ChatMessage = {
        id: `msg-${Date.now() + 1}`,
        groupId: activeGroupId,
        senderName: 'System Bot',
        senderAvatar: '',
        role: 'assistant',
        content: `Error communicating with Gemini AI: ${err.message}`,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      setMessages([...updatedMessages, errorMsg]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-7xl mx-auto h-[calc(100vh-8rem)] flex flex-col md:flex-row gap-6 pb-6">
      
      {/* Left Sidebar: Chat Groups */}
      <div className="w-full md:w-80 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-4 flex flex-col shrink-0 shadow-sm">
        <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center space-x-2">
            <Users className="w-5 h-5 text-indigo-600" />
            <h2 className="font-bold text-slate-900 dark:text-white text-base">Chat Groups</h2>
          </div>
          <button
            onClick={() => setIsNewGroupOpen(true)}
            className="p-1.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 transition"
            title="Create New Group"
          >
            <Plus className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto space-y-2 pr-1">
          {groups.map(group => {
            const isActive = group.id === activeGroupId;
            return (
              <button
                key={group.id}
                onClick={() => setActiveGroupId(group.id)}
                className={`w-full text-left p-3 rounded-xl transition flex items-start space-x-3 ${
                  isActive
                    ? 'bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-900 text-indigo-900 dark:text-indigo-200 shadow-xs'
                    : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300'
                }`}
              >
                <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${
                  isActive ? 'bg-indigo-600 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'
                }`}>
                  <Hash className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-0.5">
                    <h4 className="font-semibold text-sm truncate">{group.name}</h4>
                    <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-mono">
                      {group.membersCount}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{group.description}</p>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Main Chat Room */}
      <div className="flex-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl flex flex-col overflow-hidden shadow-sm">
        
        {/* Chat Room Header */}
        <div className="p-4 sm:p-5 border-b border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 flex items-center justify-between">
          <div>
            <div className="flex items-center space-x-2">
              <Hash className="w-5 h-5 text-indigo-600" />
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">{activeGroup.name}</h2>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">{activeGroup.description} • {activeGroup.membersCount} active researchers</p>
          </div>
          <div className="flex items-center space-x-2 text-xs text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/50 px-3 py-1 rounded-full border border-emerald-200 dark:border-emerald-900">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Encrypted Room</span>
          </div>
        </div>

        {/* Messages Stream */}
        <div className="flex-1 p-6 overflow-y-auto space-y-5">
          {activeMessages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center text-slate-400">
              <MessageSquareText className="w-12 h-12 mb-2 opacity-40" />
              <p>No messages in this group yet. Start the conversation below!</p>
            </div>
          ) : (
            activeMessages.map((msg) => {
              const isUser = msg.role === 'user';
              const isAi = msg.role === 'assistant';
              return (
                <div key={msg.id} className={`flex items-start space-x-3 ${isUser ? 'flex-row-reverse space-x-reverse' : ''}`}>
                  {msg.senderAvatar ? (
                    <img src={msg.senderAvatar} alt={msg.senderName} referrerPolicy="no-referrer" className="w-9 h-9 rounded-xl object-cover shrink-0 shadow-sm" />
                  ) : (
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 shadow-sm ${
                      isAi ? 'bg-indigo-600 text-white' : 'bg-slate-700 text-white'
                    }`}>
                      {isAi ? <Bot className="w-5 h-5" /> : <User className="w-5 h-5" />}
                    </div>
                  )}

                  <div className={`max-w-xl space-y-1 ${isUser ? 'items-end' : 'items-start'}`}>
                    <div className={`flex items-center space-x-2 text-xs text-slate-500 ${isUser ? 'justify-end' : ''}`}>
                      <span className="font-semibold text-slate-700 dark:text-slate-300">{msg.senderName}</span>
                      <span>•</span>
                      <span>{msg.timestamp}</span>
                    </div>

                    <div className={`p-4 rounded-2xl text-sm leading-relaxed ${
                      isUser
                        ? 'bg-indigo-600 text-white rounded-tr-none shadow-sm'
                        : isAi
                        ? 'bg-violet-50 dark:bg-violet-950/40 border border-violet-200 dark:border-violet-900 text-slate-800 dark:text-slate-200 rounded-tl-none'
                        : 'bg-slate-50 dark:bg-slate-800 text-slate-800 dark:text-slate-200 rounded-tl-none border border-slate-200 dark:border-slate-700'
                    }`}>
                      {msg.content}
                    </div>
                  </div>
                </div>
              );
            })
          )}
          {loading && (
            <div className="flex items-center space-x-3 text-slate-400 italic text-sm animate-pulse">
              <Bot className="w-5 h-5 text-indigo-500" />
              <span>ResearchLM is formulating synthesis...</span>
            </div>
          )}
        </div>

        {/* Message Input Form */}
        <form onSubmit={handleSend} className="p-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 flex items-center space-x-3">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder={`Message #${activeGroup.name} (Ask AI or group peers)...`}
            className="flex-1 px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-xs"
          />
          <button
            type="submit"
            disabled={loading || !input.trim()}
            className="px-5 py-3 rounded-xl bg-indigo-600 text-white font-semibold text-sm hover:bg-indigo-700 transition disabled:opacity-50 shadow-sm flex items-center space-x-2 shrink-0"
          >
            <span>Send</span>
            <Send className="w-4 h-4" />
          </button>
        </form>

      </div>

      {/* New Group Modal */}
      {isNewGroupOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Create New Chat Group</h3>
            <form onSubmit={handleCreateGroup} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Group Name</label>
                <input
                  type="text"
                  required
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  placeholder="e.g., Quantum Computing & QPU"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Description</label>
                <textarea
                  rows={2}
                  value={newGroupDesc}
                  onChange={(e) => setNewGroupDesc(e.target.value)}
                  placeholder="What is the focus of this group?"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                />
              </div>
              <div className="flex justify-end space-x-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsNewGroupOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm"
                >
                  Create Group
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
