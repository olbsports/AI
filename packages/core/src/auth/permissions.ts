import { type UserRole } from '@horse-vision/types';

/**
 * Définition des permissions par ressource
 */
export const Permissions = {
  // Horses
  HORSE_CREATE: 'horse:create',
  HORSE_READ: 'horse:read',
  HORSE_UPDATE: 'horse:update',
  HORSE_DELETE: 'horse:delete',
  HORSE_ARCHIVE: 'horse:archive',

  // Riders
  RIDER_CREATE: 'rider:create',
  RIDER_READ: 'rider:read',
  RIDER_UPDATE: 'rider:update',
  RIDER_DELETE: 'rider:delete',

  // Analysis
  ANALYSIS_CREATE: 'analysis:create',
  ANALYSIS_READ: 'analysis:read',
  ANALYSIS_UPDATE: 'analysis:update',
  ANALYSIS_DELETE: 'analysis:delete',
  ANALYSIS_CANCEL: 'analysis:cancel',

  // Reports
  REPORT_CREATE: 'report:create',
  REPORT_READ: 'report:read',
  REPORT_UPDATE: 'report:update',
  REPORT_DELETE: 'report:delete',
  REPORT_SIGN: 'report:sign',
  REPORT_SHARE: 'report:share',

  // Organization
  ORG_READ: 'org:read',
  ORG_UPDATE: 'org:update',
  ORG_MANAGE_MEMBERS: 'org:manage_members',
  ORG_MANAGE_BILLING: 'org:manage_billing',
  ORG_VIEW_ANALYTICS: 'org:view_analytics',

  // Users
  USER_READ: 'user:read',
  USER_UPDATE: 'user:update',
  USER_INVITE: 'user:invite',
  USER_REMOVE: 'user:remove',

  // Billing
  BILLING_VIEW: 'billing:view',
  BILLING_MANAGE: 'billing:manage',
  BILLING_BUY_TOKENS: 'billing:buy_tokens',
} as const;

export type Permission = (typeof Permissions)[keyof typeof Permissions];

/**
 * Mapping rôle -> permissions
 */
export const RolePermissions: Record<UserRole, Permission[]> = {
  owner: Object.values(Permissions),

  admin: [
    Permissions.HORSE_CREATE,
    Permissions.HORSE_READ,
    Permissions.HORSE_UPDATE,
    Permissions.HORSE_DELETE,
    Permissions.HORSE_ARCHIVE,
    Permissions.RIDER_CREATE,
    Permissions.RIDER_READ,
    Permissions.RIDER_UPDATE,
    Permissions.RIDER_DELETE,
    Permissions.ANALYSIS_CREATE,
    Permissions.ANALYSIS_READ,
    Permissions.ANALYSIS_UPDATE,
    Permissions.ANALYSIS_DELETE,
    Permissions.ANALYSIS_CANCEL,
    Permissions.REPORT_CREATE,
    Permissions.REPORT_READ,
    Permissions.REPORT_UPDATE,
    Permissions.REPORT_DELETE,
    Permissions.REPORT_SIGN,
    Permissions.REPORT_SHARE,
    Permissions.ORG_READ,
    Permissions.ORG_MANAGE_MEMBERS,
    Permissions.ORG_VIEW_ANALYTICS,
    Permissions.USER_READ,
    Permissions.USER_UPDATE,
    Permissions.USER_INVITE,
    Permissions.BILLING_VIEW,
  ],

  veterinarian: [
    Permissions.HORSE_READ,
    Permissions.HORSE_UPDATE,
    Permissions.RIDER_READ,
    Permissions.ANALYSIS_CREATE,
    Permissions.ANALYSIS_READ,
    Permissions.ANALYSIS_UPDATE,
    Permissions.REPORT_CREATE,
    Permissions.REPORT_READ,
    Permissions.REPORT_UPDATE,
    Permissions.REPORT_SIGN,
    Permissions.REPORT_SHARE,
    Permissions.ORG_READ,
    Permissions.USER_READ,
    Permissions.BILLING_VIEW,
  ],

  analyst: [
    Permissions.HORSE_READ,
    Permissions.RIDER_READ,
    Permissions.ANALYSIS_CREATE,
    Permissions.ANALYSIS_READ,
    Permissions.ANALYSIS_UPDATE,
    Permissions.REPORT_READ,
    Permissions.REPORT_SHARE,
    Permissions.ORG_READ,
    Permissions.USER_READ,
  ],

  viewer: [
    Permissions.HORSE_READ,
    Permissions.RIDER_READ,
    Permissions.ANALYSIS_READ,
    Permissions.REPORT_READ,
    Permissions.ORG_READ,
    Permissions.USER_READ,
  ],
};

/**
 * Vérifie si un rôle possède une permission
 */
export function hasPermission(role: UserRole, permission: Permission): boolean {
  return RolePermissions[role]?.includes(permission) ?? false;
}

/**
 * Vérifie si un rôle possède toutes les permissions
 */
export function hasAllPermissions(
  role: UserRole,
  permissions: Permission[]
): boolean {
  return permissions.every((p) => hasPermission(role, p));
}

/**
 * Vérifie si un rôle possède au moins une permission
 */
export function hasAnyPermission(
  role: UserRole,
  permissions: Permission[]
): boolean {
  return permissions.some((p) => hasPermission(role, p));
}
