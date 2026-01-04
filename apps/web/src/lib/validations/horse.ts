import { z } from 'zod';

export const horseSchema = z.object({
  name: z
    .string()
    .min(1, 'Le nom est requis')
    .min(2, 'Le nom doit contenir au moins 2 caractères'),
  sireId: z
    .string()
    .optional(),
  ueln: z
    .string()
    .optional(),
  microchip: z
    .string()
    .optional(),
  gender: z.enum(['male', 'female', 'gelding'], {
    errorMap: () => ({ message: 'Le sexe est requis' }),
  }),
  birthDate: z
    .string()
    .optional(),
  breed: z
    .string()
    .optional(),
  color: z
    .string()
    .optional(),
  heightCm: z
    .number()
    .min(100, 'La taille doit être d\'au moins 100 cm')
    .max(250, 'La taille ne peut pas dépasser 250 cm')
    .optional(),
  ownerName: z
    .string()
    .optional(),
  status: z.enum(['active', 'retired', 'sold', 'deceased']).default('active'),
  tags: z.array(z.string()).default([]),
  notes: z
    .string()
    .max(1000, 'Les notes ne peuvent pas dépasser 1000 caractères')
    .optional(),
  riderId: z
    .string()
    .optional(),
});

export type HorseFormData = z.infer<typeof horseSchema>;

export const horseFilterSchema = z.object({
  search: z.string().optional(),
  status: z.enum(['all', 'active', 'retired', 'sold', 'deceased']).optional(),
  riderId: z.string().optional(),
});

export type HorseFilterData = z.infer<typeof horseFilterSchema>;
