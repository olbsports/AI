'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import {
  ArrowLeft,
  Video,
  Stethoscope,
  Activity,
  Zap,
  ChevronRight,
  Upload,
} from 'lucide-react';

import {
  Button,
  Input,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardDescription,
  Alert,
  AlertDescription,
  Badge,
} from '@horse-tempo/ui';
import { FileUpload } from '@/components/upload';
import { TOKEN_COSTS } from '@horse-tempo/config';
import { useAuthStore } from '@/stores/auth';

type AnalysisType = 'video_course' | 'video_performance' | 'radiological' | 'locomotion';

interface AnalysisTypeOption {
  type: AnalysisType;
  title: string;
  description: string;
  icon: React.ElementType;
  tokens: number;
  acceptedFormats: string;
}

const analysisTypes: AnalysisTypeOption[] = [
  {
    type: 'video_course',
    title: 'Analyse de Parcours',
    description: 'Analyse vidéo détaillée de vos parcours de CSO avec scoring obstacle par obstacle',
    icon: Video,
    tokens: TOKEN_COSTS.COURSE_ANALYSIS,
    acceptedFormats: 'MP4, MOV, AVI',
  },
  {
    type: 'video_performance',
    title: 'Analyse Performance',
    description: 'Évaluation de la performance globale cavalier/cheval sur une reprise',
    icon: Zap,
    tokens: TOKEN_COSTS.VIDEO_ANALYSIS,
    acceptedFormats: 'MP4, MOV, AVI',
  },
  {
    type: 'radiological',
    title: 'Analyse Radiologique',
    description: 'Génération de rapport vétérinaire à partir de radiographies',
    icon: Stethoscope,
    tokens: TOKEN_COSTS.RADIO_ANALYSIS,
    acceptedFormats: 'DICOM, JPG, PNG',
  },
  {
    type: 'locomotion',
    title: 'Analyse Locomotion',
    description: 'Analyse des allures et détection d\'asymétries locomotrices',
    icon: Activity,
    tokens: TOKEN_COSTS.LOCOMOTION_ANALYSIS,
    acceptedFormats: 'MP4, MOV',
  },
];

