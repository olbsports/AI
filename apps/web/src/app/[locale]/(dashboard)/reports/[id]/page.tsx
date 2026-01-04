'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  ArrowLeft,
  Download,
  Share2,
  FileText,
  CheckCircle,
  Clock,
  Edit,
  Printer,
  Copy,
  ExternalLink,
  AlertTriangle,
  Shield,
} from 'lucide-react';

import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardDescription,
  Badge,
  Alert,
  AlertDescription,
} from '@horse-vision/ui';

export default function ReportDetailPage() {
  const params = useParams();
  const t = useTranslations('reports');
  const [showShareModal, setShowShareModal] = useState(false);
  const [showSignModal, setShowSignModal] = useState(false);

  // Mock data - will be replaced with real API call
  const report = {
    id: params['id'],
    reportNumber: 'HV-RADIO-348',
    type: 'radiological',
    status: 'pending_review',
    examDate: '2024-01-15',
    examTime: '14:30',
    horse: {
      id: '1',
      name: 'Eclipse',
      sireId: 'FRA23456789',
      breed: 'KWPN',
      birthYear: 2018,
    },
    veterinarians: ['Dr. Marie Dupont', 'Dr. Pierre Martin'],
    location: 'Clinique Vétérinaire Équine de Bordeaux',
    globalScore: 8.2,
    category: 'A-',
    categoryDescription: 'Bon état général, anomalies mineures',
    examinedRegions: [
      'Antérieur gauche',
      'Antérieur droit',
      'Postérieur gauche',
      'Postérieur droit',
    ],
    images: [
      {
        id: '1',
        region: 'Antérieur gauche - Face',
        url: '/images/radio-1.jpg',
        score: 8.5,
        findings: 'Aspect normal',
      },
      {
        id: '2',
        region: 'Antérieur gauche - Profil',
        url: '/images/radio-2.jpg',
        score: 7.8,
        findings: 'Légère sclérose sous-chondrale',
      },
      {
        id: '3',
        region: 'Antérieur droit - Face',
        url: '/images/radio-3.jpg',
        score: 8.8,
        findings: 'Aspect normal',
      },
    ],
    attentionPoints: [
      {
        region: 'Boulet antérieur gauche',
        severity: 'mild',
        description: 'Légère sclérose sous-chondrale, à surveiller',
        recommendation: 'Contrôle dans 6 mois',
      },
    ],
    pathologiesSearched: [
      { name: 'Ostéochondrose', found: false },
      { name: 'Syndrome naviculaire', found: false },
      { name: 'Arthrose', found: false },
      { name: 'Fractures', found: false },
      { name: 'Kystes osseux', found: false },
    ],
    recommendations: [
      'Suivi radiographique du boulet AG dans 6 mois',
      'Ferrure orthopédique recommandée',
      'Pas de contre-indication à l\'activité sportive',
    ],
    conclusion:
      'Examen radiographique satisfaisant. Le cheval présente un état ostéo-articulaire compatible avec son âge et son activité. Les anomalies mineures détectées ne constituent pas de contre-indication à l\'activité sportive envisagée.',
    createdAt: '2024-01-15T14:30:00',
    reviewedAt: null,
    digitalSignature: null,
    pdfUrl: null,
    shareToken: null,
  };

  const getCategoryColor = (category: string) => {
    if (category.startsWith('A')) return 'bg-green-100 text-green-800 border-green-300';
    if (category.startsWith('B')) return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    if (category === 'C') return 'bg-orange-100 text-orange-800 border-orange-300';
    return 'bg-red-100 text-red-800 border-red-300';
  };

  const handleSign = async () => {
    // API call would go here
    console.log('Signing report...');
    setShowSignModal(false);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/reports">
              <ArrowLeft className="w-4 h-4" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold flex items-center gap-2">
              <span className="font-mono">{report.reportNumber}</span>
              {report.status === 'completed' ? (
                <Badge variant="success" className="gap-1">
                  <CheckCircle className="w-3 h-3" />
                  Signé
                </Badge>
              ) : (
                <Badge variant="warning" className="gap-1">
                  <Clock className="w-3 h-3" />
                  À signer
                </Badge>
              )}
            </h1>
            <p className="text-muted-foreground">
              Rapport radiologique • {report.horse.name} •{' '}
              {new Date(report.examDate).toLocaleDateString('fr-FR')}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          {report.status === 'pending_review' && (
            <Button onClick={() => setShowSignModal(true)}>
              <Shield className="w-4 h-4 mr-2" />
              Signer le rapport
            </Button>
          )}
          <Button variant="outline">
            <Printer className="w-4 h-4 mr-2" />
            Imprimer
          </Button>
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            PDF
          </Button>
          <Button variant="outline" onClick={() => setShowShareModal(true)}>
            <Share2 className="w-4 h-4 mr-2" />
            Partager
          </Button>
        </div>
      </div>

      {/* Warning if not signed */}
      {report.status === 'pending_review' && (
        <Alert variant="warning">
          <AlertTriangle className="w-4 h-4" />
          <AlertDescription>
            Ce rapport n'a pas encore été signé. Il ne peut pas être partagé tant
            qu'il n'est pas validé par un vétérinaire.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Global Result */}
          <Card className="overflow-hidden">
            <div className={`p-6 ${getCategoryColor(report.category)}`}>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium opacity-75">
                    Classification globale
                  </p>
                  <div className="flex items-baseline gap-2 mt-1">
                    <span className="text-4xl font-bold">{report.category}</span>
                    <span className="text-lg font-medium opacity-75">
                      ({report.globalScore}/10)
                    </span>
                  </div>
                  <p className="mt-2">{report.categoryDescription}</p>
                </div>
              </div>
            </div>
          </Card>

          {/* Radiographic Images */}
          <Card>
            <CardHeader>
              <CardTitle>Images radiographiques</CardTitle>
              <CardDescription>
                {report.images.length} clichés analysés
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-3 gap-4">
                {report.images.map((image) => (
                  <div
                    key={image.id}
                    className="border rounded-lg overflow-hidden"
                  >
                    <div className="aspect-square bg-muted flex items-center justify-center">
                      <FileText className="w-12 h-12 text-muted-foreground" />
                    </div>
                    <div className="p-3">
                      <p className="font-medium text-sm">{image.region}</p>
                      <p className="text-sm text-muted-foreground">
                        {image.findings}
                      </p>
                      <p className="text-sm mt-1">
                        Score: <span className="font-medium">{image.score}</span>
                        /10
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Attention Points */}
          {report.attentionPoints.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-yellow-500" />
                  Points d'attention
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {report.attentionPoints.map((point, index) => (
                    <div
                      key={index}
                      className="p-4 border-l-4 border-yellow-500 bg-yellow-50 rounded-r-lg"
                    >
                      <p className="font-medium">{point.region}</p>
                      <p className="text-sm text-muted-foreground mt-1">
                        {point.description}
                      </p>
                      <p className="text-sm mt-2">
                        <span className="font-medium">Recommandation:</span>{' '}
                        {point.recommendation}
                      </p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Pathologies Searched */}
          <Card>
            <CardHeader>
              <CardTitle>Pathologies recherchées</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {report.pathologiesSearched.map((pathology, index) => (
                  <div
                    key={index}
                    className={`flex items-center gap-2 p-3 rounded-lg ${
                      pathology.found
                        ? 'bg-red-50 text-red-800'
                        : 'bg-green-50 text-green-800'
                    }`}
                  >
                    {pathology.found ? (
                      <AlertTriangle className="w-4 h-4" />
                    ) : (
                      <CheckCircle className="w-4 h-4" />
                    )}
                    <span className="text-sm font-medium">{pathology.name}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Recommendations */}
          <Card>
            <CardHeader>
              <CardTitle>Recommandations</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2">
                {report.recommendations.map((rec, index) => (
                  <li key={index} className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 text-primary mt-0.5" />
                    <span>{rec}</span>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>

          {/* Conclusion */}
          <Card>
            <CardHeader>
              <CardTitle>Conclusion</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">{report.conclusion}</p>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Horse Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Cheval</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Nom</span>
                <Link
                  href={`/horses/${report.horse.id}`}
                  className="text-primary hover:underline"
                >
                  {report.horse.name}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">SIRE</span>
                <span className="font-mono">{report.horse.sireId}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Race</span>
                <span>{report.horse.breed}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Année</span>
                <span>{report.horse.birthYear}</span>
              </div>
            </CardContent>
          </Card>

          {/* Exam Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Examen</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Date</span>
                <span>
                  {new Date(report.examDate).toLocaleDateString('fr-FR')}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Heure</span>
                <span>{report.examTime}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Lieu</span>
                <span className="text-right text-sm">{report.location}</span>
              </div>
              <div className="border-t pt-3">
                <p className="text-sm text-muted-foreground mb-2">Vétérinaires</p>
                {report.veterinarians.map((vet, index) => (
                  <p key={index} className="text-sm">
                    {vet}
                  </p>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Examined Regions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Régions examinées</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {report.examinedRegions.map((region, index) => (
                  <Badge key={index} variant="secondary">
                    {region}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Signature Info */}
          {report.status === 'completed' && report.digitalSignature && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Shield className="w-4 h-4 text-green-500" />
                  Signature
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Signé par</span>
                  <span>Dr. Marie Dupont</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Date</span>
                  <span>
                    {new Date(report.reviewedAt!).toLocaleDateString('fr-FR')}
                  </span>
                </div>
                <div className="p-2 bg-muted rounded font-mono text-xs break-all">
                  {report.digitalSignature}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Sign Modal */}
      {showSignModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-background rounded-lg shadow-lg w-full max-w-md p-6">
            <h2 className="text-lg font-semibold mb-4">Signer le rapport</h2>
            <p className="text-muted-foreground mb-6">
              En signant ce rapport, vous certifiez que les informations sont
              exactes et que vous en assumez la responsabilité professionnelle.
            </p>
            <Alert className="mb-6">
              <Shield className="w-4 h-4" />
              <AlertDescription>
                Cette action est irréversible. Le rapport sera horodaté et ne
                pourra plus être modifié.
              </AlertDescription>
            </Alert>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setShowSignModal(false)}>
                Annuler
              </Button>
              <Button onClick={handleSign}>
                <Shield className="w-4 h-4 mr-2" />
                Signer le rapport
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Share Modal */}
      {showShareModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-background rounded-lg shadow-lg w-full max-w-md p-6">
            <h2 className="text-lg font-semibold mb-4">Partager le rapport</h2>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Lien de partage</label>
                <div className="flex gap-2 mt-1">
                  <input
                    type="text"
                    readOnly
                    value="https://app.horse-vision.ai/shared/abc123..."
                    className="flex-1 h-10 rounded-md border border-input bg-muted px-3 text-sm"
                  />
                  <Button variant="outline">
                    <Copy className="w-4 h-4" />
                  </Button>
                </div>
              </div>
              <div>
                <label className="text-sm font-medium">Expiration</label>
                <select className="w-full h-10 rounded-md border border-input bg-background px-3 mt-1">
                  <option value="7">7 jours</option>
                  <option value="30">30 jours</option>
                  <option value="90">90 jours</option>
                  <option value="365">1 an</option>
                </select>
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="outline"
                onClick={() => setShowShareModal(false)}
              >
                Fermer
              </Button>
              <Button>
                <ExternalLink className="w-4 h-4 mr-2" />
                Créer le lien
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
