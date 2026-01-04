'use client';

import { useState, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useRouter } from 'next/navigation';
import { useDropzone } from 'react-dropzone';
import {
  Loader2,
  Upload,
  X,
  FileVideo,
  AlertCircle,
  CheckCircle,
} from 'lucide-react';
import { analysisSchema, type AnalysisFormData } from '@/lib/validations/analysis';
import { useCreateAnalysis, useHorses } from '@/hooks';

interface AnalysisUploadFormProps {
  preselectedHorseId?: string;
  onSuccess?: () => void;
  onCancel?: () => void;
}

const ANALYSIS_TYPES = [
  { value: 'locomotion', label: 'Analyse locomotion', description: 'Analyse des allures et de la locomotion' },
  { value: 'conformity', label: 'Analyse conformité', description: 'Analyse morphologique et conformité' },
  { value: 'veterinary', label: 'Examen vétérinaire', description: 'Analyse pour diagnostic vétérinaire' },
  { value: 'performance', label: 'Analyse performance', description: 'Analyse des performances sportives' },
];

const MAX_FILE_SIZE = 500 * 1024 * 1024; // 500MB
const ACCEPTED_VIDEO_TYPES = {
  'video/mp4': ['.mp4'],
  'video/quicktime': ['.mov'],
  'video/x-msvideo': ['.avi'],
  'video/webm': ['.webm'],
};

