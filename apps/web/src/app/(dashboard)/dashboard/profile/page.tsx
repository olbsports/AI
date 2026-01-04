import { Metadata } from 'next';
import { User } from 'lucide-react';
import { ProfileForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Mon Profil | Horse Vision AI',
  description: 'Gérez votre profil utilisateur',
};

export default function ProfilePage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="p-3 bg-primary/10 rounded-xl">
          <User className="h-6 w-6 text-primary" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mon Profil</h1>
          <p className="text-gray-500">
            Mettez à jour vos informations personnelles
          </p>
        </div>
      </div>

      {/* Profile Form */}
      <div className="bg-white rounded-xl border p-6">
        <ProfileForm />
      </div>
    </div>
  );
}
