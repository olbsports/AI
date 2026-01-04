'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';

import { Button, Input, Alert, AlertDescription } from '@horse-vision/ui';
import { api } from '@/lib/api';

export default function ForgotPasswordPage() {
  const t = useTranslations('auth.login');

  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      await api.auth.forgotPassword({ email });
      setSuccess(true);
    } catch (err: any) {
      setError(err.message || 'Une erreur est survenue');
    } finally {
      setIsLoading(false);
    }
  };

  if (success) {
    return (
      <div className="space-y-6 text-center">
        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
          <svg
            className="w-8 h-8 text-green-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
            />
          </svg>
        </div>
        <h2 className="text-2xl font-bold">Email envoyé !</h2>
        <p className="text-muted-foreground">
          Si un compte existe avec l'adresse <strong>{email}</strong>, vous recevrez
          un email avec les instructions pour réinitialiser votre mot de passe.
        </p>
        <Link href="/auth/login">
          <Button variant="outline" className="mt-4">
            Retour à la connexion
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="text-center lg:text-left">
        <h2 className="text-2xl font-bold">Mot de passe oublié</h2>
        <p className="text-muted-foreground mt-2">
          Entrez votre adresse email et nous vous enverrons un lien pour
          réinitialiser votre mot de passe.
        </p>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <label htmlFor="email" className="text-sm font-medium">
            {t('email')}
          </label>
          <Input
            id="email"
            type="email"
            placeholder="vous@exemple.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
        </div>

        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? 'Envoi en cours...' : 'Envoyer le lien'}
        </Button>
      </form>

      <div className="text-center">
        <Link
          href="/auth/login"
          className="text-sm text-primary hover:underline"
        >
          ← Retour à la connexion
        </Link>
      </div>
    </div>
  );
}
