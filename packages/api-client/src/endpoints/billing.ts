import type { ApiClient } from '../client';

export type PlanType = 'free' | 'starter' | 'professional' | 'enterprise';
export type BillingInterval = 'monthly' | 'yearly';

export interface Plan {
  name: string;
  description: string;
  monthlyPrice: number;
  yearlyPrice: number;
  features: string[];
  limits: {
    users: number;
    analyses: number;
    storage: number;
    tokensPerMonth: number;
  };
}

export interface SubscriptionStatus {
  plan: PlanType | null;
  status: string;
  currentPeriodEnd: string | null;
  cancelAtPeriodEnd: boolean;
  tokenBalance: number;
  tokensPerMonth: number;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  amount: number;
  currency: string;
  status: 'draft' | 'pending' | 'paid' | 'failed' | 'refunded';
  description?: string;
  createdAt: string;
  paidAt?: string;
  dueDate?: string;
  invoiceUrl?: string;
  pdfUrl?: string;
}

export interface CreateCheckoutRequest {
  plan: PlanType;
  interval: BillingInterval;
  successUrl?: string;
  cancelUrl?: string;
}

export interface UpgradePlanRequest {
  plan: PlanType;
  yearly?: boolean;
}

export interface CancelSubscriptionRequest {
  immediate?: boolean;
  reason?: string;
}

export function createBillingEndpoints(client: ApiClient) {
  return {
    /**
     * Récupérer les plans disponibles
     */
    getPlans: () => client.get<Record<PlanType, Plan>>('/subscriptions/plans'),

    /**
     * Récupérer le statut de l'abonnement
     */
    getSubscriptionStatus: () =>
      client.get<SubscriptionStatus>('/subscriptions/current'),

    /**
     * Créer une session de checkout
     */
    createCheckout: (data: CreateCheckoutRequest) =>
      client.post<{ sessionId: string; url: string }>('/billing/checkout', data),

    /**
     * Créer une session de portail de facturation
     */
    createPortalSession: (returnUrl?: string) =>
      client.post<{ url: string }>('/billing/portal', { returnUrl }),

    /**
     * Mettre à niveau le plan
     */
    upgradePlan: (data: UpgradePlanRequest) =>
      client.post<{ checkoutUrl: string }>('/subscriptions/upgrade', data),

    /**
     * Annuler l'abonnement
     */
    cancelSubscription: (data?: CancelSubscriptionRequest) =>
      client.post<{ success: boolean; cancelAt: string | null }>(
        '/subscriptions/cancel',
        data
      ),

    /**
     * Réactiver l'abonnement
     */
    reactivateSubscription: () =>
      client.post<{ success: boolean }>('/subscriptions/reactivate'),

    /**
     * Récupérer les factures
     */
    getInvoices: (params?: {
      status?: string;
      from?: string;
      to?: string;
      page?: number;
      limit?: number;
    }) =>
      client.get<{
        invoices: Invoice[];
        total: number;
        page: number;
        limit: number;
      }>('/invoices', params as Record<string, string>),

    /**
     * Récupérer le résumé des factures
     */
    getInvoiceSummary: () =>
      client.get<{
        totalPaid: number;
        totalPending: number;
        invoiceCount: number;
        currency: string;
      }>('/invoices/summary'),

    /**
     * Télécharger une facture
     */
    downloadInvoice: (invoiceId: string) =>
      client.get<{ url: string }>(`/invoices/${invoiceId}/download`),

    /**
     * Récupérer la prochaine facture
     */
    getUpcomingInvoice: () =>
      client.get<{
        amount: number;
        currency: string;
        nextBillingDate: string;
        lineItems: { description: string; amount: number }[];
      } | null>('/invoices/upcoming'),
  };
}
