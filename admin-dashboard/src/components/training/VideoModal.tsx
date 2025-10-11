'use client';

import { useEffect, useRef } from 'react';
import VideoPlayer from './VideoPlayer';

interface VideoModalProps {
  isOpen: boolean;
  onClose: () => void;
  videoUrl: string;
  thumbnailUrl?: string;
  title: string;
}

export default function VideoModal({ isOpen, onClose, videoUrl, thumbnailUrl, title }: VideoModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-75 backdrop-blur-sm"
      onClick={handleBackdropClick}
    >
      <div
        ref={modalRef}
        className="relative w-full max-w-5xl mx-4 bg-gray-900 rounded-2xl shadow-2xl overflow-hidden animate-fade-in"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 bg-gray-800 border-b border-gray-700">
          <div className="flex items-center space-x-3">
            <div className="bg-red-500 rounded-full p-2">
              <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z"/>
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-white">{title}</h3>
          </div>
          
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
            aria-label="Close video"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Video Player */}
        <div className="bg-black">
          <div className="aspect-video">
            <VideoPlayer 
              src={videoUrl}
              poster={thumbnailUrl}
              title={title}
            />
          </div>
        </div>

        {/* Footer Info */}
        <div className="px-6 py-3 bg-gray-800 text-sm text-gray-400">
          <p className="flex items-center space-x-2">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>Press ESC to close • Click outside to exit</span>
          </p>
        </div>
      </div>

      {/* CSS Animation */}
      <style jsx>{`
        @keyframes fade-in {
          from {
            opacity: 0;
            transform: scale(0.95);
          }
          to {
            opacity: 1;
            transform: scale(1);
          }
        }
        .animate-fade-in {
          animation: fade-in 0.2s ease-out;
        }
      `}</style>
    </div>
  );
}

