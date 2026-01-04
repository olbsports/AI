import { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Video } from 'lucide-react';
import { AnalysisUploadForm } from '@/components/forms';

export const metadata: Metadata = {
  title: 'Nouvelle Analyse | Horse Vision AI',
  description: 'Lancer une nouvelle analyse vidéo',
};

export default function NewAnalysisPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/dashboard/analyses"
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <ArrowLeft className="h-5 w-5 text-gray-500" />
        </Link>
        <div className="flex items-center gap-3">
          <div className="p-3 bg-primary/10 rounded-xl">
            <Video className="h-6 w-6 text-primary" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Nouvelle Analyse</h1>
            <p className="text-gray-500">
              Téléchargez une vidéo pour lancer l'analyse IA
            </p>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="bg-white rounded-xl border p-6 max-w-3xl">
        <AnalysisUploadForm />
      </div>
    </div>
  );
}
