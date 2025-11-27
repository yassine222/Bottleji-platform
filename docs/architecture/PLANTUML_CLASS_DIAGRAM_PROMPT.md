# PlantUML Class Diagram Generation Prompt

## Instructions for Generating PlantUML Class Diagram

Generate a comprehensive, high-level PlantUML class diagram for the **Bottleji Platform** - a full-stack bottle recycling collection system. The diagram should show the architectural structure, main entities, and relationships across all three components of the system.

---

## System Overview

The Bottleji Platform consists of three main components:

1. **Flutter Mobile Application** (botleji/) - Cross-platform mobile app for Android and iOS
2. **NestJS Backend API** (backend/) - RESTful API server with WebSocket support
3. **Next.js Admin Dashboard** (admin-dashboard/) - Web-based administrative interface

---

## Component 1: Flutter Mobile Application

### Package Structure
Organize classes into packages based on feature modules:

```
@startuml
package "Flutter Mobile App" {
  package "Authentication" {
    class UserData
    class AuthRequest
    class AuthResponse
    class AuthController
    class AuthRepository
    class AuthProvider
  }
  
  package "Drops Management" {
    class Drop
    class DropStatus
    class BottleType
    class DropsController
    class DropsRepository
  }
  
  package "Rewards" {
    class RewardItem
    class RewardRedemption
    class RewardProvider
    class RewardService
  }
  
  package "Notifications" {
    class Notification
    class NotificationService
    class NotificationProvider
  }
  
  package "Support" {
    class SupportTicket
    class TicketStatus
    class TicketCategory
    class SupportService
  }
  
  package "Collector" {
    class CollectorApplication
    class CollectorApplicationStatus
    class CollectorApplicationController
  }
  
  package "Core Services" {
    class NotificationService
    class PhoneVerificationService
    class NetworkInitializationService
    class ServerConfig
  }
}
@enduml
```

### Key Classes to Include:

**Authentication Module:**
- `UserData` - User profile information (id, email, name, roles, points, tier, etc.)
- `AuthRequest` - Login/registration request data
- `AuthResponse` - Authentication response with tokens
- `AuthController` - Authentication logic controller
- `AuthRepository` - Data repository for authentication
- `AuthProvider` - State management provider

**Drops Module:**
- `Drop` - Drop entity (id, location, status, bottleType, etc.)
- `DropStatus` (enum: pending, accepted, collected, cancelled, expired, stale)
- `BottleType` (enum: plastic, can, mixed)
- `DropsController` - Drop management controller
- `DropsRepository` - Drop data repository

**Rewards Module:**
- `RewardItem` - Reward item model
- `RewardRedemption` - Redemption request model
- `RewardProvider` - Reward state management
- `RewardService` - Reward API service

**Notifications Module:**
- `Notification` - Notification model (type, title, message, data, timestamp)
- `NotificationService` - WebSocket and notification handling service
- `NotificationProvider` - Notification state management

**Support Module:**
- `SupportTicket` - Ticket model
- `TicketStatus` (enum: open, in_progress, resolved, closed)
- `TicketCategory` (enum: authentication, app_technical, drop_creation, etc.)
- `SupportService` - Support ticket API service

**Collector Module:**
- `CollectorApplication` - Application model
- `CollectorApplicationStatus` (enum: pending, approved, rejected)
- `CollectorApplicationController` - Application management

**Core Services:**
- `NotificationService` - Real-time notification service (WebSocket)
- `PhoneVerificationService` - OTP verification service
- `NetworkInitializationService` - Server IP detection service
- `ServerConfig` - API configuration

---

## Component 2: NestJS Backend API

### Module Structure
Organize classes into NestJS modules:

```
@startuml
package "NestJS Backend API" {
  package "Auth Module" {
    class AuthService
    class AuthController
    class JwtStrategy
    class JwtAuthGuard
    class RolesGuard
  }
  
  package "Users Module" {
    class UsersService
    class User {Schema}
    class UserRole {enum}
  }
  
  package "Drops Module" {
    class DropoffsService
    class DropoffsController
    class Dropoff {Schema}
    class DropoffStatus {enum}
    class CollectorInteraction {Schema}
    class CollectionAttempt {Schema}
  }
  
  package "Rewards Module" {
    class RewardsService
    class RewardsController
    class RewardItem {Schema}
    class RewardRedemption {Schema}
  }
  
  package "Notifications Module" {
    class NotificationsService
    class NotificationsController
    class NotificationsGateway
    class Notification {Schema}
  }
  
  package "Admin Module" {
    class AdminService
    class AdminController
    class DropsManagementService
    class AdminGuard
  }
  
  package "Support Module" {
    class SupportTicketsService
    class SupportTicketsController
    class SupportTicket {Schema}
    class TicketStatus {enum}
  }
  
  package "Collector Applications" {
    class CollectorApplicationsService
    class CollectorApplicationsController
    class CollectorApplication {Schema}
  }
  
  package "Shipping Module" {
    class ShippingLabelService
    class ShippingController
  }
  
  package "Training Module" {
    class TrainingService
    class TrainingController
    class TrainingContent {Schema}
  }
  
  package "Email Module" {
    class EmailService
  }
}
@enduml
```

