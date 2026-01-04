import { Metadata } from 'next';
import Link from 'next/link';
import { ForgotPasswordForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Mot de passe oublié | Horse Vision AI',
  description: 'Réinitialisez votre mot de passe Horse Vision AI',
};

export default function ForgotPasswordPage() {
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
          <ForgotPasswordForm />
        </div>
      </div>
    </div>
  );
}
