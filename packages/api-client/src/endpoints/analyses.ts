import { getApiClient } from '../client';
import type { PaginatedResponse } from './horses';

export type AnalysisType = 'video_performance' | 'video_course' | 'radiological' | 'locomotion';
export type AnalysisStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled';

export interface Analysis {
  id: string;
  type: AnalysisType;
  status: AnalysisStatus;
  title: string;
  competition?: {
    name: string;
    location: string;
    level: string;
    date: string;
  };
  inputMediaUrls: string[];
  inputMetadata?: Record<string, unknown>;
  scores?: {
    global: number;
    horse?: number;
    rider?: number;
    harmony?: number;
    technique?: number;
  };
  obstacles?: Array<{
    number: number;
    score: number;
    issues: string[];
  }>;
  issues?: Array<{
    type: string;
    severity: 'low' | 'medium' | 'high';
    description: string;
    timestamp?: number;
  }>;
  recommendations: string[];
  aiAnalysis?: Record<string, unknown>;
  confidenceScore?: number;
  startedAt?: string;
  completedAt?: string;
  processingTimeMs?: number;
  errorMessage?: string;
  tokensConsumed: number;
  horseId?: string;
  horse?: {
    id: string;
    name: string;
  };
  riderId?: string;
  rider?: {
    id: string;
    firstName: string;
    lastName: string;
  };
  createdById: string;
  createdBy: {
    id: string;
    firstName: string;
    lastName: string;
  };
  createdAt: string;
  updatedAt: string;
}

export interface CreateAnalysisRequest {
  type: AnalysisType;
  title: string;
  horseId?: string;
  riderId?: string;
  competition?: {
    name: string;
    location: string;
    level: string;
    date: string;
  };
  inputMetadata?: Record<string, unknown>;
}

export interface AnalysisListParams {
  page?: number;
  limit?: number;
  type?: AnalysisType;
  status?: AnalysisStatus;
  horseId?: string;
  riderId?: string;
  from?: string;
  to?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface UploadMediaResponse {
  uploadUrl: string;
  mediaUrl: string;
  key: string;
}

export const analysesApi = {
  list: (params?: AnalysisListParams): Promise<PaginatedResponse<Analysis>> => {
    return getApiClient().get('/analyses', params);
  },

  get: (id: string): Promise<Analysis> => {
    return getApiClient().get(`/analyses/${id}`);
  },

  create: (data: CreateAnalysisRequest): Promise<Analysis> => {
    return getApiClient().post('/analyses', data);
  },

  cancel: (id: string): Promise<Analysis> => {
    return getApiClient().post(`/analyses/${id}/cancel`);
  },

  retry: (id: string): Promise<Analysis> => {
    return getApiClient().post(`/analyses/${id}/retry`);
  },

  getUploadUrl: (
    analysisId: string,
    filename: string,
    contentType: string,
  ): Promise<UploadMediaResponse> => {
    return getApiClient().post(`/analyses/${analysisId}/upload-url`, {
      filename,
      contentType,
    });
  },

  startProcessing: (id: string): Promise<Analysis> => {
    return getApiClient().post(`/analyses/${id}/process`);
  },

  getProgress: (id: string): Promise<{ progress: number; status: AnalysisStatus }> => {
    return getApiClient().get(`/analyses/${id}/progress`);
  },
};
