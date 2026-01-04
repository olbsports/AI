import { Metadata } from 'next';
import Link from 'next/link';
import { Suspense } from 'react';
import { ResetPasswordForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Réinitialiser le mot de passe | Horse Vision AI',
  description: 'Choisissez un nouveau mot de passe pour votre compte',
};

function ResetPasswordContent() {
  return <ResetPasswordForm />;
}

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-8">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center">
          <Link href="/" className="inline-flex items-center gap-3 mb-8">
            <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xl">HV</span>
            </div>
            <span className="text-gray-900 font-bold text-xl">Horse Vision AI</span>
          </Link>
        </div>

        <div className="bg-white rounded-xl shadow-sm border p-8">
          <Suspense fallback={<div className="animate-pulse h-64 bg-gray-100 rounded-lg" />}>
            <ResetPasswordContent />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
