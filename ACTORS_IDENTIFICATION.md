# Bottleji Platform - Actors' Identification

## Table of Contents
1. [Primary Actors](#primary-actors)
2. [Secondary Actors](#secondary-actors)
3. [External Systems](#external-systems)
4. [System Components](#system-components)
5. [Actor Relationships](#actor-relationships)

---

## Primary Actors

Primary actors are users who directly interact with the Bottleji platform to accomplish their goals. They initiate interactions and derive value from using the system.

---

### ACT1: Household User

**Actor Name**: Household User  
**Type**: Primary Actor (End User)  
**Description**: Regular users who create bottle/can drops for collection by collectors. They represent households or individuals who want to dispose of recyclable materials efficiently.

**Characteristics**:
- Uses the mobile application (Flutter app)
- Creates drops by providing location, bottle/can details, and photos
- Has no administrative privileges
- Can switch to Collector mode if approved
- Earns reward points (can also be implemented for household users)

**Main Responsibilities**:
1. Register and authenticate into the system
2. Create drops with location, description, and photos
3. Edit pending drops before acceptance
4. View collection history and drop status
5. Browse and redeem rewards from the reward shop
6. Track points balance and redemption history
7. Manage profile information
8. Create support tickets for assistance
9. Access training materials and tips

**Key Interactions**:
- **With System**: Creates drops, views map, manages profile
- **With Collectors**: Receives collection notifications when drops are accepted/collected
- **With Admin**: May receive account status notifications, support responses

**Use Cases**:
- Register and login
- Create drop
- Edit drop
- View drops on map
- Redeem reward
- View collection history
- Manage profile
- Submit support ticket

**Technology Access**:
- Mobile Application: Flutter (Android/iOS)

---

### ACT2: Collector

**Actor Name**: Collector  
**Type**: Primary Actor (End User)  
**Description**: Approved users who collect bottles and cans from household drops. They earn reward points for successful collections and can progress through tier levels.

**Characteristics**:
- Uses the mobile application (Flutter app)
- Must apply and be approved by administrators
- Sets collection radius preference
- Earns points based on successful collections
- Progresses through tier system (Bronze, Silver, Gold, Platinum, Diamond)
- Has no administrative privileges

**Main Responsibilities**:
1. Submit collector application with required information
2. Set collection radius preference
3. Browse available drops on interactive map
4. Accept drops within collection radius
5. Navigate to drop locations
6. Confirm collection completion
7. Earn points for successful collections
8. Track points balance, tier level, and earnings
9. View collection statistics and history
10. Redeem reward points for items
11. Manage profile and collection preferences

**Key Interactions**:
- **With System**: Accepts drops, confirms collections, earns points
- **With Households**: Collects bottles/cans from their drops
- **With Admin**: Receives application status updates, account notifications

**Use Cases**:
- Submit collector application
- View available drops
- Accept drop
- Navigate to drop location
- Confirm collection
- View collection statistics
- Redeem reward points
- Track tier progression

**Technology Access**:
- Mobile Application: Flutter (Android/iOS)

**Special Attributes**:
- **Tier System**: Bronze (0-10 drops), Silver (11-25), Gold (26-50), Platinum (51-100), Diamond (100+)
- **Points Per Drop**: Varies by tier (10-30 points per collection)
- **Collection Radius**: Configurable distance preference for available drops

---

### ACT3: Support Agent

**Actor Name**: Support Agent  
**Type**: Primary Actor (Administrative User)  
**Description**: Administrative personnel responsible for handling customer support tickets and responding to user inquiries through the admin dashboard.

**Characteristics**:
- Uses the web-based admin dashboard (Next.js)
- Has limited administrative access
- Focuses on customer support operations
- Cannot manage content or approve applications
- Can view limited user information relevant to tickets

**Main Responsibilities**:
1. View support tickets assigned or available
2. Respond to user support tickets
3. Update ticket status (open, in-progress, resolved, closed)
4. View limited user information relevant to tickets
5. Track ticket history and resolution
6. Access ticket analytics

**Key Interactions**:
- **With System**: Accesses support ticket management interface
- **With Users**: Responds to support inquiries and resolves issues
- **With Admin**: Reports ticket trends and escalates complex issues

**Use Cases**:
- View support tickets
- Respond to ticket
- Update ticket status
- Close ticket
- View ticket history

**Technology Access**:
- Admin Dashboard: Next.js Web Application

**Permissions**:
- View users (limited info relevant to tickets)
- View support tickets
- Respond to tickets
- Close tickets
- **Cannot**: Manage drops, approve applications, delete users, view full analytics

---

### ACT4: Moderator

**Actor Name**: Moderator  
**Type**: Primary Actor (Administrative User)  
**Description**: Administrative personnel responsible for content moderation, reviewing user-generated content, and managing collector applications.

**Characteristics**:
- Uses the web-based admin dashboard (Next.js)
- Focuses on content quality and user-generated content
- Cannot access sensitive user data (email, payments)
- Cannot manage other administrative roles

**Main Responsibilities**:
1. View all user-generated drops
2. Review and moderate drops (delete inappropriate content)
3. View collector applications
4. Approve or reject collector applications
5. View limited user information
6. Monitor content quality and user behavior
7. Handle content-related reports

**Key Interactions**:
- **With System**: Accesses content moderation interface
- **With Users**: Reviews and moderates user-generated content
- **With Collectors**: Approves/rejects collector applications

**Use Cases**:
- View drops
- Delete inappropriate drop
- Moderate content
- View collector applications
- Approve collector application
- Reject collector application

**Technology Access**:
- Admin Dashboard: Next.js Web Application

**Permissions**:
- View users (limited info)
- View drops
- Delete drops
- Moderate content
- View applications
- Approve/reject applications
- **Cannot**: Manage admin roles, access sensitive user data, view billing

---

### ACT5: Admin

**Actor Name**: Admin  
**Type**: Primary Actor (Administrative User)  
**Description**: Administrative personnel with comprehensive access to manage users, content, applications, and system operations through the admin dashboard.

**Characteristics**:
- Uses the web-based admin dashboard (Next.js)
- Handles day-to-day administrative tasks
- Can manage moderators and support agents
- Cannot manage other admins or super admins
- Has access to analytics and reporting

**Main Responsibilities**:
1. View and manage all user accounts
2. Lock/unlock user accounts
3. Edit user profiles and roles
4. Delete user accounts
5. View and manage all drops
6. Delete or moderate drops
7. View and process collector applications
8. Approve or reject collector applications
9. Manage reward items (add, edit, delete)
10. Process reward redemptions (approve/reject)
11. Generate shipping labels for approved redemptions
12. View system analytics and statistics
13. Manage training content
14. Access support ticket management
15. View dashboard overview with key metrics

**Key Interactions**:
- **With System**: Accesses comprehensive admin dashboard
- **With Users**: Manages accounts, locks/unlocks users, processes applications
- **With Collectors**: Approves applications, manages collector accounts
- **With Households**: Manages accounts, moderates content
- **With Reward System**: Manages items, processes redemptions, generates labels

**Use Cases**:
- View dashboard
- Manage users
- Lock/unlock user account
- View collector applications
- Approve collector application
- Reject collector application
- Manage drops
- Moderate content
- Manage reward items
- Approve reward redemption
- Reject reward redemption
- Generate shipping label
- View analytics
- Manage training content
- Respond to support tickets

**Technology Access**:
- Admin Dashboard: Next.js Web Application

**Permissions**:
- View and manage users
- Delete and ban users
- View and manage applications
- View and delete drops
- Moderate content
- View analytics
- Manage moderators and support agents
- **Cannot**: Manage admins, access billing, manage integrations, view system logs

---

### ACT6: Super Admin

**Actor Name**: Super Admin  
**Type**: Primary Actor (System Administrator)  
**Description**: Highest-level administrator with complete system control, including management of other administrators and access to all system features and sensitive settings.

**Characteristics**:
- Uses the web-based admin dashboard (Next.js)
- Has full control over the entire system
- Can manage all other administrative roles
- Has access to sensitive settings (billing, integrations, security, logs)
- Typically the system owner or highest authority

**Main Responsibilities**:
1. **All Admin responsibilities** (everything ACT5 can do)
2. Manage other administrators (create, edit, delete admin accounts)
3. Assign and manage roles (Admin, Moderator, Support Agent)
4. Access system logs and monitoring
5. Manage system integrations
6. Configure security settings
7. Access billing and payment information
8. Manage system-wide configurations
9. View comprehensive analytics and reports
10. Perform system maintenance tasks

**Key Interactions**:
- **With System**: Full access to all system features and configurations
- **With Admins**: Creates, manages, and assigns roles to administrative users
- **With All Users**: Can manage any user account
- **With External Systems**: Configures integrations and API keys

**Use Cases**:
- All use cases from Admin (ACT5)
- Manage administrators
- Assign roles
- View system logs
- Manage integrations
- Configure security settings
- Access billing information
- System maintenance

**Technology Access**:
- Admin Dashboard: Next.js Web Application

**Permissions**:
- **All permissions** in the system
- Manage other admins and assign roles
- Access sensitive settings (billing, integrations, security)
- View system logs
- Manage all users, content, and applications

---

## Secondary Actors

Secondary actors are systems or entities that provide services to the Bottleji platform but do not directly use it to achieve their goals. They support the system's operations.

---

### ACT7: Email Service

**Actor Name**: Email Service  
**Type**: Secondary Actor (External Service)  
**Description**: Third-party email service provider used for sending OTP verification codes, password reset emails, and system notifications.

**Main Responsibilities**:
1. Send OTP codes for phone/email verification
2. Send password reset links/OTPs
3. Send account status notifications
4. Send order/reward redemption notifications
5. Send application status updates

**Interactions**:
- Receives email requests from Backend API
- Sends emails to users
- Returns delivery status

**Technology**: Third-party email service (SMTP, SendGrid, AWS SES, etc.)

---

### ACT8: SMS Service

**Actor Name**: SMS Service  
**Type**: Secondary Actor (External Service)  
**Description**: Third-party SMS service provider used for sending OTP codes via SMS for phone number verification.

**Main Responsibilities**:
1. Send OTP codes via SMS for phone verification
2. Send notification SMS (if configured)

**Interactions**:
- Receives SMS requests from Backend API
- Sends SMS to user phone numbers
- Returns delivery status

**Technology**: Third-party SMS service (Twilio, AWS SNS, etc.)

---

### ACT9: Automated System Processes

**Actor Name**: Automated System Processes  
**Type**: Secondary Actor (System Component)  
**Description**: Background processes and automated tasks that run without direct user intervention.

**Main Responsibilities**:
1. **Drop Expiration**: Automatically expire drops that exceed their collection deadline
2. **Tier Calculation**: Automatically calculate and update collector tiers based on total collections
3. **Points Awarding**: Automatically award points to collectors upon collection confirmation
4. **Session Management**: Automatically invalidate expired JWT tokens
5. **Notification Delivery**: Automatically deliver real-time notifications via WebSocket
6. **Database Cleanup**: Scheduled tasks for data cleanup and maintenance
7. **Analytics Aggregation**: Background processes for generating statistics and reports

**Interactions**:
- Operates autonomously based on system events
- Triggers notifications to users
- Updates database records
- Performs scheduled maintenance tasks

---

## External Systems

External systems are third-party services and platforms that the Bottleji platform integrates with to provide enhanced functionality.

---

### ACT10: Google Maps API

**Actor Name**: Google Maps API  
**Type**: External System  
**Description**: Google's mapping service providing location services, interactive maps, geocoding, and navigation capabilities.

**Main Responsibilities**:
1. Provide interactive map visualization
2. Display user location
3. Display drop markers with custom icons
4. Provide geocoding (address to coordinates conversion)
5. Provide reverse geocoding (coordinates to address)
6. Provide turn-by-turn navigation
7. Calculate distances and routes
8. Display collection radius areas

**Interactions**:
- Receives location data from Mobile App
- Returns map tiles and markers
- Provides navigation routes
- Returns geocoded addresses

**Technology**: Google Maps Platform API

---

### ACT11: Firebase

**Actor Name**: Firebase  
**Type**: External System  
**Description**: Google's Firebase platform providing cloud storage, authentication services, and real-time database capabilities.

**Main Components**:
- **Firebase Storage**: Stores user-uploaded images (drop photos, profile pictures, reward item images)
- **Firebase Authentication**: (Optional) Can be used for additional authentication methods

**Main Responsibilities**:
1. Store and serve image files (drops, profiles, rewards)
2. Provide secure file upload/download URLs
3. Manage file access permissions
4. Handle image processing and optimization

**Interactions**:
- Receives file upload requests from Backend API
- Stores files securely
- Returns download URLs
- Manages file lifecycle

**Technology**: Google Firebase Platform

---

### ACT12: MongoDB Atlas

**Actor Name**: MongoDB Atlas  
**Type**: External System  
**Description**: Cloud-hosted MongoDB database service providing data persistence, backup, and scaling capabilities.

**Main Responsibilities**:
1. Store all application data (users, drops, rewards, notifications, etc.)
2. Provide database queries and transactions
3. Maintain data integrity with schema validation
4. Provide database backup and recovery
5. Scale database resources automatically
6. Provide database monitoring and performance insights

**Data Stored**:
- User accounts and profiles
- Drop information and status
- Reward items and redemptions
- Collector applications
- Support tickets
- Notifications
- Training content
- System logs and analytics

**Interactions**:
- Receives database queries from Backend API
- Stores and retrieves data
- Provides transaction support
- Returns query results

**Technology**: MongoDB Atlas Cloud Database

---

## System Components

System components are internal parts of the Bottleji platform architecture that interact with each other and with actors.

---

### ACT13: Mobile Application (Flutter)

**Actor Name**: Mobile Application  
**Type**: System Component  
**Description**: Cross-platform mobile application built with Flutter, serving as the primary interface for Household and Collector users.

**Main Responsibilities**:
1. Provide user interface for mobile users
2. Handle user authentication and session management
3. Display interactive maps with Google Maps integration
4. Manage real-time WebSocket connections for notifications
5. Handle offline data caching
6. Provide navigation and user flows
7. Handle image capture and upload
8. Display notifications and alerts
9. Manage state and data persistence

**Interactions**:
- **With Users**: Provides UI/UX for Household and Collector actors
- **With Backend API**: Sends HTTP requests and receives responses
- **With WebSocket Gateway**: Maintains real-time connections
- **With Google Maps**: Integrates map visualization
- **With Firebase**: Uploads images to storage

**Technology**: Flutter Framework (Dart)

---

### ACT14: Backend API (NestJS)

**Actor Name**: Backend API  
**Type**: System Component  
**Description**: Server-side RESTful API built with NestJS, handling business logic, data processing, and integrations.

**Main Responsibilities**:
1. Process authentication and authorization
2. Handle user registration and profile management
3. Process drop creation, updates, and status changes
4. Manage collector applications and approvals
5. Process reward redemptions and point transactions
6. Generate shipping labels (PDF)
7. Handle file uploads and management
8. Process support tickets
9. Integrate with external services (email, SMS, Firebase, Maps)
10. Provide data to admin dashboard
11. Maintain WebSocket gateway for real-time notifications

**Interactions**:
- **With Mobile App**: Receives API requests, returns responses
- **With Admin Dashboard**: Provides admin API endpoints
- **With MongoDB**: Stores and retrieves data
- **With Email/SMS Services**: Sends notifications
- **With Firebase**: Manages file storage
- **With WebSocket Gateway**: Emits real-time events

**Technology**: NestJS Framework (Node.js, TypeScript)

---

### ACT15: Admin Dashboard (Next.js)

**Actor Name**: Admin Dashboard  
**Type**: System Component  
**Description**: Web-based administrative interface built with Next.js, providing comprehensive management capabilities for administrative users.

**Main Responsibilities**:
1. Provide web interface for Admin, Super Admin, Moderator, and Support Agent actors
2. Display dashboard with analytics and statistics
3. Manage user accounts and roles
4. Manage drops and content moderation
5. Process collector applications
6. Manage reward items and redemptions
7. Handle support tickets
8. Manage training content
9. Generate reports and analytics
10. Download shipping labels

**Interactions**:
- **With Administrative Users**: Provides UI for admins, moderators, support agents
- **With Backend API**: Sends admin API requests
- **With WebSocket**: Receives real-time updates (if implemented)

**Technology**: Next.js Framework (React, TypeScript)

---

### ACT16: WebSocket Gateway

**Actor Name**: WebSocket Gateway  
**Type**: System Component  
**Description**: Real-time communication server using Socket.IO, providing bidirectional communication for instant notifications.

**Main Responsibilities**:
1. Maintain WebSocket connections with clients
2. Authenticate WebSocket connections using JWT
3. Broadcast real-time notifications to specific users
4. Handle connection/disconnection events
5. Emit events for order updates, account status changes, tier upgrades
6. Manage connected users registry

**Interactions**:
- **With Mobile App**: Maintains WebSocket connections
- **With Backend Services**: Receives events to broadcast
- **With Users**: Delivers real-time notifications

**Technology**: Socket.IO (NestJS Gateway)

---

## Actor Relationships

### Primary Actor Hierarchy

```
Super Admin
    └── Manages ──> Admin
            └── Manages ──> Moderator
            └── Manages ──> Support Agent

Household User
    └── Can Switch To ──> Collector (if approved)

Collector
    └── Interacts With ──> Household User (collects from drops)
```

### Interaction Flow

```
Mobile App (ACT13) ──HTTP──> Backend API (ACT14) ──> MongoDB Atlas (ACT12)
                ──WebSocket──> WebSocket Gateway (ACT16)
                
Admin Dashboard (ACT15) ──HTTP──> Backend API (ACT14)

Backend API (ACT14) ──> Email Service (ACT7)
                    ──> SMS Service (ACT8)
                    ──> Firebase (ACT11)
                    
Mobile App (ACT13) ──> Google Maps API (ACT10)
```

### User Access Matrix

| Actor | Mobile App | Admin Dashboard | Backend API | WebSocket |
|-------|-----------|-----------------|-------------|-----------|
| Household | ✅ Full Access | ❌ No Access | ✅ User Endpoints | ✅ Notifications |
| Collector | ✅ Full Access | ❌ No Access | ✅ User Endpoints | ✅ Notifications |
| Support Agent | ❌ No Access | ✅ Support Section | ✅ Support Endpoints | ⚠️ Optional |
| Moderator | ❌ No Access | ✅ Moderation | ✅ Moderation Endpoints | ⚠️ Optional |
| Admin | ❌ No Access | ✅ Full Admin | ✅ Admin Endpoints | ⚠️ Optional |
| Super Admin | ❌ No Access | ✅ Full Admin | ✅ All Endpoints | ⚠️ Optional |

---

## Summary

### Primary Actors: 6
1. Household User
2. Collector
3. Support Agent
4. Moderator
5. Admin
6. Super Admin

### Secondary Actors: 3
7. Email Service
8. SMS Service
9. Automated System Processes

### External Systems: 3
10. Google Maps API
11. Firebase
12. MongoDB Atlas

### System Components: 4
13. Mobile Application (Flutter)
14. Backend API (NestJS)
15. Admin Dashboard (Next.js)
16. WebSocket Gateway

**Total Actors Identified: 16**

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Project**: Bottleji Platform - PFE (Projet de Fin d'Études)

