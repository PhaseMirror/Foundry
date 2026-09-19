'use client';

import React, { useState, useEffect } from 'react';
import { INITIAL_PROJECTS, INITIAL_PAPERS, INITIAL_GROUPS } from '@/lib/mock-data';
import { ResearchProject, ResearchPaper, ChatGroup } from '@/types/research';
import { ADR } from '@/lib/adr-types';
import { fetchADRs } from '@/lib/foundry-service';
import Navbar from '@/components/Navbar';
import Header from '@/components/Header';
import DashboardView from '@/components/DashboardView';
import DashboardIdeView from '@/components/DashboardIdeView';
import ForgeView from '@/components/ForgeView';
import LiteratureView from '@/components/LiteratureView';
import SynthesisView from '@/components/SynthesisView';
import ChatView from '@/components/ChatView';
import ReportGeneratorView from '@/components/ReportGeneratorView';
import UorRegistryView from '@/components/UorRegistryView';
import CertifyView from '@/components/CertifyView';
import TrainingView from '@/components/TrainingView';
import ADRView from '@/components/ADRView';
import FoundryStatusBadge from '@/components/FoundryStatusBadge';

export default function Home() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [projects, setProjects] = useState<ResearchProject[]>(INITIAL_PROJECTS);
  const [papers, setPapers] = useState<ResearchPaper[]>(INITIAL_PAPERS);
  const [groups, setGroups] = useState<ChatGroup[]>(INITIAL_GROUPS);
  const [searchQuery, setSearchQuery] = useState('');
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [adrs, setADRs] = useState<ADR[]>([]);
  const [adrLoading, setAdrLoading] = useState(true);

  useEffect(() => {
    fetchADRs()
      .then(data => { setADRs(data); setAdrLoading(false); })
      .catch(() => { setAdrLoading(false); });
  }, []);

  const handleAddPaper = (newPaper: ResearchPaper) => {
    setPapers(prev => [newPaper, ...prev]);
    setProjects(prev => prev.map(proj => {
      if (proj.id === newPaper.projectId) {
        return { ...proj, papersCount: proj.papersCount + 1 };
      }
      return proj;
    }));
  };

  const handleAddProject = (newProj: ResearchProject) => {
    setProjects(prev => [newProj, ...prev]);
  };

  const handleSelectProject = (projId: string) => {
    setActiveTab('literature');
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex font-sans">
      <Navbar 
        activeTab={activeTab} 
        setActiveTab={setActiveTab} 
        projectsCount={projects.length} 
        papersCount={papers.length}
        isCollapsed={isCollapsed}
        setIsCollapsed={setIsCollapsed}
      />

      <div className={`flex-1 transition-all duration-300 flex flex-col min-h-screen ${isCollapsed ? 'ml-20' : 'ml-72'}`}>
        {activeTab !== 'dashboard' && <Header searchQuery={searchQuery} setSearchQuery={setSearchQuery} />}

        <main className={`flex-1 flex flex-col ${activeTab === 'dashboard' ? 'p-0 h-screen overflow-hidden' : 'max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8'}`}>
          {activeTab === 'dashboard' && (
            <>
              <div className="flex items-center justify-between px-4 sm:px-6 lg:px-8 py-4 border-b border-slate-200 dark:border-slate-800">
                <FoundryStatusBadge showLabel={true} />
                {adrLoading && (
                  <span className="text-xs text-slate-400">Loading Foundry ADRs…</span>
                )}
              </div>
              <DashboardIdeView />
              {!adrLoading && adrs.length > 0 && (
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                  <ADRView initialADRs={adrs} showActions={false} />
                </div>
              )}
            </>
          )}
          {activeTab === 'projects' && (
            <DashboardView 
              projects={projects} 
              papers={papers}
              groups={groups}
              setActiveTab={setActiveTab} 
              onSelectProject={handleSelectProject}
              onAddProject={handleAddProject}
            />
          )}
          {activeTab === 'forge' && (
            <ForgeView />
          )}
          {activeTab === 'literature' && (
            <LiteratureView 
              papers={papers} 
              projects={projects} 
              onAddPaper={handleAddPaper}
              initialSearchQuery={searchQuery}
            />
          )}
          {activeTab === 'synthesis' && (
            <SynthesisView papers={papers} />
          )}
          {activeTab === 'chat' && (
            <ChatView papers={papers} />
          )}
          {activeTab === 'report' && (
            <ReportGeneratorView papers={papers} />
          )}
          {activeTab === 'certify' && (
            <CertifyView />
          )}
          {activeTab === 'adr' && (
            <ADRView showActions={true} />
          )}
          {activeTab === 'uor' && (
            <UorRegistryView projects={projects} papers={papers} />
          )}
          {activeTab === 'training' && (
            <TrainingView />
          )}
        </main>
      </div>
    </div>
  );
}