### Key Classes to Include:

**Auth Module:**
- `AuthService` - Authentication business logic (login, register, OTP, password reset)
- `AuthController` - Authentication endpoints
- `JwtStrategy` - JWT authentication strategy
- `JwtAuthGuard` - JWT guard
- `RolesGuard` - Role-based access guard

**Users Module:**
- `UsersService` - User management service
- `User` (Schema) - User schema with fields: email, password, name, roles, points, tier, etc.
- `UserRole` (enum: household, collector, admin, super_admin, moderator, support_agent)
- `CollectorApplication` (embedded schema)

**Drops Module:**
- `DropoffsService` - Drop management service (create, accept, collect, confirm)
- `DropoffsController` - Drop endpoints
- `Dropoff` (Schema) - Drop schema (userId, location, status, bottleType, etc.)
- `DropoffStatus` (enum: pending, accepted, collected, cancelled, expired)
- `CollectorInteraction` (Schema) - Collector interaction tracking
- `CollectionAttempt` (Schema) - Collection attempt history

**Rewards Module:**
- `RewardsService` - Reward management (create items, process redemptions, award points)
- `RewardsController` - Reward endpoints
- `RewardItem` (Schema) - Reward item schema (name, description, pointCost, imageUrl, etc.)
- `RewardRedemption` (Schema) - Redemption schema (userId, rewardItemId, status, deliveryAddress, etc.)

**Notifications Module:**
- `NotificationsService` - Notification management service
- `NotificationsController` - Notification endpoints
- `NotificationsGateway` - WebSocket gateway for real-time notifications
- `Notification` (Schema) - Notification schema (userId, type, title, message, isRead, etc.)

**Admin Module:**
- `AdminService` - Admin dashboard service (stats, user management, analytics)
- `AdminController` - Admin endpoints
- `DropsManagementService` - Drop moderation service
- `AdminGuard` - Admin access guard

**Support Module:**
- `SupportTicketsService` - Support ticket management
- `SupportTicketsController` - Support endpoints
- `SupportTicket` (Schema) - Ticket schema (userId, title, description, status, messages, etc.)
- `TicketStatus` (enum: open, in_progress, resolved, closed)

**Collector Applications Module:**
- `CollectorApplicationsService` - Application processing service
- `CollectorApplicationsController` - Application endpoints
- `CollectorApplication` (Schema) - Application schema

**Shipping Module:**
- `ShippingLabelService` - PDF shipping label generation service
- `ShippingController` - Shipping endpoints

**Training Module:**
- `TrainingService` - Training content management
- `TrainingController` - Training endpoints
- `TrainingContent` (Schema) - Training content schema

**Email Module:**
- `EmailService` - Email sending service (OTP, notifications)

---

## Component 3: Next.js Admin Dashboard

### Component Structure
Organize React components:

```
@startuml
package "Next.js Admin Dashboard" {
  package "Layout Components" {
    class AdminLayout
    class Header
    class Sidebar
    class AuthGuard
  }
  
  package "Dashboard" {
    class DashboardPage
    class DashboardCharts
  }
  
  package "Users Management" {
    class UsersPage
  }
  
  package "Drops Management" {
    class DropsPage
  }
  
  package "Rewards Management" {
    class RewardsPage
    class RewardImageUpload
  }
  
  package "Support" {
    class SupportTicketsPage
  }
  
  package "Services" {
    class ApiService
    class ApiEndpoints
  }
}
@enduml
```

### Key Classes to Include:

**Layout Components:**
- `AdminLayout` - Main layout wrapper
- `Header` - Dashboard header
- `Sidebar` - Navigation sidebar
- `AuthGuard` - Authentication guard component

**Dashboard:**
- `DashboardPage` - Main dashboard page component
- `DashboardCharts` - Analytics charts component

**Management Pages:**
- `UsersPage` - User management page
- `DropsPage` - Drop management page
- `RewardsPage` - Reward management page
- `RewardImageUpload` - Reward image upload component
- `SupportTicketsPage` - Support ticket management page

**Services:**
- `ApiService` - API client service
- `ApiEndpoints` - API endpoint configuration

---

## Relationships to Show

### 1. Dependency Relationships

**Flutter App → Backend API:**
- All Flutter services depend on Backend API endpoints
- `AuthRepository` → `AuthController` (backend)
- `DropsRepository` → `DropoffsController` (backend)
- `RewardService` → `RewardsController` (backend)
- `NotificationService` → `NotificationsGateway` (WebSocket)
- `SupportService` → `SupportTicketsController` (backend)

