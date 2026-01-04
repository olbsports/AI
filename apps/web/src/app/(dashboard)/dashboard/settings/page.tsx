import { Metadata } from 'next';
import { Settings } from 'lucide-react';
import { SettingsForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Paramètres | Horse Vision AI',
  description: 'Gérez vos paramètres de compte',
};

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="p-3 bg-primary/10 rounded-xl">
          <Settings className="h-6 w-6 text-primary" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Paramètres</h1>
          <p className="text-gray-500">
            Gérez votre mot de passe et vos préférences
          </p>
        </div>
      </div>

      {/* Settings Form */}
      <SettingsForm />
    </div>
  );
}
