import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';

/**
 * Guard that ensures resources belong to the user's organization
 * Used for multi-tenant isolation
 */
@Injectable()
export class OrganizationGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const { user } = request;

    if (!user || !user.organizationId) {
      throw new ForbiddenException('User organization not found');
    }

    // The organizationId is injected into the request for use in services
    request.organizationId = user.organizationId;

    return true;
  }
}
