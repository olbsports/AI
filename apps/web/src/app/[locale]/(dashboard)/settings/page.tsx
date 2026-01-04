'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Save, User, Bell, Shield, Globe } from 'lucide-react';

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
} from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';
import { ImageUpload } from '@/components/upload';

export default function SettingsPage() {
  const { user } = useAuthStore();
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const [formData, setFormData] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    avatarUrl: user?.avatarUrl || null,
    locale: user?.locale || 'fr',
  });

  const [notifications, setNotifications] = useState({
    emailAnalysisComplete: true,
    emailReportReady: true,
    emailWeeklyDigest: false,
    pushNotifications: true,
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleNotificationChange = (key: string) => {
    setNotifications((prev) => ({ ...prev, [key]: !prev[key as keyof typeof prev] }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setSuccess(false);

    try {
      // API call would go here
      await new Promise((resolve) => setTimeout(resolve, 1000));
      setSuccess(true);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Paramètres</h1>
        <p className="text-muted-foreground">
          Gérez votre profil et vos préférences
        </p>
      </div>

      {success && (
        <Alert variant="success">
          <AlertDescription>
            Vos paramètres ont été enregistrés avec succès.
          </AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Profile */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <User className="w-5 h-5" />
              <CardTitle>Profil</CardTitle>
            </div>
            <CardDescription>
              Informations personnelles et photo de profil
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex gap-6">
              <ImageUpload
                value={formData.avatarUrl || ''}
                onChange={(url) =>
                  setFormData((prev) => ({ ...prev, avatarUrl: url }))
                }
              />
              <div className="flex-1 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium">Prénom</label>
                    <Input
                      name="firstName"
                      value={formData.firstName}
                      onChange={handleChange}
                    />
                  </div>
                  <div>
                    <label className="text-sm font-medium">Nom</label>
                    <Input
                      name="lastName"
                      value={formData.lastName}
                      onChange={handleChange}
                    />
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium">Email</label>
                  <Input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                  />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Language */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Globe className="w-5 h-5" />
              <CardTitle>Langue</CardTitle>
            </div>
            <CardDescription>
              Choisissez la langue de l'interface
            </CardDescription>
          </CardHeader>
          <CardContent>
            <select
              name="locale"
              value={formData.locale}
              onChange={handleChange}
              className="w-full max-w-xs h-10 rounded-md border border-input bg-background px-3"
            >
              <option value="fr">Français</option>
              <option value="en">English</option>
              <option value="es">Español</option>
              <option value="de">Deutsch</option>
              <option value="it">Italiano</option>
            </select>
          </CardContent>
        </Card>

        {/* Notifications */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Bell className="w-5 h-5" />
              <CardTitle>Notifications</CardTitle>
            </div>
            <CardDescription>
              Configurez vos préférences de notification
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {[
              {
                key: 'emailAnalysisComplete',
                label: 'Analyse terminée',
                description: 'Recevoir un email quand une analyse est terminée',
              },
              {
                key: 'emailReportReady',
                label: 'Rapport prêt',
                description: 'Recevoir un email quand un rapport est prêt à signer',
              },
              {
                key: 'emailWeeklyDigest',
                label: 'Résumé hebdomadaire',
                description: 'Recevoir un résumé de l\'activité chaque semaine',
              },
              {
                key: 'pushNotifications',
                label: 'Notifications push',
                description: 'Recevoir des notifications dans le navigateur',
              },
            ].map((item) => (
              <div
                key={item.key}
                className="flex items-center justify-between py-2"
              >
                <div>
                  <p className="font-medium">{item.label}</p>
                  <p className="text-sm text-muted-foreground">
                    {item.description}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => handleNotificationChange(item.key)}
                  className={`relative w-11 h-6 rounded-full transition-colors ${
                    notifications[item.key as keyof typeof notifications]
                      ? 'bg-primary'
                      : 'bg-muted'
                  }`}
                >
                  <span
                    className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full transition-transform ${
                      notifications[item.key as keyof typeof notifications]
                        ? 'translate-x-5'
                        : ''
                    }`}
                  />
                </button>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Security */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5" />
              <CardTitle>Sécurité</CardTitle>
            </div>
            <CardDescription>
              Mot de passe et authentification
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between py-2">
              <div>
                <p className="font-medium">Mot de passe</p>
                <p className="text-sm text-muted-foreground">
                  Dernière modification il y a 30 jours
                </p>
              </div>
              <Button variant="outline" type="button">
                Changer
              </Button>
            </div>
            <div className="flex items-center justify-between py-2">
              <div>
                <p className="font-medium">Authentification à deux facteurs</p>
                <p className="text-sm text-muted-foreground">
                  Ajoutez une couche de sécurité supplémentaire
                </p>
              </div>
              <Button variant="outline" type="button">
                Configurer
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="flex justify-end">
          <Button type="submit" disabled={isLoading}>
            <Save className="w-4 h-4 mr-2" />
            {isLoading ? 'Enregistrement...' : 'Enregistrer'}
          </Button>
        </div>
      </form>
    </div>
  );
}
