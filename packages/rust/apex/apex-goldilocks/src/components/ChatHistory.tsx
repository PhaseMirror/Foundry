import { useEffect, useRef } from 'react';
import { ChatMessage } from './ChatMessage';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ChatHistoryProps {
  messages: Message[];
  isStreaming: boolean;
}

export function ChatHistory({ messages, isStreaming }: ChatHistoryProps) {
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  if (messages.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <div className="text-center">
          <HologramLogo />
          <p className="mt-4 text-sm text-muted-foreground">
            Start a conversation
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto py-4">
      {messages.map((message, index) => (
        <ChatMessage
          key={message.id}
          role={message.role}
          content={message.content}
          isStreaming={isStreaming && index === messages.length - 1 && message.role === 'assistant'}
        />
      ))}
      <div ref={bottomRef} />
    </div>
  );
}

function HologramLogo() {
  return (
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      className="mx-auto text-foreground opacity-20"
    >
      <circle cx="32" cy="32" r="28" stroke="currentColor" strokeWidth="2" />
      <circle cx="32" cy="32" r="20" stroke="currentColor" strokeWidth="2" />
      <circle cx="32" cy="32" r="12" stroke="currentColor" strokeWidth="2" />
      <circle cx="32" cy="32" r="4" fill="currentColor" />
    </svg>
  );
}
