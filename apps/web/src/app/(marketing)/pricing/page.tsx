import { Metadata } from 'next';
import Link from 'next/link';
import { Check, X, Zap, Building2, Crown } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Tarifs | Horse Vision AI',
  description: 'Découvrez nos formules adaptées à tous les besoins',
};

const plans = [
  {
    name: 'Starter',
    description: 'Pour les particuliers et petites écuries',
    price: '29',
    period: '/mois',
    icon: Zap,
    color: 'blue',
    popular: false,
    features: [
      { text: '50 tokens/mois', included: true },
      { text: 'Jusqu\'à 5 chevaux', included: true },
      { text: 'Analyses de locomotion', included: true },
      { text: 'Rapports PDF basiques', included: true },
      { text: 'Support email', included: true },
      { text: 'Rapports vétérinaires avancés', included: false },
      { text: 'API access', included: false },
      { text: 'Multi-utilisateurs', included: false },
    ],
  },
  {
    name: 'Professional',
    description: 'Pour les vétérinaires et écuries',
    price: '79',
    period: '/mois',
    icon: Building2,
    color: 'primary',
    popular: true,
    features: [
      { text: '200 tokens/mois', included: true },
      { text: 'Chevaux illimités', included: true },
      { text: 'Analyses de locomotion', included: true },
      { text: 'Rapports vétérinaires complets', included: true },
      { text: 'Support prioritaire', included: true },
      { text: 'Multi-utilisateurs (5)', included: true },
      { text: 'Export données', included: true },
      { text: 'API access', included: false },
    ],
  },
  {
    name: 'Enterprise',
    description: 'Pour les grandes structures',
    price: 'Sur mesure',
    period: '',
    icon: Crown,
    color: 'amber',
    popular: false,
    features: [
      { text: 'Tokens illimités', included: true },
      { text: 'Chevaux illimités', included: true },
      { text: 'Toutes les analyses', included: true },
      { text: 'Rapports personnalisés', included: true },
      { text: 'Support dédié 24/7', included: true },
      { text: 'Utilisateurs illimités', included: true },
      { text: 'API complète', included: true },
      { text: 'Intégration sur mesure', included: true },
    ],
  },
];

const faqs = [
  {
    question: 'Qu\'est-ce qu\'un token ?',
    answer: 'Un token correspond à une minute de vidéo analysée. Une analyse typique de 2 minutes consomme donc 2 tokens. Les tokens non utilisés sont reportés le mois suivant.',
  },
  {
    question: 'Puis-je changer de formule ?',
    answer: 'Oui, vous pouvez upgrader ou downgrader votre formule à tout moment. Le changement prend effet immédiatement et le prix est ajusté au prorata.',
  },
  {
    question: 'Y a-t-il un engagement ?',
    answer: 'Non, toutes nos formules sont sans engagement. Vous pouvez annuler à tout moment et vous ne serez plus facturé le mois suivant.',
  },
  {
    question: 'Proposez-vous un essai gratuit ?',
    answer: 'Oui, toutes nos formules incluent un essai gratuit de 14 jours avec 10 tokens offerts. Aucune carte bancaire n\'est requise.',
  },
];

export default function PricingPage() {
  return (
    <main>
      {/* Header */}
      <section className="pt-20 pb-16 bg-gradient-to-b from-primary/5 to-white">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            Tarifs simples et transparents
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Choisissez la formule adaptée à vos besoins.
            Commencez gratuitement, évoluez quand vous voulez.
          </p>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`relative rounded-2xl border-2 p-8 ${
                  plan.popular
                    ? 'border-primary shadow-xl scale-105'
                    : 'border-gray-200'
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                    <span className="bg-primary text-white text-sm font-medium px-4 py-1 rounded-full">
                      Le plus populaire
                    </span>
                  </div>
                )}

                <div className="text-center mb-8">
                  <div className={`w-12 h-12 rounded-xl mx-auto mb-4 flex items-center justify-center ${
                    plan.popular ? 'bg-primary/10' : 'bg-gray-100'
                  }`}>
                    <plan.icon className={`h-6 w-6 ${
                      plan.popular ? 'text-primary' : 'text-gray-600'
                    }`} />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">{plan.name}</h3>
                  <p className="text-gray-500 mt-1">{plan.description}</p>
                  <div className="mt-4">
                    <span className="text-4xl font-bold text-gray-900">
                      {plan.price}€
                    </span>
                    <span className="text-gray-500">{plan.period}</span>
                  </div>
                </div>

                <ul className="space-y-4 mb-8">
                  {plan.features.map((feature) => (
                    <li key={feature.text} className="flex items-center gap-3">
                      {feature.included ? (
                        <Check className="h-5 w-5 text-green-500 flex-shrink-0" />
                      ) : (
                        <X className="h-5 w-5 text-gray-300 flex-shrink-0" />
                      )}
                      <span className={feature.included ? 'text-gray-700' : 'text-gray-400'}>
                        {feature.text}
                      </span>
                    </li>
                  ))}
                </ul>

                <Link
                  href="/auth/register"
                  className={`block w-full py-3 rounded-xl font-medium text-center transition-colors ${
                    plan.popular
                      ? 'bg-primary text-white hover:bg-primary/90'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {plan.price === 'Sur mesure' ? 'Nous contacter' : 'Commencer l\'essai gratuit'}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Token Packs */}
      <section className="py-16 bg-gray-50">
        <div className="container mx-auto px-4">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Besoin de plus de tokens ?
            </h2>
            <p className="text-gray-600">
              Achetez des packs de tokens supplémentaires à tout moment
            </p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 max-w-4xl mx-auto">
            {[
              { tokens: 50, price: 15, popular: false },
              { tokens: 100, price: 25, popular: true },
              { tokens: 250, price: 50, popular: false },
              { tokens: 500, price: 80, popular: false },
            ].map((pack) => (
              <div
                key={pack.tokens}
                className={`rounded-xl border-2 p-6 text-center ${
                  pack.popular ? 'border-primary bg-primary/5' : 'border-gray-200 bg-white'
                }`}
              >
                <div className="text-3xl font-bold text-gray-900">{pack.tokens}</div>
                <div className="text-gray-500 mb-2">tokens</div>
                <div className="text-xl font-semibold text-primary">{pack.price}€</div>
                <div className="text-xs text-gray-400 mt-1">
                  {(pack.price / pack.tokens).toFixed(2)}€/token
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Questions fréquentes
            </h2>
          </div>

          <div className="max-w-3xl mx-auto space-y-4">
            {faqs.map((faq) => (
              <div key={faq.question} className="border rounded-xl p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  {faq.question}
                </h3>
                <p className="text-gray-600">{faq.answer}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 bg-primary">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold text-white mb-4">
            Prêt à commencer ?
          </h2>
          <p className="text-white/80 mb-8">
            14 jours d'essai gratuit, sans carte bancaire
          </p>
          <Link
            href="/auth/register"
            className="inline-block bg-white text-primary px-8 py-4 rounded-xl font-semibold hover:bg-gray-100 transition-colors"
          >
            Démarrer gratuitement
          </Link>
        </div>
      </section>
    </main>
  );
}
