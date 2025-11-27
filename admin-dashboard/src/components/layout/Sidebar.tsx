'use client';

import { useState } from 'react';
import {
  UsersIcon,
  CubeIcon,
  ClipboardDocumentListIcon,
  AcademicCapIcon,
  ChatBubbleLeftRightIcon,
  ChartBarIcon,
  Cog6ToothIcon,
  ArrowLeftOnRectangleIcon,
  GiftIcon,
} from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Dashboard', id: 'dashboard', icon: ChartBarIcon },
  { name: 'Users', id: 'users', icon: UsersIcon },
  { name: 'Drops', id: 'drops', icon: CubeIcon },
  { name: 'Applications', id: 'applications', icon: ClipboardDocumentListIcon },
  { name: 'Reward Shop', id: 'reward-shop', icon: GiftIcon },
  { name: 'Training', id: 'training', icon: AcademicCapIcon },
  { name: 'Support', id: 'support', icon: ChatBubbleLeftRightIcon },
  { name: 'Settings', id: 'settings', icon: Cog6ToothIcon },
];

// Super Admin only navigation items
const superAdminNavigation = [
  { name: 'Admin Management', id: 'admin-management', icon: UsersIcon },
];

interface SidebarProps {
  activeTab: string;
  onTabChange: (tabId: string) => void;
  userRoles?: string[];
}

export default function Sidebar({ activeTab, onTabChange, userRoles = [] }: SidebarProps) {
  const isSuperAdmin = userRoles.includes('super_admin');
  const allNavigation = isSuperAdmin ? [...superAdminNavigation, ...navigation] : navigation;
  return (
    <div className="fixed inset-y-0 left-0 z-50 w-56 bg-primary-dark">
      <div className="flex h-full flex-col">
        {/* Logo/Brand */}
        <div className="flex h-16 flex-shrink-0 items-center px-4">
          <img src="/logo_v2.png" alt="Bottleji Logo" className="h-10 w-10 mr-2 flex-shrink-0" />
          <h1 className="text-lg font-bold text-white whitespace-nowrap">Bottleji Admin</h1>
        </div>

        {/* Navigation */}
        <div className="flex flex-1 flex-col overflow-y-auto">
          <nav className="flex-1 space-y-1 px-3 py-4">
            {allNavigation.map((item) => {
              const isActive = activeTab === item.id;
              const isSuperAdminItem = superAdminNavigation.some(nav => nav.id === item.id);
              
              return (
                <button
                  key={item.id}
                  onClick={() => onTabChange(item.id)}
                  className={`group flex w-full items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 ${
                    isActive
                      ? 'bg-primary text-white shadow-sm'
                      : 'text-green-100 hover:bg-primary hover:text-white'
                  } ${isSuperAdminItem ? 'border-l-4 border-yellow-400' : ''}`}
                >
                  <item.icon
                    className={`mr-3 h-5 w-5 flex-shrink-0 transition-colors duration-200 ${
                      isActive ? 'text-white' : 'text-green-300 group-hover:text-green-100'
                    }`}
                    aria-hidden="true"
                  />
                  {item.name}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Social Media Icons */}
        <div className="flex flex-shrink-0 p-4 border-t border-primary/20">
          <div className="flex justify-center w-full space-x-3">
            {/* Facebook */}
            <button className="p-2 text-green-100 hover:text-primary hover:bg-white/10 rounded-md transition-colors duration-200">
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
            </button>
            
            {/* Instagram */}
            <button className="p-2 text-green-100 hover:text-primary hover:bg-white/10 rounded-md transition-colors duration-200">
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
              </svg>
            </button>
            
            {/* TikTok */}
            <button className="p-2 text-green-100 hover:text-primary hover:bg-white/10 rounded-md transition-colors duration-200">
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
              </svg>
            </button>
            
            {/* LinkedIn */}
            <button className="p-2 text-green-100 hover:text-primary hover:bg-white/10 rounded-md transition-colors duration-200">
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
              </svg>
            </button>
          </div>
        </div>

        {/* Logout Section */}
        <div className="flex flex-shrink-0 p-4">
          <button
            onClick={() => {
              // Clear session storage (session ends when tab closes)
              sessionStorage.removeItem('admin_token');
              // Also clear any stale localStorage
              localStorage.removeItem('admin_token');
              window.location.href = '/login';
            }}
            className="group flex w-full items-center px-3 py-3 text-sm font-medium text-green-100 hover:bg-red-600 hover:text-white rounded-md transition-colors duration-200"
          >
            <ArrowLeftOnRectangleIcon className="mr-3 h-5 w-5 text-green-300 group-hover:text-white" />
            Logout
          </button>
        </div>
      </div>
    </div>
  );
} 