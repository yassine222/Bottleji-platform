import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from '../../users/users.service';
import { UserRole } from '../../users/schemas/user.schema';
import { hasPermission } from '../../auth/role-permissions';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    // Get full user data from database to check roles
    const fullUser = await this.usersService.findOne(user.id || user.sub);
    if (!fullUser) {
      throw new ForbiddenException('User not found');
    }

    // Check if user has any admin role (SUPER_ADMIN, ADMIN, MODERATOR, SUPPORT_AGENT)
    const hasAdminRole = fullUser.roles && (
      fullUser.roles.includes(UserRole.SUPER_ADMIN) ||
      fullUser.roles.includes(UserRole.ADMIN) ||
      fullUser.roles.includes(UserRole.MODERATOR) ||
      fullUser.roles.includes(UserRole.SUPPORT_AGENT)
    );
    
    if (!hasAdminRole) {
      throw new ForbiddenException('Admin access required');
    }

    // Check for specific permissions if required
    const requiredPermissions = this.reflector.get<string[]>('permissions', context.getHandler());
    if (requiredPermissions && requiredPermissions.length > 0) {
      const hasRequiredPermissions = requiredPermissions.every(permission => 
        hasPermission(fullUser.roles, permission)
      );
      
      if (!hasRequiredPermissions) {
        throw new ForbiddenException('Insufficient permissions');
      }
    }

    // Attach the full user object to the request for use in controllers
    request.fullUser = fullUser;

    return true;
  }
} 