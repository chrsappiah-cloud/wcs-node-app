import { UserRole } from './roles.constants';

export interface AuthPrincipal {
  /** How the request was authenticated ('none' when API_AUTH_REQUIRED is false) */
  authMethod: 'api-key' | 'bearer' | 'phone' | 'apple' | 'google' | 'none';
  /** Validated roles parsed from JWT claims or x-user-role header */
  roles: UserRole[];
}
