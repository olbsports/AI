import { z } from 'zod';

/**
 * Niveau du cavalier
 */
export const RiderLevel = {
  BEGINNER: 'beginner',
  AMATEUR: 'amateur',
  CONFIRMED: 'confirmed',
  PROFESSIONAL: 'professional',
  ELITE: 'elite',
} as const;

export type RiderLevel = (typeof RiderLevel)[keyof typeof RiderLevel];

/**
 * Schéma cavalier
 */
export const riderSchema = z.object({
  id: z.string().uuid(),
  organizationId: z.string().uuid(),

  // Identité
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  dateOfBirth: z.date().optional(),

  // Fédération
  licenseNumber: z.string().max(50).optional(),
  federationId: z.string().max(50).optional(), // Ex: FEI ID
  nationality: z.string().length(2).optional(), // ISO 3166-1 alpha-2

  // Niveau
  level: z.nativeEnum(RiderLevel),
  discipline: z.enum(['jumping', 'dressage', 'eventing', 'other']).default('jumping'),

  // Médias
  profileImageUrl: z.string().url().optional(),

  // Notes
  notes: z.string().max(5000).optional(),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Rider = z.infer<typeof riderSchema>;

/**
 * Schéma création cavalier
 */
export const createRiderSchema = riderSchema.pick({
  firstName: true,
  lastName: true,
  email: true,
  phone: true,
  dateOfBirth: true,
  licenseNumber: true,
  federationId: true,
  nationality: true,
  level: true,
  discipline: true,
  notes: true,
});

export type CreateRiderInput = z.infer<typeof createRiderSchema>;

/**
 * Schéma mise à jour cavalier
 */
export const updateRiderSchema = createRiderSchema.partial();

export type UpdateRiderInput = z.infer<typeof updateRiderSchema>;