export default function NewAnalysisPage() {
  const t = useTranslations('analyses');
  const router = useRouter();
  const searchParams = useSearchParams();
  const organization = useAuthStore((state) => state.organization);

  const initialType = searchParams.get('type') as AnalysisType | null;
  const horseId = searchParams.get('horseId');

  const [step, setStep] = useState<'type' | 'details' | 'upload'>(
    initialType ? 'details' : 'type'
  );
  const [selectedType, setSelectedType] = useState<AnalysisType | null>(
    initialType
  );
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    title: '',
    horseId: horseId || '',
    riderId: '',
    competitionName: '',
    competitionLocation: '',
    competitionLevel: '',
    notes: '',
  });

  const [files, setFiles] = useState<any[]>([]);

  // Mock horses data
  const horses = [
    { id: '1', name: 'Thunder' },
    { id: '2', name: 'Eclipse' },
    { id: '3', name: 'Storm' },
  ];

  const selectedTypeInfo = analysisTypes.find((t) => t.type === selectedType);
  const hasEnoughTokens =
    organization && selectedTypeInfo
      ? organization.tokenBalance >= selectedTypeInfo.tokens
      : false;

  const handleTypeSelect = (type: AnalysisType) => {
    setSelectedType(type);
    setStep('details');
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async () => {
    if (!selectedType || files.length === 0) return;

    setError(null);
    setIsLoading(true);

    try {
      // In real app, this would call the API
      console.log('Creating analysis:', {
        type: selectedType,
        ...formData,
        files: files.map((f) => f.url),
      });

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 2000));

      router.push('/analyses');
    } catch (err: any) {
      setError(err.message || 'Une erreur est survenue');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/analyses">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold">{t('new')}</h1>
          <p className="text-muted-foreground">
            {step === 'type' && 'Choisissez le type d\'analyse'}
            {step === 'details' && 'Renseignez les informations'}
            {step === 'upload' && 'Ajoutez vos fichiers'}
          </p>
        </div>
      </div>

      {/* Progress steps */}
      <div className="flex items-center gap-2">
        {['type', 'details', 'upload'].map((s, i) => (
          <div key={s} className="flex items-center">
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                step === s
                  ? 'bg-primary text-primary-foreground'
                  : i < ['type', 'details', 'upload'].indexOf(step)
                  ? 'bg-primary/20 text-primary'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {i + 1}
            </div>
            {i < 2 && (
              <div
                className={`w-12 h-0.5 ${
                  i < ['type', 'details', 'upload'].indexOf(step)
                    ? 'bg-primary'
                    : 'bg-muted'
                }`}
              />
            )}
          </div>
        ))}
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* Step 1: Type Selection */}
      {step === 'type' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {analysisTypes.map((type) => {
            const Icon = type.icon;
            const canAfford = organization
              ? organization.tokenBalance >= type.tokens
              : false;

            return (
              <Card
                key={type.type}
                className={`cursor-pointer transition-all hover:shadow-md ${
                  !canAfford ? 'opacity-60' : ''
                }`}
                onClick={() => canAfford && handleTypeSelect(type.type)}
              >
                <CardContent className="p-6">
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                      <Icon className="w-6 h-6 text-primary" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <h3 className="font-semibold">{type.title}</h3>
                        <Badge variant="secondary">{type.tokens} tokens</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground mt-1">
                        {type.description}
                      </p>
                      <p className="text-xs text-muted-foreground mt-2">
                        Formats: {type.acceptedFormats}
                      </p>
                      {!canAfford && (
                        <p className="text-xs text-red-500 mt-2">
                          Tokens insuffisants
                        </p>
                      )}
                    </div>
                    <ChevronRight className="w-5 h-5 text-muted-foreground" />
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Step 2: Details */}
      {step === 'details' && selectedTypeInfo && (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
                  <selectedTypeInfo.icon className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <CardTitle>{selectedTypeInfo.title}</CardTitle>
                  <CardDescription>
                    Coût: {selectedTypeInfo.tokens} tokens
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Titre de l'analyse *</label>
                <Input
                  name="title"
                  value={formData.title}
                  onChange={handleChange}
                  placeholder="Ex: CSI*** Grand Prix Bordeaux"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">Cheval *</label>
                  <select
                    name="horseId"
                    value={formData.horseId}
                    onChange={handleChange}
                    className="w-full h-10 rounded-md border border-input bg-background px-3"
                    required
                  >
                    <option value="">Sélectionner un cheval</option>
                    {horses.map((horse) => (
                      <option key={horse.id} value={horse.id}>
                        {horse.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-sm font-medium">Cavalier</label>
                  <Input
                    name="riderId"
                    value={formData.riderId}
                    onChange={handleChange}
                    placeholder="Optionnel"
                  />
                </div>
              </div>

              {(selectedType === 'video_course' ||
                selectedType === 'video_performance') && (
                <>
                  <div className="border-t pt-4">
                    <h4 className="font-medium mb-3">
                      Informations compétition (optionnel)
                    </h4>
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <label className="text-sm font-medium">Nom</label>
                        <Input
                          name="competitionName"
                          value={formData.competitionName}
                          onChange={handleChange}
                          placeholder="Ex: CSI*** Bordeaux"
                        />
                      </div>
                      <div>
                        <label className="text-sm font-medium">Lieu</label>
                        <Input
                          name="competitionLocation"
                          value={formData.competitionLocation}
                          onChange={handleChange}
                          placeholder="Ex: Bordeaux"
                        />
                      </div>
                      <div>
                        <label className="text-sm font-medium">Niveau</label>
                        <select
                          name="competitionLevel"
                          value={formData.competitionLevel}
                          onChange={handleChange}
                          className="w-full h-10 rounded-md border border-input bg-background px-3"
                        >
                          <option value="">Sélectionner</option>
                          <option value="amateur">Amateur</option>
                          <option value="pro">Pro</option>
                          <option value="csi1">CSI*</option>
                          <option value="csi2">CSI**</option>
                          <option value="csi3">CSI***</option>
                          <option value="csi4">CSI****</option>
                          <option value="csi5">CSI*****</option>
                        </select>
                      </div>
                    </div>
                  </div>
                </>
              )}

              <div>
                <label className="text-sm font-medium">Notes</label>
                <textarea
                  name="notes"
                  value={formData.notes}
                  onChange={handleChange}
                  placeholder="Informations supplémentaires..."
                  className="w-full h-24 rounded-md border border-input bg-background px-3 py-2 text-sm"
                />
              </div>
            </CardContent>
          </Card>

          <div className="flex justify-between">
            <Button variant="outline" onClick={() => setStep('type')}>
              Retour
            </Button>
            <Button
              onClick={() => setStep('upload')}
              disabled={!formData.title || !formData.horseId}
            >
              Continuer
              <ChevronRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </div>
      )}

      {/* Step 3: Upload */}
      {step === 'upload' && selectedTypeInfo && (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Fichiers</CardTitle>
              <CardDescription>
                Formats acceptés: {selectedTypeInfo.acceptedFormats}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <FileUpload
                accept={
                  selectedType === 'radiological'
                    ? {
                        'image/*': ['.jpg', '.jpeg', '.png', '.dcm'],
                      }
                    : {
                        'video/*': ['.mp4', '.mov', '.avi', '.webm'],
                      }
                }
                maxFiles={selectedType === 'radiological' ? 20 : 5}
                maxSize={selectedType === 'radiological' ? 50 * 1024 * 1024 : 500 * 1024 * 1024}
                onFilesChange={setFiles}
              />
            </CardContent>
          </Card>

          {/* Summary */}
          <Card>
            <CardHeader>
              <CardTitle>Récapitulatif</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Type</span>
                <span>{selectedTypeInfo.title}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Titre</span>
                <span>{formData.title}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Fichiers</span>
                <span>{files.length} fichier(s)</span>
              </div>
              <div className="border-t pt-3 flex justify-between font-medium">
                <span>Coût</span>
                <span className="text-primary">
                  {selectedTypeInfo.tokens} tokens
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Solde après analyse</span>
                <span>
                  {(organization?.tokenBalance || 0) - selectedTypeInfo.tokens}{' '}
                  tokens
                </span>
              </div>
            </CardContent>
          </Card>

          <div className="flex justify-between">
            <Button variant="outline" onClick={() => setStep('details')}>
              Retour
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={isLoading || files.length === 0 || !hasEnoughTokens}
            >
              {isLoading ? (
                'Lancement...'
              ) : (
                <>
                  <Upload className="w-4 h-4 mr-2" />
                  Lancer l'analyse ({selectedTypeInfo.tokens} tokens)
                </>
              )}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
