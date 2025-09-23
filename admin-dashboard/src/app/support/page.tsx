'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SupportPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to support tickets page
    router.replace('/support-tickets');
  }, [router]);

  return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>
  );
} 