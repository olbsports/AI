import { z } from 'zod';

import { HORSE_COLORS, HORSE_BREEDS, HORSE_GENDERS } from '@horse-tempo/config';

/**
 * Statut du cheval
 */
export const HorseStatus = {
  ACTIVE: 'active',
  RETIRED: 'retired',
  SOLD: 'sold',
  DECEASED: 'deceased',
} as const;

export type HorseStatus = (typeof HorseStatus)[keyof typeof HorseStatus];

/**
 * Schéma cheval
 */
export const horseSchema = z.object({
  id: z.string().uuid(),
  organizationId: z.string().uuid(),

  // Identité
  name: z.string().min(2).max(255),
  registrationNumber: z.string().max(100).optional(),
  microchipNumber: z.string().length(15).optional(), // 15 chiffres
  ueln: z.string().max(50).optional(), // Universal Equine Life Number
  passportNumber: z.string().max(100).optional(),

  // Caractéristiques
  dateOfBirth: z.date().optional(),
  gender: z.enum([HORSE_GENDERS.MALE, HORSE_GENDERS.FEMALE, HORSE_GENDERS.GELDING]),
  breed: z.enum(HORSE_BREEDS as unknown as [string, ...string[]]).optional(),
  color: z.enum(HORSE_COLORS as unknown as [string, ...string[]]),
  heightCm: z.number().min(100).max(200).optional(),
  weightKg: z.number().min(200).max(1000).optional(),

  // Propriétaire
  ownerName: z.string().max(255).optional(),
  ownerContact: z.object({
    email: z.string().email().optional(),
    phone: z.string().optional(),
  }).optional(),

  // Cavalier actuel
  currentRiderId: z.string().uuid().optional(),

  // Médias
  profileImageUrl: z.string().url().optional(),
  galleryUrls: z.array(z.string().url()).default([]),

  // Métadonnées
  status: z.nativeEnum(HorseStatus).default('active'),
  tags: z.array(z.string()).max(10).default([]),
  notes: z.string().max(5000).optional(),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Horse = z.infer<typeof horseSchema>;

/**
 * Schéma création cheval
 */
export const createHorseSchema = horseSchema.pick({
  name: true,
  registrationNumber: true,
  microchipNumber: true,
  ueln: true,
  passportNumber: true,
  dateOfBirth: true,
  gender: true,
  breed: true,
  color: true,
  heightCm: true,
  weightKg: true,
  ownerName: true,
  ownerContact: true,
  currentRiderId: true,
  tags: true,
  notes: true,
});

export type CreateHorseInput = z.infer<typeof createHorseSchema>;

/**
 * Schéma mise à jour cheval
 */
export const updateHorseSchema = createHorseSchema.partial();

export type UpdateHorseInput = z.infer<typeof updateHorseSchema>;

/**
 * Cheval avec relations
 */
export interface HorseWithRelations extends Horse {
  currentRider?: {
    id: string;
    firstName: string;
    lastName: string;
  };
  analysisCount: number;
  lastAnalysisAt?: Date;
}
