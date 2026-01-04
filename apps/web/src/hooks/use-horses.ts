'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './use-api';

export const horseKeys = {
  all: ['horses'] as const,
  lists: () => [...horseKeys.all, 'list'] as const,
  list: (params: Record<string, unknown>) => [...horseKeys.lists(), params] as const,
  details: () => [...horseKeys.all, 'detail'] as const,
  detail: (id: string) => [...horseKeys.details(), id] as const,
  stats: (id: string) => [...horseKeys.detail(id), 'stats'] as const,
};

export function useHorses(params?: {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
}) {
  const api = useApi();

  return useQuery({
    queryKey: horseKeys.list(params || {}),
    queryFn: () => api.horses.list(params),
  });
}

export function useHorse(id: string) {
  const api = useApi();

  return useQuery({
    queryKey: horseKeys.detail(id),
    queryFn: () => api.horses.get(id),
    enabled: !!id,
  });
}

export function useHorseStats(id: string) {
  const api = useApi();

  return useQuery({
    queryKey: horseKeys.stats(id),
    queryFn: () => api.horses.getStats(id),
    enabled: !!id,
  });
}

export function useCreateHorse() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.horses.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useUpdateHorse() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.horses.update>[1] }) =>
      api.horses.update(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: horseKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useDeleteHorse() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.horses.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useAssignRider() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ horseId, riderId }: { horseId: string; riderId: string }) =>
      api.horses.assignRider(horseId, riderId),
    onSuccess: (_, { horseId }) => {
      queryClient.invalidateQueries({ queryKey: horseKeys.detail(horseId) });
    },
  });
}
