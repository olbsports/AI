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
} from '@horse-vision/ui';
import {
  Plus,
  Search,
  Filter,
  MoreVertical,
  Activity,
  FileText,
} from 'lucide-react';

interface Horse {
  id: string;
  name: string;
  breed: string;
  gender: 'male' | 'female' | 'gelding';
  age: number;
  status: 'active' | 'retired' | 'sold';
  photoUrl?: string;
  riderName?: string;
  lastAnalysis?: string;
  analysisCount: number;
  avgScore?: number;
}

const mockHorses: Horse[] = [
  {
    id: '1',
    name: 'Eclipse',
    breed: 'Selle Français',
    gender: 'gelding',
    age: 8,
    status: 'active',
    riderName: 'Marie Dupont',
    lastAnalysis: '2024-01-05',
    analysisCount: 24,
    avgScore: 85,
  },
  {
    id: '2',
    name: 'Thunder',
    breed: 'KWPN',
    gender: 'male',
    age: 6,
    status: 'active',
    riderName: 'Jean Martin',
    lastAnalysis: '2024-01-03',
    analysisCount: 18,
    avgScore: 78,
  },
  {
    id: '3',
    name: 'Spirit',
    breed: 'Anglo-Arabe',
    gender: 'female',
    age: 10,
    status: 'active',
    lastAnalysis: '2024-01-01',
    analysisCount: 32,
    avgScore: 82,
  },
  {
    id: '4',
    name: 'Luna',
    breed: 'Hanovrien',
    gender: 'female',
    age: 5,
    status: 'active',
    riderName: 'Sophie Bernard',
    lastAnalysis: '2023-12-28',
    analysisCount: 12,
    avgScore: 75,
  },
  {
    id: '5',
    name: 'Storm',
    breed: 'Holsteiner',
    gender: 'gelding',
    age: 12,
    status: 'retired',
    analysisCount: 45,
    avgScore: 88,
  },
];

const genderLabels = {
  male: 'Étalon',
  female: 'Jument',
  gelding: 'Hongre',
};

const statusConfig = {
  active: { label: 'Actif', variant: 'default' as const },
  retired: { label: 'Retraité', variant: 'secondary' as const },
  sold: { label: 'Vendu', variant: 'outline' as const },
};

export default function HorsesPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const filteredHorses = mockHorses.filter((horse) => {
    const matchesSearch = horse.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      horse.breed.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' || horse.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Chevaux</h1>
          <p className="text-muted-foreground">
            Gérez votre écurie et suivez les analyses
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Ajouter un cheval
        </Button>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher un cheval..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          {['all', 'active', 'retired', 'sold'].map((status) => (
            <Button
              key={status}
              variant={statusFilter === status ? 'default' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter(status)}
            >
              {status === 'all' ? 'Tous' : statusConfig[status as keyof typeof statusConfig]?.label}
            </Button>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">{mockHorses.length}</div>
            <p className="text-sm text-muted-foreground">Total chevaux</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockHorses.filter((h) => h.status === 'active').length}
            </div>
            <p className="text-sm text-muted-foreground">Actifs</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockHorses.reduce((sum, h) => sum + h.analysisCount, 0)}
            </div>
            <p className="text-sm text-muted-foreground">Analyses totales</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {(mockHorses.reduce((sum, h) => sum + (h.avgScore || 0), 0) / mockHorses.filter(h => h.avgScore).length).toFixed(1)}
            </div>
            <p className="text-sm text-muted-foreground">Score moyen</p>
          </CardContent>
        </Card>
      </div>

      {/* Horse List */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredHorses.map((horse) => (
          <Card key={horse.id} className="overflow-hidden">
            <div className="aspect-video bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
              <span className="text-6xl">🐴</span>
            </div>
            <CardHeader className="pb-2">
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-lg">{horse.name}</CardTitle>
                  <p className="text-sm text-muted-foreground">
                    {horse.breed} • {genderLabels[horse.gender]} • {horse.age} ans
                  </p>
                </div>
                <Badge variant={statusConfig[horse.status].variant}>
                  {statusConfig[horse.status].label}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              {horse.riderName && (
                <p className="text-sm">
                  <span className="text-muted-foreground">Cavalier:</span> {horse.riderName}
                </p>
              )}

              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Analyses</span>
                <span className="font-medium">{horse.analysisCount}</span>
              </div>

              {horse.avgScore && (
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Score moyen</span>
                  <span className="font-medium text-primary">{horse.avgScore}/100</span>
                </div>
              )}

              {horse.lastAnalysis && (
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Dernière analyse</span>
                  <span>{new Date(horse.lastAnalysis).toLocaleDateString('fr-FR')}</span>
                </div>
              )}

              <div className="flex gap-2 pt-2">
                <Button variant="outline" size="sm" className="flex-1" asChild>
                  <Link href={`/dashboard/horses/${horse.id}`}>
                    Détails
                  </Link>
                </Button>
                <Button size="sm" className="flex-1">
                  <Activity className="h-4 w-4 mr-1" />
                  Analyser
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredHorses.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">Aucun cheval trouvé</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
