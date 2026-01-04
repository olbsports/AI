'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  Button,
  Badge,
  Input,
  Progress,
} from '@horse-vision/ui';
import {
  Plus,
  Search,
  Filter,
  Video,
  Image,
  Activity,
  Clock,
  CheckCircle,
  XCircle,
  Loader2,
} from 'lucide-react';

interface Analysis {
  id: string;
  title: string;
  type: 'video_performance' | 'video_course' | 'radiological' | 'locomotion';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  horseName: string;
  riderName?: string;
  createdAt: string;
  completedAt?: string;
  score?: number;
  progress?: number;
  tokensUsed?: number;
}

const mockAnalyses: Analysis[] = [
  {
    id: '1',
    title: 'Parcours CSO - Fontainebleau',
    type: 'video_course',
    status: 'completed',
    horseName: 'Eclipse',
    riderName: 'Marie Dupont',
    createdAt: '2024-01-05T10:30:00',
    completedAt: '2024-01-05T10:35:00',
    score: 85,
    tokensUsed: 3,
  },
  {
    id: '2',
    title: 'Analyse locomotion post-ferrure',
    type: 'locomotion',
    status: 'processing',
    horseName: 'Thunder',
    createdAt: '2024-01-05T11:00:00',
    progress: 65,
  },
  {
    id: '3',
    title: 'Radiographie jarret gauche',
    type: 'radiological',
    status: 'completed',
    horseName: 'Spirit',
    createdAt: '2024-01-04T14:20:00',
    completedAt: '2024-01-04T14:28:00',
    score: 72,
    tokensUsed: 5,
  },
  {
    id: '4',
    title: 'Entraînement dressage',
    type: 'video_performance',
    status: 'pending',
    horseName: 'Luna',
    riderName: 'Sophie Bernard',
    createdAt: '2024-01-05T11:15:00',
  },
  {
    id: '5',
    title: 'Parcours cross',
    type: 'video_course',
    status: 'failed',
    horseName: 'Storm',
    createdAt: '2024-01-03T09:00:00',
  },
];

const typeConfig = {
  video_performance: { label: 'Performance', icon: Video, color: 'bg-blue-100 text-blue-700' },
  video_course: { label: 'Parcours', icon: Video, color: 'bg-purple-100 text-purple-700' },
  radiological: { label: 'Radiologique', icon: Image, color: 'bg-orange-100 text-orange-700' },
  locomotion: { label: 'Locomotion', icon: Activity, color: 'bg-green-100 text-green-700' },
};

const statusConfig = {
  pending: { label: 'En attente', icon: Clock, color: 'text-yellow-600 bg-yellow-100' },
  processing: { label: 'En cours', icon: Loader2, color: 'text-blue-600 bg-blue-100' },
  completed: { label: 'Terminé', icon: CheckCircle, color: 'text-green-600 bg-green-100' },
  failed: { label: 'Échec', icon: XCircle, color: 'text-red-600 bg-red-100' },
};

export default function AnalysesPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');

  const filteredAnalyses = mockAnalyses.filter((analysis) => {
    const matchesSearch = analysis.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      analysis.horseName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' || analysis.status === statusFilter;
    const matchesType = typeFilter === 'all' || analysis.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Analyses</h1>
          <p className="text-muted-foreground">
            Historique et suivi des analyses IA
          </p>
        </div>
        <Button asChild>
          <Link href="/dashboard/analyses/new">
            <Plus className="h-4 w-4 mr-2" />
            Nouvelle analyse
          </Link>
        </Button>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher une analyse..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          <select
            className="px-3 py-2 border rounded-md text-sm"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">Tous les statuts</option>
            <option value="pending">En attente</option>
            <option value="processing">En cours</option>
            <option value="completed">Terminé</option>
            <option value="failed">Échec</option>
          </select>
          <select
            className="px-3 py-2 border rounded-md text-sm"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            <option value="all">Tous les types</option>
            <option value="video_performance">Performance</option>
            <option value="video_course">Parcours</option>
            <option value="radiological">Radiologique</option>
            <option value="locomotion">Locomotion</option>
          </select>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">{mockAnalyses.length}</div>
            <p className="text-sm text-muted-foreground">Total</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-yellow-600">
              {mockAnalyses.filter((a) => a.status === 'pending').length}
            </div>
            <p className="text-sm text-muted-foreground">En attente</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-blue-600">
              {mockAnalyses.filter((a) => a.status === 'processing').length}
            </div>
            <p className="text-sm text-muted-foreground">En cours</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-green-600">
              {mockAnalyses.filter((a) => a.status === 'completed').length}
            </div>
            <p className="text-sm text-muted-foreground">Terminées</p>
          </CardContent>
        </Card>
      </div>

      {/* Analysis List */}
      <div className="space-y-4">
        {filteredAnalyses.map((analysis) => {
          const typeInfo = typeConfig[analysis.type];
          const statusInfo = statusConfig[analysis.status];
          const TypeIcon = typeInfo.icon;
          const StatusIcon = statusInfo.icon;

          return (
            <Card key={analysis.id}>
              <CardContent className="p-4">
                <div className="flex items-center gap-4">
                  <div className={`p-3 rounded-lg ${typeInfo.color}`}>
                    <TypeIcon className="h-5 w-5" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <Link
                        href={`/dashboard/analyses/${analysis.id}`}
                        className="font-medium hover:text-primary"
                      >
                        {analysis.title}
                      </Link>
                      <Badge variant="outline">{typeInfo.label}</Badge>
                    </div>
                    <div className="flex items-center gap-4 mt-1 text-sm text-muted-foreground">
                      <span>🐴 {analysis.horseName}</span>
                      {analysis.riderName && <span>👤 {analysis.riderName}</span>}
                      <span>{new Date(analysis.createdAt).toLocaleDateString('fr-FR')}</span>
                    </div>

                    {analysis.status === 'processing' && analysis.progress && (
                      <div className="mt-2 max-w-xs">
                        <Progress value={analysis.progress} className="h-2" />
                        <span className="text-xs text-muted-foreground">{analysis.progress}% complété</span>
                      </div>
                    )}
                  </div>

                  <div className="flex items-center gap-4">
                    {analysis.score && (
                      <div className="text-right">
                        <div className="text-2xl font-bold text-primary">{analysis.score}</div>
                        <div className="text-xs text-muted-foreground">Score</div>
                      </div>
                    )}

                    <div className={`flex items-center gap-1 px-3 py-1 rounded-full text-sm ${statusInfo.color}`}>
                      <StatusIcon className={`h-4 w-4 ${analysis.status === 'processing' ? 'animate-spin' : ''}`} />
                      {statusInfo.label}
                    </div>

                    {analysis.status === 'completed' && (
                      <Button size="sm" asChild>
                        <Link href={`/dashboard/analyses/${analysis.id}`}>
                          Voir
                        </Link>
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filteredAnalyses.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">Aucune analyse trouvée</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
