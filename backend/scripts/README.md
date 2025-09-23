# Backend Scripts Organization

This directory contains utility scripts organized by category for easier maintenance and discovery.

## Directory Structure

```
scripts/
├── database/          # Database-related scripts (migrations, data fixes, user management)
├── admin/            # Admin dashboard and administrative tasks
├── testing/          # API testing and debugging scripts
├── utilities/        # General utility scripts (IP updates, setup, etc.)
└── README.md         # This file
```

## Database Scripts (`database/`)

### User Management
- `audit-users-simple.js` - Comprehensive user audit
- `check-all-users.js` - List all users
- `check-current-user.js` - Check specific user data
- `check-user-data.js` - Validate user data integrity
- `check-user-password.js` - Verify user passwords
- `check-user-status.js` - Check user application status
- `create-user.js` - Create new users
- `fix-all-user-roles.js` - Fix user role assignments
- `fix-inconsistent-user.js` - Fix inconsistent user data
- `fix-legacy-collectors.js` - Handle legacy collector users
- `fix-missing-fields.js` - Add missing user fields
- `fix-testuser-application-status.js` - Fix test user application
- `fix-user-roles.js` - Fix individual user roles
- `force-refresh-user-session.js` - Force user session refresh
- `force-remove-roles.js` - Remove user roles
- `reset-testuser-password.js` - Reset test user password
- `reset-user-password.js` - Reset user passwords

### Data Migration
- `migrate-collector-applications.js` - Migrate collector applications
- `migrate-users.js` - User data migration
- `migrate-with-env.js` - Environment-aware migration
- `run-cleanup.js` - Database cleanup
- `run-migration.js` - Run migrations
- `sync-all-application-statuses.js` - Sync application statuses
- `verify-structure.js` - Verify database structure

## Admin Scripts (`admin/`)

### Admin Dashboard
- `add-admin-role.js` - Add admin role to users
- `add-collector-role.js` - Add collector role to users
- `add-missing-user-fields.js` - Add missing user fields
- `add-phone-verification-fields.js` - Add phone verification fields
- `check-admin-users.js` - Check admin users
- `check-roles.js` - Check user roles
- `check-testuser-application.js` - Check test user application
- `clear-session-invalidation.js` - Clear session invalidation
- `reset-admin-password.js` - Reset admin password
- `update-subscription-types.js` - Update subscription types

### Testing Admin Features
- `test-admin-dashboard-connection.js` - Test admin dashboard connection
- `test-admin-dashboard-login.js` - Test admin login
- `test-admin-login.js` - Test admin authentication
- `test-application-update-flow.js` - Test application update flow
- `test-complete-realtime-flow.js` - Test realtime updates
- `test-realtime-status-update.js` - Test status updates
- `test-realtime-update-simple.js` - Simple realtime test

## Testing Scripts (`testing/`)

- `simple-api-test.js` - Simple API endpoint testing
- `test-api-response.js` - Test API responses

## Utility Scripts (`utilities/`)

### Setup and Configuration
- `auto-update-ip.js` - Automatically update IP addresses
- `get-current-ip.js` - Get current IP address
- `setup-env.js` - Setup environment variables
- `travel-setup-guide.js` - Travel setup instructions
- `update-ip-addresses.js` - Update IP addresses in config files

### Documentation
- `clear-app-cache-instructions.md` - Instructions for clearing app cache

## Usage

### Running Scripts

```bash
# Database scripts
node scripts/database/check-all-users.js

# Admin scripts
node scripts/admin/add-admin-role.js

# Testing scripts
node scripts/testing/simple-api-test.js

# Utility scripts
node scripts/utilities/get-current-ip.js
```

### Common Patterns

Most scripts follow these patterns:
1. Connect to MongoDB using environment variables
2. Perform the required operation
3. Log results
4. Disconnect from database

### Environment Variables

Scripts require these environment variables:
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - JWT secret for authentication
- Other variables as needed by specific scripts

## Best Practices

1. **Always backup data** before running migration scripts
2. **Test scripts** on development data first
3. **Check environment variables** before running
4. **Review script output** for errors
5. **Document any changes** made by scripts

## Adding New Scripts

When adding new scripts:
1. Place them in the appropriate category directory
2. Follow the existing naming convention
3. Include proper error handling
4. Add documentation in this README
5. Test thoroughly before committing
