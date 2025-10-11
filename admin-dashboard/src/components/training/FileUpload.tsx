'use client';

import { useState, useRef } from 'react';
import { uploadTrainingMedia, UploadProgress } from '@/lib/firebase';

interface FileUploadProps {
  type: 'video' | 'image' | 'thumbnail';
  label: string;
  accept: string;
  currentUrl?: string;
  onUploadComplete: (url: string) => void;
  disabled?: boolean;
}

export default function FileUpload({ 
  type, 
  label, 
  accept, 
  currentUrl, 
  onUploadComplete,
  disabled = false 
}: FileUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [preview, setPreview] = useState<string | null>(currentUrl || null);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file size (max 100MB for videos, 10MB for images)
    const maxSize = type === 'video' ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
    if (file.size > maxSize) {
      setError(`File size must be less than ${type === 'video' ? '100MB' : '10MB'}`);
      return;
    }

    // Create preview for images
    if (type === 'image' || type === 'thumbnail') {
      const reader = new FileReader();
      reader.onload = (e) => {
        setPreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }

    // Upload to Firebase
    try {
      setUploading(true);
      setError(null);
      setProgress(0);

      const url = await uploadTrainingMedia(
        file,
        type,
        (progressData: UploadProgress) => {
          setProgress(Math.round(progressData.progress));
        }
      );

      onUploadComplete(url);
      setPreview(url);
      setUploading(false);
      setProgress(100);
    } catch (err: any) {
      console.error('Upload error:', err);
      setError(err.message || 'Upload failed');
      setUploading(false);
      setProgress(0);
    }
  };

  const handleRemove = () => {
    setPreview(null);
    onUploadComplete('');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-2">
      <label className="block text-sm font-medium text-gray-700">
        {label}
      </label>

      {/* Upload Area */}
      <div className="border-2 border-dashed border-gray-300 rounded-lg p-4 hover:border-gray-400 transition-colors">
        {!preview && !uploading && (
          <div className="text-center">
            <div className="mb-2">
              <svg
                className="mx-auto h-12 w-12 text-gray-400"
                stroke="currentColor"
                fill="none"
                viewBox="0 0 48 48"
              >
                <path
                  d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                  strokeWidth={2}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </div>
            <div className="flex justify-center">
              <label className="cursor-pointer">
                <span className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                  Click to upload
                </span>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept={accept}
                  onChange={handleFileSelect}
                  disabled={disabled || uploading}
                  className="hidden"
                />
              </label>
              <p className="pl-1 text-sm text-gray-500">or drag and drop</p>
            </div>
            <p className="text-xs text-gray-500 mt-1">
              {type === 'video' ? 'MP4, WebM up to 100MB' : 'PNG, JPG, GIF up to 10MB'}
            </p>
          </div>
        )}

        {/* Upload Progress */}
        {uploading && (
          <div className="text-center py-4">
            <div className="mb-2">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mx-auto"></div>
            </div>
            <p className="text-sm font-medium text-gray-700 mb-2">Uploading...</p>
            <div className="w-full bg-gray-200 rounded-full h-2 mb-1">
              <div
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
            <p className="text-xs text-gray-500">{progress}%</p>
          </div>
        )}

        {/* Preview */}
        {preview && !uploading && (
          <div className="relative">
            {type === 'video' ? (
              <div className="relative">
                <video
                  src={preview}
                  controls
                  className="w-full max-h-64 rounded-lg"
                >
                  Your browser does not support the video tag.
                </video>
                <button
                  type="button"
                  onClick={handleRemove}
                  className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors shadow-lg"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            ) : (
              <div className="relative inline-block">
                <img
                  src={preview}
                  alt="Preview"
                  className="max-w-full max-h-64 rounded-lg"
                />
                <button
                  type="button"
                  onClick={handleRemove}
                  className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors shadow-lg"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            )}
            <div className="mt-2 flex items-center justify-between">
              <p className="text-xs text-green-600 flex items-center">
                <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                Upload complete
              </p>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="text-xs text-blue-600 hover:text-blue-700 font-medium"
              >
                Change file
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div className="flex items-center text-sm text-red-600 mt-2">
          <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
          </svg>
          {error}
        </div>
      )}

      {/* Current URL Display (for reference) */}
      {currentUrl && !preview && (
        <p className="text-xs text-gray-500 truncate" title={currentUrl}>
          Current: {currentUrl}
        </p>
      )}
    </div>
  );
}

