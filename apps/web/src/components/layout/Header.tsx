'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  Bell,
  Search,
  Plus,
  User,
  LogOut,
  Settings,
  Moon,
  Sun,
} from 'lucide-react';

import { Button, Input } from '@horse-tempo/ui';
import { useAuthStore } from '@/stores/auth';

interface HeaderProps {
  sidebarCollapsed: boolean;
}

export function Header({ sidebarCollapsed }: HeaderProps) {
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/auth/login');
  };

  return (
    <header
      className={`fixed top-0 right-0 z-30 h-16 bg-background border-b transition-all duration-300 ${
        sidebarCollapsed ? 'left-16' : 'left-64'
      }`}
    >
      <div className="flex h-full items-center justify-between px-6">
        {/* Search */}
        <div className="flex-1 max-w-lg">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Rechercher chevaux, analyses, rapports..."
              className="pl-10"
            />
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-4">
          {/* New analysis button */}
          <Button asChild>
            <Link href={"/analyses/new" as any}>
              <Plus className="w-4 h-4 mr-2" />
              Nouvelle analyse
            </Link>
          </Button>

          {/* Notifications */}
          <div className="relative">
            <button
              onClick={() => setShowNotifications(!showNotifications)}
              className="p-2 rounded-lg hover:bg-muted transition-colors relative"
            >
              <Bell className="w-5 h-5" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" />
            </button>

            {showNotifications && (
              <div className="absolute right-0 mt-2 w-80 bg-card rounded-lg shadow-lg border p-4">
                <h3 className="font-semibold mb-3">Notifications</h3>
                <div className="space-y-3">
                  <div className="flex gap-3 p-2 rounded-lg hover:bg-muted cursor-pointer">
                    <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                      <span className="text-green-600">✓</span>
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Analyse terminée</p>
                      <p className="text-xs text-muted-foreground">
                        L'analyse du parcours CSI*** est prête
                      </p>
                    </div>
                  </div>
                  <div className="flex gap-3 p-2 rounded-lg hover:bg-muted cursor-pointer">
                    <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                      <span className="text-blue-600">📋</span>
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium">Rapport généré</p>
                      <p className="text-xs text-muted-foreground">
                        Rapport radiologique HV-348 disponible
                      </p>
                    </div>
                  </div>
                </div>
                <Link
                  href="/notifications"
                  className="block text-center text-sm text-primary mt-3 hover:underline"
                >
                  Voir toutes les notifications
                </Link>
              </div>
            )}
          </div>

          {/* User menu */}
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted transition-colors"
            >
              <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-white text-sm font-medium">
                {user?.firstName?.[0]}
                {user?.lastName?.[0]}
              </div>
              <div className="hidden md:block text-left">
                <p className="text-sm font-medium">
                  {user?.firstName} {user?.lastName}
                </p>
                <p className="text-xs text-muted-foreground capitalize">
                  {user?.role}
                </p>
              </div>
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-56 bg-card rounded-lg shadow-lg border py-2">
                <Link
                  href={"/settings/profile" as any}
                  className="flex items-center gap-3 px-4 py-2 hover:bg-muted"
                >
                  <User className="w-4 h-4" />
                  <span>Mon profil</span>
                </Link>
                <Link
                  href="/settings"
                  className="flex items-center gap-3 px-4 py-2 hover:bg-muted"
                >
                  <Settings className="w-4 h-4" />
                  <span>Paramètres</span>
                </Link>
                <div className="border-t my-2" />
                <button
                  onClick={handleLogout}
                  className="flex items-center gap-3 px-4 py-2 hover:bg-muted w-full text-left text-red-600"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Déconnexion</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
