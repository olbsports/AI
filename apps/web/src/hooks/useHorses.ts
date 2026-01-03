import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { Horse, CreateHorseInput, UpdateHorseInput } from '@horse-vision/types';

export const horseKeys = {
  all: ['horses'] as const,
  lists: () => [...horseKeys.all, 'list'] as const,
  list: (filters: Record<string, any>) => [...horseKeys.lists(), filters] as const,
  details: () => [...horseKeys.all, 'detail'] as const,
  detail: (id: string) => [...horseKeys.details(), id] as const,
};

interface UseHorsesOptions {
  page?: number;
  pageSize?: number;
  search?: string;
  status?: string;
  gender?: string;
}

export function useHorses(options: UseHorsesOptions = {}) {
  return useQuery({
    queryKey: horseKeys.list(options),
    queryFn: async () => {
      const params: Record<string, string> = {};
      if (options.page) params.page = String(options.page);
      if (options.pageSize) params.pageSize = String(options.pageSize);
      if (options.search) params.search = options.search;
      if (options.status) params.status = options.status;
      if (options.gender) params.gender = options.gender;

      const response = await api.horses.list(params as any);
      return response.data;
    },
  });
}

export function useHorse(id: string) {
  return useQuery({
    queryKey: horseKeys.detail(id),
    queryFn: async () => {
      const response = await api.horses.get(id);
      return response.data;
    },
    enabled: !!id,
  });
}

export function useCreateHorse() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateHorseInput) => {
      const response = await api.horses.create(data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useUpdateHorse() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: UpdateHorseInput }) => {
      const response = await api.horses.update(id, data);
      return response.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: horseKeys.detail(variables.id) });
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useDeleteHorse() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      await api.horses.delete(id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}

export function useArchiveHorse() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await api.horses.archive(id);
      return response.data;
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: horseKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: horseKeys.lists() });
    },
  });
}
