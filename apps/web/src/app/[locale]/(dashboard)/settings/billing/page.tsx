'use client';

import { useState } from 'react';
import {
  CreditCard,
  Coins,
  Receipt,
  TrendingUp,
  Check,
  Zap,
  Building2,
} from 'lucide-react';

import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardDescription,
  Badge,
} from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';
import { PLANS, PLAN_LIMITS, PLAN_DETAILS, TOKEN_COSTS } from '@horse-vision/config';
import { formatTokenBalance, calculateTokenPrice } from '@horse-vision/core';

export default function BillingSettingsPage() {
  const { organization } = useAuthStore();
  const [selectedTokens, setSelectedTokens] = useState(100);

  const tokenPackages = [
    { amount: 50, popular: false },
    { amount: 100, popular: true },
    { amount: 250, popular: false },
    { amount: 500, popular: false },
    { amount: 1000, popular: false },
  ];

  const invoices = [
    {
      id: '1',
      date: '2024-01-15',
      description: '100 tokens',
      amount: 10.0,
      status: 'paid',
    },
    {
      id: '2',
      date: '2024-01-01',
      description: 'Abonnement Professional - Janvier',
      amount: 49.0,
      status: 'paid',
    },
    {
      id: '3',
      date: '2023-12-15',
      description: '250 tokens',
      amount: 22.5,
      status: 'paid',
    },
  ];

  const currentPlan = organization?.plan || 'starter';
  const planLimits = PLAN_LIMITS[currentPlan as keyof typeof PLAN_LIMITS];

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Facturation</h1>
        <p className="text-muted-foreground">
          Gérez votre abonnement et vos tokens
        </p>
      </div>

      {/* Current Plan */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Plan actuel</CardTitle>
              <CardDescription>
                Votre abonnement et ses fonctionnalités
              </CardDescription>
            </div>
            <Badge variant="secondary" className="text-lg px-3 py-1 capitalize">
              {currentPlan}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div className="text-center p-4 bg-muted/50 rounded-lg">
              <p className="text-2xl font-bold">
                {planLimits.analyses === -1
                  ? '∞'
                  : planLimits.analyses}
              </p>
              <p className="text-sm text-muted-foreground">Analyses/mois</p>
            </div>
            <div className="text-center p-4 bg-muted/50 rounded-lg">
              <p className="text-2xl font-bold">
                {planLimits.horses === -1 ? '∞' : planLimits.horses}
              </p>
              <p className="text-sm text-muted-foreground">Chevaux max</p>
            </div>
            <div className="text-center p-4 bg-muted/50 rounded-lg">
              <p className="text-2xl font-bold">
                {planLimits.users === -1 ? '∞' : planLimits.users}
              </p>
              <p className="text-sm text-muted-foreground">Membres</p>
            </div>
            <div className="text-center p-4 bg-muted/50 rounded-lg">
              <p className="text-2xl font-bold">
                {planLimits.tokens === -1 ? '∞' : planLimits.tokens}
              </p>
              <p className="text-sm text-muted-foreground">Tokens inclus</p>
            </div>
          </div>

          {currentPlan !== 'enterprise' && (
            <div className="flex justify-center">
              <Button>
                <TrendingUp className="w-4 h-4 mr-2" />
                Upgrader mon plan
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Token Balance */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Coins className="w-5 h-5" />
              <CardTitle>Tokens</CardTitle>
            </div>
            <div className="text-right">
              <p className="text-3xl font-bold text-primary">
                {formatTokenBalance(organization?.tokenBalance || 0)}
              </p>
              <p className="text-sm text-muted-foreground">tokens disponibles</p>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="mb-6">
            <p className="text-sm text-muted-foreground mb-4">
              Coût par analyse:
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="p-3 border rounded-lg">
                <p className="font-medium">Parcours</p>
                <p className="text-sm text-muted-foreground">
                  {TOKEN_COSTS.COURSE_ANALYSIS} tokens
                </p>
              </div>
              <div className="p-3 border rounded-lg">
                <p className="font-medium">Performance</p>
                <p className="text-sm text-muted-foreground">
                  {TOKEN_COSTS.VIDEO_ANALYSIS} tokens
                </p>
              </div>
              <div className="p-3 border rounded-lg">
                <p className="font-medium">Radiologique</p>
                <p className="text-sm text-muted-foreground">
                  {TOKEN_COSTS.RADIO_ANALYSIS} tokens
                </p>
              </div>
              <div className="p-3 border rounded-lg">
                <p className="font-medium">Locomotion</p>
                <p className="text-sm text-muted-foreground">
                  {TOKEN_COSTS.LOCOMOTION_ANALYSIS} tokens
                </p>
              </div>
            </div>
          </div>

          <div className="border-t pt-6">
            <h4 className="font-medium mb-4">Acheter des tokens</h4>
            <div className="grid grid-cols-5 gap-3 mb-4">
              {tokenPackages.map((pkg) => (
                <button
                  key={pkg.amount}
                  onClick={() => setSelectedTokens(pkg.amount)}
                  className={`relative p-4 rounded-lg border-2 transition-all ${
                    selectedTokens === pkg.amount
                      ? 'border-primary bg-primary/5'
                      : 'border-muted hover:border-muted-foreground/50'
                  }`}
                >
                  {pkg.popular && (
                    <span className="absolute -top-2 left-1/2 -translate-x-1/2 bg-primary text-primary-foreground text-xs px-2 py-0.5 rounded-full">
                      Populaire
                    </span>
                  )}
                  <p className="text-xl font-bold">{pkg.amount}</p>
                  <p className="text-sm text-muted-foreground">tokens</p>
                </button>
              ))}
            </div>

            <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
              <div>
                <p className="font-medium">{selectedTokens} tokens</p>
                <p className="text-sm text-muted-foreground">
                  {(calculateTokenPrice(selectedTokens) / selectedTokens).toFixed(
                    2
                  )}
                  € par token
                </p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold">
                  {calculateTokenPrice(selectedTokens).toFixed(2)} €
                </p>
                <Button className="mt-2">
                  <CreditCard className="w-4 h-4 mr-2" />
                  Acheter
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Payment Method */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <CreditCard className="w-5 h-5" />
            <CardTitle>Moyen de paiement</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div className="flex items-center gap-4">
              <div className="w-12 h-8 bg-gradient-to-r from-blue-600 to-blue-400 rounded flex items-center justify-center text-white text-xs font-bold">
                VISA
              </div>
              <div>
                <p className="font-medium">•••• •••• •••• 4242</p>
                <p className="text-sm text-muted-foreground">Expire 12/25</p>
              </div>
            </div>
            <Button variant="outline">Modifier</Button>
          </div>
        </CardContent>
      </Card>

      {/* Invoices */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Receipt className="w-5 h-5" />
            <CardTitle>Historique de facturation</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <div className="divide-y">
            {invoices.map((invoice) => (
              <div
                key={invoice.id}
                className="flex items-center justify-between py-4"
              >
                <div>
                  <p className="font-medium">{invoice.description}</p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(invoice.date).toLocaleDateString('fr-FR')}
                  </p>
                </div>
                <div className="flex items-center gap-4">
                  <p className="font-medium">{invoice.amount.toFixed(2)} €</p>
                  <Badge variant="success">Payé</Badge>
                  <Button variant="ghost" size="sm">
                    PDF
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Plans Comparison */}
      <Card>
        <CardHeader>
          <CardTitle>Comparer les plans</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {Object.entries(PLAN_DETAILS).slice(0, 6).map(([planKey, details]) => (
              <div
                key={planKey}
                className={`p-6 rounded-lg border-2 ${
                  currentPlan === planKey
                    ? 'border-primary bg-primary/5'
                    : 'border-muted'
                }`}
              >
                <div className="flex items-center gap-2 mb-4">
                  {planKey === 'enterprise' ? (
                    <Building2 className="w-5 h-5 text-primary" />
                  ) : (
                    <Zap className="w-5 h-5 text-primary" />
                  )}
                  <h3 className="font-semibold capitalize">{planKey}</h3>
                </div>
                <p className="text-3xl font-bold mb-4">
                  {details.monthlyPrice === 0
                    ? 'Gratuit'
                    : details.monthlyPrice === -1
                    ? 'Sur devis'
                    : `${details.monthlyPrice}€/mois`}
                </p>
                <ul className="space-y-2 text-sm">
                  {details.features.slice(0, 5).map((feature, i) => (
                    <li key={i} className="flex items-center gap-2">
                      <Check className="w-4 h-4 text-green-500" />
                      {feature}
                    </li>
                  ))}
                </ul>
                {currentPlan !== planKey && (
                  <Button
                    className="w-full mt-4"
                    variant={planKey === 'enterprise' ? 'outline' : 'default'}
                  >
                    {planKey === 'enterprise' ? 'Contacter' : 'Upgrader'}
                  </Button>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
