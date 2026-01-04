import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { Report } from '@horse-vision/types';

export const reportKeys = {
  all: ['reports'] as const,
  lists: () => [...reportKeys.all, 'list'] as const,
  list: (filters: Record<string, any>) => [...reportKeys.lists(), filters] as const,
  details: () => [...reportKeys.all, 'detail'] as const,
  detail: (id: string) => [...reportKeys.details(), id] as const,
  shared: (token: string) => [...reportKeys.all, 'shared', token] as const,
};

interface UseReportsOptions {
  page?: number;
  pageSize?: number;
  type?: string;
  status?: string;
  horseId?: string;
  category?: string;
}

export function useReports(options: UseReportsOptions = {}) {
  return useQuery({
    queryKey: reportKeys.list(options),
    queryFn: async () => {
      const response = await api.reports.list(options as any);
      return response.data;
    },
  });
}

export function useReport(id: string) {
  return useQuery({
    queryKey: reportKeys.detail(id),
    queryFn: async () => {
      const response = await api.reports.get(id);
      return response.data;
    },
    enabled: !!id,
  });
}

export function useSharedReport(token: string) {
  return useQuery({
    queryKey: reportKeys.shared(token),
    queryFn: async () => {
      const response = await api.reports.getShared(token);
      return response.data;
    },
    enabled: !!token,
  });
}

export function useUpdateReport() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<Report> }) => {
      const response = await api.reports.update(id, data);
      return response.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(variables.id) });
      queryClient.invalidateQueries({ queryKey: reportKeys.lists() });
    },
  });
}

export function useSignReport() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.reports.sign(id);
      return response.data;
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: reportKeys.lists() });
    },
  });
}

export function useGeneratePdf() {
  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.reports.generatePdf(id);
      return response.data;
    },
  });
}

export function useCreateShareLink() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, expiresInDays }: { id: string; expiresInDays?: number }) => {
      const response = await api.reports.createShareLink(id, expiresInDays);
      return response.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(variables.id) });
    },
  });
}

export function useRevokeShareLink() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      await api.reports.revokeShareLink(id);
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
    },
  });
}

export function useArchiveReport() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.reports.archive(id);
      return response.data;
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: reportKeys.lists() });
    },
  });
}
