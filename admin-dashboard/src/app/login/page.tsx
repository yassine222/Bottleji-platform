'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { authAPI } from '@/lib/api';
import Image from 'next/image';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await authAPI.login(email, password);
      
      console.log('✅ Login successful:', response.data);
      
      if (response.data.token) {
        // Store token only in sessionStorage for security
        // Session ends when tab closes - user must login again
        try {
          // Clear any old tokens first (cleanup)
          sessionStorage.removeItem('admin_token');
          localStorage.removeItem('admin_token');
          
          // Store only in sessionStorage
          sessionStorage.setItem('admin_token', response.data.token);
          console.log('✅ Token saved to sessionStorage (session-based):', response.data.token.substring(0, 20) + '...');
          console.log('ℹ️ Session will end when tab closes for security');
          
          // Verify token was saved
          const sessionToken = sessionStorage.getItem('admin_token');
          if (sessionToken) {
            console.log('✅ Token verification successful in sessionStorage');
          } else {
            console.error('❌ Token was not saved properly');
          }
        } catch (error) {
          console.error('❌ Error saving token to storage:', error);
        }
        
        // Check if user must change password
        if (response.data.user?.mustChangePassword) {
          router.push('/change-password');
        } else {
          router.push('/dashboard');
        }
      }
    } catch (error: any) {
      console.error('❌ Login error details:', {
        message: error.message || 'Unknown error',
        code: error.code || 'No error code',
        status: error.response?.status || 'No status',
        data: error.response?.data || 'No response data',
        config: error.config ? {
          url: error.config.url || 'No URL',
          method: error.config.method || 'No method',
          timeout: error.config.timeout || 'No timeout'
        } : 'No config',
        stack: error.stack || 'No stack trace'
      });
      
      if (error.response?.status === 401) {
        setError('Invalid credentials. Please check your email and password.');
      } else if (error.response?.status === 403) {
        // Redirect to access denied page for non-admin users
        router.push('/access-denied');
        return;
      } else if (error.response?.data?.message) {
        setError(error.response.data.message);
      } else if (error.code === 'ERR_NETWORK') {
        setError('Network error. Please check your internet connection and try again.');
      } else if (error.code === 'ECONNABORTED') {
        setError('Request timed out. Please try again.');
      } else {
        setError('An error occurred during login. Please check your credentials and try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left Side - Login Form */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-6 lg:px-8 bg-white">
        <div className="max-w-md w-full space-y-8">
          {/* Logo and Header */}
          <div className="text-center">
            <div className="mx-auto w-48 h-48 mb-6">
              <Image
                src="/logo_v2.png"
                alt="Bottleji Logo"
                width={200}
                height={200}
                className="w-full h-full object-contain"
                priority
              />
            </div>
            <h1 className="text-3xl font-bold text-[#00695C] mb-2">
              Bottleji Admin
            </h1>
            <p className="text-[#00695C] text-sm opacity-70">
              Sign in to access the admin dashboard
            </p>
          </div>

          {/* Login Form */}
          <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div className="rounded-lg bg-red-50 border border-red-200 p-4">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">
                      Login Failed
                    </h3>
                    <div className="mt-1 text-sm text-red-700">
                      {error}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Email Field */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-[#00695C] mb-2">
                Email Address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="appearance-none relative block w-full px-3 py-3 border border-[#00695C] placeholder-gray-400 text-black rounded-lg focus:outline-none focus:ring-2 focus:ring-[#00695C] focus:border-[#00695C] focus:z-10 text-sm transition-colors bg-gray-50"
                placeholder="Enter your email address"
              />
            </div>

            {/* Password Field */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-[#00695C] mb-2">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="appearance-none relative block w-full px-3 py-3 border border-[#00695C] placeholder-gray-400 text-black rounded-lg focus:outline-none focus:ring-2 focus:ring-[#00695C] focus:border-[#00695C] focus:z-10 text-sm transition-colors bg-gray-50"
                placeholder="Enter your password"
              />
            </div>

            {/* Submit Button */}
            <div>
              <button
                type="submit"
                disabled={isLoading}
                className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-[#00695C] hover:bg-[#004D40] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#00695C] disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-sm hover:shadow-md"
              >
                {isLoading ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Signing in...
                  </>
                ) : (
                  <>
                    <svg className="-ml-1 mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                    </svg>
                    Sign in to Dashboard
                  </>
                )}
              </button>
            </div>
          </form>

          {/* Footer */}
          <div className="text-center">
            <p className="text-xs text-[#00695C] opacity-60">
              Secure admin access for Bottleji management
            </p>
          </div>
        </div>
      </div>

      {/* Right Side - Decorative Background */}
      <div className="hidden lg:block lg:w-1/2 bg-[#00695C] relative overflow-hidden">
        <div className="relative h-full flex items-center justify-center">
          <div className="text-center text-white">
            <div className="mb-8">
              <svg className="mx-auto h-24 w-24 text-white opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <h2 className="text-3xl font-bold mb-4">
              Admin Dashboard
            </h2>
            <p className="text-lg opacity-90 max-w-md mx-auto">
              Manage users, drops, applications, and monitor the Bottleji ecosystem
            </p>
            <div className="mt-8 grid grid-cols-2 gap-6 max-w-sm mx-auto">
              <div className="text-center">
                <div className="bg-white bg-opacity-20 rounded-lg p-4 mb-2">
                  <svg className="h-8 w-8 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <p className="text-sm">User Management</p>
              </div>
              <div className="text-center">
                <div className="bg-white bg-opacity-20 rounded-lg p-4 mb-2">
                  <svg className="h-8 w-8 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                  </svg>
                </div>
                <p className="text-sm">Analytics</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 