import { z } from 'zod';

import { type User } from '../entities/user';
import { type Organization } from '../entities/organization';

/**
 * Réponse API standard
 */
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: ApiMeta;
}

/**
 * Erreur API
 */
export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, string[]>;
  stack?: string; // Uniquement en dev
}

/**
 * Métadonnées API
 */
export interface ApiMeta {
  requestId: string;
  timestamp: string;
  version: string;
}

/**
 * Réponse paginée
 */
export interface PaginatedResponse<T> {
  items: T[];
  pagination: {
    page: number;
    pageSize: number;
    totalItems: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

/**
 * Réponse d'authentification
 */
export interface AuthResponse {
  user: User;
  organization: Organization;
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // Unix timestamp
}

/**
 * Réponse de refresh token
 */
export interface RefreshTokenResponse {
  accessToken: string;
  expiresAt: number;
}

/**
 * Réponse upload
 */
export interface UploadResponse {
  id: string;
  url: string;
  thumbnailUrl?: string;
  contentType: string;
  size: number;
  filename: string;
}

/**
 * Réponse URL présignée
 */
export interface PresignedUrlResponse {
  uploadUrl: string;
  fileUrl: string;
  fields?: Record<string, string>;
  expiresAt: number;
}

/**
 * Statut de santé
 */
export interface HealthResponse {
  status: 'ok' | 'degraded' | 'down';
  version: string;
  timestamp: string;
  services: {
    database: 'ok' | 'error';
    redis: 'ok' | 'error';
    storage: 'ok' | 'error';
  };
}

/**
 * Codes d'erreur standard
 */
export const ErrorCodes = {
  // Auth
  INVALID_CREDENTIALS: 'AUTH_INVALID_CREDENTIALS',
  TOKEN_EXPIRED: 'AUTH_TOKEN_EXPIRED',
  TOKEN_INVALID: 'AUTH_TOKEN_INVALID',
  MFA_REQUIRED: 'AUTH_MFA_REQUIRED',
  MFA_INVALID: 'AUTH_MFA_INVALID',
  EMAIL_NOT_VERIFIED: 'AUTH_EMAIL_NOT_VERIFIED',
  ACCOUNT_LOCKED: 'AUTH_ACCOUNT_LOCKED',

  // Validation
  VALIDATION_ERROR: 'VALIDATION_ERROR',

  // Resources
  NOT_FOUND: 'RESOURCE_NOT_FOUND',
  ALREADY_EXISTS: 'RESOURCE_ALREADY_EXISTS',
  CONFLICT: 'RESOURCE_CONFLICT',

  // Permissions
  FORBIDDEN: 'PERMISSION_FORBIDDEN',
  INSUFFICIENT_PERMISSIONS: 'PERMISSION_INSUFFICIENT',

  // Rate limiting
  RATE_LIMITED: 'RATE_LIMITED',

  // Billing
  INSUFFICIENT_TOKENS: 'BILLING_INSUFFICIENT_TOKENS',
  PLAN_LIMIT_REACHED: 'BILLING_PLAN_LIMIT_REACHED',
  PAYMENT_REQUIRED: 'BILLING_PAYMENT_REQUIRED',

  // Server
  INTERNAL_ERROR: 'SERVER_INTERNAL_ERROR',
  SERVICE_UNAVAILABLE: 'SERVER_SERVICE_UNAVAILABLE',
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];
