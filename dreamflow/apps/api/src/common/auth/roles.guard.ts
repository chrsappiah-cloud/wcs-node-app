import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthPrincipal } from './auth-principal';
import { ROLES_KEY } from './roles.decorator';
import { UserRole } from './roles.constants';

type RequestLike = {
  headers?: Record<string, unknown>;
  principal?: AuthPrincipal;
};

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass()
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    if (process.env.API_AUTH_REQUIRED !== 'true') {
      return true;
    }

    const req = context.switchToHttp().getRequest<RequestLike>();
    const grantedRoles = req.principal?.roles ?? [];
    return requiredRoles.some(role => grantedRoles.includes(role));
  }
}