'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './use-api';

export const tokenKeys = {
  all: ['tokens'] as const,
  balance: () => [...tokenKeys.all, 'balance'] as const,
  transactions: (params: Record<string, unknown>) =>
    [...tokenKeys.all, 'transactions', params] as const,
  usage: () => [...tokenKeys.all, 'usage'] as const,
  costs: () => [...tokenKeys.all, 'costs'] as const,
};

export function useTokenBalance() {
  const api = useApi();

  return useQuery({
    queryKey: tokenKeys.balance(),
    queryFn: () => api.tokens.getBalance(),
  });
}

export function useTokenTransactions(params?: { type?: string; page?: number; limit?: number }) {
  const api = useApi();

  return useQuery({
    queryKey: tokenKeys.transactions(params || {}),
    queryFn: () => api.tokens.getTransactions(params),
  });
}

export function useTokenUsageStats() {
  const api = useApi();

  return useQuery({
    queryKey: tokenKeys.usage(),
    queryFn: () => api.tokens.getUsageStats(),
  });
}

export function useTokenCosts() {
  const api = useApi();

  return useQuery({
    queryKey: tokenKeys.costs(),
    queryFn: () => api.tokens.getCosts(),
    staleTime: 1000 * 60 * 60, // Cache for 1 hour
  });
}

export function usePurchaseTokens() {
  const api = useApi();

  return useMutation({
    mutationFn: (amount: number) => api.tokens.purchase({ amount }),
    onSuccess: (data) => {
      // Redirect to Stripe checkout
      if (data.data?.url) {
        window.location.href = data.data.url;
      }
    },
  });
}

export function useTransferTokens() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.tokens.transfer,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: tokenKeys.balance() });
      queryClient.invalidateQueries({ queryKey: tokenKeys.transactions({}) });
    },
  });
}
