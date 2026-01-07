import type { ApiClient } from '../client';
import type {
  LoginRequest,
  RegisterRequest,
  ForgotPasswordRequest,
  ResetPasswordRequest,
  ChangePasswordRequest,
  Verify2FARequest,
  AuthResponse,
  RefreshTokenResponse,
} from '@horse-tempo/types';

export function createAuthEndpoints(client: ApiClient) {
  return {
    /**
     * Connexion utilisateur
     */
    login: (data: LoginRequest) =>
      client.post<AuthResponse>('/auth/login', data),

    /**
     * Inscription
     */
    register: (data: RegisterRequest) =>
      client.post<AuthResponse>('/auth/register', data),

    /**
     * Déconnexion
     */
    logout: () => client.post<void>('/auth/logout'),

    /**
     * Rafraîchir le token
     */
    refreshToken: (refreshToken: string) =>
      client.post<RefreshTokenResponse>('/auth/refresh', { refreshToken }),

    /**
     * Mot de passe oublié
     */
    forgotPassword: (data: ForgotPasswordRequest) =>
      client.post<{ message: string }>('/auth/forgot-password', data),

    /**
     * Réinitialiser le mot de passe
     */
    resetPassword: (data: ResetPasswordRequest) =>
      client.post<{ message: string }>('/auth/reset-password', data),

    /**
     * Changer le mot de passe
     */
    changePassword: (data: ChangePasswordRequest) =>
      client.post<{ message: string }>('/auth/change-password', data),

    /**
     * Vérifier le code 2FA
     */
    verify2FA: (data: Verify2FARequest) =>
      client.post<AuthResponse>('/auth/verify-2fa', data),

    /**
     * Activer 2FA
     */
    enable2FA: () =>
      client.post<{ qrCode: string; secret: string }>('/auth/enable-2fa'),

    /**
     * Désactiver 2FA
     */
    disable2FA: (code: string) =>
      client.post<{ message: string }>('/auth/disable-2fa', { code }),

    /**
     * Récupérer le profil courant
     */
    me: () => client.get<AuthResponse['user']>('/auth/me'),

    /**
     * Vérifier l'email
     */
    verifyEmail: (token: string) =>
      client.post<{ message: string }>('/auth/verify-email', { token }),

    /**
     * Renvoyer l'email de vérification
     */
    resendVerificationEmail: () =>
      client.post<{ message: string }>('/auth/resend-verification'),
  };
}
