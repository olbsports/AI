import type { ApiClient } from '../client';

export interface Rider {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  photoUrl?: string;
  federationId?: string;
  federationName?: string;
  level?: string;
  discipline?: string;
  horses?: Array<{
    id: string;
    name: string;
  }>;
  createdAt: string;
  updatedAt: string;
}

export interface CreateRiderRequest {
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  federationId?: string;
  federationName?: string;
  level?: string;
  discipline?: string;
}

export interface UpdateRiderRequest extends Partial<CreateRiderRequest> {}

export interface RiderListParams {
  page?: number;
  limit?: number;
  search?: string;
  discipline?: string;
  level?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface RiderStats {
  totalHorses: number;
  totalAnalyses: number;
  avgScore: number;
  lastAnalysisDate?: string;
}

export function createRidersEndpoints(client: ApiClient) {
  return {
    /**
     * Lister les cavaliers
     */
    list: (params?: RiderListParams) =>
      client.get<{
        data: Rider[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
      }>('/riders', params as Record<string, string>),

    /**
     * Récupérer un cavalier
     */
    get: (id: string) => client.get<Rider>(`/riders/${id}`),

    /**
     * Créer un cavalier
     */
    create: (data: CreateRiderRequest) => client.post<Rider>('/riders', data),

    /**
     * Mettre à jour un cavalier
     */
    update: (id: string, data: UpdateRiderRequest) =>
      client.patch<Rider>(`/riders/${id}`, data),

    /**
     * Supprimer un cavalier
     */
    delete: (id: string) => client.delete<void>(`/riders/${id}`),

    /**
     * Récupérer les statistiques d'un cavalier
     */
    getStats: (id: string) => client.get<RiderStats>(`/riders/${id}/stats`),

    /**
     * Assigner un cheval
     */
    assignHorse: (riderId: string, horseId: string) =>
      client.post<Rider>(`/riders/${riderId}/assign-horse`, { horseId }),

    /**
     * Désassigner un cheval
     */
    unassignHorse: (riderId: string, horseId: string) =>
      client.post<Rider>(`/riders/${riderId}/unassign-horse`, { horseId }),
  };
}
