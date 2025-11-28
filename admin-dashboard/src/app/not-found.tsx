'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function NotFound() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to home page after a short delay
    const timer = setTimeout(() => {
      router.push('/');
    }, 2000);

    return () => clearTimeout(timer);
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">404 - Page Not Found</h1>
        <p className="text-gray-600 mb-8">Redirecting to home page...</p>
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
      </div>
    </div>
  );
}

