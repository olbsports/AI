'use client';

import { useParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  ArrowLeft,
  Edit,
  Trash,
  Archive,
  Video,
  FileText,
  Calendar,
  TrendingUp,
} from 'lucide-react';

import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Badge,
} from '@horse-vision/ui';

export default function HorseDetailPage() {
  const params = useParams();
  const t = useTranslations('horses');

  // Mock data - will be replaced with real API call
  const horse = {
    id: params['id'],
    name: 'Thunder',
    sireId: 'FRA12345678',
    ueln: '250123456789012',
    microchip: '250123456789012',
    breed: 'Selle Français',
    gender: 'gelding',
    birthDate: '2015-04-15',
    color: 'Bay',
    heightCm: 172,
    status: 'active',
    ownerName: 'Jean Dupont',
    photoUrl: null,
    rider: { firstName: 'Marie', lastName: 'Dubois' },
    createdAt: '2023-06-01',
  };

  const recentAnalyses = [
    {
      id: '1',
      title: 'CSI*** Grand Prix Bordeaux',
      type: 'video_course',
      status: 'completed',
      score: 8.5,
      createdAt: '2024-01-15',
    },
    {
      id: '2',
      title: 'Entraînement performance',
      type: 'video_performance',
      status: 'completed',
      score: 7.8,
      createdAt: '2024-01-10',
    },
    {
      id: '3',
      title: 'CSI** La Baule',
      type: 'video_course',
      status: 'completed',
      score: 8.2,
      createdAt: '2024-01-05',
    },
  ];

  const recentReports = [
    {
      id: '1',
      reportNumber: 'HV-RADIO-348',
      type: 'radiological',
      category: 'A-',
      examDate: '2024-01-15',
    },
    {
      id: '2',
      reportNumber: 'HV-LOCO-089',
      type: 'locomotion',
      category: 'B+',
      examDate: '2023-12-20',
    },
  ];

  const getAge = (birthDate: string) => {
    const birth = new Date(birthDate);
    const now = new Date();
    return now.getFullYear() - birth.getFullYear();
  };

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
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/horses">
              <ArrowLeft className="w-4 h-4" />
            </Link>
          </Button>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-muted rounded-full flex items-center justify-center text-3xl">
              🐴
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                {horse.name}
                <Badge variant={horse.status === 'active' ? 'success' : 'secondary'}>
                  {horse.status === 'active' ? 'Actif' : 'Retraité'}
                </Badge>
              </h1>
              <p className="text-muted-foreground">
                {horse.breed} • {getGenderLabel(horse.gender)} •{' '}
                {getAge(horse.birthDate)} ans
              </p>
            </div>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <Archive className="w-4 h-4 mr-2" />
            Archiver
          </Button>
          <Button variant="outline" size="sm" asChild>
            <Link href={`/horses/${horse.id}/edit` as any}>
              <Edit className="w-4 h-4 mr-2" />
              Modifier
            </Link>
          </Button>
          <Button asChild>
            <Link href={`/analyses/new?horseId=${horse.id}` as any}>
              <Video className="w-4 h-4 mr-2" />
              Nouvelle analyse
            </Link>
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column - Info */}
        <div className="space-y-6">
          {/* Identification */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Identification</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">SIRE</span>
                <span className="font-mono">{horse.sireId}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">UELN</span>
                <span className="font-mono text-sm">{horse.ueln}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Puce</span>
                <span className="font-mono text-sm">{horse.microchip}</span>
              </div>
            </CardContent>
          </Card>

          {/* Physical */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Caractéristiques</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Race</span>
                <span>{horse.breed}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Robe</span>
                <span>{horse.color}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Taille</span>
                <span>{horse.heightCm} cm</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Naissance</span>
                <span>
                  {new Date(horse.birthDate).toLocaleDateString('fr-FR')}
                </span>
              </div>
            </CardContent>
          </Card>

          {/* Owner & Rider */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Entourage</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Propriétaire</span>
                <span>{horse.ownerName}</span>
              </div>
              {horse.rider && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Cavalier</span>
                  <span>
                    {horse.rider.firstName} {horse.rider.lastName}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right column - Analyses & Reports */}
        <div className="lg:col-span-2 space-y-6">
          {/* Stats */}
          <div className="grid grid-cols-3 gap-4">
            <Card>
              <CardContent className="pt-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-primary">12</div>
                  <div className="text-sm text-muted-foreground">Analyses</div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-primary">8.2</div>
                  <div className="text-sm text-muted-foreground">Score moyen</div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-green-600">+0.8</div>
                  <div className="text-sm text-muted-foreground">Progression</div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Recent Analyses */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Analyses récentes</CardTitle>
                <Link
                  href={`/analyses?horseId=${horse.id}` as any}
                  className="text-sm text-primary hover:underline"
                >
                  Voir tout →
                </Link>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {recentAnalyses.map((analysis) => (
                  <Link
                    key={analysis.id}
                    href={`/analyses/${analysis.id}` as any}
                    className="flex items-center justify-between p-3 rounded-lg hover:bg-muted transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-muted rounded-lg flex items-center justify-center">
                        <Video className="w-5 h-5 text-primary" />
                      </div>
                      <div>
                        <p className="font-medium">{analysis.title}</p>
                        <p className="text-sm text-muted-foreground">
                          {new Date(analysis.createdAt).toLocaleDateString('fr-FR')}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xl font-bold">{analysis.score}</div>
                      <div className="text-xs text-muted-foreground">/10</div>
                    </div>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Recent Reports */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Rapports</CardTitle>
                <Link
                  href={`/reports?horseId=${horse.id}` as any}
                  className="text-sm text-primary hover:underline"
                >
                  Voir tout →
                </Link>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {recentReports.map((report) => (
                  <Link
                    key={report.id}
                    href={`/reports/${report.id}` as any}
                    className="flex items-center justify-between p-3 rounded-lg hover:bg-muted transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-muted rounded-lg flex items-center justify-center">
                        <FileText className="w-5 h-5 text-primary" />
                      </div>
                      <div>
                        <p className="font-mono font-medium">
                          {report.reportNumber}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {report.type === 'radiological'
                            ? 'Radiologique'
                            : 'Locomotion'}{' '}
                          • {new Date(report.examDate).toLocaleDateString('fr-FR')}
                        </p>
                      </div>
                    </div>
                    <Badge
                      className={
                        report.category.startsWith('A')
                          ? 'bg-green-100 text-green-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }
                    >
                      {report.category}
                    </Badge>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
