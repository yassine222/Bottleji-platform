'use client';

import { useRouter } from 'next/navigation';
import Sidebar from '@/components/layout/Sidebar';
import Header from '@/components/layout/Header';
import AuthGuard from '@/components/auth/AuthGuard';

export default function SupportLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();

  const handleTabChange = (tabId: string) => {
    if (tabId === 'dashboard') {
      router.push('/dashboard');
    } else {
      router.push(`/${tabId}`);
    }
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-gray-50">
        <Sidebar activeTab="support" onTabChange={handleTabChange} />
        <div className="pl-56">
          <Header />
          <main className="pt-24 pb-8">
            <div className="mx-auto max-w-7xl px-6 lg:px-8">
              {children}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
} 