import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

export type Role = 'owner' | 'admin' | 'veterinarian' | 'analyst' | 'viewer';

export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

// Role hierarchy - higher roles inherit lower roles permissions
export const ROLE_HIERARCHY: Record<Role, Role[]> = {
  owner: ['owner', 'admin', 'veterinarian', 'analyst', 'viewer'],
  admin: ['admin', 'veterinarian', 'analyst', 'viewer'],
  veterinarian: ['veterinarian', 'viewer'],
  analyst: ['analyst', 'viewer'],
  viewer: ['viewer'],
};

export function hasRole(userRole: Role, requiredRoles: Role[]): boolean {
  const userPermissions = ROLE_HIERARCHY[userRole] || [];
  return requiredRoles.some((role) => userPermissions.includes(role));
}
