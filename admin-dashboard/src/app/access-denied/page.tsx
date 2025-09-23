'use client';

import { useRouter } from 'next/navigation';
import { ShieldExclamationIcon, ArrowLeftIcon } from '@heroicons/react/24/outline';

export default function AccessDeniedPage() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100">
            <ShieldExclamationIcon className="h-8 w-8 text-red-600" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Access Denied
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            You do not have permission to access this area
          </p>
        </div>
        
        <div className="bg-white shadow rounded-lg p-6">
          <div className="text-center">
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Administrator Access Required
            </h3>
            <p className="text-sm text-gray-600 mb-6">
              This area is restricted to users with administrator privileges. 
              Please contact your system administrator if you believe you should have access.
            </p>
            
            <div className="space-y-3">
              <button
                onClick={() => router.push('/login')}
                className="w-full flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <ArrowLeftIcon className="h-4 w-4 mr-2" />
                Back to Login
              </button>
              
              <button
                onClick={() => router.push('/')}
                className="w-full flex justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Go to Home
              </button>
            </div>
          </div>
        </div>
        
        <div className="text-center">
          <p className="text-xs text-gray-500">
            Error Code: 403 Forbidden
          </p>
        </div>
      </div>
    </div>
  );
} 