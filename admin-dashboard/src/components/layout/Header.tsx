'use client';

import { Fragment, useState, useEffect } from 'react';
import { Menu, Transition } from '@headlessui/react';
import { UserCircleIcon } from '@heroicons/react/24/outline';
import { authAPI } from '@/lib/api';

interface User {
  id: string;
  name: string;
  email: string;
  profilePhoto?: string;
}

export default function Header() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUserProfile = async () => {
      try {
        const token = localStorage.getItem('admin_token');
        if (!token) {
          console.log('No admin token found, redirecting to login');
          window.location.href = '/login';
          return;
        }

        // Try to decode JWT token to get basic user info
        try {
          const payload = JSON.parse(atob(token.split('.')[1]));
          console.log('JWT payload:', payload);
          
          // Set basic user info from JWT as fallback
          const fallbackUser = {
            id: payload.sub,
            email: payload.email,
            name: payload.name || payload.email?.split('@')[0] || 'Admin User',
            profilePhoto: undefined
          };
          
          setUser(fallbackUser);
          console.log('Set fallback user from JWT:', fallbackUser);
        } catch (jwtError) {
          console.log('Could not decode JWT token:', jwtError);
          // Set a basic fallback user
          setUser({
            id: 'unknown',
            email: 'admin@bottleji.com',
            name: 'Admin User',
            profilePhoto: undefined
          });
        }

        // Try to fetch full profile from API
        try {
          console.log('Fetching user profile with token:', token.substring(0, 20) + '...');
          const response = await authAPI.getProfile();
          console.log('Profile response:', response);
          
          if (response.data && response.data.user) {
            setUser(response.data.user);
            console.log('Updated user with API data:', response.data.user);
          } else {
            console.error('Invalid response structure:', response);
          }
        } catch (apiError: any) {
          console.error('API Error fetching user profile:', apiError);
          if (apiError.response?.status === 401) {
            console.log('Token expired or invalid, redirecting to login');
            localStorage.removeItem('admin_token');
            sessionStorage.removeItem('admin_token');
            window.location.href = '/login';
          }
          // Keep the fallback user from JWT
        }
      } catch (error: any) {
        console.error('General error in fetchUserProfile:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchUserProfile();
  }, []);

  return (
    <header className="fixed top-0 right-0 left-56 z-40 bg-primary-dark shadow-lg">
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 justify-end items-center">
          <div className="flex items-center">
            <Menu as="div" className="relative ml-3">
              <div>
                <Menu.Button className="flex rounded-full bg-white/10 text-sm focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-primary-dark p-1 hover:bg-white/20 transition-colors duration-200">
                  <UserCircleIcon className="h-6 w-6 text-white" />
                </Menu.Button>
              </div>
              <Transition
                as={Fragment}
                enter="transition ease-out duration-100"
                enterFrom="transform opacity-0 scale-95"
                enterTo="transform opacity-100 scale-100"
                leave="transition ease-in duration-75"
                leaveFrom="transform opacity-100 scale-100"
                leaveTo="transform opacity-0 scale-95"
              >
                <Menu.Items className="absolute right-0 z-10 mt-2 w-64 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
                  {/* User Info Section */}
                  <div className="px-4 py-3 border-b border-gray-100">
                    {loading ? (
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-gray-200 rounded-full animate-pulse"></div>
                        <div className="flex-1">
                          <div className="h-4 bg-gray-200 rounded animate-pulse mb-2"></div>
                          <div className="h-3 bg-gray-200 rounded animate-pulse w-3/4"></div>
                        </div>
                      </div>
                    ) : user ? (
                      <div className="flex items-center space-x-3">
                        {user.profilePhoto ? (
                          <img 
                            src={user.profilePhoto} 
                            alt={user.name}
                            className="w-10 h-10 rounded-full object-cover"
                          />
                        ) : (
                          <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center">
                            <span className="text-white font-semibold text-sm">
                              {user.name.charAt(0).toUpperCase()}
                            </span>
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {user.name}
                          </p>
                          <p className="text-sm text-gray-500 truncate">
                            {user.email}
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="text-sm text-gray-500">
                        User not found
                      </div>
                    )}
                  </div>
                </Menu.Items>
              </Transition>
            </Menu>
          </div>
        </div>
      </div>
    </header>
  );
} 