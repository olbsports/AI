'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  Search,
  Filter,
  Download,
  Share2,
  FileText,
  CheckCircle,
  Clock,
  Edit,
  Eye,
} from 'lucide-react';

import {
  Button,
  Input,
  Card,
  CardContent,
  Badge,
} from '@horse-tempo/ui';

export default function ReportsPage() {
  const t = useTranslations('reports');
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data
  const reports = [
    {
      id: '1',
      reportNumber: 'HV-RADIO-348',
      type: 'radiological',
      status: 'completed',
      horse: { name: 'Eclipse' },
      category: 'A-',
      globalScore: 8.2,
      examDate: '2024-01-15',
      reviewedAt: '2024-01-15T14:30:00',
      digitalSignature: 'SIG-ABC123',
      pdfUrl: '/reports/HV-RADIO-348.pdf',
    },
    {
      id: '2',
      reportNumber: 'HV-COURSE-127',
      type: 'course_analysis',
      status: 'pending_review',
      horse: { name: 'Thunder' },
      category: null,
      globalScore: 8.5,
      examDate: '2024-01-15',
      reviewedAt: null,
      digitalSignature: null,
      pdfUrl: null,
    },
    {
      id: '3',
      reportNumber: 'HV-RADIO-347',
      type: 'radiological',
      status: 'completed',
      horse: { name: 'Storm' },
      category: 'B+',
      globalScore: 7.1,
      examDate: '2024-01-14',
      reviewedAt: '2024-01-14T16:00:00',
      digitalSignature: 'SIG-DEF456',
      pdfUrl: '/reports/HV-RADIO-347.pdf',
    },
    {
      id: '4',
      reportNumber: 'HV-LOCO-089',
      type: 'locomotion',
      status: 'draft',
      horse: { name: 'Lightning' },
      category: null,
      globalScore: 6.8,
      examDate: '2024-01-13',
      reviewedAt: null,
      digitalSignature: null,
      pdfUrl: null,
    },
  ];

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'radiological':
        return 'Radiologique';
      case 'course_analysis':
        return 'Analyse Parcours';
      case 'locomotion':
        return 'Locomotion';
      case 'purchase_exam':
        return 'Visite d\'achat';
      default:
        return type;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return (
          <Badge variant="success" className="gap-1">
            <CheckCircle className="w-3 h-3" />
            Signé
          </Badge>
        );
      case 'pending_review':
        return (
          <Badge variant="warning" className="gap-1">
            <Clock className="w-3 h-3" />
            À signer
          </Badge>
        );
      case 'draft':
        return (
          <Badge variant="secondary" className="gap-1">
            <Edit className="w-3 h-3" />
            Brouillon
          </Badge>
        );
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  const getCategoryColor = (category: string | null) => {
    if (!category) return 'bg-gray-100 text-gray-800';
    if (category.startsWith('A')) return 'bg-green-100 text-green-800';
    if (category.startsWith('B')) return 'bg-yellow-100 text-yellow-800';
    if (category === 'C') return 'bg-orange-100 text-orange-800';
    return 'bg-red-100 text-red-800';
  };

  const filteredReports = reports.filter((report) =>
    report.reportNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
    report.horse.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('title')}</h1>
          <p className="text-muted-foreground">
            Consultez, signez et partagez vos rapports
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher par numéro ou cheval..."
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

      {/* Reports Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b bg-muted/50">
                  <th className="text-left p-4 font-medium">Numéro</th>
                  <th className="text-left p-4 font-medium">Type</th>
                  <th className="text-left p-4 font-medium">Cheval</th>
                  <th className="text-left p-4 font-medium">Catégorie</th>
                  <th className="text-left p-4 font-medium">Score</th>
                  <th className="text-left p-4 font-medium">Date</th>
                  <th className="text-left p-4 font-medium">Statut</th>
                  <th className="text-right p-4 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredReports.map((report) => (
                  <tr key={report.id} className="border-b hover:bg-muted/30">
                    <td className="p-4">
                      <span className="font-mono font-medium">
                        {report.reportNumber}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className="text-sm">{getTypeLabel(report.type)}</span>
                    </td>
                    <td className="p-4">{report.horse.name}</td>
                    <td className="p-4">
                      {report.category && (
                        <span
                          className={`inline-flex px-2 py-1 rounded-md text-sm font-medium ${getCategoryColor(
                            report.category
                          )}`}
                        >
                          {report.category}
                        </span>
                      )}
                    </td>
                    <td className="p-4">
                      <span className="font-medium">{report.globalScore}</span>
                      <span className="text-muted-foreground">/10</span>
                    </td>
                    <td className="p-4 text-sm text-muted-foreground">
                      {new Date(report.examDate).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="p-4">{getStatusBadge(report.status)}</td>
                    <td className="p-4">
                      <div className="flex justify-end gap-2">
                        <Button variant="ghost" size="sm" asChild>
                          <Link href={`/reports/${report.id}` as any}>
                            <Eye className="w-4 h-4" />
                          </Link>
                        </Button>
                        {report.pdfUrl && (
                          <Button variant="ghost" size="sm">
                            <Download className="w-4 h-4" />
                          </Button>
                        )}
                        {report.status === 'completed' && (
                          <Button variant="ghost" size="sm">
                            <Share2 className="w-4 h-4" />
                          </Button>
                        )}
                        {report.status === 'pending_review' && (
                          <Button size="sm" asChild>
                            <Link href={`/reports/${report.id}/sign` as any}>
                              Signer
                            </Link>
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {filteredReports.length === 0 && (
        <div className="text-center py-12">
          <FileText className="w-12 h-12 mx-auto text-muted-foreground" />
          <h3 className="mt-4 text-lg font-semibold">Aucun rapport trouvé</h3>
          <p className="text-muted-foreground mt-2">
            Les rapports apparaîtront ici après une analyse
          </p>
        </div>
      )}
    </div>
  );
}