**Admin Dashboard → Backend API:**
- `ApiService` → All backend controllers
- `DashboardPage` → `AdminController`
- `UsersPage` → `AdminController`
- `RewardsPage` → `RewardsController`

### 2. Composition Relationships

**Backend Services → Schemas:**
- `UsersService` uses `User` schema
- `DropoffsService` uses `Dropoff`, `CollectorInteraction` schemas
- `RewardsService` uses `RewardItem`, `RewardRedemption` schemas
- `NotificationsService` uses `Notification` schema
- `SupportTicketsService` uses `SupportTicket` schema

**Backend Services → Other Services:**
- `AuthService` depends on `UsersService`, `EmailService`
- `DropoffsService` depends on `RewardsService`, `NotificationsGateway`
- `RewardsService` depends on `NotificationsGateway`
- `AdminService` depends on multiple services

**Backend Controllers → Services:**
- All controllers depend on their corresponding services
- `AuthController` → `AuthService`
- `DropoffsController` → `DropoffsService`
- `RewardsController` → `RewardsService`

### 3. Inheritance Relationships

**Guards:**
- `JwtAuthGuard` implements `CanActivate`
- `RolesGuard` implements `CanActivate`
- `AdminGuard` implements `CanActivate`

**Schemas:**
- All schemas extend `Document` (Mongoose)

### 4. Enum Relationships

Show enums as separate classes with relationships:
- `UserRole` enum used by `User` schema
- `DropoffStatus` enum used by `Dropoff` schema
- `TicketStatus` enum used by `SupportTicket` schema
- `BottleType` enum used by `Dropoff` schema

---

## Additional Requirements

### 1. Show Module Boundaries
Use packages to group related classes:
- Separate packages for each NestJS module
- Separate packages for each Flutter feature
- Separate package for Admin Dashboard

### 2. Include Key Attributes
For schemas/models, show only the most important attributes:
- `User`: id, email, roles, currentPoints, currentTier
- `Dropoff`: id, userId, location, status, bottleType
- `RewardItem`: id, name, pointCost, imageUrl
- `RewardRedemption`: id, userId, rewardItemId, status

### 3. Show Service Methods (Optional)
You may include key service methods as operations:
- `AuthService`: login(), register(), verifyOTP()
- `DropoffsService`: createDrop(), acceptDrop(), confirmCollection()
- `RewardsService`: awardPoints(), createRedemption(), approveRedemption()

### 4. Color Coding (Optional)
Use different colors for:
- Flutter classes (light blue)
- Backend schemas (light green)
- Backend services (light yellow)
- Backend controllers (light orange)
- Admin dashboard components (light pink)
- Enums (light gray)

---

## PlantUML Syntax Guidelines

1. Use `@startuml` and `@enduml` tags
2. Use `package` for grouping
3. Use `class` for classes
4. Use `enum` for enumerations
5. Use arrows for relationships:
   - `-->` for dependencies
   - `--|>` for inheritance
   - `*--` for composition
   - `o--` for aggregation
6. Use `note` for important notes if needed
7. Use `skinparam` for styling if desired

---

## Example Relationship Syntax

```plantuml
' Flutter App dependencies
AuthRepository --> AuthController : HTTP
NotificationService --> NotificationsGateway : WebSocket

' Backend Service dependencies
AuthService --> UsersService
AuthService --> EmailService
DropoffsService --> RewardsService
DropoffsService --> NotificationsGateway
RewardsService --> NotificationsGateway

' Service to Schema relationships
UsersService --> User : uses
DropoffsService --> Dropoff : uses
RewardsService --> RewardItem : uses
RewardsService --> RewardRedemption : uses

' Controller to Service relationships
AuthController --> AuthService
DropoffsController --> DropoffsService
RewardsController --> RewardsService

' Schema inheritance
User --|> Document
Dropoff --|> Document
RewardItem --|> Document
```

---

## Output Requirements

1. Generate a complete PlantUML class diagram
2. Include all three components (Flutter, Backend, Admin Dashboard)
3. Show clear module/package boundaries
4. Display key relationships (dependencies, composition, inheritance)
5. Include enums as separate classes
6. Show only essential attributes and methods
7. Ensure the diagram is readable and well-organized
8. Use appropriate naming conventions (PascalCase for classes, camelCase for methods)
9. Include legend or notes if needed for clarity

---

## Final Notes

- This is a **high-level architectural diagram**, not a detailed implementation diagram
- Focus on **main entities, services, and their relationships**
- Show the **overall system structure** and how components interact
- Keep it **readable and maintainable** - avoid overcrowding
- Use **logical grouping** by feature/module rather than physical file structure

---

**Generate the complete PlantUML class diagram code following these specifications.**

