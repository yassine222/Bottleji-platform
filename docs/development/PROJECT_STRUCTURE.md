# Backend Project Structure

This document describes the organization and structure of the Bottleji backend application.

## Directory Structure

```
backend/
├── src/                          # Source code
│   ├── main.ts                   # Application entry point
│   ├── app.module.ts             # Root module
│   ├── app.controller.ts         # Root controller
│   ├── app.service.ts            # Root service
│   ├── config/                   # Configuration files
│   │   ├── configuration.ts      # App configuration
│   │   └── validation.schema.ts  # Environment validation
│   ├── common/                   # Shared utilities and decorators
│   ├── migrations/               # Database migration scripts
│   └── modules/                  # Feature modules
│       ├── auth/                 # Authentication module
│       ├── users/                # User management
│       ├── dropoffs/             # Drop management
│       ├── admin/                # Admin dashboard
│       ├── collector-applications/ # Collector applications
│       ├── notifications/        # Real-time notifications
│       └── email/                # Email services
├── scripts/                      # Utility scripts (organized by category)
│   ├── database/                 # Database operations
│   ├── admin/                    # Admin tasks
│   ├── testing/                  # Testing utilities
│   ├── utilities/                # General utilities
│   └── README.md                 # Scripts documentation
├── test/                         # Test files
├── dist/                         # Compiled output
├── node_modules/                 # Dependencies
├── package.json                  # Project configuration
├── tsconfig.json                 # TypeScript configuration
├── nest-cli.json                 # NestJS CLI configuration
├── .gitignore                    # Git ignore rules
├── .prettierrc                   # Prettier configuration
├── eslint.config.mjs             # ESLint configuration
├── README.md                     # Project documentation
└── PROJECT_STRUCTURE.md          # This file
```

## Module Organization

### Core Modules

#### Auth Module (`src/modules/auth/`)
- **Purpose**: Handles user authentication and authorization
- **Components**:
  - `auth.controller.ts` - Authentication endpoints
  - `auth.service.ts` - Authentication logic
  - `auth.module.ts` - Module configuration
  - `dto/` - Data transfer objects
  - `guards/` - Authentication guards
  - `strategies/` - JWT strategies
  - `decorators/` - Custom decorators

#### Users Module (`src/modules/users/`)
- **Purpose**: User management and profile operations
- **Components**:
  - `users.service.ts` - User business logic
  - `users.module.ts` - Module configuration
  - `schemas/` - User data schemas
  - `dto/` - User data transfer objects

#### Dropoffs Module (`src/modules/dropoffs/`)
- **Purpose**: Drop creation, management, and collection
- **Components**:
  - `dropoffs.controller.ts` - Drop endpoints
  - `dropoffs.service.ts` - Drop business logic
  - `dropoffs.module.ts` - Module configuration
  - `schemas/` - Drop and interaction schemas
  - `dto/` - Drop data transfer objects

#### Admin Module (`src/modules/admin/`)
- **Purpose**: Admin dashboard functionality
- **Components**:
  - `admin.controller.ts` - Admin endpoints
  - `admin.service.ts` - Admin business logic
  - `admin.module.ts` - Module configuration
  - `guards/` - Admin guards
  - `decorators/` - Admin decorators

#### Collector Applications Module (`src/modules/collector-applications/`)
- **Purpose**: Collector application management
- **Components**:
  - `collector-applications.controller.ts` - Application endpoints
  - `collector-applications.service.ts` - Application logic
  - `collector-applications.module.ts` - Module configuration
  - `schemas/` - Application schemas

#### Notifications Module (`src/modules/notifications/`)
- **Purpose**: Real-time notifications via WebSockets
- **Components**:
  - `notifications.gateway.ts` - WebSocket gateway
  - `notifications.service.ts` - Notification logic
  - `notifications.module.ts` - Module configuration

#### Email Module (`src/modules/email/`)
- **Purpose**: Email sending functionality
- **Components**:
  - `email.service.ts` - Email logic
  - `email.module.ts` - Module configuration

### Shared Components

#### Common (`src/common/`)
- **Purpose**: Shared utilities, decorators, and interfaces
- **Contents**:
  - Custom decorators
  - Shared interfaces
  - Utility functions
  - Common guards

#### Config (`src/config/`)
- **Purpose**: Application configuration
- **Contents**:
  - `configuration.ts` - App configuration
  - `validation.schema.ts` - Environment validation

#### Migrations (`src/migrations/`)
- **Purpose**: Database migration scripts
- **Contents**:
  - Data migration scripts
  - Schema updates
  - Data cleanup scripts

## Scripts Organization

### Database Scripts (`scripts/database/`)
- User management operations
- Data migration scripts
- Database cleanup and verification
- User role management

### Admin Scripts (`scripts/admin/`)
- Admin user management
- Admin dashboard testing
- Application status management
- Role assignment scripts

### Testing Scripts (`scripts/testing/`)
- API endpoint testing
- Response validation
- Integration testing utilities

### Utility Scripts (`scripts/utilities/`)
- IP address management
- Environment setup
- Travel setup guides
- Server startup scripts

## Key Design Principles

### 1. Modular Architecture
- Each feature is organized into its own module
- Clear separation of concerns
- Independent module development

### 2. Consistent Structure
- Each module follows the same structure:
  - Controller (endpoints)
  - Service (business logic)
  - Module (configuration)
  - Schemas (data models)
  - DTOs (data transfer objects)

### 3. Dependency Injection
- Services are injected where needed
- Loose coupling between components
- Easy testing and maintenance

### 4. Type Safety
- Full TypeScript implementation
- Strong typing throughout the application
- Interface-driven development

### 5. Configuration Management
- Environment-based configuration
- Validation of environment variables
- Centralized configuration management

## Development Guidelines

### Adding New Features
1. Create a new module in `src/modules/`
2. Follow the established module structure
3. Add proper TypeScript interfaces
4. Include comprehensive error handling
5. Add appropriate tests

### Database Operations
1. Use Mongoose schemas for data modeling
2. Implement proper validation
3. Handle database errors gracefully
4. Use transactions where appropriate

### API Design
1. Follow RESTful conventions
2. Use proper HTTP status codes
3. Implement consistent error responses
4. Add proper request validation

### Testing
1. Write unit tests for services
2. Write integration tests for controllers
3. Test error scenarios
4. Maintain good test coverage

## Environment Configuration

### Required Environment Variables
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - JWT signing secret
- `EMAIL_HOST` - SMTP host for emails
- `EMAIL_PORT` - SMTP port
- `EMAIL_USER` - SMTP username
- `EMAIL_PASS` - SMTP password

### Optional Environment Variables
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `CORS_ORIGIN` - CORS allowed origins

## Deployment

### Production Setup
1. Set all required environment variables
2. Build the application: `npm run build`
3. Start the server: `npm run start:prod`
4. Use PM2 or similar for process management

### Development Setup
1. Install dependencies: `npm install`
2. Set up environment variables
3. Start development server: `npm run start:dev`
4. Use `npm run start:debug` for debugging
