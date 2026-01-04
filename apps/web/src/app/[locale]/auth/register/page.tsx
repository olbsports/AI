'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

import { Button, Input, Alert, AlertDescription } from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';
import { api } from '@/lib/api';

export default function RegisterPage() {
  const t = useTranslations('auth.register');
  const router = useRouter();
  const setAuth = useAuthStore((state) => state.setAuth);

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: '',
    organizationName: '',
    acceptTerms: false,
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (formData.password !== formData.confirmPassword) {
      setError('Les mots de passe ne correspondent pas');
      return;
    }

    if (!formData.acceptTerms) {
      setError('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    setIsLoading(true);

    try {
      const response = await api.auth.register({
        email: formData.email,
        password: formData.password,
        firstName: formData.firstName,
        lastName: formData.lastName,
        organizationName: formData.organizationName,
        acceptTerms: formData.acceptTerms,
      });

      if (response.data) {
        setAuth({
          user: response.data.user,
          organization: response.data.organization,
          accessToken: response.data.accessToken,
          refreshToken: response.data.refreshToken,
        });
        router.push('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Une erreur est survenue');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="text-center lg:text-left">
        <h2 className="text-2xl font-bold">{t('title')}</h2>
        <p className="text-muted-foreground mt-2">
          {t('hasAccount')}{' '}
          <Link href={"/auth/login" as any} className="text-primary hover:underline">
            {t('login')}
          </Link>
        </p>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <label htmlFor="firstName" className="text-sm font-medium">
              {t('firstName')}
            </label>
            <Input
              id="firstName"
              name="firstName"
              placeholder="Jean"
              value={formData.firstName}
              onChange={handleChange}
              required
            />
          </div>
          <div className="space-y-2">
            <label htmlFor="lastName" className="text-sm font-medium">
              {t('lastName')}
            </label>
            <Input
              id="lastName"
              name="lastName"
              placeholder="Dupont"
              value={formData.lastName}
              onChange={handleChange}
              required
            />
          </div>
        </div>

        <div className="space-y-2">
          <label htmlFor="email" className="text-sm font-medium">
            {t('email')}
          </label>
          <Input
            id="email"
            name="email"
            type="email"
            placeholder="vous@exemple.com"
            value={formData.email}
            onChange={handleChange}
            required
            autoComplete="email"
          />
        </div>

        <div className="space-y-2">
          <label htmlFor="organizationName" className="text-sm font-medium">
            {t('organization')}
          </label>
          <Input
            id="organizationName"
            name="organizationName"
            placeholder="Ma Clinique Vétérinaire"
            value={formData.organizationName}
            onChange={handleChange}
            required
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <label htmlFor="password" className="text-sm font-medium">
              {t('password')}
            </label>
            <Input
              id="password"
              name="password"
              type="password"
              placeholder="••••••••"
              value={formData.password}
              onChange={handleChange}
              required
              minLength={8}
              autoComplete="new-password"
            />
          </div>
          <div className="space-y-2">
            <label htmlFor="confirmPassword" className="text-sm font-medium">
              {t('confirmPassword')}
            </label>
            <Input
              id="confirmPassword"
              name="confirmPassword"
              type="password"
              placeholder="••••••••"
              value={formData.confirmPassword}
              onChange={handleChange}
              required
              minLength={8}
              autoComplete="new-password"
            />
          </div>
        </div>

        <div className="flex items-start gap-2">
          <input
            id="acceptTerms"
            name="acceptTerms"
            type="checkbox"
            checked={formData.acceptTerms}
            onChange={handleChange}
            className="rounded border-gray-300 mt-1"
            required
          />
          <label htmlFor="acceptTerms" className="text-sm">
            {t('terms')}{' '}
            <Link href={"/legal/terms" as any} className="text-primary hover:underline">
              conditions d'utilisation
            </Link>{' '}
            et la{' '}
            <Link href={"/legal/privacy" as any} className="text-primary hover:underline">
              politique de confidentialité
            </Link>
          </label>
        </div>

        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? 'Création du compte...' : t('submit')}
        </Button>
      </form>

      <p className="text-xs text-muted-foreground text-center">
        En créant un compte, vous bénéficiez de 100 tokens gratuits pour tester la plateforme.
      </p>
    </div>
  );
}
