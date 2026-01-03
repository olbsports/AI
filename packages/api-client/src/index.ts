import { ApiClient, type ApiClientConfig } from './client';
import { createAuthEndpoints } from './endpoints/auth';
import { createHorsesEndpoints } from './endpoints/horses';
import { createAnalysisEndpoints } from './endpoints/analysis';
import { createReportsEndpoints } from './endpoints/reports';

export { ApiClient, ApiClientError, type ApiClientConfig } from './client';

/**
 * Crée une instance complète du client API
 */
export function createApiClient(config: ApiClientConfig) {
  const client = new ApiClient(config);

  return {
    client,
    auth: createAuthEndpoints(client),
    horses: createHorsesEndpoints(client),
    analyses: createAnalysisEndpoints(client),
    reports: createReportsEndpoints(client),
  };
}

export type HorseVisionApi = ReturnType<typeof createApiClient>;
