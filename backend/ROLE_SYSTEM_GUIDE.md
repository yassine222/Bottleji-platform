# Role Hierarchy System Guide

## Overview

The Bottleji admin system now supports a comprehensive role hierarchy with granular permissions. This system allows for better security, scalability, and delegation of administrative tasks.

## Role Hierarchy

### 1. SUPER_ADMIN (Owner)
**Full control over the system.**

**Permissions:**
- All permissions in the system
- Can manage other admins and assign roles
- Has access to sensitive settings (billing, integrations, security, etc.)
- Can view system logs and analytics
- Can manage all users, content, and applications

**Can Manage Roles:**
- ADMIN
- MODERATOR
- SUPPORT_AGENT

**Description:** This is the highest level of access. Super admins have complete control over the system and can manage all other admin users.

---

### 2. ADMIN
**Manages users, posts, and applications.**

**Permissions:**
- View and manage users
- Delete and ban users
- View and manage applications (approve/reject)
- View and delete drops
- Moderate content
- View analytics

**Can Manage Roles:**
- MODERATOR
- SUPPORT_AGENT

**Description:** Admins handle day-to-day administrative tasks including user management, content moderation, and application processing.

---

### 3. MODERATOR
**Focus on user-generated content.**

**Permissions:**
- View users (limited info)
- View and delete drops
- Moderate content
- View and approve/reject applications

**Can Manage Roles:**
- None

**Description:** Moderators focus on content quality and user-generated content. They don't have access to sensitive user data like email, payments, etc.

---

### 4. SUPPORT_AGENT
**Handles support tickets.**

**Permissions:**
- View users (limited info relevant to tickets)
- View support tickets
- Respond to tickets
- Close tickets

**Can Manage Roles:**
- None

**Description:** Support agents handle customer support and can only access information relevant to the tickets they're working on.

---

### 5. COLLECTOR
**User who can collect drops.**

**Permissions:**
- None (regular user with collection privileges)

**Description:** Regular users who have been approved to collect drops. No administrative privileges.

---

### 6. HOUSEHOLD
**Regular users.**

**Permissions:**
- None (basic user privileges)

**Description:** Standard users who can create drops and use the basic features of the app.

## Migration from Old System

### Current Status
- Your existing admin users currently have the basic `ADMIN` role
- This role will be automatically upgraded to `SUPER_ADMIN` during migration

### Migration Process
1. Run the migration script: `node migrate-admin-roles.js`
2. All existing admin users will be upgraded to `SUPER_ADMIN`
3. You can then create new users with appropriate roles

## Implementation Details

### Files Modified
1. `backend/src/modules/users/schemas/user.schema.ts` - Updated UserRole enum
2. `backend/src/modules/auth/role-permissions.ts` - New permission system
3. `backend/src/modules/admin/guards/admin.guard.ts` - Updated guard logic
4. `backend/src/modules/auth/decorators/permissions.decorator.ts` - New permission decorator
5. `backend/src/modules/auth/auth.service.ts` - Updated admin login logic

### Key Features
- **Granular Permissions**: Each role has specific permissions
- **Role Hierarchy**: Higher roles can manage lower roles
- **Permission Checking**: Controllers can require specific permissions
- **Flexible System**: Easy to add new roles and permissions

## Usage Examples

### Checking Permissions in Controllers
```typescript
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { PERMISSIONS } from '../auth/role-permissions';

@Controller('admin')
export class AdminController {
  @Get('users')
  @RequirePermissions(PERMISSIONS.VIEW_USERS)
  async getUsers() {
    // Only users with VIEW_USERS permission can access this
  }

  @Delete('users/:id')
  @RequirePermissions(PERMISSIONS.DELETE_USERS)
  async deleteUser() {
    // Only users with DELETE_USERS permission can access this
  }
}
```

### Checking Permissions in Services
```typescript
import { hasPermission } from '../auth/role-permissions';

async someServiceMethod(userRoles: UserRole[]) {
  if (hasPermission(userRoles, PERMISSIONS.MANAGE_USERS)) {
    // User can manage users
  }
}
```

## Security Considerations

1. **Principle of Least Privilege**: Each role has only the permissions it needs
2. **Role Hierarchy**: Higher roles can manage lower roles but not vice versa
3. **Permission Granularity**: Fine-grained permissions for better security
4. **Audit Trail**: All role changes should be logged

## Next Steps

1. **Run Migration**: Execute the migration script to upgrade existing admins
2. **Create New Roles**: Add new users with appropriate roles
3. **Update Frontend**: Modify the admin dashboard to show role-appropriate features
4. **Test Permissions**: Verify that each role can only access what they should
5. **Document Procedures**: Create procedures for role management

## Support

For questions about the role system or implementation, refer to:
- `backend/src/modules/auth/role-permissions.ts` - Permission definitions
- `backend/migrate-admin-roles.js` - Migration script
- This guide for usage examples
