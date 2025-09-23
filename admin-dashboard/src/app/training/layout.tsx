import Sidebar from '@/components/layout/Sidebar';
import Header from '@/components/layout/Header';
import AuthGuard from '@/components/auth/AuthGuard';

export default function TrainingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGuard>
      <div className="min-h-screen bg-gray-50">
        <Sidebar activeTab="training" onTabChange={() => {}} />
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