import { ApiClient, type ApiClientConfig } from './client';
import { createAuthEndpoints } from './endpoints/auth';
import { createHorsesEndpoints } from './endpoints/horses';
import { createAnalysisEndpoints } from './endpoints/analysis';
import { createReportsEndpoints } from './endpoints/reports';
import { createTokensEndpoints } from './endpoints/tokens';
import { createBillingEndpoints } from './endpoints/billing';
import { createRidersEndpoints } from './endpoints/riders';

export { ApiClient, ApiClientError, type ApiClientConfig } from './client';

// Re-export types
export type * from './endpoints/tokens';
export type * from './endpoints/billing';
export type * from './endpoints/riders';

/**
 * Crée une instance complète du client API
 */
export function createApiClient(config: ApiClientConfig) {
  const client = new ApiClient(config);

  return {
    client,
    auth: createAuthEndpoints(client),
    horses: createHorsesEndpoints(client),
    riders: createRidersEndpoints(client),
    analyses: createAnalysisEndpoints(client),
    reports: createReportsEndpoints(client),
    tokens: createTokensEndpoints(client),
    billing: createBillingEndpoints(client),
  };
}

export type HorseVisionApi = ReturnType<typeof createApiClient>;
