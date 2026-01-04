'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './use-api';

export const reportKeys = {
  all: ['reports'] as const,
  lists: () => [...reportKeys.all, 'list'] as const,
  list: (params: Record<string, unknown>) => [...reportKeys.lists(), params] as const,
  details: () => [...reportKeys.all, 'detail'] as const,
  detail: (id: string) => [...reportKeys.details(), id] as const,
  shared: (token: string) => [...reportKeys.all, 'shared', token] as const,
};

export function useReports(params?: {
  page?: number;
  limit?: number;
  type?: string;
  status?: string;
  horseId?: string;
}) {
  const api = useApi();

  return useQuery({
    queryKey: reportKeys.list(params || {}),
    queryFn: () => api.reports.list(params),
  });
}

export function useReport(id: string) {
  const api = useApi();

  return useQuery({
    queryKey: reportKeys.detail(id),
    queryFn: () => api.reports.get(id),
    enabled: !!id,
  });
}

export function useSharedReport(token: string) {
  const api = useApi();

  return useQuery({
    queryKey: reportKeys.shared(token),
    queryFn: () => api.reports.getByShareToken(token),
    enabled: !!token,
  });
}

export function useUpdateReport() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.reports.update>[1] }) =>
      api.reports.update(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
    },
  });
}

export function useSubmitReport() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.reports.submit(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: reportKeys.lists() });
    },
  });
}

export function useApproveReport() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.reports.approve(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: reportKeys.lists() });
    },
  });
}

export function useGenerateReportPdf() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.reports.generatePdf(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
    },
  });
}

export function useShareReport() {
  const api = useApi();

  return useMutation({
    mutationFn: ({ id, expiresInDays }: { id: string; expiresInDays?: number }) =>
      api.reports.share(id, { expiresInDays }),
  });
}

export function useRevokeReportShare() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.reports.revokeShare(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: reportKeys.detail(id) });
    },
  });
}
