import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import { getStorage, ref, uploadBytesResumable, getDownloadURL, UploadTask, UploadMetadata } from 'firebase/storage';

// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyAscOxSvCt6qFYKBvHfLCBzVrLKcxKQGNk",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "botleji.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "botleji",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "botleji.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "603427607468",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:603427607468:web:d4cb0e3e6d8c8f8f8f8f8f",
};

// Initialize Firebase
let app: FirebaseApp;
if (!getApps().length) {
  app = initializeApp(firebaseConfig);
} else {
  app = getApps()[0];
}

// Get Firebase Storage instance
export const storage = getStorage(app);

// Helper to get proper content type
const getContentType = (file: File): string => {
  if (file.type) return file.type;
  
  const extension = file.name.split('.').pop()?.toLowerCase();
  switch (extension) {
    case 'mp4':
      return 'video/mp4';
    case 'webm':
      return 'video/webm';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    default:
      return 'application/octet-stream';
  }
};

// Upload file to Firebase Storage with progress tracking
export interface UploadProgress {
  progress: number; // 0-100
  bytesTransferred: number;
  totalBytes: number;
}

export const uploadFile = (
  file: File,
  path: string,
  onProgress?: (progress: UploadProgress) => void
): Promise<string> => {
  return new Promise((resolve, reject) => {
    const storageRef = ref(storage, path);
    
    // Set proper metadata for the file
    const metadata: UploadMetadata = {
      contentType: getContentType(file),
      cacheControl: 'public, max-age=31536000', // Cache for 1 year
      customMetadata: {
        uploadedAt: new Date().toISOString(),
        originalName: file.name,
      }
    };
    
    const uploadTask: UploadTask = uploadBytesResumable(storageRef, file, metadata);

    uploadTask.on(
      'state_changed',
      (snapshot) => {
        const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (onProgress) {
          onProgress({
            progress,
            bytesTransferred: snapshot.bytesTransferred,
            totalBytes: snapshot.totalBytes,
          });
        }
      },
      (error) => {
        console.error('Upload error:', error);
        reject(error);
      },
      async () => {
        try {
          const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
          // Add token parameter to URL for better CORS handling
          resolve(downloadURL);
        } catch (error) {
          reject(error);
        }
      }
    );
  });
};

// Upload training content media
export const uploadTrainingMedia = async (
  file: File,
  type: 'video' | 'image' | 'thumbnail',
  onProgress?: (progress: UploadProgress) => void
): Promise<string> => {
  const timestamp = Date.now();
  const fileName = `${timestamp}_${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
  const path = `training/${type}s/${fileName}`;
  
  return uploadFile(file, path, onProgress);
};

export default app;

