'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  Plus,
  Search,
  Filter,
  Video,
  Clock,
  CheckCircle,
  XCircle,
  Loader2,
  Eye,
  RotateCcw,
} from 'lucide-react';

import {
  Button,
  Input,
  Card,
  CardContent,
  Badge,
} from '@horse-vision/ui';

export default function AnalysesPage() {
  const t = useTranslations('analyses');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | null>(null);

  // Mock data
  const analyses = [
    {
      id: '1',
      title: 'CSI*** Grand Prix Bordeaux',
      type: 'video_course',
      status: 'completed',
      horse: { name: 'Thunder' },
      rider: { firstName: 'Marie', lastName: 'Dubois' },
      scores: { global: 8.5 },
      tokensConsumed: 15,
      createdAt: '2024-01-15T10:30:00',
      completedAt: '2024-01-15T10:35:00',
    },
    {
      id: '2',
      title: 'Radiographie visite d\'achat',
      type: 'radiological',
      status: 'processing',
      horse: { name: 'Eclipse' },
      rider: null,
      scores: null,
      tokensConsumed: 25,
      createdAt: '2024-01-15T09:00:00',
      completedAt: null,
    },
    {
      id: '3',
      title: 'Analyse locomotion post-ferrure',
      type: 'locomotion',
      status: 'completed',
      horse: { name: 'Storm' },
      rider: null,
      scores: { global: 7.2 },
      tokensConsumed: 20,
      createdAt: '2024-01-14T16:45:00',
      completedAt: '2024-01-14T16:52:00',
    },
    {
      id: '4',
      title: 'CSI** La Baule',
      type: 'video_course',
      status: 'failed',
      horse: { name: 'Thunder' },
      rider: { firstName: 'Marie', lastName: 'Dubois' },
      scores: null,
      tokensConsumed: 0,
      createdAt: '2024-01-13T14:00:00',
      completedAt: null,
      errorMessage: 'Vidéo corrompue ou format non supporté',
    },
    {
      id: '5',
      title: 'Entraînement performance',
      type: 'video_performance',
      status: 'pending',
      horse: { name: 'Lightning' },
      rider: { firstName: 'Pierre', lastName: 'Martin' },
      scores: null,
      tokensConsumed: 10,
      createdAt: '2024-01-15T11:00:00',
      completedAt: null,
    },
  ];

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'radiological':
        return '🩺';
      case 'locomotion':
        return '🏃';
      case 'video_course':
      case 'video_performance':
      default:
        return '🎥';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'processing':
        return <Loader2 className="w-4 h-4 text-yellow-500 animate-spin" />;
      case 'failed':
        return <XCircle className="w-4 h-4 text-red-500" />;
      case 'pending':
      default:
        return <Clock className="w-4 h-4 text-gray-500" />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <Badge variant="success">{t(`status.${status}`)}</Badge>;
      case 'processing':
        return <Badge variant="warning">{t(`status.${status}`)}</Badge>;
      case 'failed':
        return <Badge variant="destructive">{t(`status.${status}`)}</Badge>;
      case 'cancelled':
        return <Badge variant="secondary">{t(`status.${status}`)}</Badge>;
      default:
        return <Badge variant="secondary">{t(`status.${status}`)}</Badge>;
    }
  };

  const filteredAnalyses = analyses.filter((analysis) => {
    const matchesSearch = analysis.title
      .toLowerCase()
      .includes(searchQuery.toLowerCase());
    const matchesStatus = !statusFilter || analysis.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('title')}</h1>
          <p className="text-muted-foreground">
            Consultez et gérez toutes vos analyses
          </p>
        </div>
        <Button asChild>
          <Link href="/analyses/new">
            <Plus className="w-4 h-4 mr-2" />
            {t('new')}
          </Link>
        </Button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher une analyse..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          {['pending', 'processing', 'completed', 'failed'].map((status) => (
            <Button
              key={status}
              variant={statusFilter === status ? 'default' : 'outline'}
              size="sm"
              onClick={() =>
                setStatusFilter(statusFilter === status ? null : status)
              }
            >
              {t(`status.${status}`)}
            </Button>
          ))}
        </div>
      </div>

      {/* Analyses List */}
      <div className="space-y-3">
        {filteredAnalyses.map((analysis) => (
          <Card key={analysis.id}>
            <CardContent className="p-4">
              <div className="flex items-center gap-4">
                {/* Type icon */}
                <div className="w-12 h-12 bg-muted rounded-lg flex items-center justify-center text-2xl">
                  {getTypeIcon(analysis.type)}
                </div>

                {/* Content */}
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold">{analysis.title}</h3>
                    {getStatusBadge(analysis.status)}
                  </div>
                  <div className="flex items-center gap-4 mt-1 text-sm text-muted-foreground">
                    <span>{analysis.horse.name}</span>
                    {analysis.rider && (
                      <>
                        <span>•</span>
                        <span>
                          {analysis.rider.firstName} {analysis.rider.lastName}
                        </span>
                      </>
                    )}
                    <span>•</span>
                    <span>{t(`types.${analysis.type}`)}</span>
                  </div>
                </div>

                {/* Score */}
                {analysis.scores && (
                  <div className="text-center">
                    <div className="text-2xl font-bold text-primary">
                      {analysis.scores.global}
                    </div>
                    <div className="text-xs text-muted-foreground">/10</div>
                  </div>
                )}

                {/* Tokens */}
                <div className="text-center">
                  <div className="font-medium">{analysis.tokensConsumed}</div>
                  <div className="text-xs text-muted-foreground">tokens</div>
                </div>

                {/* Date */}
                <div className="text-sm text-muted-foreground">
                  {new Date(analysis.createdAt).toLocaleDateString('fr-FR', {
                    day: 'numeric',
                    month: 'short',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  {analysis.status === 'completed' && (
                    <Button variant="outline" size="sm" asChild>
                      <Link href={`/analyses/${analysis.id}`}>
                        <Eye className="w-4 h-4 mr-1" />
                        Voir
                      </Link>
                    </Button>
                  )}
                  {analysis.status === 'failed' && (
                    <Button variant="outline" size="sm">
                      <RotateCcw className="w-4 h-4 mr-1" />
                      Réessayer
                    </Button>
                  )}
                </div>
              </div>

              {/* Error message */}
              {analysis.status === 'failed' && (analysis as any).errorMessage && (
                <div className="mt-3 p-3 bg-red-50 text-red-700 text-sm rounded-lg">
                  {(analysis as any).errorMessage}
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredAnalyses.length === 0 && (
        <div className="text-center py-12">
          <Video className="w-12 h-12 mx-auto text-muted-foreground" />
          <h3 className="mt-4 text-lg font-semibold">Aucune analyse trouvée</h3>
          <p className="text-muted-foreground mt-2">
            Lancez votre première analyse pour commencer
          </p>
          <Button className="mt-4" asChild>
            <Link href="/analyses/new">
              <Plus className="w-4 h-4 mr-2" />
              {t('new')}
            </Link>
          </Button>
        </div>
      )}
    </div>
  );
}
