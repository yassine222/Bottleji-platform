# Bottleji Platform - Functional and Non-Functional Requirements

## Table of Contents
1. [Functional Requirements](#functional-requirements)
2. [Non-Functional Requirements](#non-functional-requirements)

---

## Functional Requirements

### FR1: User Authentication and Authorization

#### FR1.1: User Registration
- **Description**: The system shall allow new users to register with email, password, and phone number.
- **Input**: Email, password, phone number
- **Output**: User account created, OTP sent for verification
- **Priority**: High

#### FR1.2: Phone Verification
- **Description**: The system shall verify user phone numbers via OTP (One-Time Password) sent via SMS or email.
- **Input**: Phone number, OTP code
- **Output**: Phone verified, account activated
- **Priority**: High

#### FR1.3: User Login
- **Description**: The system shall authenticate users using email/password credentials and issue JWT tokens.
- **Input**: Email, password
- **Output**: JWT authentication token, user profile data
- **Priority**: High

#### FR1.4: Password Reset
- **Description**: The system shall allow users to reset forgotten passwords via email OTP verification.
- **Input**: Email address
- **Output**: OTP sent, password reset link/OTP
- **Priority**: Medium

#### FR1.5: Role-Based Access Control
- **Description**: The system shall support three user roles: Household, Collector, and Admin with distinct permissions.
- **Roles**: 
  - **Household**: Create drops, view history, redeem rewards
  - **Collector**: Accept drops, collect bottles, earn points
  - **Admin/Super Admin**: Manage users, approve applications, manage rewards, generate reports
- **Priority**: High

#### FR1.6: Session Management
- **Description**: The system shall manage user sessions with JWT tokens, including expiration and invalidation capabilities.
- **Priority**: High

---

### FR2: Dual User Mode System

#### FR2.1: Mode Selection
- **Description**: Users shall be able to switch between Household and Collector modes during onboarding or settings.
- **Input**: User preference
- **Output**: Active mode set, UI adapted accordingly
- **Priority**: High

#### FR2.2: Household Mode Features
- **Description**: In Household mode, users shall be able to:
  - Create bottle/can drops with location, description, and photos
  - Edit existing drops (before acceptance)
  - View collection history
  - Track drop status in real-time
  - Redeem reward points for items
- **Priority**: High

#### FR2.3: Collector Mode Features
- **Description**: In Collector mode, users shall be able to:
  - Set collection radius preference
  - View available drops on map
  - Accept drops within radius
  - Navigate to drop locations
  - Confirm collection completion
  - Earn points for successful collections
- **Priority**: High

---

### FR3: Drop Management System

#### FR3.1: Create Drop
- **Description**: Household users shall create drops by providing:
  - Location (GPS coordinates or address)
  - Bottle/can type and quantity
  - Description
  - Optional photos
  - Collection deadline
- **Priority**: High

#### FR3.2: Edit Drop
- **Description**: Household users shall edit drops that are in "pending" status (not yet accepted).
- **Priority**: Medium

#### FR3.3: View Drops
- **Description**: Users shall view:
  - All available drops on interactive map
  - Drop details (location, description, status)
  - Real-time status updates (pending, accepted, collected, expired)
- **Priority**: High

#### FR3.4: Accept Drop (Collector)
- **Description**: Collectors shall accept drops within their collection radius, changing status to "accepted".
- **Priority**: High

#### FR3.5: Confirm Collection
- **Description**: After collection, collectors shall confirm completion, updating drop status to "collected" and awarding points.
- **Priority**: High

#### FR3.6: Drop Expiration
- **Description**: The system shall automatically expire drops that exceed their collection deadline.
- **Priority**: Medium

#### FR3.7: Drop Reporting
- **Description**: Users shall report issues with drops (wrong location, already collected, etc.).
- **Priority**: Low

---

### FR4: Real-time Map Integration

#### FR4.1: Google Maps Integration
- **Description**: The system shall display an interactive map using Google Maps API showing:
  - User's current location
  - Available drops as custom markers
  - Accepted drops with different markers
  - Collection radius (for collectors)
- **Priority**: High

#### FR4.2: Navigation
- **Description**: The system shall provide turn-by-turn navigation to selected drop locations.
- **Priority**: High

#### FR4.3: Real-time Location Updates
- **Description**: The system shall update drop markers and user locations in real-time via WebSocket connections.
- **Priority**: High

#### FR4.4: Map Filtering
- **Description**: Users shall filter drops by status, type, or distance.
- **Priority**: Medium

---

### FR5: Reward Points System

#### FR5.1: Points Earning (Collectors)
- **Description**: Collectors shall earn points based on:
  - Successful drop collections
  - Current tier level (higher tier = more points per drop)
  - Tier progression system (Bronze, Silver, Gold, Platinum, Diamond)
- **Calculation**: Points per drop increase with collector tier
- **Priority**: High

#### FR5.2: Points Tracking
- **Description**: The system shall track:
  - Current available points
  - Total points earned (lifetime)
  - Points spent on redemptions
  - Points earned per collection
- **Priority**: High

#### FR5.3: Tier System
- **Description**: Collectors shall progress through tiers based on total drops collected:
  - **Bronze**: 0-10 drops (10 points/drop)
  - **Silver**: 11-25 drops (15 points/drop)
  - **Gold**: 26-50 drops (20 points/drop)
  - **Platinum**: 51-100 drops (25 points/drop)
  - **Diamond**: 100+ drops (30 points/drop)
- **Priority**: High

#### FR5.4: Tier Upgrade Notifications
- **Description**: The system shall notify users when they upgrade to a new tier via real-time WebSocket notifications.
- **Priority**: Medium

---

### FR6: Reward Shop and Redemption

#### FR6.1: Browse Reward Items
- **Description**: Users shall browse available reward items with:
  - Item name, description, and images
  - Point cost
  - Category and subcategory
  - Size options (for applicable items)
  - Availability status
- **Priority**: High

#### FR6.2: Filter and Search Rewards
- **Description**: Users shall filter rewards by category, subcategory, point range, and availability.
- **Priority**: Medium

#### FR6.3: Redeem Reward
- **Description**: Users shall redeem rewards by:
  - Selecting item and size (if applicable)
  - Providing delivery address
  - Confirming redemption (deducting points)
- **Priority**: High

#### FR6.4: Redemption Management (Admin)
- **Description**: Admins shall:
  - View all redemption requests
  - Approve or reject redemptions
  - Generate shipping labels for approved orders
  - Track delivery status
  - Update redemption status (pending, approved, rejected, delivered)
- **Priority**: High

#### FR6.5: Shipping Label Generation
- **Description**: Upon admin approval, the system shall automatically generate a DHL-style shipping label PDF containing:
  - Sender and recipient addresses
  - Tracking number
  - QR code for tracking
  - Order information
  - Estimated delivery date
- **Priority**: High

---

### FR7: Collector Application System

#### FR7.1: Submit Application
- **Description**: Users shall apply to become collectors by submitting:
  - Personal information
  - Vehicle information (if applicable)
  - Collection preferences
  - Supporting documents/photos
- **Priority**: High

#### FR7.2: Application Review (Admin)
- **Description**: Admins shall:
  - View pending applications
  - Approve or reject applications
  - View application details and history
  - Send notifications to applicants about status
- **Priority**: High

#### FR7.3: Application Status Tracking
- **Description**: Applicants shall track their application status (pending, approved, rejected) in real-time.
- **Priority**: Medium

#### FR7.4: Account Activation/Deactivation
- **Description**: Admins shall activate approved collector accounts and deactivate accounts if needed.
- **Priority**: High

---

### FR8: Real-time Notification System

#### FR8.1: WebSocket Connection
- **Description**: The system shall maintain WebSocket connections for real-time communication between server and clients.
- **Priority**: High

#### FR8.2: Notification Types
- **Description**: The system shall send real-time notifications for:
  - Order approval/rejection (reward redemptions)
  - Account unlock/lock status changes
  - Tier upgrades
  - Points earned
  - Drop status changes
  - Application status updates
- **Priority**: High

#### FR8.3: In-App Notifications
- **Description**: Users shall receive and view notifications within the mobile app with notification history.
- **Priority**: High

#### FR8.4: Notification Storage
- **Description**: The system shall store notification history for retrieval and display in the notifications screen.
- **Priority**: Medium

---

### FR9: Admin Dashboard

#### FR9.1: Dashboard Overview
- **Description**: Admins shall view:
  - Total users, drops, collectors statistics
  - Pending applications count
  - Open support tickets
  - Reward items inventory
  - User growth charts
  - Drop activity analytics
- **Priority**: High

#### FR9.2: User Management
- **Description**: Admins shall:
  - View all users with filtering and search
  - Edit user profiles
  - Lock/unlock user accounts
  - Change user roles
  - View user statistics and history
- **Priority**: High

#### FR9.3: Drop Management
- **Description**: Admins shall:
  - View all drops with filtering options
  - View drop details and history
  - Remove or moderate drops
  - View drop statistics and analytics
- **Priority**: High

#### FR9.4: Application Management
- **Description**: Admins shall:
  - Review collector applications
  - Approve or reject applications
  - View application history
  - Send status notifications
- **Priority**: High

#### FR9.5: Reward Management
- **Description**: Admins shall:
  - Add, edit, and delete reward items
  - Upload reward item images
  - Set point costs and categories
  - Manage inventory and availability
  - View redemption requests and approve/reject
  - Download shipping labels
- **Priority**: High

#### FR9.6: Training Content Management
- **Description**: Admins shall:
  - Upload training videos and materials
  - Organize content by categories
  - Manage content visibility
- **Priority**: Medium

#### FR9.7: Support Ticket Management
- **Description**: Admins shall:
  - View and respond to support tickets
  - Change ticket status (open, in-progress, resolved, closed)
  - View ticket history
- **Priority**: Medium

---

### FR10: Support Ticket System

#### FR10.1: Create Support Ticket
- **Description**: Users shall create support tickets with:
  - Subject and description
  - Category selection
  - Optional attachments
- **Priority**: Medium

#### FR10.2: View Ticket Status
- **Description**: Users shall view their ticket history and current status.
- **Priority**: Medium

#### FR10.3: Admin Response
- **Description**: Admins shall respond to tickets, updating status accordingly.
- **Priority**: Medium

---

### FR11: Profile Management

#### FR11.1: View Profile
- **Description**: Users shall view their profile information including:
  - Personal details
  - Points balance and tier
  - Collection statistics
  - Account settings
- **Priority**: High

#### FR11.2: Edit Profile
- **Description**: Users shall edit:
  - Name, email, phone number
  - Profile photo
  - Collection preferences (collectors)
  - Notification settings
- **Priority**: High

#### FR11.3: Statistics Dashboard
- **Description**: Users shall view:
  - Total drops created/collected
  - Total points earned/spent
  - Current tier and progression
  - Collection history
  - Earnings (for collectors)
- **Priority**: Medium

---

### FR12: Training Content

#### FR12.1: Browse Training Materials
- **Description**: Users shall browse and access training videos and educational content.
- **Priority**: Low

#### FR12.2: Video Playback
- **Description**: The system shall support video playback within the app.
- **Priority**: Low

---

### FR13: History and Analytics

#### FR13.1: Collection History
- **Description**: Users shall view:
  - Past drops created (households)
  - Past drops collected (collectors)
  - Date, location, points earned
- **Priority**: Medium

#### FR13.2: Redemption History
- **Description**: Users shall view their reward redemption history with status tracking.
- **Priority**: Medium

---

## Non-Functional Requirements

### NFR1: Performance Requirements

#### NFR1.1: Response Time
- **API Response Time**: REST API endpoints shall respond within 2 seconds for 95% of requests under normal load.
- **WebSocket Latency**: Real-time notifications shall be delivered within 500ms of event occurrence.
- **Map Rendering**: Map with 100 markers shall load and render within 3 seconds.
- **Image Loading**: Reward item images shall load within 2 seconds on 4G connection.
- **Priority**: High

#### NFR1.2: Throughput
- **API Requests**: The system shall handle at least 1000 concurrent API requests per second.
- **WebSocket Connections**: The system shall support at least 5000 concurrent WebSocket connections.
- **Priority**: Medium

#### NFR1.3: Resource Usage
- **Mobile App**: The mobile app shall consume less than 200MB RAM during normal operation.
- **Backend Server**: Backend server shall handle operations efficiently with optimal database query performance.
- **Priority**: Medium

---

### NFR2: Security Requirements

#### NFR2.1: Authentication Security
- **JWT Tokens**: Authentication tokens shall use secure JWT with expiration (24 hours) and refresh mechanisms.
- **Password Security**: Passwords shall be hashed using bcrypt with salt rounds ≥ 10.
- **OTP Security**: OTP codes shall expire after 10 minutes and be single-use.
- **Priority**: High

#### NFR2.2: Data Encryption
- **Data in Transit**: All API communications shall use HTTPS/TLS 1.2 or higher.
- **Sensitive Data**: Sensitive user data (passwords, tokens) shall be encrypted at rest.
- **Database**: MongoDB connections shall use SSL/TLS encryption.
- **Priority**: High

#### NFR2.3: Authorization
- **Role-Based Access**: The system shall enforce role-based access control (RBAC) for all endpoints.
- **Admin Guards**: Admin-only endpoints shall be protected with authentication and authorization guards.
- **API Security**: API endpoints shall validate JWT tokens on every request.
- **Priority**: High

#### NFR2.4: Input Validation
- **Data Validation**: All user inputs shall be validated and sanitized to prevent SQL injection, XSS, and injection attacks.
- **File Upload Security**: File uploads shall be validated for type, size, and scanned for malicious content.
- **Priority**: High

#### NFR2.5: Session Management
- **Session Invalidation**: The system shall support session invalidation for security (e.g., password change, account lock).
- **Token Refresh**: JWT tokens shall be refreshable without re-authentication.
- **Priority**: Medium

---

### NFR3: Scalability Requirements

#### NFR3.1: Horizontal Scalability
- **Backend**: The backend architecture shall support horizontal scaling across multiple server instances.
- **Database**: MongoDB Atlas shall support scaling for increased data volume and query load.
- **WebSocket**: WebSocket connections shall be distributed across server instances using Redis adapter.
- **Priority**: Medium

#### NFR3.2: Database Scalability
- **Indexing**: Database queries shall use appropriate indexes for optimal performance.
- **Data Growth**: The system shall handle growth to 100,000+ users and 1,000,000+ drops without performance degradation.
- **Priority**: Medium

#### NFR3.3: Mobile App Scalability
- **Offline Support**: The mobile app shall cache critical data for offline access.
- **State Management**: Efficient state management to handle large datasets (1000+ drops) without lag.
- **Priority**: Low

---

### NFR4: Usability Requirements

#### NFR4.1: User Interface
- **Design Consistency**: The mobile app shall follow Material Design 3 guidelines for consistent UI/UX.
- **Navigation**: Navigation shall be intuitive with clear visual hierarchy and feedback.
- **Accessibility**: The app shall support accessibility features (screen readers, appropriate contrast ratios).
- **Priority**: High

#### NFR4.2: Responsiveness
- **Screen Sizes**: The mobile app shall support various screen sizes (phones, tablets) with responsive layouts.
- **Admin Dashboard**: The admin dashboard shall be responsive and usable on desktop (1920x1080) and tablet (1024x768).
- **Priority**: High

#### NFR4.3: Error Handling
- **Error Messages**: User-facing error messages shall be clear, actionable, and non-technical.
- **Loading States**: The system shall provide loading indicators for operations exceeding 1 second.
- **Feedback**: Users shall receive immediate visual feedback for all actions (button presses, form submissions).
- **Priority**: High

#### NFR4.4: Onboarding
- **First-Time Experience**: New users shall receive guided onboarding explaining key features.
- **Help Documentation**: In-app help and FAQ sections shall be accessible.
- **Priority**: Medium

---

### NFR5: Reliability Requirements

#### NFR5.1: System Availability
- **Uptime**: The system shall maintain 99% uptime (approximately 7.2 hours downtime per month).
- **Backup Systems**: Critical services (authentication, database) shall have backup/redundancy.
- **Priority**: High

#### NFR5.2: Fault Tolerance
- **Error Recovery**: The system shall gracefully handle errors without crashing the application.
- **Database Failover**: MongoDB Atlas shall provide automatic failover for database connections.
- **API Resilience**: Failed API requests shall retry with exponential backoff (max 3 retries).
- **Priority**: High

#### NFR5.3: Data Integrity
- **Transaction Management**: Critical operations (point redemption, drop acceptance) shall use database transactions to ensure data consistency.
- **Data Validation**: Database schemas shall enforce data integrity constraints.
- **Priority**: High

#### NFR5.4: Logging and Monitoring
- **Error Logging**: The system shall log errors with sufficient detail for debugging.
- **Performance Monitoring**: Key metrics (response times, error rates) shall be monitored.
- **Priority**: Medium

---

### NFR6: Maintainability Requirements

#### NFR6.1: Code Quality
- **Code Organization**: Code shall follow clean architecture principles with separation of concerns.
- **Documentation**: Critical functions and modules shall have inline documentation.
- **Code Standards**: Code shall follow language-specific style guides (Dart for Flutter, TypeScript for NestJS/Next.js).
- **Priority**: Medium

#### NFR6.2: Modularity
- **Backend**: NestJS modules shall be organized by feature for easy maintenance.
- **Frontend**: Flutter features shall follow feature-based architecture (auth, drops, rewards, etc.).
- **Reusability**: Common components and utilities shall be reusable across modules.
- **Priority**: Medium

#### NFR6.3: Version Control
- **Git Workflow**: Code shall be version-controlled using Git with clear commit messages.
- **Branch Strategy**: Feature branches shall be used for development, with main/master for production.
- **Priority**: Medium

---

### NFR7: Portability Requirements

#### NFR7.1: Cross-Platform Support
- **Mobile Platforms**: The Flutter app shall run on both Android (API 21+) and iOS (iOS 12+).
- **Web Admin**: The admin dashboard shall run on modern browsers (Chrome, Firefox, Safari, Edge).
- **Priority**: High

#### NFR7.2: Dependency Management
- **Package Management**: Dependencies shall be clearly defined (pubspec.yaml for Flutter, package.json for Node.js).
- **Version Pinning**: Critical dependencies shall have pinned versions for stability.
- **Priority**: Medium

---

### NFR8: Interoperability Requirements

#### NFR8.1: API Standards
- **RESTful API**: The backend shall follow RESTful API design principles with consistent endpoint naming.
- **JSON Format**: All API responses shall use JSON format with consistent structure.
- **API Documentation**: API endpoints shall be documented (preferably with Swagger/OpenAPI).
- **Priority**: Medium

#### NFR8.2: Third-Party Integrations
- **Google Maps**: Integration with Google Maps API for location services.
- **Firebase**: Integration with Firebase for storage and authentication features.
- **MongoDB Atlas**: Cloud database service for data persistence.
- **Email Service**: Integration with email service provider for OTP and notifications.
- **Priority**: High

---

### NFR9: Availability Requirements

#### NFR9.1: Service Availability
- **24/7 Operation**: The system shall be available 24/7 for user access (excluding planned maintenance).
- **Maintenance Windows**: Maintenance shall be scheduled during low-traffic periods with user notification.
- **Priority**: High

#### NFR9.2: Redundancy
- **Database Backup**: Daily automated backups of database with point-in-time recovery capability.
- **File Storage**: Firebase Storage provides redundancy and high availability.
- **Priority**: Medium

---

### NFR10: Compliance and Legal Requirements

#### NFR10.1: Data Privacy
- **User Data**: The system shall comply with data privacy regulations (GDPR, CCPA) regarding user data collection and storage.
- **Data Retention**: User data retention policies shall be clearly defined.
- **Priority**: Medium

#### NFR10.2: Security Standards
- **Industry Standards**: The system shall follow OWASP security best practices.
- **Vulnerability Management**: Regular security audits and dependency updates.
- **Priority**: Medium

---

## Summary

### Functional Requirements Summary
- **Total Functional Requirements**: 13 main categories with 50+ specific requirements
- **High Priority**: 35 requirements
- **Medium Priority**: 12 requirements
- **Low Priority**: 3 requirements

### Non-Functional Requirements Summary
- **Total Non-Functional Requirements**: 10 main categories with 30+ specific requirements
- **High Priority**: 18 requirements
- **Medium Priority**: 12 requirements
- **Low Priority**: 0 requirements

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Project**: Bottleji Platform - PFE (Projet de Fin d'Études)

