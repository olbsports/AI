import { z } from 'zod';

import { PLANS } from '@horse-tempo/config';

/**
 * Statut d'abonnement
 */
export const SubscriptionStatus = {
  TRIALING: 'trialing',
  ACTIVE: 'active',
  PAST_DUE: 'past_due',
  CANCELED: 'canceled',
  UNPAID: 'unpaid',
} as const;

export type SubscriptionStatus = (typeof SubscriptionStatus)[keyof typeof SubscriptionStatus];

/**
 * Schéma organisation
 */
export const organizationSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(2).max(255),
  slug: z.string().min(2).max(100).regex(/^[a-z0-9-]+$/),
  logoUrl: z.string().url().optional(),

  // Plan & Billing
  plan: z.enum([
    PLANS.FREE,
    PLANS.STARTER,
    PLANS.RIDER,
    PLANS.CHAMPION,
    PLANS.PRO,
    PLANS.ELITE,
    PLANS.ENTERPRISE,
  ]),
  subscriptionStatus: z.nativeEnum(SubscriptionStatus),
  stripeCustomerId: z.string().optional(),
  stripeSubscriptionId: z.string().optional(),

  // Tokens
  tokenBalance: z.number().int().min(0).default(0),

  // Settings
  settings: z.object({
    defaultLocale: z.string().default('fr-FR'),
    defaultTimezone: z.string().default('Europe/Paris'),
    brandColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
  }).default({}),

  // Compliance
  dataRegion: z.string().default('eu-west-1'),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Organization = z.infer<typeof organizationSchema>;

/**
 * Schéma création organisation
 */
export const createOrganizationSchema = organizationSchema.pick({
  name: true,
  slug: true,
});

export type CreateOrganizationInput = z.infer<typeof createOrganizationSchema>;

/**
 * Schéma mise à jour organisation
 */
export const updateOrganizationSchema = organizationSchema
  .pick({
    name: true,
    logoUrl: true,
    settings: true,
  })
  .partial();

export type UpdateOrganizationInput = z.infer<typeof updateOrganizationSchema>;
