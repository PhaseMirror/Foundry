'use client';

import React, { useState } from 'react';
import { Search, Sun, Moon, Sparkles } from 'lucide-react';

interface HeaderProps {
  searchQuery: string;
  setSearchQuery: (query: string) => void;
}

export default function Header({ searchQuery, setSearchQuery }: HeaderProps) {
  const [isDarkMode, setIsDarkMode] = useState(() => 
    typeof window !== 'undefined' ? document.documentElement.classList.contains('dark') : false
  );

  const toggleTheme = () => {
    const newDark = !isDarkMode;
    setIsDarkMode(newDark);
    if (newDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  return (
    <header className="sticky top-0 z-40 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 px-6 py-3.5 flex items-center justify-between shadow-xs">
      {/* Left spacer item */}
      <div className="w-40 hidden lg:block text-xs font-semibold text-slate-400 dark:text-slate-500">
        PrismPM v.1.0
      </div>

      {/* Centered Global Search Box */}
      <div className="flex-1 max-w-md mx-auto px-4">
        <div className="relative">
          <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Global search papers, projects, UOR hashes..."
            className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-xs"
          />
        </div>
      </div>

      {/* Right Controls: Theme Toggle */}
      <div className="flex items-center justify-end space-x-4 w-auto lg:w-40">
        {/* Theme Toggle Button */}
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 transition shadow-xs flex items-center space-x-2"
          title={isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}
        >
          {isDarkMode ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-indigo-600" />
          )}
          <span className="text-xs font-medium hidden sm:inline">
            {isDarkMode ? 'Light' : 'Dark'}
          </span>
        </button>
      </div>
    </header>
  );
}
