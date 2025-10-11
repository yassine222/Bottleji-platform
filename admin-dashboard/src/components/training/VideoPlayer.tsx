'use client';

import { useState, useRef, useEffect } from 'react';

interface VideoPlayerProps {
  src: string;
  poster?: string;
  title?: string;
}

export default function VideoPlayer({ src, poster, title }: VideoPlayerProps) {
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [canPlay, setCanPlay] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    // Reset states when src changes
    setError(null);
    setLoading(true);
    setCanPlay(false);
  }, [src]);

  const handleLoadedData = () => {
    console.log('✅ Video loaded successfully:', src);
    setLoading(false);
    setCanPlay(true);
  };

  const handleError = (e: React.SyntheticEvent<HTMLVideoElement, Event>) => {
    const videoElement = e.currentTarget;
    console.error('❌ Video error:', {
      error: videoElement.error,
      code: videoElement.error?.code,
      message: videoElement.error?.message,
      src: src,
      networkState: videoElement.networkState,
      readyState: videoElement.readyState
    });

    let errorMessage = 'Failed to load video';
    if (videoElement.error) {
      switch (videoElement.error.code) {
        case 1:
          errorMessage = 'Video loading aborted';
          break;
        case 2:
          errorMessage = 'Network error while loading video';
          break;
        case 3:
          errorMessage = 'Video decoding failed (format may not be supported)';
          break;
        case 4:
          errorMessage = 'Video format not supported';
          break;
        default:
          errorMessage = videoElement.error.message || 'Unknown error';
      }
    }

    setError(errorMessage);
    setLoading(false);
  };

  const handleLoadStart = () => {
    console.log('🔄 Video loading started:', src);
    setLoading(true);
  };

  const handleCanPlay = () => {
    console.log('✅ Video can play:', src);
    setCanPlay(true);
    setLoading(false);
  };

  // Create a direct Firebase Storage URL without token for testing
  const getDirectUrl = (url: string) => {
    try {
      const urlObj = new URL(url);
      // If it's a Firebase URL, try to get the direct path
      if (urlObj.hostname.includes('firebasestorage.googleapis.com')) {
        return url;
      }
      return url;
    } catch {
      return url;
    }
  };

  const directUrl = getDirectUrl(src);

  return (
    <div className="relative w-full max-w-2xl">
      {/* Loading Overlay */}
      {loading && !error && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-900 bg-opacity-75 rounded-lg z-10">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-2"></div>
            <p className="text-white text-sm">Loading video...</p>
          </div>
        </div>
      )}

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <div className="flex items-start space-x-3">
            <svg className="w-6 h-6 text-red-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div className="flex-1">
              <h4 className="text-red-800 font-medium mb-2">Unable to Play Video</h4>
              <p className="text-red-700 text-sm mb-3">{error}</p>
              
              <div className="space-y-2 text-sm">
                <p className="text-red-600 font-medium">Possible solutions:</p>
                <ul className="list-disc list-inside text-red-600 space-y-1 ml-2">
                  <li>Check if CORS is configured on Firebase Storage</li>
                  <li>Verify the video file format (should be MP4 or WebM)</li>
                  <li>Try re-uploading the video</li>
                  <li>Check browser console for detailed errors</li>
                </ul>
              </div>

              <div className="mt-4 pt-4 border-t border-red-200">
                <p className="text-xs text-red-600 mb-2">Direct URL for testing:</p>
                <a 
                  href={directUrl} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 hover:text-blue-800 break-all"
                >
                  {directUrl}
                </a>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Video Player */}
      {!error && (
        <div className={loading ? 'opacity-50' : ''}>
          <video
            ref={videoRef}
            className="w-full rounded-lg shadow-lg bg-black"
            controls
            poster={poster}
            preload="metadata"
            onLoadStart={handleLoadStart}
            onLoadedData={handleLoadedData}
            onCanPlay={handleCanPlay}
            onError={handleError}
            playsInline
            controlsList="nodownload"
          >
            <source src={directUrl} type="video/mp4" />
            <source src={directUrl} type="video/webm" />
            <p className="text-white p-4">
              Your browser does not support HTML5 video. 
              <a href={directUrl} className="text-blue-400 hover:text-blue-300 ml-1">
                Download the video
              </a>
            </p>
          </video>

          {/* Video Info */}
          {canPlay && (
            <div className="mt-2 flex items-center justify-between text-xs text-gray-500">
              <span className="flex items-center">
                <svg className="w-4 h-4 mr-1 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                Ready to play
              </span>
              {title && <span className="truncate ml-2">{title}</span>}
            </div>
          )}
        </div>
      )}

      {/* Debug Info (only in development) */}
      {process.env.NODE_ENV === 'development' && (
        <details className="mt-2 text-xs text-gray-500">
          <summary className="cursor-pointer hover:text-gray-700">Debug Info</summary>
          <div className="mt-2 p-2 bg-gray-50 rounded border border-gray-200 space-y-1">
            <p><strong>URL:</strong> <span className="break-all">{src}</span></p>
            <p><strong>Poster:</strong> {poster || 'None'}</p>
            <p><strong>Loading:</strong> {loading ? 'Yes' : 'No'}</p>
            <p><strong>Can Play:</strong> {canPlay ? 'Yes' : 'No'}</p>
            <p><strong>Error:</strong> {error || 'None'}</p>
          </div>
        </details>
      )}
    </div>
  );
}

