import { z } from 'zod';

export const analysisTypes = ['video_performance', 'video_course', 'radiological', 'locomotion'] as const;

export const analysisSchema = z.object({
  type: z.enum(analysisTypes, {
    errorMap: () => ({ message: 'Le type d\'analyse est requis' }),
  }),
  title: z
    .string()
    .min(1, 'Le titre est requis')
    .min(3, 'Le titre doit contenir au moins 3 caractères')
    .max(100, 'Le titre ne peut pas dépasser 100 caractères'),
  horseId: z
    .string()
    .min(1, 'Le cheval est requis'),
  riderId: z
    .string()
    .optional(),
  notes: z
    .string()
    .optional(),
  competition: z.object({
    name: z.string().optional(),
    location: z.string().optional(),
    level: z.string().optional(),
    date: z.string().optional(),
  }).optional(),
});

export type AnalysisFormData = z.infer<typeof analysisSchema>;

export const analysisFilterSchema = z.object({
  type: z.enum(['all', ...analysisTypes]).optional(),
  status: z.enum(['all', 'pending', 'processing', 'completed', 'failed']).optional(),
  horseId: z.string().optional(),
  riderId: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
});

export type AnalysisFilterData = z.infer<typeof analysisFilterSchema>;
