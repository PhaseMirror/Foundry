interface ChatMessageProps {
  role: 'user' | 'assistant';
  content: string;
  isStreaming?: boolean;
}

export function ChatMessage({ role, content, isStreaming }: ChatMessageProps) {
  const isUser = role === 'user';

  return (
    <div
      className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-3 px-4`}
    >
      <div
        className={`max-w-[85%] rounded-2xl px-4 py-2 ${
          isUser
            ? 'bg-primary text-primary-foreground'
            : 'bg-muted text-foreground'
        }`}
      >
        <p className="whitespace-pre-wrap text-sm">{content}</p>
        {isStreaming && (
          <span className="ml-1 inline-block h-2 w-2 animate-pulse rounded-full bg-current" />
        )}
      </div>
    </div>
  );
}
