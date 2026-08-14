import { useState } from 'react';
import { useModels } from './hooks/useModels';
import { useTheme } from './hooks/useTheme';
import { Header } from './components/Header';
import { ChatContainer } from './components/ChatContainer';
import { StabilityDashboard } from './components/StabilityDashboard';
import { PirtmValidator } from './components/PirtmValidator';
import './index.css';

function App() {
  const { theme, toggleTheme } = useTheme();
  const { models, selectedModel, setSelectedModel, isLoading } = useModels();
  const [view, setView] = useState<'chat' | 'stability' | 'pirtm'>('chat');

  return (
    <div className="flex h-screen flex-col bg-surface text-foreground">
      <Header
        models={models}
        selectedModel={selectedModel}
        onModelSelect={setSelectedModel}
        isLoading={isLoading}
        onThemeToggle={toggleTheme}
        theme={theme}
        onViewChange={setView}
        currentView={view}
      />
      <main className="flex-1 overflow-hidden">
        {view === 'chat' ? (
          <ChatContainer selectedModel={selectedModel} />
        ) : view === 'stability' ? (
          <div className="h-full overflow-y-auto">
            <StabilityDashboard />
          </div>
        ) : (
          <div className="h-full overflow-y-auto">
            <PirtmValidator />
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
