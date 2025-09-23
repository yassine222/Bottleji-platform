'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authAPI } from '@/lib/api';

interface AuthGuardProps {
  children: React.ReactNode;
}

export default function AuthGuard({ children }: AuthGuardProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      console.log('🔐 Starting authentication check...');
      
      // Check if localStorage is available
      if (typeof window === 'undefined') {
        console.log('🔐 Window not available, skipping auth check');
        setIsLoading(false);
        return;
      }
      
      // Try localStorage first, then sessionStorage as fallback
      let token = localStorage.getItem('admin_token');
      if (!token) {
        token = sessionStorage.getItem('admin_token');
        if (token) {
          console.log('🔐 Token found in sessionStorage, copying to localStorage');
          localStorage.setItem('admin_token', token);
        }
      }
      console.log('🔐 Token from storage:', token ? token.substring(0, 20) + '...' : 'No token found');
      
      if (!token) {
        console.log('🔐 No admin token found, redirecting to login');
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
          localStorage.removeItem('admin_token');
          sessionStorage.removeItem('admin_token');
          router.push('/login');
        } else {
          // For other errors, still redirect to login
          console.log('🔐 Other error, redirecting to login');
          localStorage.removeItem('admin_token');
          sessionStorage.removeItem('admin_token');
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

  return <>{children}</>;
} 