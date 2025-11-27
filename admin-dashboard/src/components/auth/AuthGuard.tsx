'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authAPI } from '@/lib/api';
import { useActivityTimeout } from '@/hooks/useActivityTimeout';
import InactivityWarning from './InactivityWarning';

interface AuthGuardProps {
  children: React.ReactNode;
}

export default function AuthGuard({ children }: AuthGuardProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const router = useRouter();

  // Activity timeout: 30 minutes inactivity, 2 minutes warning
  const { showWarning, timeRemaining, extendSession, handleLogout } = useActivityTimeout({
    timeoutMinutes: 30,
    warningMinutes: 2,
    onLogout: () => {
      sessionStorage.removeItem('admin_token');
      localStorage.removeItem('admin_token');
      router.push('/login');
    },
  });

  useEffect(() => {
    const checkAuth = async () => {
      console.log('🔐 Starting authentication check...');
      
      // Check if localStorage is available
      if (typeof window === 'undefined') {
        console.log('🔐 Window not available, skipping auth check');
        setIsLoading(false);
        return;
      }
      
      // Use sessionStorage only for tab-specific authentication
      // Session ends when tab closes - more secure
      const token = sessionStorage.getItem('admin_token');
      console.log('🔐 Token from sessionStorage:', token ? token.substring(0, 20) + '...' : 'No token found');
      
      if (!token) {
        console.log('🔐 No admin token found, redirecting to login');
        // Clear any stale localStorage tokens
        localStorage.removeItem('admin_token');
        router.push('/login');
        return;
      }

      try {
        console.log('🔐 Checking admin authentication...');
        // Verify the token by calling the admin profile endpoint
        const response = await authAPI.verifyToken();
        console.log('✅ Admin authentication successful:', response);
        setIsAuthenticated(true);
      } catch (error: any) {
        console.error('❌ Auth check failed:', error);
        console.error('❌ Error response:', error.response?.data);
        console.error('❌ Error status:', error.response?.status);
        
        if (error.response?.status === 401 || error.response?.status === 403) {
          console.log('🔐 Unauthorized/Forbidden, redirecting to login');
          // Clear session storage and any stale localStorage
          sessionStorage.removeItem('admin_token');
          localStorage.removeItem('admin_token');
          router.push('/login');
        } else {
          // For other errors, still redirect to login
          console.log('🔐 Other error, redirecting to login');
          sessionStorage.removeItem('admin_token');
          localStorage.removeItem('admin_token');
          router.push('/login');
        }
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, [router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Verifying admin access...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // Will redirect to login
  }

  return (
    <>
      {children}
      <InactivityWarning
        isOpen={showWarning}
        timeRemaining={timeRemaining}
        onExtend={extendSession}
        onLogout={handleLogout}
      />
    </>
  );
} 