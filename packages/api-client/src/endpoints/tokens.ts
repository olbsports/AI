import type { ApiClient } from '../client';

export interface TokenBalance {
  balance: number;
  reservedTokens: number;
  availableTokens: number;
  monthlyAllocation: number;
  usedThisMonth: number;
}

export interface TokenTransaction {
  id: string;
  type: 'credit' | 'debit' | 'transfer_in' | 'transfer_out';
  amount: number;
  description: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface TokenUsageStats {
  daily: { date: string; usage: number }[];
  byType: { type: string; count: number; tokens: number }[];
  trend: number;
}

export interface TokenCosts {
  basicAnalysis: number;
  advancedAnalysis: number;
  videoAnalysis: number;
  reportGeneration: number;
  aiRecommendation: number;
}

export interface PurchaseTokensRequest {
  amount: number;
}

export interface TransferTokensRequest {
  targetOrganizationId: string;
  amount: number;
  note?: string;
}

export function createTokensEndpoints(client: ApiClient) {
  return {
    /**
     * Récupérer le solde de tokens
     */
    getBalance: () => client.get<TokenBalance>('/tokens/balance'),

    /**
     * Récupérer l'historique des transactions
     */
    getTransactions: (params?: {
      type?: string;
      page?: number;
      limit?: number;
    }) =>
      client.get<{
        transactions: TokenTransaction[];
        total: number;
        page: number;
        limit: number;
      }>('/tokens/transactions', params as Record<string, string>),

    /**
     * Récupérer les statistiques d'utilisation
     */
    getUsageStats: () => client.get<TokenUsageStats>('/tokens/usage'),

    /**
     * Récupérer les coûts par opération
     */
    getCosts: () => client.get<TokenCosts>('/tokens/costs'),

    /**
     * Acheter des tokens
     */
    purchase: (data: PurchaseTokensRequest) =>
      client.post<{ sessionId: string; url: string }>('/billing/tokens/purchase', data),

    /**
     * Transférer des tokens
     */
    transfer: (data: TransferTokensRequest) =>
      client.post<{
        success: boolean;
        sourceBalance: number;
        targetBalance: number;
      }>('/tokens/transfer', data),
  };
}
