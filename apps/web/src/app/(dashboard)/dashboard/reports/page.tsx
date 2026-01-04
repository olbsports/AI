'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Card,
  CardContent,
  Button,
  Badge,
  Input,
} from '@horse-vision/ui';
import {
  Search,
  FileText,
  Download,
  Share2,
  Eye,
  CheckCircle,
  Clock,
  AlertCircle,
} from 'lucide-react';

interface Report {
  id: string;
  reportNumber: string;
  type: 'course_analysis' | 'radiological' | 'locomotion' | 'purchase_exam';
  status: 'draft' | 'pending_review' | 'completed' | 'archived';
  horseName: string;
  examDate: string;
  veterinarians: string[];
  globalScore?: number;
  category?: string;
  hasPdf: boolean;
}

const mockReports: Report[] = [
  {
    id: '1',
    reportNumber: 'HV-RADIO-348',
    type: 'radiological',
    status: 'completed',
    horseName: 'Eclipse',
    examDate: '2024-01-05',
    veterinarians: ['Dr. Martin'],
    globalScore: 85,
    category: 'A-',
    hasPdf: true,
  },
  {
    id: '2',
    reportNumber: 'HV-PERF-124',
    type: 'course_analysis',
    status: 'pending_review',
    horseName: 'Thunder',
    examDate: '2024-01-04',
    veterinarians: ['Dr. Dupont'],
    globalScore: 78,
    hasPdf: false,
  },
  {
    id: '3',
    reportNumber: 'HV-LOCO-089',
    type: 'locomotion',
    status: 'completed',
    horseName: 'Spirit',
    examDate: '2024-01-03',
    veterinarians: ['Dr. Bernard', 'Dr. Martin'],
    globalScore: 72,
    category: 'B+',
    hasPdf: true,
  },
  {
    id: '4',
    reportNumber: 'HV-EXAM-056',
    type: 'purchase_exam',
    status: 'draft',
    horseName: 'Luna',
    examDate: '2024-01-02',
    veterinarians: ['Dr. Dupont'],
    hasPdf: false,
  },
];

const typeConfig = {
  course_analysis: { label: 'Analyse Parcours', color: 'bg-blue-100 text-blue-700' },
  radiological: { label: 'Radiologique', color: 'bg-orange-100 text-orange-700' },
  locomotion: { label: 'Locomotion', color: 'bg-green-100 text-green-700' },
  purchase_exam: { label: 'Visite Achat', color: 'bg-purple-100 text-purple-700' },
};

const statusConfig = {
  draft: { label: 'Brouillon', icon: Clock, color: 'text-gray-600 bg-gray-100' },
  pending_review: { label: 'En révision', icon: AlertCircle, color: 'text-yellow-600 bg-yellow-100' },
  completed: { label: 'Finalisé', icon: CheckCircle, color: 'text-green-600 bg-green-100' },
  archived: { label: 'Archivé', icon: FileText, color: 'text-gray-600 bg-gray-100' },
};

const categoryColors: Record<string, string> = {
  'A': 'bg-green-500',
  'A-': 'bg-green-400',
  'B+': 'bg-lime-400',
  'B': 'bg-yellow-400',
  'B-': 'bg-orange-400',
  'C': 'bg-red-400',
  'D': 'bg-red-600',
};

export default function ReportsPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const filteredReports = mockReports.filter((report) => {
    const matchesSearch = report.reportNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      report.horseName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' || report.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Rapports</h1>
          <p className="text-muted-foreground">
            Consultez et gérez vos rapports vétérinaires
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher par numéro ou cheval..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          {['all', 'draft', 'pending_review', 'completed'].map((status) => (
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
            <div className="text-2xl font-bold">{mockReports.length}</div>
            <p className="text-sm text-muted-foreground">Total rapports</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-yellow-600">
              {mockReports.filter((r) => r.status === 'pending_review').length}
            </div>
            <p className="text-sm text-muted-foreground">En révision</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-green-600">
              {mockReports.filter((r) => r.status === 'completed').length}
            </div>
            <p className="text-sm text-muted-foreground">Finalisés</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {mockReports.filter((r) => r.hasPdf).length}
            </div>
            <p className="text-sm text-muted-foreground">PDF disponibles</p>
          </CardContent>
        </Card>
      </div>

      {/* Reports List */}
      <div className="space-y-4">
        {filteredReports.map((report) => {
          const typeInfo = typeConfig[report.type];
          const statusInfo = statusConfig[report.status];
          const StatusIcon = statusInfo.icon;

          return (
            <Card key={report.id}>
              <CardContent className="p-4">
                <div className="flex items-center gap-4">
                  <div className="p-3 rounded-lg bg-primary/10">
                    <FileText className="h-5 w-5 text-primary" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <Link
                        href={`/dashboard/reports/${report.id}`}
                        className="font-medium hover:text-primary"
                      >
                        {report.reportNumber}
                      </Link>
                      <Badge className={typeInfo.color}>{typeInfo.label}</Badge>
                    </div>
                    <div className="flex items-center gap-4 mt-1 text-sm text-muted-foreground">
                      <span>🐴 {report.horseName}</span>
                      <span>📅 {new Date(report.examDate).toLocaleDateString('fr-FR')}</span>
                      <span>👨‍⚕️ {report.veterinarians.join(', ')}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    {report.globalScore && (
                      <div className="text-right">
                        <div className="text-2xl font-bold">{report.globalScore}</div>
                        <div className="text-xs text-muted-foreground">Score</div>
                      </div>
                    )}

                    {report.category && (
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold ${categoryColors[report.category]}`}>
                        {report.category}
                      </div>
                    )}

                    <div className={`flex items-center gap-1 px-3 py-1 rounded-full text-sm ${statusInfo.color}`}>
                      <StatusIcon className="h-4 w-4" />
                      {statusInfo.label}
                    </div>

                    <div className="flex gap-1">
                      <Button variant="ghost" size="icon" asChild>
                        <Link href={`/dashboard/reports/${report.id}`}>
                          <Eye className="h-4 w-4" />
                        </Link>
                      </Button>
                      {report.hasPdf && (
                        <Button variant="ghost" size="icon">
                          <Download className="h-4 w-4" />
                        </Button>
                      )}
                      <Button variant="ghost" size="icon">
                        <Share2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filteredReports.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">Aucun rapport trouvé</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
