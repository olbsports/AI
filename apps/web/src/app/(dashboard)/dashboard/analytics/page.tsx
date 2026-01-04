'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, Button } from '@horse-vision/ui';
import {
  Activity,
  TrendingUp,
  Users,
  Coins,
  FileText,
  BarChart3,
  Calendar,
} from 'lucide-react';
import { StatCard } from '@/components/dashboard/stat-card';
import { AreaChart, BarChart, PieChart } from '@/components/charts';

// Mock data - in production, fetch from API
const analysisTimeSeriesData = [
  { date: '01/12', value: 12 },
  { date: '02/12', value: 19 },
  { date: '03/12', value: 15 },
  { date: '04/12', value: 25 },
  { date: '05/12', value: 22 },
  { date: '06/12', value: 30 },
  { date: '07/12', value: 28 },
  { date: '08/12', value: 35 },
  { date: '09/12', value: 32 },
  { date: '10/12', value: 40 },
];

const tokenUsageData = [
  { date: '01/12', value: 50 },
  { date: '02/12', value: 65 },
  { date: '03/12', value: 45 },
  { date: '04/12', value: 80 },
  { date: '05/12', value: 75 },
  { date: '06/12', value: 90 },
  { date: '07/12', value: 85 },
  { date: '08/12', value: 110 },
  { date: '09/12', value: 95 },
  { date: '10/12', value: 120 },
];

const analysisByTypeData = [
  { name: 'Vidéo Performance', value: 45 },
  { name: 'Radiologique', value: 30 },
  { name: 'Locomotion', value: 15 },
  { name: 'Examen Achat', value: 10 },
];

const topHorsesData = [
  { name: 'Eclipse', value: 92 },
  { name: 'Thunder', value: 88 },
  { name: 'Spirit', value: 85 },
  { name: 'Luna', value: 82 },
  { name: 'Storm', value: 79 },
];

type TimeRange = '7d' | '30d' | '90d' | '1y';

export default function AnalyticsPage() {
  const [timeRange, setTimeRange] = useState<TimeRange>('30d');

  const timeRangeOptions: { value: TimeRange; label: string }[] = [
    { value: '7d', label: '7 jours' },
    { value: '30d', label: '30 jours' },
    { value: '90d', label: '90 jours' },
    { value: '1y', label: '1 an' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Analytics</h1>
          <p className="text-muted-foreground">
            Vue d'ensemble des performances et métriques
          </p>
        </div>
        <div className="flex gap-2">
          {timeRangeOptions.map((option) => (
            <Button
              key={option.value}
              variant={timeRange === option.value ? 'default' : 'outline'}
              size="sm"
              onClick={() => setTimeRange(option.value)}
            >
              {option.label}
            </Button>
          ))}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Analyses"
          value="258"
          change={12.5}
          icon={<Activity className="h-4 w-4" />}
        />
        <StatCard
          title="Taux de Réussite"
          value="94.2%"
          change={2.1}
          icon={<TrendingUp className="h-4 w-4" />}
        />
        <StatCard
          title="Tokens Utilisés"
          value="1,234"
          change={-5.3}
          icon={<Coins className="h-4 w-4" />}
        />
        <StatCard
          title="Rapports Générés"
          value="186"
          change={8.7}
          icon={<FileText className="h-4 w-4" />}
        />
      </div>

      {/* Charts Row 1 */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Analyses par jour
            </CardTitle>
          </CardHeader>
          <CardContent>
            <AreaChart
              data={analysisTimeSeriesData}
              color="#0066cc"
              height={280}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Coins className="h-5 w-5" />
              Consommation de Tokens
            </CardTitle>
          </CardHeader>
          <CardContent>
            <AreaChart
              data={tokenUsageData}
              color="#10b981"
              height={280}
            />
          </CardContent>
        </Card>
      </div>

      {/* Charts Row 2 */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Analyses par Type</CardTitle>
          </CardHeader>
          <CardContent>
            <PieChart
              data={analysisByTypeData}
              height={280}
              innerRadius={50}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top 5 Chevaux (Score Moyen)</CardTitle>
          </CardHeader>
          <CardContent>
            <BarChart
              data={topHorsesData}
              horizontal
              height={280}
              color="#8b5cf6"
            />
          </CardContent>
        </Card>
      </div>

      {/* Detailed Stats */}
      <div className="grid gap-6 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Performance Analyses</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Temps moyen</span>
              <span className="font-medium">2.3 min</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">En attente</span>
              <span className="font-medium">3</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">En cours</span>
              <span className="font-medium">1</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Échecs (30j)</span>
              <span className="font-medium text-red-600">12</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Utilisateurs Actifs</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Total</span>
              <span className="font-medium">8</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Vétérinaires</span>
              <span className="font-medium">3</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Analystes</span>
              <span className="font-medium">2</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Connectés aujourd'hui</span>
              <span className="font-medium text-green-600">5</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Chevaux & Cavaliers</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Chevaux actifs</span>
              <span className="font-medium">24</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Cavaliers</span>
              <span className="font-medium">12</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Analyses/cheval (moy.)</span>
              <span className="font-medium">10.7</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">Score global moyen</span>
              <span className="font-medium text-blue-600">78.5</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
