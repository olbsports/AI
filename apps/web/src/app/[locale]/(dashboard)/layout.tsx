'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { useAuthStore } from '@/stores/auth';
import { Spinner } from '@horse-tempo/ui';

interface DashboardLayoutProps {
  children: React.ReactNode;
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check auth status
    if (!isAuthenticated) {
      router.push('/auth/login');
    } else {
      setIsLoading(false);
    }
  }, [isAuthenticated, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <Sidebar
        collapsed={sidebarCollapsed}
        onToggle={() => setSidebarCollapsed(!sidebarCollapsed)}
      />
      <Header sidebarCollapsed={sidebarCollapsed} />

      <main
        className={`pt-16 transition-all duration-300 ${
          sidebarCollapsed ? 'pl-16' : 'pl-64'
        }`}
      >
        <div className="p-6">{children}</div>
      </main>
    </div>
  );
}
