'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useRouter } from 'next/navigation';
import { Loader2, Upload, X } from 'lucide-react';
import { horseSchema, type HorseFormData } from '@/lib/validations/horse';
import { useCreateHorse, useUpdateHorse } from '@/hooks/use-horses';

interface HorseFormProps {
  horse?: {
    id: string;
    name: string;
    breed?: string;
    birthDate?: string;
    gender: string;
    color?: string;
    height?: number;
    weight?: number;
    chipNumber?: string;
    passportNumber?: string;
    ownerId?: string;
    notes?: string;
    imageUrl?: string;
  };
  onSuccess?: () => void;
  onCancel?: () => void;
}

const GENDERS = [
  { value: 'stallion', label: 'Étalon' },
  { value: 'mare', label: 'Jument' },
  { value: 'gelding', label: 'Hongre' },
];

const BREEDS = [
  'Pur-sang',
  'Selle Français',
  'KWPN',
  'Hanovrien',
  'Holsteiner',
  'Trakehner',
  'Lusitanien',
  'Pur-sang Arabe',
  'Frison',
  'Quarter Horse',
  'Autre',
];

export function HorseForm({ horse, onSuccess, onCancel }: HorseFormProps) {
  const router = useRouter();
  const createHorse = useCreateHorse();
  const updateHorse = useUpdateHorse();
  const [error, setError] = useState<string | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(
    horse?.imageUrl || null
  );

  const isEditing = !!horse;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setValue,
  } = useForm<HorseFormData>({
    resolver: zodResolver(horseSchema),
    defaultValues: {
      name: horse?.name || '',
      breed: horse?.breed || '',
      birthDate: horse?.birthDate || '',
      gender: horse?.gender || 'gelding',
      color: horse?.color || '',
      height: horse?.height || undefined,
      weight: horse?.weight || undefined,
      chipNumber: horse?.chipNumber || '',
      passportNumber: horse?.passportNumber || '',
      notes: horse?.notes || '',
    },
  });

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = () => {
    setImagePreview(null);
    setValue('image' as keyof HorseFormData, undefined);
  };

  const onSubmit = async (data: HorseFormData) => {
    setError(null);
    try {
      if (isEditing) {
        await updateHorse.mutateAsync({ id: horse.id, data });
      } else {
        await createHorse.mutateAsync(data);
      }
      onSuccess?.();
      router.push('/dashboard/horses');
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : `Une erreur est survenue lors de ${isEditing ? 'la modification' : 'la création'}`
      );
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Image Upload */}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">
          Photo du cheval
        </label>
        <div className="flex items-center gap-4">
          {imagePreview ? (
            <div className="relative">
              <img
                src={imagePreview}
                alt="Preview"
                className="w-24 h-24 object-cover rounded-lg"
              />
              <button
                type="button"
                onClick={removeImage}
                className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ) : (
            <label className="w-24 h-24 flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary">
              <Upload className="h-6 w-6 text-gray-400" />
              <span className="text-xs text-gray-500 mt-1">Ajouter</span>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="hidden"
              />
            </label>
          )}
        </div>
      </div>

      {/* Name */}
      <div className="space-y-2">
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Nom du cheval *
        </label>
        <input
          {...register('name')}
          type="text"
          id="name"
          className={`block w-full px-3 py-2.5 border rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
            errors.name ? 'border-red-500' : 'border-gray-300'
          }`}
          placeholder="Nom du cheval"
        />
        {errors.name && (
          <p className="text-sm text-red-600">{errors.name.message}</p>
        )}
      </div>

      {/* Breed & Gender Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <label htmlFor="breed" className="block text-sm font-medium text-gray-700">
            Race
          </label>
          <select
            {...register('breed')}
            id="breed"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
          >
            <option value="">Sélectionner une race</option>
            {BREEDS.map((breed) => (
              <option key={breed} value={breed}>
                {breed}
              </option>
            ))}
          </select>
        </div>

        <div className="space-y-2">
          <label htmlFor="gender" className="block text-sm font-medium text-gray-700">
            Sexe *
          </label>
          <select
            {...register('gender')}
            id="gender"
            className={`block w-full px-3 py-2.5 border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
              errors.gender ? 'border-red-500' : 'border-gray-300'
            }`}
          >
            {GENDERS.map((gender) => (
              <option key={gender.value} value={gender.value}>
                {gender.label}
              </option>
            ))}
          </select>
          {errors.gender && (
            <p className="text-sm text-red-600">{errors.gender.message}</p>
          )}
        </div>
      </div>

      {/* Birth Date & Color Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <label htmlFor="birthDate" className="block text-sm font-medium text-gray-700">
            Date de naissance
          </label>
          <input
            {...register('birthDate')}
            type="date"
            id="birthDate"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
          />
        </div>

        <div className="space-y-2">
          <label htmlFor="color" className="block text-sm font-medium text-gray-700">
            Robe
          </label>
          <input
            {...register('color')}
            type="text"
            id="color"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="ex: Bai, Alezan, Gris..."
          />
        </div>
      </div>

      {/* Height & Weight Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <label htmlFor="height" className="block text-sm font-medium text-gray-700">
            Taille (cm)
          </label>
          <input
            {...register('height', { valueAsNumber: true })}
            type="number"
            id="height"
            min="100"
            max="200"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="165"
          />
          {errors.height && (
            <p className="text-sm text-red-600">{errors.height.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <label htmlFor="weight" className="block text-sm font-medium text-gray-700">
            Poids (kg)
          </label>
          <input
            {...register('weight', { valueAsNumber: true })}
            type="number"
            id="weight"
            min="200"
            max="1000"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="550"
          />
          {errors.weight && (
            <p className="text-sm text-red-600">{errors.weight.message}</p>
          )}
        </div>
      </div>

      {/* Chip & Passport Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <label htmlFor="chipNumber" className="block text-sm font-medium text-gray-700">
            Numéro de puce
          </label>
          <input
            {...register('chipNumber')}
            type="text"
            id="chipNumber"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="250XXXXXXXXXXXX"
          />
        </div>

        <div className="space-y-2">
          <label htmlFor="passportNumber" className="block text-sm font-medium text-gray-700">
            Numéro de passeport
          </label>
          <input
            {...register('passportNumber')}
            type="text"
            id="passportNumber"
            className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="FR-XXXXX"
          />
        </div>
      </div>

      {/* Notes */}
      <div className="space-y-2">
        <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
          Notes
        </label>
        <textarea
          {...register('notes')}
          id="notes"
          rows={4}
          className="block w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent resize-none"
          placeholder="Informations complémentaires sur le cheval..."
        />
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
          disabled={isSubmitting}
          className="flex items-center px-4 py-2.5 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? (
            <>
              <Loader2 className="animate-spin -ml-1 mr-2 h-4 w-4" />
              {isEditing ? 'Modification...' : 'Création...'}
            </>
          ) : isEditing ? (
            'Enregistrer les modifications'
          ) : (
            'Créer le cheval'
          )}
        </button>
      </div>
    </form>
  );
}
