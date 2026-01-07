import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { AnalysisSession, CreateAnalysisInput } from '@horse-tempo/types';

export const analysisKeys = {
  all: ['analyses'] as const,
  lists: () => [...analysisKeys.all, 'list'] as const,
  list: (filters: Record<string, any>) => [...analysisKeys.lists(), filters] as const,
  details: () => [...analysisKeys.all, 'detail'] as const,
  detail: (id: string) => [...analysisKeys.details(), id] as const,
  status: (id: string) => [...analysisKeys.all, 'status', id] as const,
};

interface UseAnalysesOptions {
  page?: number;
  pageSize?: number;
  type?: string;
  status?: string;
  horseId?: string;
}

export function useAnalyses(options: UseAnalysesOptions = {}) {
  return useQuery({
    queryKey: analysisKeys.list(options),
    queryFn: async () => {
      const response = await api.analyses.list(options as any);
      return response.data;
    },
  });
}

export function useAnalysis(id: string) {
  return useQuery({
    queryKey: analysisKeys.detail(id),
    queryFn: async () => {
      const response = await api.analyses.get(id);
      return response.data;
    },
    enabled: !!id,
  });
}

export function useAnalysisStatus(id: string, enabled = true) {
  return useQuery({
    queryKey: analysisKeys.status(id),
    queryFn: async () => {
      const response = await api.analyses.getStatus(id);
      return response.data;
    },
    enabled: enabled && !!id,
    refetchInterval: (data) => {
      // Poll every 3 seconds while processing
      if (data?.status === 'processing' || data?.status === 'pending') {
        return 3000;
      }
      return false;
    },
  });
}

export function useCreateAnalysis() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateAnalysisInput) => {
      const response = await api.analyses.create(data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}

export function useCancelAnalysis() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.analyses.cancel(id);
      return response.data;
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}

export function useRetryAnalysis() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.analyses.retry(id);
      return response.data;
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}

export function useUploadMedia() {
  return useMutation({
    mutationFn: async ({
      file,
      onProgress,
    }: {
      file: File;
      onProgress?: (progress: number) => void;
    }) => {
      const response = await api.analyses.uploadMedia(file, onProgress);
      return response.data;
    },
  });
}
