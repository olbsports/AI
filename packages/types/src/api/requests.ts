import { z } from 'zod';

/**
 * Schéma de connexion
 */
export const loginRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  rememberMe: z.boolean().optional(),
});

export type LoginRequest = z.infer<typeof loginRequestSchema>;

/**
 * Schéma d'inscription
 */
export const registerRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(100),
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  organizationName: z.string().min(2).max(255),
  acceptTerms: z.literal(true),
});

export type RegisterRequest = z.infer<typeof registerRequestSchema>;

/**
 * Schéma reset password
 */
export const forgotPasswordRequestSchema = z.object({
  email: z.string().email(),
});

export type ForgotPasswordRequest = z.infer<typeof forgotPasswordRequestSchema>;

export const resetPasswordRequestSchema = z.object({
  token: z.string(),
  password: z.string().min(8).max(100),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Les mots de passe ne correspondent pas",
  path: ["confirmPassword"],
});

export type ResetPasswordRequest = z.infer<typeof resetPasswordRequestSchema>;

/**
 * Schéma changement de mot de passe
 */
export const changePasswordRequestSchema = z.object({
  currentPassword: z.string(),
  newPassword: z.string().min(8).max(100),
  confirmPassword: z.string(),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Les mots de passe ne correspondent pas",
  path: ["confirmPassword"],
});

export type ChangePasswordRequest = z.infer<typeof changePasswordRequestSchema>;

/**
 * Schéma vérification 2FA
 */
export const verify2FARequestSchema = z.object({
  code: z.string().length(6),
});

export type Verify2FARequest = z.infer<typeof verify2FARequestSchema>;
