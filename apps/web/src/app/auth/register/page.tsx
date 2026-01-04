import { Metadata } from 'next';
import Link from 'next/link';
import { RegisterForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Inscription | Horse Vision AI',
  description: 'Créez votre compte Horse Vision AI',
};

export default function RegisterPage() {
  return (
    <div className="min-h-screen flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary to-primary/80 p-12 flex-col justify-between">
        <div>
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center">
              <span className="text-primary font-bold text-xl">HV</span>
            </div>
            <span className="text-white font-bold text-xl">Horse Vision AI</span>
          </Link>
        </div>

        <div className="space-y-6">
          <h1 className="text-4xl font-bold text-white">
            Rejoignez la révolution équine
          </h1>
          <p className="text-white/80 text-lg">
            Créez votre compte et commencez à analyser vos chevaux avec
            l'intelligence artificielle la plus avancée du marché.
          </p>

          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <span className="text-white">Analyse de locomotion en temps réel</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <span className="text-white">Rapports vétérinaires détaillés</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <span className="text-white">Suivi de l'évolution dans le temps</span>
            </div>
          </div>
        </div>

        <p className="text-white/60 text-sm">
          © 2024 Horse Vision AI. Tous droits réservés.
        </p>
      </div>

      {/* Right Side - Form */}
      <div className="flex-1 flex items-center justify-center p-8 overflow-y-auto">
        <div className="w-full max-w-md space-y-8 py-8">
          <div className="text-center lg:text-left">
            <div className="lg:hidden flex justify-center mb-8">
              <Link href="/" className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-xl">HV</span>
                </div>
                <span className="text-gray-900 font-bold text-xl">Horse Vision AI</span>
              </Link>
            </div>
            <h2 className="text-2xl font-bold text-gray-900">
              Créer votre compte
            </h2>
            <p className="mt-2 text-gray-600">
              Commencez à analyser vos chevaux dès aujourd'hui
            </p>
          </div>

          <RegisterForm />
        </div>
      </div>
    </div>
  );
}
