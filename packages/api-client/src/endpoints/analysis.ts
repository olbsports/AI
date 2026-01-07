import type { ApiClient } from '../client';
import type {
  AnalysisSession,
  CreateAnalysisInput,
  PaginatedResponse,
  AnalysisFilters,
  PaginationParams,
} from '@horse-tempo/types';

export function createAnalysisEndpoints(client: ApiClient) {
  return {
    /**
     * Lister les analyses
     */
    list: (params?: Partial<PaginationParams & AnalysisFilters>) => {
      const searchParams: Record<string, string> = {};

      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            if (value instanceof Date) {
              searchParams[key] = value.toISOString();
            } else {
              searchParams[key] = String(value);
            }
          }
        });
      }

      return client.get<PaginatedResponse<AnalysisSession>>('/analyses', searchParams);
    },

    /**
     * Récupérer une analyse par ID
     */
    get: (id: string) => client.get<AnalysisSession>(`/analyses/${id}`),

    /**
     * Créer une nouvelle analyse
     */
    create: (data: CreateAnalysisInput) =>
      client.post<AnalysisSession>('/analyses', data),

    /**
     * Annuler une analyse
     */
    cancel: (id: string) =>
      client.post<AnalysisSession>(`/analyses/${id}/cancel`),

    /**
     * Relancer une analyse échouée
     */
    retry: (id: string) =>
      client.post<AnalysisSession>(`/analyses/${id}/retry`),

    /**
     * Uploader un fichier média pour analyse
     */
    uploadMedia: (file: File, onProgress?: (progress: number) => void) =>
      client.upload<{ url: string; id: string }>('/analyses/upload', file, onProgress),

    /**
     * Obtenir une URL présignée pour upload
     */
    getPresignedUrl: (filename: string, contentType: string) =>
      client.post<{
        uploadUrl: string;
        fileUrl: string;
        fields?: Record<string, string>;
      }>('/analyses/presigned-url', { filename, contentType }),

    /**
     * Récupérer le statut en temps réel
     */
    getStatus: (id: string) =>
      client.get<{
        status: AnalysisSession['status'];
        progress?: number;
        message?: string;
      }>(`/analyses/${id}/status`),
  };
}
