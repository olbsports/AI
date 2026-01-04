'use client';

import { useState, useRef } from 'react';
import { Camera, Upload, X } from 'lucide-react';

import { cn, Button } from '@horse-vision/ui';

interface ImageUploadProps {
  value?: string;
  onChange: (url: string | null) => void;
  onUpload?: (file: File) => Promise<{ url: string }>;
  disabled?: boolean;
  className?: string;
}

export function ImageUpload({
  value,
  onChange,
  onUpload,
  disabled = false,
  className,
}: ImageUploadProps) {
  const [isUploading, setIsUploading] = useState(false);
  const [preview, setPreview] = useState<string | null>(value || null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Create preview
    const previewUrl = URL.createObjectURL(file);
    setPreview(previewUrl);

    if (onUpload) {
      setIsUploading(true);
      try {
        const result = await onUpload(file);
        onChange(result.url);
      } catch (error) {
        console.error('Upload error:', error);
        setPreview(null);
        onChange(null);
      } finally {
        setIsUploading(false);
      }
    } else {
      onChange(previewUrl);
    }
  };

  const handleRemove = () => {
    if (preview) {
      URL.revokeObjectURL(preview);
    }
    setPreview(null);
    onChange(null);
    if (inputRef.current) {
      inputRef.current.value = '';
    }
  };

  return (
    <div className={cn('relative', className)}>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        disabled={disabled || isUploading}
        className="hidden"
      />

      {preview ? (
        <div className="relative w-32 h-32 rounded-lg overflow-hidden group">
          <img
            src={preview}
            alt="Preview"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
            <Button
              variant="secondary"
              size="sm"
              onClick={() => inputRef.current?.click()}
              disabled={disabled || isUploading}
            >
              <Camera className="w-4 h-4" />
            </Button>
            <Button
              variant="destructive"
              size="sm"
              onClick={handleRemove}
              disabled={disabled || isUploading}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
          {isUploading && (
            <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
              <div className="w-8 h-8 border-2 border-white border-t-transparent rounded-full animate-spin" />
            </div>
          )}
        </div>
      ) : (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          disabled={disabled || isUploading}
          className={cn(
            'w-32 h-32 rounded-lg border-2 border-dashed flex flex-col items-center justify-center gap-2 transition-colors',
            'hover:border-primary hover:bg-primary/5',
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          <Upload className="w-8 h-8 text-muted-foreground" />
          <span className="text-sm text-muted-foreground">Photo</span>
        </button>
      )}
    </div>
  );
}
