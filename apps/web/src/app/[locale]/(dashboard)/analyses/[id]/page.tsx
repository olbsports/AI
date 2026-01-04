'use client';

import { useParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  ArrowLeft,
  Download,
  Share2,
  FileText,
  Clock,
  CheckCircle,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
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

export default function AnalysisDetailPage() {
  const params = useParams();
  const t = useTranslations('analyses');

  // Mock data - will be replaced with real API call
  const analysis = {
    id: params['id'],
    title: 'CSI*** Grand Prix Bordeaux',
    type: 'video_course',
    status: 'completed',
    horse: { id: '1', name: 'Thunder' },
    rider: { firstName: 'Marie', lastName: 'Dubois' },
    competition: {
      name: 'CSI*** Bordeaux',
      location: 'Bordeaux, France',
      level: 'CSI***',
    },
    scores: {
      global: 8.5,
      horse: 8.8,
      rider: 8.2,
      harmony: 8.5,
      technique: 8.4,
    },
    tokensConsumed: 15,
    createdAt: '2024-01-15T10:30:00',
    completedAt: '2024-01-15T10:35:00',
    processingTimeMs: 312000,
    confidenceScore: 0.94,
  };

  const obstacles = [
    { number: 1, type: 'Vertical', score: 9.0, issues: [] },
    { number: 2, type: 'Oxer', score: 8.5, issues: ['Approche légèrement longue'] },
    { number: 3, type: 'Vertical', score: 8.8, issues: [] },
    { number: 4, type: 'Triple', score: 7.5, issues: ['Contrat manqué dans la combinaison'] },
    { number: 5, type: 'Oxer large', score: 9.2, issues: [] },
    { number: 6, type: 'Vertical', score: 8.0, issues: ['Légère perte de rythme'] },
    { number: 7, type: 'Double', score: 8.5, issues: [] },
    { number: 8, type: 'Oxer', score: 9.0, issues: [] },
  ];

  const recommendations = [
    'Améliorer la régularité du galop dans les lignes longues',
    'Travailler les abords des triples pour maintenir le contrat',
    'Excellente gestion des oxers larges à maintenir',
    'Renforcer la connexion main-jambe avant les combinaisons',
  ];

  const getScoreColor = (score: number) => {
    if (score >= 8.5) return 'text-green-600';
    if (score >= 7) return 'text-yellow-600';
    return 'text-red-600';
  };

  const formatDuration = (ms: number) => {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    return `${minutes}m ${seconds % 60}s`;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/analyses">
              <ArrowLeft className="w-4 h-4" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold flex items-center gap-2">
              {analysis.title}
              <Badge variant="success">
                <CheckCircle className="w-3 h-3 mr-1" />
                Terminée
              </Badge>
            </h1>
            <p className="text-muted-foreground">
              {analysis.horse.name} • {analysis.rider.firstName}{' '}
              {analysis.rider.lastName} •{' '}
              {new Date(analysis.createdAt).toLocaleDateString('fr-FR')}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">
            <Share2 className="w-4 h-4 mr-2" />
            Partager
          </Button>
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Exporter
          </Button>
          <Button asChild>
            <Link href={`/reports?analysisId=${analysis.id}` as any}>
              <FileText className="w-4 h-4 mr-2" />
              Voir le rapport
            </Link>
          </Button>
        </div>
      </div>

      {/* Global Score */}
      <Card className="bg-gradient-to-br from-primary/10 to-primary/5">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Score Global</p>
              <div className="flex items-baseline gap-2">
                <span className="text-5xl font-bold text-primary">
                  {analysis.scores.global}
                </span>
                <span className="text-2xl text-muted-foreground">/10</span>
              </div>
              <div className="flex items-center gap-1 mt-2 text-green-600">
                <TrendingUp className="w-4 h-4" />
                <span className="text-sm font-medium">+0.8 vs moyenne</span>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-x-8 gap-y-4">
              {Object.entries(analysis.scores)
                .filter(([key]) => key !== 'global')
                .map(([key, value]) => (
                  <div key={key} className="text-center">
                    <p className="text-xs text-muted-foreground capitalize">
                      {key === 'horse' ? 'Cheval' : key === 'rider' ? 'Cavalier' : key === 'harmony' ? 'Harmonie' : 'Technique'}
                    </p>
                    <p className={`text-2xl font-bold ${getScoreColor(value)}`}>
                      {value}
                    </p>
                  </div>
                ))}
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Obstacles Analysis */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Analyse par Obstacle</CardTitle>
              <CardDescription>
                Scores détaillés pour chaque obstacle du parcours
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {obstacles.map((obstacle) => (
                  <div
                    key={obstacle.number}
                    className="flex items-center gap-4 p-3 rounded-lg bg-muted/50"
                  >
                    <div className="w-10 h-10 bg-background rounded-full flex items-center justify-center font-bold">
                      {obstacle.number}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{obstacle.type}</span>
                        {obstacle.issues.length > 0 && (
                          <AlertTriangle className="w-4 h-4 text-yellow-500" />
                        )}
                      </div>
                      {obstacle.issues.length > 0 && (
                        <p className="text-sm text-muted-foreground">
                          {obstacle.issues[0]}
                        </p>
                      )}
                    </div>
                    <div className="text-right">
                      <span
                        className={`text-xl font-bold ${getScoreColor(
                          obstacle.score
                        )}`}
                      >
                        {obstacle.score}
                      </span>
                      <span className="text-muted-foreground">/10</span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Recommendations */}
          <Card>
            <CardHeader>
              <CardTitle>Recommandations</CardTitle>
              <CardDescription>
                Points d'amélioration identifiés par l'IA
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="space-y-3">
                {recommendations.map((rec, index) => (
                  <li key={index} className="flex items-start gap-3">
                    <div className="w-6 h-6 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                      <span className="text-xs font-medium text-primary">
                        {index + 1}
                      </span>
                    </div>
                    <span>{rec}</span>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Informations</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Type</span>
                <span>{t(`types.${analysis.type}`)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Cheval</span>
                <Link
                  href={`/horses/${analysis.horse.id}` as any}
                  className="text-primary hover:underline"
                >
                  {analysis.horse.name}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Cavalier</span>
                <span>
                  {analysis.rider.firstName} {analysis.rider.lastName}
                </span>
              </div>
              {analysis.competition && (
                <>
                  <div className="border-t pt-3">
                    <p className="text-sm font-medium mb-2">Compétition</p>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Nom</span>
                    <span>{analysis.competition.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Lieu</span>
                    <span>{analysis.competition.location}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Niveau</span>
                    <Badge variant="secondary">{analysis.competition.level}</Badge>
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Technical info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Détails techniques</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Durée traitement</span>
                <span>{formatDuration(analysis.processingTimeMs)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Tokens consommés</span>
                <span>{analysis.tokensConsumed}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Confiance IA</span>
                <span>{Math.round(analysis.confidenceScore * 100)}%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Date</span>
                <span>
                  {new Date(analysis.createdAt).toLocaleDateString('fr-FR', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric',
                  })}
                </span>
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" className="w-full justify-start">
                <FileText className="w-4 h-4 mr-2" />
                Générer un rapport PDF
              </Button>
              <Button variant="outline" className="w-full justify-start">
                <Share2 className="w-4 h-4 mr-2" />
                Partager les résultats
              </Button>
              <Button variant="outline" className="w-full justify-start asChild">
                <Link href={`/analyses/new?horseId=${analysis.horse.id}` as any}>
                  <TrendingUp className="w-4 h-4 mr-2" />
                  Nouvelle analyse
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
