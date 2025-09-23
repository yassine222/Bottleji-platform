import { UserRole } from '../users/schemas/user.schema';

export interface Permission {
  id: string;
  name: string;
  description: string;
}

export interface RolePermissions {
  role: UserRole;
  permissions: string[];
  canManageRoles: UserRole[];
  description: string;
}

// Define all available permissions
export const PERMISSIONS = {
  // User Management
  VIEW_USERS: 'view_users',
  MANAGE_USERS: 'manage_users',
  DELETE_USERS: 'delete_users',
  BAN_USERS: 'ban_users',
  UNBAN_USERS: 'unban_users',
  
  // Application Management
  VIEW_APPLICATIONS: 'view_applications',
  APPROVE_APPLICATIONS: 'approve_applications',
  REJECT_APPLICATIONS: 'reject_applications',
  
  // Content Management
  VIEW_DROPS: 'view_drops',
  DELETE_DROPS: 'delete_drops',
  MODERATE_CONTENT: 'moderate_content',
  
  // Support Management
  VIEW_TICKETS: 'view_tickets',
  RESPOND_TICKETS: 'respond_tickets',
  CLOSE_TICKETS: 'close_tickets',
  
  // System Management
  VIEW_ANALYTICS: 'view_analytics',
  MANAGE_ADMINS: 'manage_admins',
  MANAGE_ROLES: 'manage_roles',
  VIEW_BILLING: 'view_billing',
  MANAGE_INTEGRATIONS: 'manage_integrations',
  MANAGE_SECURITY: 'manage_security',
  VIEW_SYSTEM_LOGS: 'view_system_logs',
} as const;

// Define role hierarchy and permissions
export const ROLE_PERMISSIONS: RolePermissions[] = [
  {
    role: UserRole.SUPER_ADMIN,
    permissions: Object.values(PERMISSIONS), // All permissions
    canManageRoles: [UserRole.ADMIN, UserRole.MODERATOR, UserRole.SUPPORT_AGENT],
    description: 'Full control over the system. Can manage other admins and assign roles. Has access to sensitive settings (billing, integrations, security, etc.).'
  },
  {
    role: UserRole.ADMIN,
    permissions: [
      PERMISSIONS.VIEW_USERS,
      PERMISSIONS.MANAGE_USERS,
      PERMISSIONS.DELETE_USERS,
      PERMISSIONS.BAN_USERS,
      PERMISSIONS.UNBAN_USERS,
      PERMISSIONS.VIEW_APPLICATIONS,
      PERMISSIONS.APPROVE_APPLICATIONS,
      PERMISSIONS.REJECT_APPLICATIONS,
      PERMISSIONS.VIEW_DROPS,
      PERMISSIONS.DELETE_DROPS,
      PERMISSIONS.MODERATE_CONTENT,
      PERMISSIONS.VIEW_ANALYTICS,
    ],
    canManageRoles: [UserRole.MODERATOR, UserRole.SUPPORT_AGENT],
    description: 'Manages users, posts, and applications. Can approve/reject applications. Can delete or suspend users. Can moderate reported content.'
  },
  {
    role: UserRole.MODERATOR,
    permissions: [
      PERMISSIONS.VIEW_USERS,
      PERMISSIONS.VIEW_DROPS,
      PERMISSIONS.DELETE_DROPS,
      PERMISSIONS.MODERATE_CONTENT,
      PERMISSIONS.VIEW_APPLICATIONS,
      PERMISSIONS.APPROVE_APPLICATIONS,
      PERMISSIONS.REJECT_APPLICATIONS,
    ],
    canManageRoles: [],
    description: 'Focus on user-generated content. Often does not have access to sensitive user data like email, payments, etc.'
  },
  {
    role: UserRole.SUPPORT_AGENT,
    permissions: [
      PERMISSIONS.VIEW_USERS,
      PERMISSIONS.VIEW_TICKETS,
      PERMISSIONS.RESPOND_TICKETS,
      PERMISSIONS.CLOSE_TICKETS,
    ],
    canManageRoles: [],
    description: 'Handles support tickets. Can view limited user info relevant to the ticket. Cannot manage posts or approve applications.'
  },
  {
    role: UserRole.HOUSEHOLD,
    permissions: [],
    canManageRoles: [],
    description: 'Regular user with no administrative privileges.'
  },
  {
    role: UserRole.COLLECTOR,
    permissions: [],
    canManageRoles: [],
    description: 'User who can collect drops. No administrative privileges.'
  },
];

// Helper functions
export function getRolePermissions(role: UserRole): string[] {
  const roleConfig = ROLE_PERMISSIONS.find(r => r.role === role);
  return roleConfig?.permissions || [];
}

export function canManageRole(userRole: UserRole, targetRole: UserRole): boolean {
  const userConfig = ROLE_PERMISSIONS.find(r => r.role === userRole);
  return userConfig?.canManageRoles.includes(targetRole) || false;
}

export function hasPermission(userRoles: UserRole[], permission: string): boolean {
  return userRoles.some(role => {
    const rolePermissions = getRolePermissions(role);
    return rolePermissions.includes(permission);
  });
}

export function getRoleDescription(role: UserRole): string {
  const roleConfig = ROLE_PERMISSIONS.find(r => r.role === role);
  return roleConfig?.description || 'No description available.';
}

export function getManageableRoles(userRole: UserRole): UserRole[] {
  const userConfig = ROLE_PERMISSIONS.find(r => r.role === userRole);
  return userConfig?.canManageRoles || [];
}
