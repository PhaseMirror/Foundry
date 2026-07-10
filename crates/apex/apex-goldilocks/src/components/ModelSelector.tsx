import { useState, useRef, useEffect } from 'react';
import { Model } from '../lib/tauri';

interface ModelSelectorProps {
  models: Model[];
  selected: string | null;
  onSelect: (model: string) => void;
  isLoading: boolean;
}

export function ModelSelector({
  models,
  selected,
  onSelect,
  isLoading,
}: ModelSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const formatSize = (bytes: number): string => {
    const gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return `${gb.toFixed(1)} GB`;
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(1)} MB`;
  };

  return (
    <div ref={dropdownRef} className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 rounded-lg bg-muted px-3 py-1.5 text-sm text-foreground hover:bg-muted-hover"
      >
        <span>{selected || 'Select model'}</span>
        <ChevronDownIcon />
      </button>

      {isOpen && (
        <div className="absolute left-0 top-full z-10 mt-1 w-64 rounded-lg border border-border bg-surface shadow-lg">
          {isLoading ? (
            <div className="p-3 text-center text-sm text-muted-foreground">
              Loading models...
            </div>
          ) : models.length === 0 ? (
            <div className="p-3 text-center text-sm text-muted-foreground">
              No models available
              <p className="mt-1 text-xs">
                Pull a model with: holoapp pull owner/repo
              </p>
            </div>
          ) : (
            <ul className="max-h-60 overflow-y-auto py-1">
              {models.map((model) => (
                <li key={model.name}>
                  <button
                    onClick={() => {
                      onSelect(model.name);
                      setIsOpen(false);
                    }}
                    className={`w-full px-3 py-2 text-left text-sm hover:bg-muted ${
                      selected === model.name ? 'bg-muted' : ''
                    }`}
                  >
                    <div className="font-medium text-foreground">{model.name}</div>
                    <div className="text-xs text-muted-foreground">
                      {formatSize(model.size)}
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}
