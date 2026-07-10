import { ModelSelector } from './ModelSelector';
import { Model } from '../lib/tauri';

interface HeaderProps {
  models: Model[];
  selectedModel: string | null;
  onModelSelect: (model: string) => void;
  isLoading: boolean;
  onThemeToggle: () => void;
  theme: 'light' | 'dark';
  onViewChange: (view: 'chat' | 'stability' | 'pirtm') => void;
  currentView: 'chat' | 'stability' | 'pirtm';
}

export function Header({
  models,
  selectedModel,
  onModelSelect,
  isLoading,
  onThemeToggle,
  theme,
  onViewChange,
  currentView,
}: HeaderProps) {
  return (
    <header className="flex items-center justify-between border-b border-border px-4 py-3">
      <div className="flex items-center gap-3">
        <HologramIcon />
        <div className="flex bg-muted rounded-lg p-1 mr-4">
          <button
            onClick={() => onViewChange('chat')}
            className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
              currentView === 'chat'
                ? 'bg-surface text-foreground shadow-sm'
                : 'text-foreground-muted hover:text-foreground'
            }`}
          >
            Chat
          </button>
          <button
            onClick={() => onViewChange('stability')}
            className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
              currentView === 'stability'
                ? 'bg-surface text-foreground shadow-sm'
                : 'text-foreground-muted hover:text-foreground'
            }`}
          >
            Stability
          </button>
          <button
            onClick={() => onViewChange('pirtm')}
            className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
              currentView === 'pirtm'
                ? 'bg-surface text-foreground shadow-sm'
                : 'text-foreground-muted hover:text-foreground'
            }`}
          >
            PIRTM
          </button>
        </div>
        <ModelSelector
          models={models}
          selected={selectedModel}
          onSelect={onModelSelect}
          isLoading={isLoading}
        />
      </div>
      <button
        onClick={onThemeToggle}
        className="rounded-lg p-2 text-foreground-muted hover:bg-muted hover:text-foreground"
        title={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
      >
        {theme === 'light' ? <MoonIcon /> : <SunIcon />}
      </button>
    </header>
  );
}

function HologramIcon() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 24 24"
      fill="none"
      className="text-foreground"
    >
      <path
        d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"
        fill="currentColor"
      />
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
    </svg>
  );
}

function SunIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="12" r="5" />
      <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
    </svg>
  );
}
