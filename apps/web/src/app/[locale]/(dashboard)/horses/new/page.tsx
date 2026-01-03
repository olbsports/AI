'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { ArrowLeft, Save } from 'lucide-react';
import Link from 'next/link';

import {
  Button,
  Input,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Alert,
  AlertDescription,
} from '@horse-vision/ui';
import { ImageUpload } from '@/components/upload';
import { api } from '@/lib/api';

export default function NewHorsePage() {
  const t = useTranslations('horses');
  const router = useRouter();

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    name: '',
    sireId: '',
    ueln: '',
    microchip: '',
    gender: 'gelding',
    birthDate: '',
    breed: '',
    color: '',
    heightCm: '',
    ownerName: '',
    photoUrl: null as string | null,
    tags: [] as string[],
  });

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      const payload = {
        ...formData,
        heightCm: formData.heightCm ? parseInt(formData.heightCm) : undefined,
        birthDate: formData.birthDate || undefined,
      };

      await api.horses.create(payload as any);
      router.push('/horses');
    } catch (err: any) {
      setError(err.message || 'Une erreur est survenue');
    } finally {
      setIsLoading(false);
    }
  };

  const breeds = [
    'Selle Français',
    'KWPN',
    'Holsteiner',
    'Hanovrien',
    'BWP',
    'Zangersheide',
    'Oldenbourg',
    'Westphalien',
    'Anglo-Arabe',
    'Pur-Sang',
    'Autre',
  ];

  const colors = [
    'Alezan',
    'Bai',
    'Bai-brun',
    'Noir',
    'Gris',
    'Palomino',
    'Isabelle',
    'Pie',
    'Rouan',
    'Autre',
  ];

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/horses">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold">{t('add')}</h1>
          <p className="text-muted-foreground">
            Renseignez les informations du cheval
          </p>
        </div>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Photo & Basic Info */}
        <Card>
          <CardHeader>
            <CardTitle>Informations générales</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex gap-6">
              <ImageUpload
                value={formData.photoUrl || undefined}
                onChange={(url) =>
                  setFormData((prev) => ({ ...prev, photoUrl: url }))
                }
              />
              <div className="flex-1 space-y-4">
                <div>
                  <label className="text-sm font-medium">{t('fields.name')} *</label>
                  <Input
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    placeholder="Ex: Thunder"
                    required
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium">{t('fields.gender')} *</label>
                    <select
                      name="gender"
                      value={formData.gender}
                      onChange={handleChange}
                      className="w-full h-10 rounded-md border border-input bg-background px-3"
                      required
                    >
                      <option value="male">Étalon</option>
                      <option value="female">Jument</option>
                      <option value="gelding">Hongre</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-sm font-medium">{t('fields.birthDate')}</label>
                    <Input
                      type="date"
                      name="birthDate"
                      value={formData.birthDate}
                      onChange={handleChange}
                    />
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Identification */}
        <Card>
          <CardHeader>
            <CardTitle>Identification</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Numéro SIRE</label>
                <Input
                  name="sireId"
                  value={formData.sireId}
                  onChange={handleChange}
                  placeholder="Ex: FRA12345678"
                  className="font-mono"
                />
              </div>
              <div>
                <label className="text-sm font-medium">UELN</label>
                <Input
                  name="ueln"
                  value={formData.ueln}
                  onChange={handleChange}
                  placeholder="Ex: 250123456789012"
                  className="font-mono"
                />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium">Transpondeur / Puce</label>
              <Input
                name="microchip"
                value={formData.microchip}
                onChange={handleChange}
                placeholder="Ex: 250123456789012"
                className="font-mono"
              />
            </div>
          </CardContent>
        </Card>

        {/* Physical Characteristics */}
        <Card>
          <CardHeader>
            <CardTitle>Caractéristiques physiques</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">{t('fields.breed')}</label>
                <select
                  name="breed"
                  value={formData.breed}
                  onChange={handleChange}
                  className="w-full h-10 rounded-md border border-input bg-background px-3"
                >
                  <option value="">Sélectionner...</option>
                  {breeds.map((breed) => (
                    <option key={breed} value={breed}>
                      {breed}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium">{t('fields.color')}</label>
                <select
                  name="color"
                  value={formData.color}
                  onChange={handleChange}
                  className="w-full h-10 rounded-md border border-input bg-background px-3"
                >
                  <option value="">Sélectionner...</option>
                  {colors.map((color) => (
                    <option key={color} value={color}>
                      {color}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="w-1/2">
              <label className="text-sm font-medium">{t('fields.height')} (cm)</label>
              <Input
                type="number"
                name="heightCm"
                value={formData.heightCm}
                onChange={handleChange}
                placeholder="Ex: 168"
                min="100"
                max="200"
              />
            </div>
          </CardContent>
        </Card>

        {/* Owner */}
        <Card>
          <CardHeader>
            <CardTitle>Propriétaire</CardTitle>
          </CardHeader>
          <CardContent>
            <div>
              <label className="text-sm font-medium">{t('fields.owner')}</label>
              <Input
                name="ownerName"
                value={formData.ownerName}
                onChange={handleChange}
                placeholder="Nom du propriétaire"
              />
            </div>
          </CardContent>
        </Card>

        {/* Actions */}
        <div className="flex justify-end gap-4">
          <Button variant="outline" type="button" asChild>
            <Link href="/horses">Annuler</Link>
          </Button>
          <Button type="submit" disabled={isLoading}>
            <Save className="w-4 h-4 mr-2" />
            {isLoading ? 'Enregistrement...' : 'Enregistrer'}
          </Button>
        </div>
      </form>
    </div>
  );
}