export function AnalysisUploadForm({
  preselectedHorseId,
  onSuccess,
  onCancel,
}: AnalysisUploadFormProps) {
  const router = useRouter();
  const createAnalysis = useCreateAnalysis();
  const { data: horsesData } = useHorses();
  const horses = horsesData?.items || [];

  const [error, setError] = useState<string | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setValue,
    watch,
  } = useForm<AnalysisFormData>({
    resolver: zodResolver(analysisSchema),
    defaultValues: {
      horseId: preselectedHorseId || '',
      type: 'locomotion',
      title: '',
      notes: '',
    },
  });

  const selectedType = watch('type');

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: unknown[]) => {
    if (rejectedFiles.length > 0) {
      setError('Fichier invalide. Veuillez utiliser un format vidéo supporté (MP4, MOV, AVI, WebM) de moins de 500MB.');
      return;
    }

    if (acceptedFiles.length > 0) {
      const file = acceptedFiles[0];
      setVideoFile(file);
      setError(null);
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: ACCEPTED_VIDEO_TYPES,
    maxSize: MAX_FILE_SIZE,
    maxFiles: 1,
  });

  const removeVideo = () => {
    setVideoFile(null);
    setUploadProgress(0);
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const onSubmit = async (data: AnalysisFormData) => {
    if (!videoFile) {
      setError('Veuillez sélectionner une vidéo à analyser');
      return;
    }

    setError(null);
    try {
      // Create FormData for upload
      const formData = new FormData();
      formData.append('video', videoFile);
      formData.append('horseId', data.horseId);
      formData.append('type', data.type);
      if (data.notes) {
        formData.append('notes', data.notes);
      }

      // Simulate progress for demo
      const progressInterval = setInterval(() => {
        setUploadProgress((prev) => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return prev;
          }
          return prev + 10;
        });
      }, 500);

      await createAnalysis.mutateAsync({
        ...data,
        videoFile,
      });

      clearInterval(progressInterval);
      setUploadProgress(100);

      onSuccess?.();
      router.push('/dashboard/analyses');
    } catch (err) {
      setUploadProgress(0);
      setError(
        err instanceof Error
          ? err.message
          : 'Une erreur est survenue lors de l\'envoi'
      );
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
          <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Video Upload */}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">
          Vidéo à analyser *
        </label>

        {!videoFile ? (
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
              isDragActive
                ? 'border-primary bg-primary/5'
                : 'border-gray-300 hover:border-primary'
            }`}
          >
            <input {...getInputProps()} />
            <Upload className="mx-auto h-12 w-12 text-gray-400" />
            <p className="mt-4 text-sm text-gray-600">
              {isDragActive ? (
                'Déposez la vidéo ici...'
              ) : (
                <>
                  <span className="font-medium text-primary">Cliquez pour sélectionner</span>
                  {' '}ou glissez-déposez une vidéo
                </>
              )}
            </p>
            <p className="mt-2 text-xs text-gray-500">
              MP4, MOV, AVI, WebM • Max 500MB
            </p>
          </div>
        ) : (
          <div className="border rounded-lg p-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-50 rounded-lg">
                <FileVideo className="h-8 w-8 text-blue-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">
                  {videoFile.name}
                </p>
                <p className="text-xs text-gray-500">
                  {formatFileSize(videoFile.size)}
                </p>
                {uploadProgress > 0 && uploadProgress < 100 && (
                  <div className="mt-2">
                    <div className="w-full bg-gray-200 rounded-full h-1.5">
                      <div
                        className="bg-primary h-1.5 rounded-full transition-all"
                        style={{ width: `${uploadProgress}%` }}
                      />
                    </div>
                    <p className="text-xs text-gray-500 mt-1">
                      Upload: {uploadProgress}%
                    </p>
                  </div>
                )}
                {uploadProgress === 100 && (
                  <div className="flex items-center gap-1 mt-1 text-green-600">
                    <CheckCircle className="h-4 w-4" />
                    <span className="text-xs">Upload terminé</span>
                  </div>
                )}
              </div>
              <button
                type="button"
                onClick={removeVideo}
                className="p-2 text-gray-400 hover:text-red-500"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Horse Selection */}
      <div className="space-y-2">
        <label htmlFor="horseId" className="block text-sm font-medium text-gray-700">
          Cheval *
        </label>
        <select
          {...register('horseId')}
          id="horseId"
          className={`block w-full px-3 py-2.5 border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
            errors.horseId ? 'border-red-500' : 'border-gray-300'
          }`}
        >
          <option value="">Sélectionner un cheval</option>
          {horses.map((horse) => (
            <option key={horse.id} value={horse.id}>
              {horse.name} {horse.breed && `(${horse.breed})`}
            </option>
          ))}
        </select>
        {errors.horseId && (
          <p className="text-sm text-red-600">{errors.horseId.message}</p>
        )}
      </div>

      {/* Analysis Type */}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">
          Type d'analyse *
        </label>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {ANALYSIS_TYPES.map((type) => (
            <label
              key={type.value}
              className={`relative flex items-start p-4 border rounded-lg cursor-pointer transition-colors ${
                selectedType === type.value
                  ? 'border-primary bg-primary/5'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <input
                type="radio"
                {...register('type')}
                value={type.value}
                className="sr-only"
              />
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{type.label}</p>
                <p className="text-xs text-gray-500 mt-1">{type.description}</p>
              </div>
              {selectedType === type.value && (
                <CheckCircle className="h-5 w-5 text-primary" />
              )}
            </label>
          ))}
        </div>
        {errors.type && (
          <p className="text-sm text-red-600">{errors.type.message}</p>
        )}
      </div>

      {/* Notes */}
      <div className="space-y-2">
        <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
          Notes (optionnel)
        </label>
        <textarea
          {...register('notes')}
          id="notes"
          rows={3}
          className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent resize-none"
          placeholder="Observations particulières, contexte de la prise de vue..."
        />
      </div>

      {/* Token Cost Info */}
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
        <div className="flex items-start gap-3">
          <AlertCircle className="h-5 w-5 text-amber-600 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-amber-800">
              Coût de l'analyse
            </p>
            <p className="text-xs text-amber-700 mt-1">
              Cette analyse consommera entre 10 et 50 tokens selon la durée de la vidéo.
              Votre solde actuel sera débité après le traitement.
            </p>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex justify-end gap-3 pt-4 border-t">
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
          >
            Annuler
          </button>
        )}
        <button
          type="submit"
          disabled={isSubmitting || !videoFile}
          className="flex items-center px-4 py-2.5 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? (
            <>
              <Loader2 className="animate-spin -ml-1 mr-2 h-4 w-4" />
              Envoi en cours...
            </>
          ) : (
            <>
              <Upload className="-ml-1 mr-2 h-4 w-4" />
              Lancer l'analyse
            </>
          )}
        </button>
      </div>
    </form>
  );
}
