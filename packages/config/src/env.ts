import { z } from 'zod';

/**
 * Schéma de validation des variables d'environnement partagées
 */
export const sharedEnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

/**
 * Schéma pour le backend
 */
export const serverEnvSchema = sharedEnvSchema.extend({
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),

  // S3
  S3_BUCKET: z.string(),
  S3_REGION: z.string().default('eu-west-1'),
  S3_ACCESS_KEY_ID: z.string(),
  S3_SECRET_ACCESS_KEY: z.string(),

  // Stripe
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),

  // Email
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().default(587),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  EMAIL_FROM: z.string().email().default('noreply@horsevision.ai'),

  // OpenAI / Claude
  OPENAI_API_KEY: z.string().optional(),
  ANTHROPIC_API_KEY: z.string().optional(),
});

/**
 * Schéma pour le frontend
 */
export const clientEnvSchema = sharedEnvSchema.extend({
  NEXT_PUBLIC_API_URL: z.string().url(),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith('pk_'),
  NEXT_PUBLIC_SENTRY_DSN: z.string().url().optional(),
});

export type SharedEnv = z.infer<typeof sharedEnvSchema>;
export type ServerEnv = z.infer<typeof serverEnvSchema>;
export type ClientEnv = z.infer<typeof clientEnvSchema>;
