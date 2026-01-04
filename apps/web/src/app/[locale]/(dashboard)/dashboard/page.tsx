'use client';

import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  TrendingUp,
  Video,
  FileText,
  Activity,
  ArrowUpRight,
  ArrowDownRight,
  Rabbit,
  Clock,
} from 'lucide-react';

import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardDescription,
  Button,
  Badge,
} from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';
import { formatTokenBalance } from '@horse-vision/core';

export default function DashboardPage() {
  const t = useTranslations('dashboard');
  const { user, organization } = useAuthStore();

  // Mock data - will be replaced with real API calls
  const stats = [
    {
      name: 'Analyses ce mois',
      value: '24',
      change: '+12%',
      trend: 'up',
      icon: Video,
    },
    {
      name: 'Rapports générés',
      value: '18',
      change: '+8%',
      trend: 'up',
      icon: FileText,
    },
    {
      name: 'Chevaux actifs',
      value: '45',
      change: '+3',
      trend: 'up',
      icon: Rabbit,
    },
    {
      name: 'Tokens utilisés',
      value: '156',
      change: '-23%',
      trend: 'down',
      icon: Activity,
    },
  ];

  const recentAnalyses = [
    {
      id: '1',
      title: 'CSI*** Grand Prix - Thunder',
      type: 'video_course',
      status: 'completed',
      score: 8.5,
      createdAt: '2024-01-15T10:30:00',
    },
    {
      id: '2',
      title: 'Radiographie - Eclipse',
      type: 'radiological',
      status: 'processing',
      createdAt: '2024-01-15T09:00:00',
    },
    {
      id: '3',
      title: 'Analyse locomotion - Storm',
      type: 'locomotion',
      status: 'completed',
      score: 7.2,
      createdAt: '2024-01-14T16:45:00',
    },
  ];

  const pendingReports = [
    {
      id: '1',
      number: 'HV-RADIO-348',
      horse: 'Eclipse',
      type: 'radiological',
      status: 'pending_review',
    },
    {
      id: '2',
      number: 'HV-COURSE-127',
      horse: 'Thunder',
      type: 'course_analysis',
      status: 'draft',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">
            {t('welcome', { name: user?.firstName })}
          </h1>
          <p className="text-muted-foreground">
            Voici un aperçu de votre activité récente
          </p>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" asChild>
            <Link href="/reports">Voir les rapports</Link>
          </Button>
          <Button asChild>
            <Link href="/analyses/new">Nouvelle analyse</Link>
          </Button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <Card key={stat.name}>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
                    <Icon className="w-5 h-5 text-primary" />
                  </div>
                  <div
                    className={`flex items-center gap-1 text-sm ${
                      stat.trend === 'up' ? 'text-green-600' : 'text-red-600'
                    }`}
                  >
                    {stat.trend === 'up' ? (
                      <ArrowUpRight className="w-4 h-4" />
                    ) : (
                      <ArrowDownRight className="w-4 h-4" />
                    )}
                    {stat.change}
                  </div>
                </div>
                <div className="mt-4">
                  <p className="text-2xl font-bold">{stat.value}</p>
                  <p className="text-sm text-muted-foreground">{stat.name}</p>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Main content grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent analyses */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Analyses récentes</CardTitle>
                <Link
                  href="/analyses"
                  className="text-sm text-primary hover:underline"
                >
                  Voir tout →
                </Link>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {recentAnalyses.map((analysis) => (
                  <Link
                    key={analysis.id}
                    href={`/analyses/${analysis.id}` as any}
                    className="flex items-center gap-4 p-3 rounded-lg hover:bg-muted transition-colors"
                  >
                    <div
                      className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                        analysis.type === 'radiological'
                          ? 'bg-purple-100'
                          : analysis.type === 'locomotion'
                          ? 'bg-blue-100'
                          : 'bg-green-100'
                      }`}
                    >
                      {analysis.type === 'radiological' ? (
                        <span className="text-lg">🩺</span>
                      ) : analysis.type === 'locomotion' ? (
                        <span className="text-lg">🏃</span>
                      ) : (
                        <span className="text-lg">🎥</span>
                      )}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium">{analysis.title}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <Badge
                          variant={
                            analysis.status === 'completed'
                              ? 'success'
                              : analysis.status === 'processing'
                              ? 'warning'
                              : 'secondary'
                          }
                        >
                          {analysis.status === 'completed'
                            ? 'Terminée'
                            : analysis.status === 'processing'
                            ? 'En cours'
                            : 'En attente'}
                        </Badge>
                        {analysis.score && (
                          <span className="text-sm text-muted-foreground">
                            Score: {analysis.score}/10
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="text-sm text-muted-foreground flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      {new Date(analysis.createdAt).toLocaleDateString('fr-FR')}
                    </div>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Token balance */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Tokens</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center">
                <p className="text-4xl font-bold text-primary">
                  {formatTokenBalance(organization?.tokenBalance ?? 0)}
                </p>
                <p className="text-sm text-muted-foreground mt-1">
                  tokens disponibles
                </p>
                <Button className="w-full mt-4" asChild>
                  <Link href="/settings/billing">Acheter des tokens</Link>
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Pending reports */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Rapports en attente</CardTitle>
                <Badge variant="secondary">{pendingReports.length}</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {pendingReports.map((report) => (
                  <Link
                    key={report.id}
                    href={`/reports/${report.id}` as any}
                    className="block p-3 rounded-lg border hover:bg-muted transition-colors"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-mono text-sm">{report.number}</span>
                      <Badge
                        variant={
                          report.status === 'pending_review'
                            ? 'warning'
                            : 'secondary'
                        }
                      >
                        {report.status === 'pending_review'
                          ? 'À signer'
                          : 'Brouillon'}
                      </Badge>
                    </div>
                    <p className="text-sm text-muted-foreground mt-1">
                      {report.horse}
                    </p>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Quick actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Actions rapides</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" className="w-full justify-start" asChild>
                <Link href="/horses/new">
                  <span className="mr-2">🐴</span>
                  Ajouter un cheval
                </Link>
              </Button>
              <Button variant="outline" className="w-full justify-start" asChild>
                <Link href="/analyses/new?type=radiological">
                  <span className="mr-2">🩺</span>
                  Analyse radiologique
                </Link>
              </Button>
              <Button variant="outline" className="w-full justify-start" asChild>
                <Link href="/analyses/new?type=video_course">
                  <span className="mr-2">🎥</span>
                  Analyse de parcours
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
