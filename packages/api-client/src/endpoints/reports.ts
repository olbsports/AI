import type { ApiClient } from '../client';
import type {
  Report,
  ReportWithRelations,
  PaginatedResponse,
  ReportFilters,
  PaginationParams,
} from '@horse-vision/types';

export function createReportsEndpoints(client: ApiClient) {
  return {
    /**
     * Lister les rapports
     */
    list: (params?: Partial<PaginationParams & ReportFilters>) => {
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

      return client.get<PaginatedResponse<ReportWithRelations>>('/reports', searchParams);
    },

    /**
     * Récupérer un rapport par ID
     */
    get: (id: string) => client.get<ReportWithRelations>(`/reports/${id}`),

    /**
     * Mettre à jour un rapport
     */
    update: (id: string, data: Partial<Report>) =>
      client.patch<Report>(`/reports/${id}`, data),

    /**
     * Signer un rapport
     */
    sign: (id: string) => client.post<Report>(`/reports/${id}/sign`),

    /**
     * Générer le PDF
     */
    generatePdf: (id: string) =>
      client.post<{ url: string }>(`/reports/${id}/generate-pdf`),

    /**
     * Générer le HTML
     */
    generateHtml: (id: string) =>
      client.post<{ url: string }>(`/reports/${id}/generate-html`),

    /**
     * Créer un lien de partage
     */
    createShareLink: (id: string, expiresInDays?: number) =>
      client.post<{ shareUrl: string; expiresAt: string }>(
        `/reports/${id}/share`,
        { expiresInDays }
      ),

    /**
     * Révoquer le lien de partage
     */
    revokeShareLink: (id: string) =>
      client.delete<void>(`/reports/${id}/share`),

    /**
     * Récupérer un rapport partagé (public)
     */
    getShared: (token: string) =>
      client.get<ReportWithRelations>(`/reports/shared/${token}`),

    /**
     * Archiver un rapport
     */
    archive: (id: string) => client.post<Report>(`/reports/${id}/archive`),

    /**
     * Restaurer un rapport
     */
    restore: (id: string) => client.post<Report>(`/reports/${id}/restore`),
  };
}
