'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './use-api';
import { tokenKeys } from './use-tokens';

export const billingKeys = {
  all: ['billing'] as const,
  plans: () => [...billingKeys.all, 'plans'] as const,
  subscription: () => [...billingKeys.all, 'subscription'] as const,
  invoices: (params: Record<string, unknown>) => [...billingKeys.all, 'invoices', params] as const,
  invoiceSummary: () => [...billingKeys.all, 'invoice-summary'] as const,
  upcomingInvoice: () => [...billingKeys.all, 'upcoming-invoice'] as const,
};

export function usePlans() {
  const api = useApi();

  return useQuery({
    queryKey: billingKeys.plans(),
    queryFn: () => api.billing.getPlans(),
    staleTime: 1000 * 60 * 60, // Cache for 1 hour
  });
}

export function useSubscription() {
  const api = useApi();

  return useQuery({
    queryKey: billingKeys.subscription(),
    queryFn: () => api.billing.getSubscriptionStatus(),
  });
}

export function useInvoices(params?: {
  status?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
}) {
  const api = useApi();

  return useQuery({
    queryKey: billingKeys.invoices(params || {}),
    queryFn: () => api.billing.getInvoices(params),
  });
}

export function useInvoiceSummary() {
  const api = useApi();

  return useQuery({
    queryKey: billingKeys.invoiceSummary(),
    queryFn: () => api.billing.getInvoiceSummary(),
  });
}

export function useUpcomingInvoice() {
  const api = useApi();

  return useQuery({
    queryKey: billingKeys.upcomingInvoice(),
    queryFn: () => api.billing.getUpcomingInvoice(),
  });
}

export function useCreateCheckout() {
  const api = useApi();

  return useMutation({
    mutationFn: api.billing.createCheckout,
    onSuccess: (data) => {
      if (data.data?.url) {
        window.location.href = data.data.url;
      }
    },
  });
}

export function useCreatePortalSession() {
  const api = useApi();

  return useMutation({
    mutationFn: (returnUrl?: string) => api.billing.createPortalSession(returnUrl),
    onSuccess: (data) => {
      if (data.data?.url) {
        window.location.href = data.data.url;
      }
    },
  });
}

export function useUpgradePlan() {
  const api = useApi();

  return useMutation({
    mutationFn: api.billing.upgradePlan,
    onSuccess: (data) => {
      if (data.data?.checkoutUrl) {
        window.location.href = data.data.checkoutUrl;
      }
    },
  });
}

export function useCancelSubscription() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.billing.cancelSubscription,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: billingKeys.subscription() });
    },
  });
}

export function useReactivateSubscription() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => api.billing.reactivateSubscription(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: billingKeys.subscription() });
    },
  });
}

export function useDownloadInvoice() {
  const api = useApi();

  return useMutation({
    mutationFn: (invoiceId: string) => api.billing.downloadInvoice(invoiceId),
    onSuccess: (data) => {
      if (data.data?.url) {
        window.open(data.data.url, '_blank');
      }
    },
  });
}
