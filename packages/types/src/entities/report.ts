import { z } from 'zod';

import { RADIO_CATEGORIES } from '@horse-tempo/config';

/**
 * Type de rapport
 */
export const ReportType = {
  COURSE_ANALYSIS: 'course_analysis',
  RADIOLOGICAL: 'radiological',
  LOCOMOTION: 'locomotion',
  PURCHASE_EXAM: 'purchase_exam',
} as const;

export type ReportType = (typeof ReportType)[keyof typeof ReportType];

/**
 * Statut du rapport
 */
export const ReportStatus = {
  DRAFT: 'draft',
  PENDING_REVIEW: 'pending_review',
  COMPLETED: 'completed',
  ARCHIVED: 'archived',
} as const;

export type ReportStatus = (typeof ReportStatus)[keyof typeof ReportStatus];

/**
 * Catégorie radiologique
 */
export type RadioCategory = keyof typeof RADIO_CATEGORIES;

/**
 * Schéma image radiographique
 */
export const radiographicImageSchema = z.object({
  id: z.string().uuid(),
  sequence: z.number().int().min(1),
  limb: z.enum(['LF', 'RF', 'LH', 'RH']), // Left Front, Right Front, Left Hind, Right Hind
  limbDescription: z.string(), // "Antérieur Gauche"
  region: z.string(), // "Pied", "Boulet", etc.
  view: z.string(), // "DP", "Latérale", etc.
  calibration: z.string().optional(),
  status: z.enum(['normal', 'attention', 'abnormal']),
  findings: z.array(z.string()).default([]),
  imageUrl: z.string().url(),
  thumbnailUrl: z.string().url().optional(),
});

export type RadiographicImage = z.infer<typeof radiographicImageSchema>;

/**
 * Schéma point d'attention
 */
export const attentionPointSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  region: z.string(),
  severity: z.enum(['minor', 'moderate', 'severe']),
  clinicalSignificance: z.string(),
  recommendation: z.string().optional(),
});

export type AttentionPoint = z.infer<typeof attentionPointSchema>;

/**
 * Schéma pathologie recherchée
 */
export const pathologySearchSchema = z.object({
  name: z.string(),
  region: z.string(),
  detected: z.boolean(),
  confidence: z.number().min(0).max(1).optional(),
  notes: z.string().optional(),
});

export type PathologySearch = z.infer<typeof pathologySearchSchema>;

/**
 * Schéma rapport
 */
export const reportSchema = z.object({
  id: z.string().uuid(),
  reportNumber: z.string(), // "HV-RADIO-348"
  organizationId: z.string().uuid(),
  analysisSessionId: z.string().uuid(),
  horseId: z.string().uuid().optional(),

  // Type et statut
  type: z.nativeEnum(ReportType),
  status: z.nativeEnum(ReportStatus),

  // Métadonnées examen
  examDate: z.date(),
  examTime: z.string().optional(),
  veterinarians: z.array(z.string()).default([]),
  location: z.string().optional(),

  // Score global
  globalScore: z.number().min(0).max(10),
  category: z.enum(['A', 'A-', 'B+', 'B', 'B-', 'C', 'D']).optional(),
  categoryDescription: z.string().optional(),

  // Contenu radiologique
  images: z.array(radiographicImageSchema).optional(),
  attentionPoints: z.array(attentionPointSchema).optional(),
  pathologiesSearched: z.array(pathologySearchSchema).optional(),

  // Régions
  examinedRegions: z.array(z.string()).default([]),
  missingRegions: z.array(z.string()).default([]),

  // Recommandations et conclusion
  recommendations: z.array(z.string()).default([]),
  suggestedFollowUp: z.string().optional(),
  conclusion: z.string(),
  clinicalCorrelation: z.string().optional(),

  // Fichiers générés
  htmlReportUrl: z.string().url().optional(),
  pdfReportUrl: z.string().url().optional(),

  // Signature
  reviewedById: z.string().uuid().optional(),
  reviewedAt: z.date().optional(),
  digitalSignature: z.string().optional(),

  // Partage
  shareToken: z.string().optional(),
  shareExpiresAt: z.date().optional(),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Report = z.infer<typeof reportSchema>;

/**
 * Rapport avec relations
 */
export interface ReportWithRelations extends Report {
  horse?: {
    id: string;
    name: string;
    breed?: string;
  };
  analysisSession?: {
    id: string;
    title: string;
  };
}
