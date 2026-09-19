'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import PrismTesseractLogo from '@/components/PrismTesseractLogo';
import LoginModal from '@/components/LoginModal';
import { 
  BookOpen, 
  Sparkles, 
  MessageSquareText, 
  FileText, 
  Network, 
  FolderKanban,
  Hammer,
  ChevronLeft,
  ChevronRight,
  User as UserIcon,
  ShieldCheck,
  LogIn,
  Compass,
  Code2,
  FileBadge
} from 'lucide-react';

interface SidebarNavProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  projectsCount: number;
  papersCount: number;
  isCollapsed?: boolean;
  setIsCollapsed?: (collapsed: boolean) => void;
}

interface UserProfile {
  name: string;
  email: string;
  avatar: string;
}

export default function SidebarNav({ 
  activeTab, 
  setActiveTab, 
  projectsCount, 
  papersCount,
  isCollapsed: propIsCollapsed,
  setIsCollapsed: propSetIsCollapsed
}: SidebarNavProps) {
  const [localCollapsed, setLocalCollapsed] = useState(false);
  const isCollapsed = propIsCollapsed !== undefined ? propIsCollapsed : localCollapsed;
  const setIsCollapsed = propSetIsCollapsed || setLocalCollapsed;

  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState<UserProfile | null>({
    name: 'Dr. Eleanor Vance',
    email: 'eleanor.vance@foundry-uor.org',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  });

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: Code2 },
    { id: 'projects', label: 'Projects', icon: FolderKanban },
    { id: 'literature', label: 'Documents', icon: BookOpen, badge: papersCount },
    { id: 'synthesis', label: 'AI Synthesis', icon: Sparkles },
    { id: 'chat', label: 'Prism Chat', icon: MessageSquareText },
    { id: 'report', label: 'Draft Generator', icon: FileText },
    { id: 'forge', label: 'Prism Forge', icon: Hammer },
    { id: 'certify', label: 'Certify', icon: ShieldCheck },
    { id: 'uor', label: 'UOR Registry', icon: Network },
    { id: 'training', label: 'Training', icon: Compass },
    { id: 'adr', label: 'ADR Registry', icon: FileBadge },
  ];

  return (
    <>
      <aside 
        className={`fixed top-0 left-0 h-screen bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 transition-all duration-300 z-50 flex flex-col justify-between shadow-lg ${
          isCollapsed ? 'w-20' : 'w-72'
        }`}
      >
        {/* Divider Actuator Handle on the right border */}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="absolute -right-3.5 top-1/2 -translate-y-1/2 w-7 h-7 rounded-full bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-950 dark:hover:text-indigo-400 flex items-center justify-center shadow-md transition-all z-50 group"
          title={isCollapsed ? "Expand Sidebar" : "Collapse Sidebar"}
        >
          {isCollapsed ? (
            <ChevronRight className="w-4 h-4 transition-transform group-hover:scale-110" />
          ) : (
            <ChevronLeft className="w-4 h-4 transition-transform group-hover:scale-110" />
          )}
        </button>

        <div>
          {/* Top Branding Header */}
          <div className="p-4 flex items-center justify-between border-b border-slate-100 dark:border-slate-800">
            <div className="flex items-center space-x-3 cursor-pointer overflow-hidden" onClick={() => setActiveTab('dashboard')}>
              <div className="shrink-0">
                <PrismTesseractLogo className="w-10 h-10" />
              </div>
              {!isCollapsed && (
                <div className="truncate">
                  <h1 className="font-bold text-base text-slate-900 dark:text-white tracking-tight leading-tight">The Foundry</h1>
                  <p className="text-[11px] text-indigo-600 dark:text-indigo-400 font-medium">UOR Foundation</p>
                </div>
              )}
            </div>
          </div>

          {/* Navigation Items */}
          <nav className="p-3 space-y-1.5">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  title={isCollapsed ? item.label : undefined}
                  className={`w-full flex items-center space-x-3 px-3.5 py-3 rounded-xl text-sm font-medium transition-all duration-150 ${
                    isActive
                      ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300 shadow-sm border border-indigo-200/60 dark:border-indigo-800/60'
                      : 'text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/80'
                  }`}
                >
                  <Icon className={`w-5 h-5 shrink-0 ${isActive ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-400 dark:text-slate-500'}`} />
                  {!isCollapsed && (
                    <span className="truncate flex-1 text-left">{item.label}</span>
                  )}
                  {!isCollapsed && item.badge !== undefined && item.badge > 0 && (
                    <span className={`px-2 py-0.5 text-xs rounded-full font-medium ${
                      isActive ? 'bg-indigo-200/60 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200' : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
                    }`}>
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Footer / User Profile */}
        <div className="p-4 border-t border-slate-100 dark:border-slate-800">
          {/* User Profile Button */}
          <button
            onClick={() => setIsLoginOpen(true)}
            title={isCollapsed ? (currentUser ? currentUser.name : "Sign In") : undefined}
            className={`w-full flex items-center space-x-3 p-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/80 dark:bg-slate-800/60 hover:bg-slate-100 dark:hover:bg-slate-800 transition text-left group`}
          >
            {currentUser ? (
              <div className="relative w-9 h-9 rounded-full overflow-hidden shrink-0 border border-indigo-500/40">
                <Image
                  src={currentUser.avatar}
                  alt={currentUser.name}
                  fill
                  sizes="36px"
                  className="object-cover"
                  referrerPolicy="no-referrer"
                />
              </div>
            ) : (
              <div className="w-9 h-9 rounded-full bg-indigo-100 dark:bg-indigo-950 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                <UserIcon className="w-5 h-5" />
              </div>
            )}

            {!isCollapsed && (
              <div className="truncate flex-1">
                <p className="text-xs font-semibold text-slate-900 dark:text-white truncate">
                  {currentUser ? currentUser.name : 'Sign In'}
                </p>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 truncate">
                  {currentUser ? currentUser.email : 'Google Workspace'}
                </p>
              </div>
            )}
          </button>
        </div>
      </aside>

      <LoginModal
        isOpen={isLoginOpen}
        onClose={() => setIsLoginOpen(false)}
        currentUser={currentUser}
        onLogin={(user) => setCurrentUser(user)}
        onLogout={() => setCurrentUser(null)}
      />
    </>
  );
}
