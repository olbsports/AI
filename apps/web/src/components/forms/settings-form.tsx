'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Loader2, Eye, EyeOff, Bell, Mail, Shield } from 'lucide-react';
import { z } from 'zod';
import { useApi } from '@/hooks/use-api';

const passwordSchema = z.object({
  currentPassword: z.string().min(1, 'Le mot de passe actuel est requis'),
  newPassword: z
    .string()
    .min(8, 'Le mot de passe doit contenir au moins 8 caractères')
    .regex(/[A-Z]/, 'Le mot de passe doit contenir au moins une majuscule')
    .regex(/[a-z]/, 'Le mot de passe doit contenir au moins une minuscule')
    .regex(/[0-9]/, 'Le mot de passe doit contenir au moins un chiffre'),
  confirmPassword: z.string().min(1, 'La confirmation est requise'),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
});

type PasswordFormData = z.infer<typeof passwordSchema>;

interface NotificationSettings {
  emailAnalysisComplete: boolean;
  emailReportReady: boolean;
  emailWeeklySummary: boolean;
  pushAnalysisComplete: boolean;
  pushReportReady: boolean;
  marketingEmails: boolean;
}

export function SettingsForm() {
  const api = useApi();

  // Password form state
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordSuccess, setPasswordSuccess] = useState(false);

  // Notification settings state
  const [notifications, setNotifications] = useState<NotificationSettings>({
    emailAnalysisComplete: true,
    emailReportReady: true,
    emailWeeklySummary: false,
    pushAnalysisComplete: true,
    pushReportReady: true,
    marketingEmails: false,
  });
  const [notificationsSaving, setNotificationsSaving] = useState(false);
  const [notificationsSuccess, setNotificationsSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<PasswordFormData>({
    resolver: zodResolver(passwordSchema),
  });

  const onPasswordSubmit = async (data: PasswordFormData) => {
    setPasswordError(null);
    setPasswordSuccess(false);
    try {
      await api.auth.changePassword(data.currentPassword, data.newPassword);
      setPasswordSuccess(true);
      reset();
      setTimeout(() => setPasswordSuccess(false), 3000);
    } catch (err) {
      setPasswordError(
        err instanceof Error
          ? err.message
          : 'Une erreur est survenue'
      );
    }
  };

  const handleNotificationChange = (key: keyof NotificationSettings) => {
    setNotifications((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const saveNotifications = async () => {
    setNotificationsSaving(true);
    try {
      // API call would go here
      await new Promise((resolve) => setTimeout(resolve, 500));
      setNotificationsSuccess(true);
      setTimeout(() => setNotificationsSuccess(false), 3000);
    } finally {
      setNotificationsSaving(false);
    }
  };

  return (
    <div className="space-y-8">
      {/* Password Section */}
      <div className="bg-white rounded-lg border p-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="p-2 bg-primary/10 rounded-lg">
            <Shield className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h3 className="text-lg font-medium text-gray-900">
              Modifier le mot de passe
            </h3>
            <p className="text-sm text-gray-500">
              Sécurisez votre compte avec un nouveau mot de passe
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit(onPasswordSubmit)} className="space-y-4">
          {passwordError && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{passwordError}</p>
            </div>
          )}

          {passwordSuccess && (
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-sm text-green-600">
                Mot de passe modifié avec succès
              </p>
            </div>
          )}

          <div className="space-y-2">
            <label htmlFor="currentPassword" className="block text-sm font-medium text-gray-700">
              Mot de passe actuel
            </label>
            <div className="relative">
              <input
                {...register('currentPassword')}
                type={showCurrentPassword ? 'text' : 'password'}
                id="currentPassword"
                className={`block w-full px-3 py-2.5 pr-10 border rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.currentPassword ? 'border-red-500' : 'border-gray-300'
                }`}
              />
              <button
                type="button"
                onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                {showCurrentPassword ? (
                  <EyeOff className="h-5 w-5 text-gray-400" />
                ) : (
                  <Eye className="h-5 w-5 text-gray-400" />
                )}
              </button>
            </div>
            {errors.currentPassword && (
              <p className="text-sm text-red-600">{errors.currentPassword.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <label htmlFor="newPassword" className="block text-sm font-medium text-gray-700">
              Nouveau mot de passe
            </label>
            <div className="relative">
              <input
                {...register('newPassword')}
                type={showNewPassword ? 'text' : 'password'}
                id="newPassword"
                className={`block w-full px-3 py-2.5 pr-10 border rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.newPassword ? 'border-red-500' : 'border-gray-300'
                }`}
              />
              <button
                type="button"
                onClick={() => setShowNewPassword(!showNewPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                {showNewPassword ? (
                  <EyeOff className="h-5 w-5 text-gray-400" />
                ) : (
                  <Eye className="h-5 w-5 text-gray-400" />
                )}
              </button>
            </div>
            {errors.newPassword && (
              <p className="text-sm text-red-600">{errors.newPassword.message}</p>
            )}
            <p className="text-xs text-gray-500">
              Minimum 8 caractères avec majuscule, minuscule et chiffre
            </p>
          </div>

          <div className="space-y-2">
            <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
              Confirmer le nouveau mot de passe
            </label>
            <div className="relative">
              <input
                {...register('confirmPassword')}
                type={showConfirmPassword ? 'text' : 'password'}
                id="confirmPassword"
                className={`block w-full px-3 py-2.5 pr-10 border rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.confirmPassword ? 'border-red-500' : 'border-gray-300'
                }`}
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                {showConfirmPassword ? (
                  <EyeOff className="h-5 w-5 text-gray-400" />
                ) : (
                  <Eye className="h-5 w-5 text-gray-400" />
                )}
              </button>
            </div>
            {errors.confirmPassword && (
              <p className="text-sm text-red-600">{errors.confirmPassword.message}</p>
            )}
          </div>

          <div className="flex justify-end pt-2">
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex items-center px-4 py-2.5 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="animate-spin -ml-1 mr-2 h-4 w-4" />
                  Modification...
                </>
              ) : (
                'Modifier le mot de passe'
              )}
            </button>
          </div>
        </form>
      </div>

      {/* Notifications Section */}
      <div className="bg-white rounded-lg border p-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="p-2 bg-primary/10 rounded-lg">
            <Bell className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h3 className="text-lg font-medium text-gray-900">
              Notifications
            </h3>
            <p className="text-sm text-gray-500">
              Gérez vos préférences de notifications
            </p>
          </div>
        </div>

        {notificationsSuccess && (
          <div className="p-4 mb-4 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-sm text-green-600">
              Préférences enregistrées
            </p>
          </div>
        )}

        <div className="space-y-6">
          {/* Email Notifications */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <Mail className="h-4 w-4 text-gray-500" />
              <span className="text-sm font-medium text-gray-700">
                Notifications par email
              </span>
            </div>
            <div className="space-y-3 ml-6">
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Analyse terminée</span>
                <input
                  type="checkbox"
                  checked={notifications.emailAnalysisComplete}
                  onChange={() => handleNotificationChange('emailAnalysisComplete')}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
              </label>
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Rapport disponible</span>
                <input
                  type="checkbox"
                  checked={notifications.emailReportReady}
                  onChange={() => handleNotificationChange('emailReportReady')}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
              </label>
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Résumé hebdomadaire</span>
                <input
                  type="checkbox"
                  checked={notifications.emailWeeklySummary}
                  onChange={() => handleNotificationChange('emailWeeklySummary')}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
              </label>
            </div>
          </div>

          {/* Push Notifications */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <Bell className="h-4 w-4 text-gray-500" />
              <span className="text-sm font-medium text-gray-700">
                Notifications push
              </span>
            </div>
            <div className="space-y-3 ml-6">
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Analyse terminée</span>
                <input
                  type="checkbox"
                  checked={notifications.pushAnalysisComplete}
                  onChange={() => handleNotificationChange('pushAnalysisComplete')}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
              </label>
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Rapport disponible</span>
                <input
                  type="checkbox"
                  checked={notifications.pushReportReady}
                  onChange={() => handleNotificationChange('pushReportReady')}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
              </label>
            </div>
          </div>

          {/* Marketing */}
          <div className="pt-4 border-t">
            <label className="flex items-center justify-between">
              <div>
                <span className="text-sm font-medium text-gray-700">
                  Emails marketing
                </span>
                <p className="text-xs text-gray-500">
                  Recevez nos actualités et offres spéciales
                </p>
              </div>
              <input
                type="checkbox"
                checked={notifications.marketingEmails}
                onChange={() => handleNotificationChange('marketingEmails')}
                className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
              />
            </label>
          </div>
        </div>

        <div className="flex justify-end pt-6">
          <button
            onClick={saveNotifications}
            disabled={notificationsSaving}
            className="flex items-center px-4 py-2.5 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {notificationsSaving ? (
              <>
                <Loader2 className="animate-spin -ml-1 mr-2 h-4 w-4" />
                Enregistrement...
              </>
            ) : (
              'Enregistrer les préférences'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
