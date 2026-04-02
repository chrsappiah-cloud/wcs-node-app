import { verify as jwtVerify } from 'jsonwebtoken';
import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { AuthPrincipal } from '../auth/auth-principal';
import { ALL_USER_ROLES, UserRole } from '../auth/roles.constants';

type RequestLike = {
  method?: string;
  originalUrl?: string;
  url?: string;
  headers?: Record<string, unknown>;
  requestId?: string;
  principal?: AuthPrincipal;
};

type ResponseLike = {
  status: (code: number) => ResponseLike;
  json: (body: unknown) => void;
};

interface JwtPayload {
  sub?: string;
  authMethod?: string;
  roles?: unknown[];
}

function parseRoles(headers: Record<string, unknown>): UserRole[] {
  const roleHeader = headers['x-user-role'];
  if (typeof roleHeader !== 'string' || roleHeader.trim().length === 0) return [];
  return roleHeader
    .split(',')
    .map(r => r.trim())
    .filter((r): r is UserRole => ALL_USER_ROLES.includes(r as UserRole));
}

/** Attempts to verify a Bearer token as a GeoWCS-issued JWT.
 *  Returns the embedded roles if valid; null otherwise. */
function extractJwtPrincipal(
  bearerToken: string
): { authMethod: AuthPrincipal['authMethod']; roles: UserRole[] } | null {
  const secret = process.env.JWT_SECRET;
  if (!secret) return null;

  try {
    const payload = jwtVerify(bearerToken, secret, {
      issuer: 'geowcs',
      algorithms: ['HS256']
    }) as JwtPayload;

    const method = payload.authMethod as AuthPrincipal['authMethod'] | undefined;
    const authMethod: AuthPrincipal['authMethod'] =
      method === 'apple' || method === 'google' || method === 'phone' ? method : 'none';

    const roles = Array.isArray(payload.roles)
      ? (payload.roles as unknown[]).filter(
          (r): r is UserRole => typeof r === 'string' && ALL_USER_ROLES.includes(r as UserRole)
        )
      : [];

    return { authMethod, roles };
  } catch {
    return null;
  }
}

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  private readonly logger = new Logger(AuthMiddleware.name);

  use(req: RequestLike, res: ResponseLike, next: () => void) {
    const path = req.originalUrl ?? req.url ?? '';
    if (path.endsWith('/health')) {
      next();
      return;
    }

    const authRequired = process.env.API_AUTH_REQUIRED === 'true';
    if (!authRequired || req.method === 'OPTIONS') {
      req.principal = { authMethod: 'none', roles: parseRoles(req.headers ?? {}) };
      next();
      return;
    }

    const expectedToken = process.env.API_AUTH_TOKEN;
    const expectedApiKey = process.env.API_AUTH_KEY;
    const jwtSecretConfigured = !!process.env.JWT_SECRET;

    if (!expectedToken && !expectedApiKey && !jwtSecretConfigured) {
      this.logger.error('API_AUTH_REQUIRED=true but no credentials are configured.');
      res.status(503).json({
        message: 'Authentication is required but not configured',
        requestId: req.requestId
      });
      return;
    }

    const authHeader = req.headers?.authorization;
    const apiKeyHeader = req.headers?.['x-api-key'];

    const bearerToken =
      typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length).trim()
        : undefined;

    const apiKey = typeof apiKeyHeader === 'string' ? apiKeyHeader : undefined;

    // ── Try JWT first (user-issued token from /auth endpoints) ───────────────
    if (bearerToken) {
      const jwtPrincipal = extractJwtPrincipal(bearerToken);
      if (jwtPrincipal) {
        // JWT overrides x-user-role header — roles come from the token claims
        req.principal = jwtPrincipal;
        next();
        return;
      }
    }

    // ── Fall back to static API key / bearer token ────────────────────────────
    const bearerMatches = expectedToken ? bearerToken === expectedToken : false;
    const apiKeyMatches = expectedApiKey ? apiKey === expectedApiKey : false;

    if (!bearerMatches && !apiKeyMatches) {
      res.status(401).json({ message: 'Unauthorized', requestId: req.requestId });
      return;
    }

    req.principal = {
      authMethod: bearerMatches ? 'bearer' : 'api-key',
      roles: parseRoles(req.headers ?? {})
    };
    next();
  }
}