'use client';

import { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import Sidebar from './Sidebar';
import AuthGuard from '../auth/AuthGuard';

interface AdminLayoutProps {
  children: React.ReactNode;
}

export default function AdminLayout({ children }: AdminLayoutProps) {
  const [isLoading, setIsLoading] = useState(false);
  const pathname = usePathname();

  // Show loading state when pathname changes
  useEffect(() => {
    setIsLoading(true);
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 300); // Short loading time for smooth feel

    return () => clearTimeout(timer);
  }, [pathname]);

  return (
    <AuthGuard>
      <div className="min-h-screen bg-gray-50">
        <div className="pl-56">
          <main className="py-8">
            <div className="mx-auto max-w-7xl px-6 lg:px-8">
              {isLoading ? (
                <div className="flex items-center justify-center h-64">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                </div>
              ) : (
                <div className="fade-in">
                  {children}
                </div>
              )}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
} 