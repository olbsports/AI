import { Metadata } from 'next';
import Link from 'next/link';
import { LoginForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Connexion | Horse Vision AI',
  description: 'Connectez-vous à votre compte Horse Vision AI',
};

export default function LoginPage() {
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
            Analyse équine par Intelligence Artificielle
          </h1>
          <p className="text-white/80 text-lg">
            Obtenez des rapports vétérinaires détaillés et des analyses de locomotion
            grâce à notre technologie de pointe.
          </p>
          <div className="flex items-center gap-4">
            <div className="flex -space-x-2">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="w-10 h-10 rounded-full bg-white/20 border-2 border-white/40"
                />
              ))}
            </div>
            <p className="text-white/80 text-sm">
              +500 professionnels nous font confiance
            </p>
          </div>
        </div>

        <p className="text-white/60 text-sm">
          © 2024 Horse Vision AI. Tous droits réservés.
        </p>
      </div>

      {/* Right Side - Form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md space-y-8">
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
              Connexion à votre compte
            </h2>
            <p className="mt-2 text-gray-600">
              Accédez à vos analyses et rapports
            </p>
          </div>

          <LoginForm />
        </div>
      </div>
    </div>
  );
}
