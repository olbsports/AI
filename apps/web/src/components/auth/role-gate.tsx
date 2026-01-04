'use client';

import { useAuth } from '@/contexts/auth-context';

interface RoleGateProps {
  children: React.ReactNode;
  allowedRoles: string[];
  fallback?: React.ReactNode;
}

const ROLE_HIERARCHY: Record<string, string[]> = {
  owner: ['owner', 'admin', 'veterinarian', 'analyst', 'viewer'],
  admin: ['admin', 'veterinarian', 'analyst', 'viewer'],
  veterinarian: ['veterinarian', 'viewer'],
  analyst: ['analyst', 'viewer'],
  viewer: ['viewer'],
};

export function RoleGate({ children, allowedRoles, fallback = null }: RoleGateProps) {
  const { user } = useAuth();

  if (!user) {
    return <>{fallback}</>;
  }

  // Check if user's role or any role they inherit has access
  const userRoles = ROLE_HIERARCHY[user.role] || [user.role];
  const hasAccess = allowedRoles.some((role) => userRoles.includes(role));

  if (!hasAccess) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

export function useHasRole(requiredRoles: string[]): boolean {
  const { user } = useAuth();

  if (!user) {
    return false;
  }

  const userRoles = ROLE_HIERARCHY[user.role] || [user.role];
  return requiredRoles.some((role) => userRoles.includes(role));
}

export function useIsOwner(): boolean {
  return useHasRole(['owner']);
}

export function useIsAdmin(): boolean {
  return useHasRole(['owner', 'admin']);
}

export function useIsVeterinarian(): boolean {
  return useHasRole(['owner', 'admin', 'veterinarian']);
}
