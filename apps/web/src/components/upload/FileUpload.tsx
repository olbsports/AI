'use client';

import { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { Upload, X, FileVideo, FileImage, File, Loader2 } from 'lucide-react';

import { cn, Button } from '@horse-tempo/ui';
import { formatFileSize } from '@horse-tempo/core';

interface UploadedFile {
  id: string;
  file: File;
  preview?: string;
  progress: number;
  status: 'pending' | 'uploading' | 'completed' | 'error';
  url?: string;
  error?: string;
}

interface FileUploadProps {
  accept?: Record<string, string[]>;
  maxFiles?: number;
  maxSize?: number; // in bytes
  onFilesChange: (files: UploadedFile[]) => void;
  onUpload?: (file: File) => Promise<{ url: string }>;
  disabled?: boolean;
  className?: string;
}

export function FileUpload({
  accept = {
    'video/*': ['.mp4', '.mov', '.avi', '.webm'],
    'image/*': ['.jpg', '.jpeg', '.png', '.webp'],
  },
  maxFiles = 10,
  maxSize = 500 * 1024 * 1024, // 500MB
  onFilesChange,
  onUpload,
  disabled = false,
  className,
}: FileUploadProps) {
  const [files, setFiles] = useState<UploadedFile[]>([]);

  const onDrop = useCallback(
    async (acceptedFiles: File[]) => {
      const newFiles: UploadedFile[] = acceptedFiles.map((file) => ({
        id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        file,
        preview: file.type.startsWith('image/')
          ? URL.createObjectURL(file)
          : undefined,
        progress: 0,
        status: 'pending' as const,
      }));

      const updatedFiles = [...files, ...newFiles].slice(0, maxFiles);
      setFiles(updatedFiles);
      onFilesChange(updatedFiles);

      // Auto-upload if onUpload is provided
      if (onUpload) {
        for (const uploadedFile of newFiles) {
          try {
            // Update status to uploading
            setFiles((prev) =>
              prev.map((f) =>
                f.id === uploadedFile.id ? { ...f, status: 'uploading' } : f
              )
            );

            // Simulate progress (in real app, use XMLHttpRequest for progress)
            const progressInterval = setInterval(() => {
              setFiles((prev) =>
                prev.map((f) =>
                  f.id === uploadedFile.id && f.progress < 90
                    ? { ...f, progress: f.progress + 10 }
                    : f
                )
              );
            }, 200);

            const result = await onUpload(uploadedFile.file);

            clearInterval(progressInterval);

            setFiles((prev) => {
              const updated = prev.map((f) =>
                f.id === uploadedFile.id
                  ? { ...f, status: 'completed' as const, progress: 100, url: result.url }
                  : f
              );
              onFilesChange(updated);
              return updated;
            });
          } catch (error: any) {
            setFiles((prev) => {
              const updated = prev.map((f) =>
                f.id === uploadedFile.id
                  ? { ...f, status: 'error' as const, error: error.message }
                  : f
              );
              onFilesChange(updated);
              return updated;
            });
          }
        }
      }
    },
    [files, maxFiles, onFilesChange, onUpload]
  );

  const removeFile = (id: string) => {
    const file = files.find((f) => f.id === id);
    if (file?.preview) {
      URL.revokeObjectURL(file.preview);
    }
    const updatedFiles = files.filter((f) => f.id !== id);
    setFiles(updatedFiles);
    onFilesChange(updatedFiles);
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept,
    maxFiles: maxFiles - files.length,
    maxSize,
    disabled: disabled || files.length >= maxFiles,
  });

  const getFileIcon = (file: File) => {
    if (file.type.startsWith('video/')) {
      return <FileVideo className="w-8 h-8 text-blue-500" />;
    }
    if (file.type.startsWith('image/')) {
      return <FileImage className="w-8 h-8 text-green-500" />;
    }
    return <File className="w-8 h-8 text-gray-500" />;
  };

  return (
    <div className={cn('space-y-4', className)}>
      {/* Dropzone */}
      <div
        {...getRootProps()}
        className={cn(
          'border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors',
          isDragActive
            ? 'border-primary bg-primary/5'
            : 'border-muted-foreground/25 hover:border-primary/50',
          (disabled || files.length >= maxFiles) &&
            'opacity-50 cursor-not-allowed'
        )}
      >
        <input {...getInputProps()} />
        <Upload className="w-10 h-10 mx-auto text-muted-foreground mb-4" />
        {isDragActive ? (
          <p className="text-primary font-medium">Déposez les fichiers ici...</p>
        ) : (
          <>
            <p className="font-medium">
              Glissez-déposez vos fichiers ici, ou{' '}
              <span className="text-primary">parcourir</span>
            </p>
            <p className="text-sm text-muted-foreground mt-2">
              Formats acceptés: MP4, MOV, AVI, JPG, PNG
              <br />
              Taille max: {formatFileSize(maxSize)} par fichier
            </p>
          </>
        )}
      </div>

      {/* File list */}
      {files.length > 0 && (
        <div className="space-y-2">
          {files.map((uploadedFile) => (
            <div
              key={uploadedFile.id}
              className="flex items-center gap-4 p-3 bg-muted/50 rounded-lg"
            >
              {/* Preview or icon */}
              <div className="w-12 h-12 flex-shrink-0 rounded-lg overflow-hidden bg-muted flex items-center justify-center">
                {uploadedFile.preview ? (
                  <img
                    src={uploadedFile.preview}
                    alt={uploadedFile.file.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  getFileIcon(uploadedFile.file)
                )}
              </div>

              {/* File info */}
              <div className="flex-1 min-w-0">
                <p className="font-medium truncate">{uploadedFile.file.name}</p>
                <p className="text-sm text-muted-foreground">
                  {formatFileSize(uploadedFile.file.size)}
                </p>

                {/* Progress bar */}
                {uploadedFile.status === 'uploading' && (
                  <div className="mt-2 h-1.5 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-primary transition-all duration-300"
                      style={{ width: `${uploadedFile.progress}%` }}
                    />
                  </div>
                )}

                {/* Error message */}
                {uploadedFile.status === 'error' && (
                  <p className="text-sm text-red-500 mt-1">
                    {uploadedFile.error || 'Erreur lors de l\'upload'}
                  </p>
                )}
              </div>

              {/* Status / Actions */}
              <div className="flex items-center gap-2">
                {uploadedFile.status === 'uploading' && (
                  <Loader2 className="w-5 h-5 animate-spin text-primary" />
                )}
                {uploadedFile.status === 'completed' && (
                  <span className="text-green-500 text-sm font-medium">
                    ✓ Uploadé
                  </span>
                )}
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => removeFile(uploadedFile.id)}
                  disabled={uploadedFile.status === 'uploading'}
                >
                  <X className="w-4 h-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* File count */}
      {maxFiles > 1 && (
        <p className="text-sm text-muted-foreground text-center">
          {files.length} / {maxFiles} fichiers
        </p>
      )}
    </div>
  );
}
