import type { ApiClient } from '../client';
import type {
  Horse,
  CreateHorseInput,
  UpdateHorseInput,
  PaginatedResponse,
  HorseFilters,
  PaginationParams,
} from '@horse-vision/types';

export function createHorsesEndpoints(client: ApiClient) {
  return {
    /**
     * Lister les chevaux
     */
    list: (params?: Partial<PaginationParams & HorseFilters>) => {
      const searchParams: Record<string, string> = {};

      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            if (Array.isArray(value)) {
              searchParams[key] = value.join(',');
            } else if (value instanceof Date) {
              searchParams[key] = value.toISOString();
            } else {
              searchParams[key] = String(value);
            }
          }
        });
      }

      return client.get<PaginatedResponse<Horse>>('/horses', searchParams);
    },

    /**
     * Récupérer un cheval par ID
     */
    get: (id: string) => client.get<Horse>(`/horses/${id}`),

    /**
     * Créer un cheval
     */
    create: (data: CreateHorseInput) => client.post<Horse>('/horses', data),

    /**
     * Mettre à jour un cheval
     */
    update: (id: string, data: UpdateHorseInput) =>
      client.patch<Horse>(`/horses/${id}`, data),

    /**
     * Supprimer un cheval
     */
    delete: (id: string) => client.delete<void>(`/horses/${id}`),

    /**
     * Archiver un cheval
     */
    archive: (id: string) => client.post<Horse>(`/horses/${id}/archive`),

    /**
     * Restaurer un cheval archivé
     */
    restore: (id: string) => client.post<Horse>(`/horses/${id}/restore`),

    /**
     * Uploader une photo
     */
    uploadPhoto: (id: string, file: File, onProgress?: (p: number) => void) =>
      client.upload<{ url: string }>(`/horses/${id}/photo`, file, onProgress),

    /**
     * Récupérer l'historique des analyses
     */
    getAnalysisHistory: (id: string) =>
      client.get<PaginatedResponse<unknown>>(`/horses/${id}/analyses`),

    /**
     * Récupérer les rapports du cheval
     */
    getReports: (id: string) =>
      client.get<PaginatedResponse<unknown>>(`/horses/${id}/reports`),
  };
}
