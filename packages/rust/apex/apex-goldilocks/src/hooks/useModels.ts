import { useState, useEffect, useCallback } from 'react';
import { listModels, Model } from '../lib/tauri';

export function useModels() {
  const [models, setModels] = useState<Model[]>([]);
  const [selectedModel, setSelectedModel] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchModels = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const modelList = await listModels();
      setModels(modelList);
      // Auto-select first model if none selected
      if (!selectedModel && modelList.length > 0) {
        setSelectedModel(modelList[0].name);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load models');
    } finally {
      setIsLoading(false);
    }
  }, [selectedModel]);

  useEffect(() => {
    fetchModels();
  }, []);

  return {
    models,
    selectedModel,
    setSelectedModel,
    isLoading,
    error,
    refetch: fetchModels,
  };
}
