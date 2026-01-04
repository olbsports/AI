import { z } from 'zod';

export const riderSchema = z.object({
  firstName: z
    .string()
    .min(1, 'Le prénom est requis')
    .min(2, 'Le prénom doit contenir au moins 2 caractères'),
  lastName: z
    .string()
    .min(1, 'Le nom est requis')
    .min(2, 'Le nom doit contenir au moins 2 caractères'),
  email: z
    .string()
    .email('Email invalide')
    .optional()
    .or(z.literal('')),
  phone: z
    .string()
    .optional(),
  federationId: z
    .string()
    .optional(),
  federationName: z
    .string()
    .optional(),
  level: z
    .string()
    .optional(),
  discipline: z
    .string()
    .optional(),
});

export type RiderFormData = z.infer<typeof riderSchema>;

export const riderFilterSchema = z.object({
  search: z.string().optional(),
  discipline: z.string().optional(),
  level: z.string().optional(),
});

export type RiderFilterData = z.infer<typeof riderFilterSchema>;
