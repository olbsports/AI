'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  Plus,
  Search,
  Filter,
  MoreVertical,
  Edit,
  Trash,
  Archive,
  Eye,
} from 'lucide-react';

import {
  Button,
  Input,
  Card,
  CardContent,
  Badge,
} from '@horse-vision/ui';

export default function HorsesPage() {
  const t = useTranslations('horses');
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data
  const horses = [
    {
      id: '1',
      name: 'Thunder',
      sireId: 'FRA12345678',
      breed: 'Selle Français',
      gender: 'gelding',
      birthYear: 2015,
      color: 'Bay',
      heightCm: 172,
      status: 'active',
      photoUrl: null,
      rider: { firstName: 'Marie', lastName: 'Dubois' },
      analysisCount: 12,
    },
    {
      id: '2',
      name: 'Eclipse',
      sireId: 'FRA23456789',
      breed: 'KWPN',
      gender: 'male',
      birthYear: 2018,
      color: 'Black',
      heightCm: 168,
      status: 'active',
      photoUrl: null,
      rider: { firstName: 'Pierre', lastName: 'Martin' },
      analysisCount: 8,
    },
    {
      id: '3',
      name: 'Storm',
      sireId: 'GER34567890',
      breed: 'Holsteiner',
      gender: 'female',
      birthYear: 2016,
      color: 'Grey',
      heightCm: 165,
      status: 'active',
      photoUrl: null,
      rider: null,
      analysisCount: 5,
    },
    {
      id: '4',
      name: 'Lightning',
      sireId: 'BEL45678901',
      breed: 'BWP',
      gender: 'gelding',
      birthYear: 2012,
      color: 'Chestnut',
      heightCm: 170,
      status: 'retired',
      photoUrl: null,
      rider: null,
      analysisCount: 24,
    },
  ];

  const filteredHorses = horses.filter((horse) =>
    horse.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getGenderLabel = (gender: string) => {
    switch (gender) {
      case 'male':
        return 'Étalon';
      case 'female':
        return 'Jument';
      case 'gelding':
        return 'Hongre';
      default:
        return gender;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('title')}</h1>
          <p className="text-muted-foreground">
            Gérez vos chevaux et accédez à leur historique d'analyses
          </p>
        </div>
        <Button asChild>
          <Link href="/horses/new">
            <Plus className="w-4 h-4 mr-2" />
            {t('add')}
          </Link>
        </Button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher un cheval..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button variant="outline">
          <Filter className="w-4 h-4 mr-2" />
          Filtres
        </Button>
      </div>

      {/* Horses Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredHorses.map((horse) => (
          <Card key={horse.id} className="hover:shadow-md transition-shadow">
            <CardContent className="p-0">
              {/* Photo placeholder */}
              <div className="h-40 bg-muted flex items-center justify-center">
                <span className="text-6xl">🐴</span>
              </div>

              <div className="p-4">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-semibold text-lg">{horse.name}</h3>
                    <p className="text-sm text-muted-foreground">
                      {horse.breed}
                    </p>
                  </div>
                  <Badge
                    variant={horse.status === 'active' ? 'success' : 'secondary'}
                  >
                    {horse.status === 'active' ? 'Actif' : 'Retraité'}
                  </Badge>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-muted-foreground">SIRE:</span>{' '}
                    <span className="font-mono">{horse.sireId}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Sexe:</span>{' '}
                    {getGenderLabel(horse.gender)}
                  </div>
                  <div>
                    <span className="text-muted-foreground">Année:</span>{' '}
                    {horse.birthYear}
                  </div>
                  <div>
                    <span className="text-muted-foreground">Taille:</span>{' '}
                    {horse.heightCm} cm
                  </div>
                </div>

                {horse.rider && (
                  <div className="mt-3 pt-3 border-t text-sm">
                    <span className="text-muted-foreground">Cavalier:</span>{' '}
                    {horse.rider.firstName} {horse.rider.lastName}
                  </div>
                )}

                <div className="mt-4 flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    {horse.analysisCount} analyses
                  </span>
                  <div className="flex gap-2">
                    <Button variant="ghost" size="sm" asChild>
                      <Link href={`/horses/${horse.id}` as any}>
                        <Eye className="w-4 h-4" />
                      </Link>
                    </Button>
                    <Button variant="ghost" size="sm" asChild>
                      <Link href={`/horses/${horse.id}/edit` as any}>
                        <Edit className="w-4 h-4" />
                      </Link>
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredHorses.length === 0 && (
        <div className="text-center py-12">
          <span className="text-6xl">🐴</span>
          <h3 className="mt-4 text-lg font-semibold">{t('empty')}</h3>
          <p className="text-muted-foreground mt-2">
            Commencez par ajouter votre premier cheval
          </p>
          <Button className="mt-4" asChild>
            <Link href="/horses/new">
              <Plus className="w-4 h-4 mr-2" />
              {t('add')}
            </Link>
          </Button>
        </div>
      )}
    </div>
  );
}
