import Link from 'next/link';
import {
  ArrowRight,
  Play,
  CheckCircle2,
  Zap,
  Shield,
  BarChart3,
  Video,
  FileText,
  Users
} from 'lucide-react';

export default function HomePage() {
  return (
    <main>
      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-b from-primary/5 to-white pt-20 pb-32">
        <div className="absolute inset-0 bg-grid-pattern opacity-5" />
        <div className="container mx-auto px-4 relative">
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-8">
              <Zap className="h-4 w-4" />
              Propulsé par l'Intelligence Artificielle
            </div>

            <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              Analysez vos chevaux avec{' '}
              <span className="text-primary">l'IA la plus avancée</span>
            </h1>

            <p className="text-xl text-gray-600 mb-10 max-w-2xl mx-auto">
              Obtenez des rapports vétérinaires détaillés et des analyses de locomotion
              en quelques minutes. Détectez les problèmes avant qu'ils ne s'aggravent.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link
                href="/auth/register"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-primary text-white px-8 py-4 rounded-xl font-semibold hover:bg-primary/90 transition-colors"
              >
                Commencer gratuitement
                <ArrowRight className="h-5 w-5" />
              </Link>
              <button className="w-full sm:w-auto inline-flex items-center justify-center gap-2 border-2 border-gray-200 text-gray-700 px-8 py-4 rounded-xl font-semibold hover:border-primary hover:text-primary transition-colors">
                <Play className="h-5 w-5" />
                Voir la démo
              </button>
            </div>

            <div className="mt-12 flex items-center justify-center gap-8 text-sm text-gray-500">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-500" />
                Essai gratuit 14 jours
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-500" />
                Sans carte bancaire
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-500" />
                Annulation facile
              </div>
            </div>
          </div>

          {/* Hero Image/Video Placeholder */}
          <div className="mt-16 max-w-5xl mx-auto">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl border bg-gray-900">
              <div className="aspect-video flex items-center justify-center">
                <div className="text-center text-white">
                  <div className="w-20 h-20 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-4">
                    <Play className="h-10 w-10 text-white" />
                  </div>
                  <p className="text-lg font-medium">Démo de Horse Vision AI</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Trusted By Section */}
      <section className="py-16 bg-gray-50 border-y">
        <div className="container mx-auto px-4">
          <p className="text-center text-gray-500 mb-8">
            Ils nous font confiance
          </p>
          <div className="flex flex-wrap items-center justify-center gap-12 opacity-50">
            {['Haras National', 'FFE', 'IFCE', 'Ecurie Royale', 'VetEquine'].map((name) => (
              <div key={name} className="text-2xl font-bold text-gray-400">
                {name}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24">
        <div className="container mx-auto px-4">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Tout ce dont vous avez besoin
            </h2>
            <p className="text-xl text-gray-600">
              Une solution complète pour l'analyse équine professionnelle
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: Video,
                title: 'Analyse Vidéo IA',
                description: 'Téléchargez une vidéo et notre IA analyse automatiquement la locomotion, la posture et les mouvements.',
              },
              {
                icon: FileText,
                title: 'Rapports Vétérinaires',
                description: 'Générez des rapports détaillés conformes aux standards vétérinaires, prêts à partager.',
              },
              {
                icon: BarChart3,
                title: 'Suivi & Historique',
                description: 'Suivez l\'évolution de chaque cheval dans le temps avec des graphiques et comparaisons.',
              },
              {
                icon: Shield,
                title: 'Données Sécurisées',
                description: 'Vos données sont chiffrées et hébergées en France, conformes RGPD.',
              },
              {
                icon: Users,
                title: 'Multi-utilisateurs',
                description: 'Gérez votre équipe avec différents niveaux d\'accès : vétérinaire, propriétaire, soigneur.',
              },
              {
                icon: Zap,
                title: 'Résultats Rapides',
                description: 'Obtenez vos analyses en quelques minutes, pas en jours. Gagnez un temps précieux.',
              },
            ].map((feature) => (
              <div
                key={feature.title}
                className="p-6 rounded-2xl border bg-white hover:shadow-lg transition-shadow"
              >
                <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                  <feature.icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-600">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-24 bg-gray-50">
        <div className="container mx-auto px-4">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Comment ça marche ?
            </h2>
            <p className="text-xl text-gray-600">
              En 3 étapes simples, obtenez une analyse complète
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="grid md:grid-cols-3 gap-8">
              {[
                {
                  step: '1',
                  title: 'Filmez votre cheval',
                  description: 'Prenez une vidéo de 30 secondes minimum en suivant nos recommandations.',
                },
                {
                  step: '2',
                  title: 'Téléchargez la vidéo',
                  description: 'Uploadez la vidéo sur notre plateforme et sélectionnez le type d\'analyse.',
                },
                {
                  step: '3',
                  title: 'Recevez votre rapport',
                  description: 'Notre IA analyse la vidéo et génère un rapport détaillé en quelques minutes.',
                },
              ].map((item) => (
                <div key={item.step} className="text-center">
                  <div className="w-16 h-16 rounded-full bg-primary text-white text-2xl font-bold flex items-center justify-center mx-auto mb-4">
                    {item.step}
                  </div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-600">
                    {item.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto bg-primary rounded-3xl p-12 text-center text-white">
            <h2 className="text-4xl font-bold mb-4">
              Prêt à révolutionner votre suivi équin ?
            </h2>
            <p className="text-xl text-white/80 mb-8">
              Rejoignez plus de 500 professionnels qui utilisent Horse Vision AI
            </p>
            <Link
              href="/auth/register"
              className="inline-flex items-center gap-2 bg-white text-primary px-8 py-4 rounded-xl font-semibold hover:bg-gray-100 transition-colors"
            >
              Démarrer l'essai gratuit
              <ArrowRight className="h-5 w-5" />
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
