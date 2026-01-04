import { z } from 'zod';

/**
 * Rôles utilisateur
 */
export const UserRole = {
  OWNER: 'owner',
  ADMIN: 'admin',
  MEMBER: 'member',
  VIEWER: 'viewer',
} as const;

export type UserRole = (typeof UserRole)[keyof typeof UserRole];

/**
 * Schéma utilisateur
 */
export const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  emailVerified: z.boolean().default(false),
  firstName: z.string().min(1).max(100).optional(),
  lastName: z.string().min(1).max(100).optional(),
  avatarUrl: z.string().url().optional(),
  role: z.nativeEnum(UserRole),
  organizationId: z.string().uuid(),

  // Sécurité
  mfaEnabled: z.boolean().default(false),
  lastLoginAt: z.date().optional(),

  // Préférences
  locale: z.string().default('fr-FR'),
  timezone: z.string().default('Europe/Paris'),
  theme: z.enum(['light', 'dark', 'system']).default('system'),

  // Timestamps
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type User = z.infer<typeof userSchema>;

/**
 * Schéma création utilisateur
 */
export const createUserSchema = userSchema.pick({
  email: true,
  firstName: true,
  lastName: true,
  role: true,
  organizationId: true,
});

export type CreateUserInput = z.infer<typeof createUserSchema>;

/**
 * Schéma mise à jour utilisateur
 */
export const updateUserSchema = userSchema
  .pick({
    firstName: true,
    lastName: true,
    avatarUrl: true,
    locale: true,
    timezone: true,
    theme: true,
  })
  .partial();

export type UpdateUserInput = z.infer<typeof updateUserSchema>;

/**
 * Utilisateur public (sans données sensibles)
 */
export const publicUserSchema = userSchema.pick({
  id: true,
  firstName: true,
  lastName: true,
  avatarUrl: true,
  role: true,
});

export type PublicUser = z.infer<typeof publicUserSchema>;
