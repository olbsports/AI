'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import {
  LayoutDashboard,
  Horse,
  Video,
  FileText,
  Settings,
  CreditCard,
  Users,
  HelpCircle,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

import { cn } from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

const navigation = [
  { name: 'dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'horses', href: '/horses', icon: Horse },
  { name: 'analyses', href: '/analyses', icon: Video },
  { name: 'reports', href: '/reports', icon: FileText },
];

const secondaryNavigation = [
  { name: 'team', href: '/settings/team', icon: Users },
  { name: 'billing', href: '/settings/billing', icon: CreditCard },
  { name: 'settings', href: '/settings', icon: Settings },
  { name: 'help', href: '/help', icon: HelpCircle },
];

export function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const pathname = usePathname();
  const t = useTranslations('nav');
  const organization = useAuthStore((state) => state.organization);

  const isActive = (href: string) => {
    const cleanPath = pathname.replace(/^\/[a-z]{2}/, '');
    return cleanPath === href || cleanPath.startsWith(href + '/');
  };

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 z-40 h-screen bg-card border-r transition-all duration-300',
        collapsed ? 'w-16' : 'w-64'
      )}
    >
      <div className="flex h-full flex-col">
        {/* Logo */}
        <div className="flex h-16 items-center justify-between px-4 border-b">
          <Link href="/dashboard" className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-white text-lg">🐴</span>
            </div>
            {!collapsed && (
              <span className="font-bold text-lg">Horse Vision</span>
            )}
          </Link>
          <button
            onClick={onToggle}
            className="p-1 rounded-md hover:bg-muted transition-colors"
          >
            {collapsed ? (
              <ChevronRight className="w-4 h-4" />
            ) : (
              <ChevronLeft className="w-4 h-4" />
            )}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 space-y-1 p-2 overflow-y-auto">
          <div className="space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              const active = isActive(item.href);
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors',
                    active
                      ? 'bg-primary text-primary-foreground'
                      : 'hover:bg-muted'
                  )}
                >
                  <Icon className="w-5 h-5 flex-shrink-0" />
                  {!collapsed && <span>{t(item.name)}</span>}
                </Link>
              );
            })}
          </div>

          <div className="border-t my-4" />

          <div className="space-y-1">
            {secondaryNavigation.map((item) => {
              const Icon = item.icon;
              const active = isActive(item.href);
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-muted-foreground',
                    active ? 'bg-muted text-foreground' : 'hover:bg-muted'
                  )}
                >
                  <Icon className="w-5 h-5 flex-shrink-0" />
                  {!collapsed && <span>{t(item.name)}</span>}
                </Link>
              );
            })}
          </div>
        </nav>

        {/* Token balance */}
        {!collapsed && organization && (
          <div className="p-4 border-t">
            <div className="bg-muted rounded-lg p-3">
              <div className="text-xs text-muted-foreground mb-1">
                Tokens disponibles
              </div>
              <div className="text-2xl font-bold text-primary">
                {organization.tokenBalance}
              </div>
              <Link
                href="/settings/billing"
                className="text-xs text-primary hover:underline"
              >
                Acheter des tokens →
              </Link>
            </div>
          </div>
        )}
      </div>
    </aside>
  );
}
