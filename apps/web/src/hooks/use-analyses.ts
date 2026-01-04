'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './use-api';

export const analysisKeys = {
  all: ['analyses'] as const,
  lists: () => [...analysisKeys.all, 'list'] as const,
  list: (params: Record<string, unknown>) => [...analysisKeys.lists(), params] as const,
  details: () => [...analysisKeys.all, 'detail'] as const,
  detail: (id: string) => [...analysisKeys.details(), id] as const,
  progress: (id: string) => [...analysisKeys.detail(id), 'progress'] as const,
};

export function useAnalyses(params?: {
  page?: number;
  limit?: number;
  type?: string;
  status?: string;
  horseId?: string;
}) {
  const api = useApi();

  return useQuery({
    queryKey: analysisKeys.list(params || {}),
    queryFn: () => api.analyses.list(params),
  });
}

export function useAnalysis(id: string) {
  const api = useApi();

  return useQuery({
    queryKey: analysisKeys.detail(id),
    queryFn: () => api.analyses.get(id),
    enabled: !!id,
  });
}

export function useAnalysisProgress(id: string, enabled = true) {
  const api = useApi();

  return useQuery({
    queryKey: analysisKeys.progress(id),
    queryFn: () => api.analyses.getProgress(id),
    enabled: !!id && enabled,
    refetchInterval: (query) => {
      const data = query.state.data;
      if (data && (data.status === 'completed' || data.status === 'failed')) {
        return false;
      }
      return 2000; // Poll every 2 seconds
    },
  });
}

export function useCreateAnalysis() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.analyses.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}

export function useStartAnalysis() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.analyses.startProcessing(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.detail(id) });
    },
  });
}

export function useCancelAnalysis() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.analyses.cancel(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}

export function useRetryAnalysis() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.analyses.retry(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: analysisKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: analysisKeys.lists() });
    },
  });
}
