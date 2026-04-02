export const USER_ROLES = {
  VIEWER: 'viewer',
  OPERATOR: 'operator',
  ADMIN: 'admin'
} as const;

export type UserRole = (typeof USER_ROLES)[keyof typeof USER_ROLES];

export const ALL_USER_ROLES: UserRole[] = [USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN];