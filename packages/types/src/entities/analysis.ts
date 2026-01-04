import { z } from 'zod';

import { ANALYSIS_TYPES, ANALYSIS_STATUS, OBSTACLE_TYPES } from '@horse-vision/config';

/**
 * Type d'analyse
 */
export type AnalysisType = (typeof ANALYSIS_TYPES)[keyof typeof ANALYSIS_TYPES];

/**
 * Statut d'analyse
 */
export type AnalysisStatus = (typeof ANALYSIS_STATUS)[keyof typeof ANALYSIS_STATUS];

/**
 * Schéma obstacle analysé
 */
export const obstacleAnalysisSchema = z.object({
  number: z.union([z.number(), z.string()]), // "5A-B" pour les combinaisons
  name: z.string(),
  type: z.enum([
    OBSTACLE_TYPES.VERTICAL,
    OBSTACLE_TYPES.OXER,
    OBSTACLE_TYPES.TRIPLE_BAR,
    OBSTACLE_TYPES.COMBINATION,
    OBSTACLE_TYPES.WATER,
    OBSTACLE_TYPES.LIVERPOOL,
    OBSTACLE_TYPES.WALL,
  ]),
  sponsor: z.string().optional(),
  score: z.number().min(0).max(10),
  issues: z.array(z.string()).default([]),
  notes: z.string().optional(),
  videoTimestamp: z.number().optional(), // secondes
});

export type ObstacleAnalysis = z.infer<typeof obstacleAnalysisSchema>;

/**
 * Schéma problème identifié
 */
export const issueSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  severity: z.enum(['low', 'medium', 'high', 'critical']),
  category: z.enum(['horse', 'rider', 'harmony', 'technique']),
  visibleAt: z.array(z.number()).default([]), // Numéros d'obstacles
  recommendation: z.string().optional(),
});

export type Issue = z.infer<typeof issueSchema>;

/**
 * Schéma scores
 */
export const scoresSchema = z.object({
  global: z.number().min(0).max(10),
  horse: z.number().min(0).max(10).optional(),
  rider: z.number().min(0).max(10).optional(),
  harmony: z.number().min(0).max(10).optional(),
  technique: z.number().min(0).max(10).optional(),
});

export type Scores = z.infer<typeof scoresSchema>;

/**
 * Schéma session d'analyse
 */
export const analysisSessionSchema = z.object({
  id: z.string().uuid(),
  organizationId: z.string().uuid(),
  horseId: z.string().uuid().optional(),
  riderId: z.string().uuid().optional(),
  createdById: z.string().uuid(),

  // Type et statut
  type: z.enum([
    ANALYSIS_TYPES.VIDEO_PERFORMANCE,
    ANALYSIS_TYPES.VIDEO_COURSE,
    ANALYSIS_TYPES.RADIOLOGICAL,
    ANALYSIS_TYPES.LOCOMOTION,
  ]),
  status: z.enum([
    ANALYSIS_STATUS.PENDING,
    ANALYSIS_STATUS.PROCESSING,
    ANALYSIS_STATUS.COMPLETED,
    ANALYSIS_STATUS.FAILED,
    ANALYSIS_STATUS.CANCELLED,
  ]),

  // Titre et contexte
  title: z.string().max(255),
  competition: z.object({
    name: z.string(),
    location: z.string().optional(),
    level: z.string().optional(),
    date: z.date().optional(),
  }).optional(),

  // Input
  inputMediaUrls: z.array(z.string().url()),
  inputMetadata: z.record(z.unknown()).optional(),

  // Résultats
  scores: scoresSchema.optional(),
  obstacles: z.array(obstacleAnalysisSchema).optional(),
  issues: z.array(issueSchema).optional(),
  recommendations: z.array(z.string()).optional(),

  // AI
  aiAnalysis: z.record(z.unknown()).optional(),
  confidenceScore: z.number().min(0).max(1).optional(),

  // Rapport
  reportId: z.string().uuid().optional(),

  // Processing
  startedAt: z.date().optional(),
  completedAt: z.date().optional(),
  processingTimeMs: z.number().optional(),
  errorMessage: z.string().optional(),

  // Billing
  tokensConsumed: z.number().int().min(0).default(0),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type AnalysisSession = z.infer<typeof analysisSessionSchema>;

/**
 * Schéma création analyse
 */
export const createAnalysisSchema = analysisSessionSchema.pick({
  type: true,
  title: true,
  horseId: true,
  riderId: true,
  competition: true,
  inputMediaUrls: true,
  inputMetadata: true,
});

export type CreateAnalysisInput = z.infer<typeof createAnalysisSchema>;
