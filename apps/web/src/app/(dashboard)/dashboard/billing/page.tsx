'use client';

import { useState } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  Button,
  Badge,
} from '@horse-vision/ui';
import {
  CreditCard,
  Check,
  Download,
  ExternalLink,
  Zap,
  Building2,
  Crown,
} from 'lucide-react';

interface Plan {
  id: string;
  name: string;
  price: number;
  interval: 'month' | 'year';
  features: string[];
  popular?: boolean;
  icon: React.ReactNode;
}

const plans: Plan[] = [
  {
    id: 'starter',
    name: 'Starter',
    price: 49,
    interval: 'month',
    icon: <Zap className="h-6 w-6" />,
    features: [
      '50 analyses par mois',
      '3 utilisateurs',
      '10 GB stockage',
      'Support email',
      'Rapports PDF',
    ],
  },
  {
    id: 'professional',
    name: 'Professional',
    price: 149,
    interval: 'month',
    popular: true,
    icon: <Building2 className="h-6 w-6" />,
    features: [
      '200 analyses par mois',
      '10 utilisateurs',
      '50 GB stockage',
      'Support prioritaire',
      'API access',
      'Intégrations tierces',
    ],
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    price: 499,
    interval: 'month',
    icon: <Crown className="h-6 w-6" />,
    features: [
      'Analyses illimitées',
      'Utilisateurs illimités',
      'Stockage illimité',
      'Support dédié 24/7',
      'SLA garanti',
      'Formation personnalisée',
    ],
  },
];

const invoices = [
  { id: '1', number: 'INV-2024-001', date: '2024-01-01', amount: 149, status: 'paid' },
  { id: '2', number: 'INV-2023-012', date: '2023-12-01', amount: 149, status: 'paid' },
  { id: '3', number: 'INV-2023-011', date: '2023-11-01', amount: 149, status: 'paid' },
];

export default function BillingPage() {
  const [currentPlan] = useState('professional');
  const [billingInterval, setBillingInterval] = useState<'month' | 'year'>('month');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold">Facturation</h1>
        <p className="text-muted-foreground">
          Gérez votre abonnement et consultez vos factures
        </p>
      </div>

      {/* Current Plan */}
      <Card>
        <CardHeader>
          <CardTitle>Abonnement Actuel</CardTitle>
          <CardDescription>
            Votre plan actuel et les détails de facturation
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <div className="flex items-center gap-2">
                <Building2 className="h-5 w-5 text-primary" />
                <span className="text-xl font-bold">Plan Professional</span>
                <Badge>Actif</Badge>
              </div>
              <p className="text-muted-foreground mt-1">
                Prochaine facturation: 1 février 2024 • 149€/mois
              </p>
            </div>
            <div className="flex gap-2">
              <Button variant="outline">
                <ExternalLink className="h-4 w-4 mr-2" />
                Portail de facturation
              </Button>
              <Button variant="outline">
                Annuler l'abonnement
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Plans */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold">Changer de plan</h2>
          <div className="flex items-center gap-2 bg-muted p-1 rounded-lg">
            <Button
              variant={billingInterval === 'month' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setBillingInterval('month')}
            >
              Mensuel
            </Button>
            <Button
              variant={billingInterval === 'year' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setBillingInterval('year')}
            >
              Annuel
              <Badge variant="secondary" className="ml-2">-20%</Badge>
            </Button>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          {plans.map((plan) => {
            const price = billingInterval === 'year'
              ? Math.round(plan.price * 12 * 0.8)
              : plan.price;
            const isCurrentPlan = plan.id === currentPlan;

            return (
              <Card
                key={plan.id}
                className={plan.popular ? 'border-primary shadow-lg' : ''}
              >
                {plan.popular && (
                  <div className="bg-primary text-primary-foreground text-center text-sm py-1 rounded-t-lg">
                    Le plus populaire
                  </div>
                )}
                <CardHeader>
                  <div className="flex items-center gap-2">
                    {plan.icon}
                    <CardTitle>{plan.name}</CardTitle>
                  </div>
                  <div className="mt-2">
                    <span className="text-3xl font-bold">{price}€</span>
                    <span className="text-muted-foreground">
                      /{billingInterval === 'year' ? 'an' : 'mois'}
                    </span>
                  </div>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2 mb-4">
                    {plan.features.map((feature, i) => (
                      <li key={i} className="flex items-center gap-2 text-sm">
                        <Check className="h-4 w-4 text-green-500" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <Button
                    className="w-full"
                    variant={isCurrentPlan ? 'outline' : 'default'}
                    disabled={isCurrentPlan}
                  >
                    {isCurrentPlan ? 'Plan actuel' : 'Choisir ce plan'}
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Payment Method */}
      <Card>
        <CardHeader>
          <CardTitle>Méthode de Paiement</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-2 bg-muted rounded">
                <CreditCard className="h-6 w-6" />
              </div>
              <div>
                <p className="font-medium">Visa •••• 4242</p>
                <p className="text-sm text-muted-foreground">Expire 12/2025</p>
              </div>
            </div>
            <Button variant="outline">Modifier</Button>
          </div>
        </CardContent>
      </Card>

      {/* Invoices */}
      <Card>
        <CardHeader>
          <CardTitle>Historique des Factures</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {invoices.map((invoice) => (
              <div
                key={invoice.id}
                className="flex items-center justify-between py-3 border-b last:border-0"
              >
                <div>
                  <p className="font-medium">{invoice.number}</p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(invoice.date).toLocaleDateString('fr-FR')}
                  </p>
                </div>
                <div className="flex items-center gap-4">
                  <span className="font-medium">{invoice.amount}€</span>
                  <Badge variant="outline" className="text-green-600">
                    Payée
                  </Badge>
                  <Button variant="ghost" size="sm">
                    <Download className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
