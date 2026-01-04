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
  User,
  Mail,
  Phone,
  Award,
} from 'lucide-react';

interface Rider {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  level?: string;
  discipline?: string;
  federationId?: string;
  horsesCount: number;
  analysisCount: number;
  photoUrl?: string;
}

const mockRiders: Rider[] = [
  {
    id: '1',
    firstName: 'Marie',
    lastName: 'Dupont',
    email: 'marie.dupont@email.com',
    phone: '+33 6 12 34 56 78',
    level: 'Pro Elite',
    discipline: 'CSO',
    federationId: 'FFE-123456',
    horsesCount: 2,
    analysisCount: 42,
  },
  {
    id: '2',
    firstName: 'Jean',
    lastName: 'Martin',
    email: 'jean.martin@email.com',
    level: 'Amateur 1',
    discipline: 'Dressage',
    federationId: 'FFE-234567',
    horsesCount: 1,
    analysisCount: 18,
  },
  {
    id: '3',
    firstName: 'Sophie',
    lastName: 'Bernard',
    email: 'sophie.bernard@email.com',
    phone: '+33 6 98 76 54 32',
    level: 'Pro 2',
    discipline: 'Complet',
    horsesCount: 3,
    analysisCount: 56,
  },
  {
    id: '4',
    firstName: 'Lucas',
    lastName: 'Petit',
    level: 'Amateur 2',
    discipline: 'CSO',
    horsesCount: 1,
    analysisCount: 8,
  },
];

export default function RidersPage() {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredRiders = mockRiders.filter((rider) => {
    const fullName = `${rider.firstName} ${rider.lastName}`.toLowerCase();
    return fullName.includes(searchQuery.toLowerCase()) ||
      rider.email?.toLowerCase().includes(searchQuery.toLowerCase());
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Cavaliers</h1>
          <p className="text-muted-foreground">
            Gérez les cavaliers et leurs affectations
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Ajouter un cavalier
        </Button>
      </div>

      {/* Search */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Rechercher un cavalier..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">{mockRiders.length}</div>
            <p className="text-sm text-muted-foreground">Total cavaliers</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockRiders.reduce((sum, r) => sum + r.horsesCount, 0)}
            </div>
            <p className="text-sm text-muted-foreground">Chevaux assignés</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockRiders.reduce((sum, r) => sum + r.analysisCount, 0)}
            </div>
            <p className="text-sm text-muted-foreground">Analyses totales</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockRiders.filter((r) => r.federationId).length}
            </div>
            <p className="text-sm text-muted-foreground">Licenciés FFE</p>
          </CardContent>
        </Card>
      </div>

      {/* Riders List */}
      <div className="grid gap-4 md:grid-cols-2">
        {filteredRiders.map((rider) => (
          <Card key={rider.id}>
            <CardContent className="p-6">
              <div className="flex items-start gap-4">
                <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
                  <User className="h-8 w-8 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-lg">
                      {rider.firstName} {rider.lastName}
                    </h3>
                    {rider.level && (
                      <Badge variant="secondary">{rider.level}</Badge>
                    )}
                  </div>

                  {rider.discipline && (
                    <p className="text-sm text-muted-foreground flex items-center gap-1 mt-1">
                      <Award className="h-3 w-3" />
                      {rider.discipline}
                    </p>
                  )}

                  <div className="mt-3 space-y-1">
                    {rider.email && (
                      <p className="text-sm flex items-center gap-2">
                        <Mail className="h-3 w-3 text-muted-foreground" />
                        <span className="truncate">{rider.email}</span>
                      </p>
                    )}
                    {rider.phone && (
                      <p className="text-sm flex items-center gap-2">
                        <Phone className="h-3 w-3 text-muted-foreground" />
                        {rider.phone}
                      </p>
                    )}
                  </div>

                  <div className="flex items-center gap-4 mt-4 text-sm">
                    <div>
                      <span className="font-medium">{rider.horsesCount}</span>
                      <span className="text-muted-foreground ml-1">cheva{rider.horsesCount > 1 ? 'ux' : 'l'}</span>
                    </div>
                    <div>
                      <span className="font-medium">{rider.analysisCount}</span>
                      <span className="text-muted-foreground ml-1">analyses</span>
                    </div>
                    {rider.federationId && (
                      <Badge variant="outline" className="text-xs">
                        {rider.federationId}
                      </Badge>
                    )}
                  </div>

                  <div className="flex gap-2 mt-4">
                    <Button variant="outline" size="sm" asChild>
                      <Link href={`/dashboard/riders/${rider.id}`}>
                        Voir le profil
                      </Link>
                    </Button>
                    <Button variant="outline" size="sm">
                      Assigner un cheval
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredRiders.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">Aucun cavalier trouvé</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
