import { z } from 'zod';

/**
 * Schéma de paramètres de pagination
 */
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export type PaginationParams = z.infer<typeof paginationSchema>;

/**
 * Schéma de filtres génériques
 */
export const baseFiltersSchema = z.object({
  search: z.string().optional(),
  createdAfter: z.coerce.date().optional(),
  createdBefore: z.coerce.date().optional(),
});

export type BaseFilters = z.infer<typeof baseFiltersSchema>;

/**
 * Combine pagination et filtres
 */
export const queryParamsSchema = paginationSchema.merge(baseFiltersSchema);

export type QueryParams = z.infer<typeof queryParamsSchema>;

/**
 * Filtres pour les chevaux
 */
export const horseFiltersSchema = baseFiltersSchema.extend({
  status: z.enum(['active', 'retired', 'sold', 'deceased']).optional(),
  gender: z.enum(['male', 'female', 'gelding']).optional(),
  breed: z.string().optional(),
  riderId: z.string().uuid().optional(),
  tags: z.array(z.string()).optional(),
});

export type HorseFilters = z.infer<typeof horseFiltersSchema>;

/**
 * Filtres pour les analyses
 */
export const analysisFiltersSchema = baseFiltersSchema.extend({
  type: z.enum(['video_performance', 'video_course', 'radiological', 'locomotion']).optional(),
  status: z.enum(['pending', 'processing', 'completed', 'failed', 'cancelled']).optional(),
  horseId: z.string().uuid().optional(),
  riderId: z.string().uuid().optional(),
});

export type AnalysisFilters = z.infer<typeof analysisFiltersSchema>;

/**
 * Filtres pour les rapports
 */
export const reportFiltersSchema = baseFiltersSchema.extend({
  type: z.enum(['course_analysis', 'radiological', 'locomotion', 'purchase_exam']).optional(),
  status: z.enum(['draft', 'pending_review', 'completed', 'archived']).optional(),
  horseId: z.string().uuid().optional(),
  category: z.enum(['A', 'A-', 'B+', 'B', 'B-', 'C', 'D']).optional(),
});

export type ReportFilters = z.infer<typeof reportFiltersSchema>;

/**
 * Calcule les métadonnées de pagination
 */
export function calculatePagination(
  totalItems: number,
  page: number,
  pageSize: number
) {
  const totalPages = Math.ceil(totalItems / pageSize);

  return {
    page,
    pageSize,
    totalItems,
    totalPages,
    hasNextPage: page < totalPages,
    hasPreviousPage: page > 1,
  };
}

/**
 * Calcule l'offset pour les requêtes SQL
 */
export function calculateOffset(page: number, pageSize: number): number {
  return (page - 1) * pageSize;
}
