import { useChat } from '../hooks/useChat';
import { ChatHistory } from './ChatHistory';
import { ChatInput } from './ChatInput';

interface ChatContainerProps {
  selectedModel: string | null;
}

export function ChatContainer({ selectedModel }: ChatContainerProps) {
  const { messages, isStreaming, sendMessage } = useChat(selectedModel);

  return (
    <div className="flex h-full flex-col">
      <ChatHistory messages={messages} isStreaming={isStreaming} />
      <ChatInput
        onSend={sendMessage}
        disabled={isStreaming || !selectedModel}
        placeholder={
          selectedModel
            ? 'Send a message...'
            : 'Select a model to start chatting'
        }
      />
    </div>
  );
}
