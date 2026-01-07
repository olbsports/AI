import { useTranslations } from 'next-intl';
import Link from 'next/link';

interface AuthLayoutProps {
  children: React.ReactNode;
}

export default function AuthLayout({ children }: AuthLayoutProps) {
  return (
    <div className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-primary items-center justify-center p-12">
        <div className="max-w-md text-white">
          <Link href="/" className="flex items-center gap-3 mb-8">
            <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
              <span className="text-2xl">🐴</span>
            </div>
            <span className="text-2xl font-bold">Horse Tempo</span>
          </Link>
          <h1 className="text-4xl font-bold mb-6">
            Analysez vos performances équestres avec l'IA
          </h1>
          <p className="text-lg text-white/80">
            Obtenez des rapports détaillés de vos parcours de CSO et des analyses
            radiologiques professionnelles en quelques minutes.
          </p>
          <div className="mt-12 grid grid-cols-2 gap-6">
            <div className="bg-white/10 rounded-lg p-4">
              <div className="text-3xl font-bold">500+</div>
              <div className="text-sm text-white/70">Analyses réalisées</div>
            </div>
            <div className="bg-white/10 rounded-lg p-4">
              <div className="text-3xl font-bold">50+</div>
              <div className="text-sm text-white/70">Cliniques partenaires</div>
            </div>
          </div>
        </div>
      </div>

      {/* Right side - Auth form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          {children}
        </div>
      </div>
    </div>
  );
}
