import { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { HorseForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Nouveau Cheval | Horse Vision AI',
  description: 'Ajouter un nouveau cheval à votre écurie',
};

export default function NewHorsePage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/dashboard/horses"
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <ArrowLeft className="h-5 w-5 text-gray-500" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Nouveau Cheval</h1>
          <p className="text-gray-500">
            Ajoutez un nouveau cheval à votre écurie
          </p>
        </div>
      </div>

      {/* Form */}
      <div className="bg-white rounded-xl border p-6 max-w-3xl">
        <HorseForm />
      </div>
    </div>
  );
}
