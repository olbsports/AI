import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Decorator to extract the organization ID from the request
 * Use with OrganizationGuard to ensure multi-tenant isolation
 */
export const CurrentOrganization = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest();
    return request.user?.organizationId;
  },
);
