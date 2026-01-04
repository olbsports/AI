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
  Progress,
} from '@horse-vision/ui';
import { Coins, Plus, ArrowUpRight, ArrowDownRight, History } from 'lucide-react';
import { AreaChart } from '@/components/charts';

const tokenPackages = [
  { amount: 100, price: 10, popular: false },
  { amount: 500, price: 45, popular: true },
  { amount: 1000, price: 80, popular: false },
  { amount: 5000, price: 350, popular: false },
];

const transactions = [
  { id: '1', type: 'credit', amount: 500, description: 'Tokens mensuels - Plan Professional', date: '2024-01-01' },
  { id: '2', type: 'debit', amount: -3, description: 'Analyse vidéo - Eclipse', date: '2024-01-02' },
  { id: '3', type: 'debit', amount: -5, description: 'Analyse radiologique - Thunder', date: '2024-01-03' },
  { id: '4', type: 'debit', amount: -1, description: 'Analyse locomotion - Spirit', date: '2024-01-04' },
  { id: '5', type: 'credit', amount: 100, description: 'Achat de tokens', date: '2024-01-05' },
  { id: '6', type: 'debit', amount: -3, description: 'Analyse vidéo - Luna', date: '2024-01-06' },
];

const usageData = [
  { date: '01/01', value: 0 },
  { date: '02/01', value: 3 },
  { date: '03/01', value: 8 },
  { date: '04/01', value: 9 },
  { date: '05/01', value: 9 },
  { date: '06/01', value: 12 },
  { date: '07/01', value: 15 },
];

export default function TokensPage() {
  const [balance] = useState(588);
  const [monthlyAllocation] = useState(500);
  const [usedThisMonth] = useState(12);

  const usagePercent = (usedThisMonth / monthlyAllocation) * 100;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold">Tokens</h1>
        <p className="text-muted-foreground">
          Gérez votre solde de tokens et consultez l'historique d'utilisation
        </p>
      </div>

      {/* Balance Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Solde Total</CardTitle>
            <Coins className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{balance.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Tokens disponibles
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Utilisation Mensuelle</CardTitle>
            <ArrowDownRight className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{usedThisMonth}</div>
            <div className="mt-2">
              <Progress value={usagePercent} className="h-2" />
              <p className="text-xs text-muted-foreground mt-1">
                {usedThisMonth} / {monthlyAllocation} tokens utilisés
              </p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Allocation Mensuelle</CardTitle>
            <ArrowUpRight className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{monthlyAllocation}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Inclus dans votre plan Professional
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Usage Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Consommation ce mois</CardTitle>
          <CardDescription>
            Évolution de l'utilisation des tokens
          </CardDescription>
        </CardHeader>
        <CardContent>
          <AreaChart data={usageData} color="#10b981" height={250} />
        </CardContent>
      </Card>

      {/* Token Costs */}
      <Card>
        <CardHeader>
          <CardTitle>Coût par Opération</CardTitle>
          <CardDescription>
            Nombre de tokens requis pour chaque type d'analyse
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {[
              { name: 'Analyse Basique', cost: 1, description: 'Photos, mesures' },
              { name: 'Analyse Avancée', cost: 3, description: 'Vidéo performance' },
              { name: 'Analyse Vidéo', cost: 5, description: 'Analyse complète' },
              { name: 'Génération Rapport', cost: 2, description: 'PDF professionnel' },
            ].map((item) => (
              <div key={item.name} className="p-4 border rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">{item.name}</span>
                  <Badge variant="secondary">{item.cost} token{item.cost > 1 ? 's' : ''}</Badge>
                </div>
                <p className="text-sm text-muted-foreground">{item.description}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Buy Tokens */}
      <Card>
        <CardHeader>
          <CardTitle>Acheter des Tokens</CardTitle>
          <CardDescription>
            Rechargez votre solde avec des tokens supplémentaires
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-4">
            {tokenPackages.map((pkg) => (
              <div
                key={pkg.amount}
                className={`p-4 border rounded-lg text-center ${
                  pkg.popular ? 'border-primary bg-primary/5' : ''
                }`}
              >
                {pkg.popular && (
                  <Badge className="mb-2">Populaire</Badge>
                )}
                <div className="text-2xl font-bold">{pkg.amount}</div>
                <div className="text-sm text-muted-foreground mb-2">tokens</div>
                <div className="text-xl font-semibold text-primary">{pkg.price}€</div>
                <div className="text-xs text-muted-foreground mb-3">
                  {(pkg.price / pkg.amount * 100).toFixed(1)} cents/token
                </div>
                <Button className="w-full" variant={pkg.popular ? 'default' : 'outline'}>
                  <Plus className="h-4 w-4 mr-2" />
                  Acheter
                </Button>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Transaction History */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Historique des Transactions
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {transactions.map((tx) => (
              <div
                key={tx.id}
                className="flex items-center justify-between py-3 border-b last:border-0"
              >
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-full ${
                    tx.type === 'credit'
                      ? 'bg-green-100 text-green-600'
                      : 'bg-red-100 text-red-600'
                  }`}>
                    {tx.type === 'credit'
                      ? <ArrowUpRight className="h-4 w-4" />
                      : <ArrowDownRight className="h-4 w-4" />
                    }
                  </div>
                  <div>
                    <p className="font-medium">{tx.description}</p>
                    <p className="text-sm text-muted-foreground">
                      {new Date(tx.date).toLocaleDateString('fr-FR')}
                    </p>
                  </div>
                </div>
                <span className={`font-semibold ${
                  tx.type === 'credit' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {tx.type === 'credit' ? '+' : ''}{tx.amount}
                </span>
              </div>
            ))}
          </div>
          <Button variant="outline" className="w-full mt-4">
            Voir tout l'historique
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
