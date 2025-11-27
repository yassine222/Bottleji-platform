# Admin Dashboard Documentation

## Overview
The Botleji Admin Dashboard is a comprehensive web-based administration panel built with Next.js and React. It provides administrators with complete control over the Botleji ecosystem, including user management, content moderation, application processing, and business operations.

## Authentication & Access Control

### Login Process
1. **Access**: Navigate to admin dashboard URL
2. **Authentication**: Enter admin credentials (email/password)
3. **Token Storage**: JWT token stored in sessionStorage/localStorage
4. **Role Verification**: System validates admin/super_admin role
5. **Redirect**: Successful login redirects to main dashboard

### User Roles
- **Admin**: Standard administrative access
- **Super Admin**: Full system access including admin management

---

## Main Navigation Structure

### Primary Navigation Tabs
1. **Dashboard** - Overview and analytics
2. **Users** - User management and monitoring
3. **Drops** - Content moderation and management
4. **Applications** - Collector application processing
5. **Reward Shop** - Reward system management
6. **Training** - Educational content management
7. **Support** - Customer support ticket system
8. **Settings** - System configuration

---

## 1. Dashboard Overview

### Purpose
Central hub displaying key metrics, analytics, and recent activity across the platform.

### Features

#### Statistics Cards
- **Total Users**: Current user count with growth indicators
- **Total Drops**: All drops created with status breakdown
- **Active Collectors**: Users with collector role
- **Pending Applications**: Collector applications awaiting review
- **Support Tickets**: Open tickets requiring attention
- **Reward Items**: Available items in reward shop

#### Analytics Charts
- **Users Growth Chart**: User registration trends over time
- **Drops Activity Chart**: Drop creation patterns
- **Drop Status Pie Chart**: Distribution of drop statuses
- **Bottle Type Distribution**: Most collected bottle types
- **Applications Status**: Application approval/rejection rates

#### Recent Activity Feed
- **Activity Types**: Drop creation, user registration, application submissions
- **Filtering Options**: 
  - Activity type (drops-created, users-registered, applications-submitted)
  - Time period (all, today, week, month)
  - User role filter
- **Real-time Updates**: Live activity monitoring

### User Interactions
1. **View Statistics**: Click on stat cards for detailed views
2. **Filter Activity**: Use dropdown filters to narrow activity feed
3. **Navigate Charts**: Interactive chart elements for detailed analysis
4. **Refresh Data**: Manual refresh button for latest data

---

## 2. Users Management

### Purpose
Comprehensive user administration including profile management, role assignment, and account actions.

### Features

#### User List View
- **Search Functionality**: Search by name, email, or user ID
- **Role Filtering**: Filter by household, collector, admin roles
- **Status Filtering**: Active, banned, pending users
- **Pagination**: Handle large user datasets
- **Sort Options**: Sort by registration date, last activity, etc.

#### User Profile Details
- **Personal Information**: Name, email, phone number
- **Account Status**: Active, banned, warning count
- **Role Information**: Current roles and permissions
- **Activity History**: Recent drops, applications, interactions
- **Statistics**: Points earned, drops collected, redemptions

#### User Actions
- **View Profile**: Detailed user information modal
- **Ban User**: Temporary or permanent account suspension
- **Unban User**: Restore suspended accounts
- **Add Warning**: Issue warnings for policy violations
- **Role Management**: Assign/remove roles (admin only)
- **Send Notifications**: Direct communication with users

### User Workflows

#### Banning a User
1. Navigate to Users tab
2. Search/filter to find target user
3. Click "View Profile" or user row
4. Click "Ban User" button
5. Select ban duration (temporary/permanent)
6. Enter reason for ban
7. Confirm action
8. System sends notification to user

#### Unbanning a User
1. Find banned user in user list
2. Click "View Profile"
3. Click "Unban User" button
4. Confirm action
5. System sends unlock notification
6. User account restored

#### Adding Warning
1. Select user from list
2. Click "Add Warning" button
3. Enter warning reason
4. Select warning severity
5. Confirm warning
6. Warning count incremented
7. User notified of warning

---

## 3. Drops Management

### Purpose
Content moderation system for managing user-created drops, handling reports, and maintaining content quality.

### Features

#### Drop List View
- **All Drops Tab**: Complete drop inventory
- **Reported Drops Tab**: Drops flagged by users
- **Search & Filter**: By user, location, date, status
- **Status Indicators**: Active, censored, deleted, stale
- **Bulk Actions**: Mass approve/censor/delete operations

#### Drop Details Modal
- **Drop Information**: Title, description, location, timestamp
- **User Information**: Creator details and profile link
- **Media Content**: Images/videos with zoom functionality
- **Report History**: All reports filed against the drop
- **Action History**: Previous moderation actions

#### Drop Actions
- **Approve Drop**: Keep drop active and visible
- **Censor Drop**: Hide from public but keep in system
- **Delete Drop**: Permanently remove from system
- **Analyze Old Drops**: Review and mark drops as stale
- **View Reports**: See all user reports for the drop

### Drop Workflows

#### Moderating Reported Drop
1. Navigate to Drops tab
2. Click "Reported Drops" sub-tab
3. Select reported drop from list
4. Review drop content and reports
5. Choose moderation action:
   - **Approve**: Dismiss reports, keep drop active
   - **Censor**: Hide drop, notify creator
   - **Delete**: Remove drop, notify creator
6. Enter moderation reason
7. Confirm action
8. System notifies creator of decision

#### Analyzing Old Drops
1. Navigate to Drops tab
2. Click "Analyze Old Drops" button
3. Review drops older than specified threshold
4. Mark drops as "stale" if no longer relevant
5. Bulk actions available for multiple drops
6. System updates drop status

#### Bulk Drop Actions
1. Select multiple drops using checkboxes
2. Choose bulk action from dropdown
3. Confirm bulk operation
4. System processes all selected drops
5. Notifications sent to affected users

---

## 4. Applications Management

### Purpose
Process collector applications, review submissions, and manage collector onboarding.

### Features

#### Application List View
- **Status Filtering**: Pending, approved, rejected applications
- **Search Functionality**: Find applications by user details
- **Sort Options**: By submission date, review date, status
- **Pagination**: Handle large application volumes

#### Application Review Modal
- **Personal Information**: Name, contact details, location
- **Application Details**: Motivation, experience, availability
- **Supporting Documents**: ID verification, references
- **Review History**: Previous application attempts
- **Admin Notes**: Internal review comments

#### Application Actions
- **Approve Application**: Grant collector role and permissions
- **Reject Application**: Deny collector status with reason
- **Request More Info**: Ask for additional documentation
- **Schedule Interview**: Set up video/phone interview
- **Add Internal Notes**: Private admin comments

### Application Workflows

#### Approving Collector Application
1. Navigate to Applications tab
2. Select pending application
3. Review all submitted information
4. Verify supporting documents
5. Click "Approve Application"
6. System grants collector role
7. Welcome notification sent to user
8. Application marked as approved

#### Rejecting Collector Application
1. Select application for review
2. Review application details
3. Click "Reject Application"
4. Select rejection reason from predefined list:
   - Insufficient experience
   - Incomplete documentation
   - Geographic restrictions
   - Background check issues
   - Other (custom reason)
5. Enter detailed rejection explanation
6. Confirm rejection
7. System sends rejection notification
8. Application marked as rejected

#### Reversing Application Decision
1. Find previously processed application
2. Click "Reverse Decision" button
3. Select new status (approve/reject)
4. Enter reason for reversal
5. Confirm action
6. System updates application status
7. User notified of status change

---

## 5. Reward Shop Management

### Purpose
Manage reward items, inventory, pricing, and process customer orders.

### Features

#### Reward Items Tab

##### Item List View
- **Item Grid**: Visual display of all reward items
- **Search & Filter**: By name, category, subcategory, status
- **Category Filters**: Collector rewards, Household rewards
- **Subcategory Filters**: Tools, Equipment, Accessories, etc.
- **Status Indicators**: Active, inactive, out of stock

##### Item Management
- **Create New Item**: Add new reward items
- **Edit Item**: Modify existing item details
- **Delete Item**: Remove items from catalog
- **Toggle Active Status**: Enable/disable items
- **Stock Management**: Update inventory levels

##### Item Creation/Edit Form
- **Basic Information**: Name, description, category
- **Pricing**: Point cost configuration
- **Inventory**: Stock quantity management
- **Media**: Image upload via Firebase Storage
- **Wearable Options**: Size selection for clothing items
  - Footwear checkbox
  - Jacket checkbox
  - Bottoms checkbox
- **Status**: Active/inactive toggle

#### Orders Tab

##### Order List View
- **Order Cards**: Visual order display with key information
- **Status Filtering**: Pending, approved, rejected, delivered
- **Search**: Find orders by customer or item
- **Sort Options**: By date, status, value

##### Order Details
- **Customer Information**: Name, email, phone, roles
- **Item Information**: Product details, image, size selected
- **Delivery Address**: Complete shipping information
- **Order Timeline**: Creation, approval, delivery dates
- **Points Transaction**: Points spent, refunds if applicable

##### Order Actions
- **Approve Order**: Process order and generate shipping label
- **Reject Order**: Cancel order with reason and refund points
- **Download DHL Label**: Generate professional shipping label
- **Mark Delivered**: Complete order fulfillment
- **Update Status**: Change order status manually

### Reward Shop Workflows

#### Creating New Reward Item
1. Navigate to Reward Shop tab
2. Click "Create New Reward" button
3. Fill out item form:
   - Enter item name and description
   - Select category (Collector/Household)
   - Choose subcategory
   - Set point cost (minimum 0)
   - Set initial stock quantity
   - Upload item image
   - Configure wearable options if applicable
4. Click "Create Item"
5. Item added to catalog
6. Success notification displayed

#### Processing Customer Order
1. Navigate to Orders tab
2. Review pending orders
3. Select order for processing
4. Review customer and item details
5. Choose action:
   - **Approve**: Click "Approve" button
     - System generates tracking number
     - Creates shipping label
     - Sends approval notification
     - Order status: approved
   - **Reject**: Click "Reject" button
     - Select rejection reason
     - Enter detailed explanation
     - System refunds points
     - Sends rejection notification
     - Order status: rejected

#### Generating Shipping Label
1. Find approved order
2. Click "📦 Download DHL Label" button
3. System generates professional PDF label
4. PDF downloads automatically
5. Label includes:
   - DHL branding and colors
   - Sender address (Botleji HQ)
   - Recipient delivery address
   - Tracking number with barcode
   - QR code for scanning
   - Order details and weight

#### Managing Inventory
1. Select item from reward list
2. Click edit button
3. Update stock quantity
4. Save changes
5. System updates availability
6. Out-of-stock items automatically disabled

---

## 6. Training Content Management

### Purpose
Create, manage, and organize educational content for users.

### Features

#### Content List View
- **Content Grid**: Visual display of training materials
- **Search & Filter**: By title, type, category
- **Content Types**: Videos, documents, interactive content
- **Status Management**: Active, draft, archived

#### Content Creation
- **Upload Videos**: Direct video file upload
- **Upload Documents**: PDF, Word, PowerPoint files
- **Content Metadata**: Title, description, category
- **Access Control**: Public, collector-only, admin-only
- **Thumbnail Management**: Custom thumbnails for videos

#### Content Management
- **Edit Content**: Modify existing training materials
- **Delete Content**: Remove outdated materials
- **Reorder Content**: Change display sequence
- **Bulk Actions**: Mass operations on multiple items

### Training Workflows

#### Adding Training Video
1. Navigate to Training tab
2. Click "Add New Content" button
3. Select "Video" content type
4. Upload video file
5. Enter title and description
6. Set access permissions
7. Upload custom thumbnail
8. Save content
9. Video available in training library

#### Managing Training Library
1. View all training content
2. Use search/filter to find specific content
3. Edit content details as needed
4. Reorder content for better organization
5. Archive outdated content
6. Monitor content usage statistics

---

## 7. Support Ticket System

### Purpose
Handle customer inquiries, technical issues, and user support requests.

### Features

#### Ticket List View
- **Ticket Grid**: All support requests
- **Status Filtering**: Open, in-progress, resolved, closed
- **Priority Levels**: Low, medium, high, urgent
- **Category Filtering**: Technical, billing, general, application
- **Search**: Find tickets by user, subject, content

#### Ticket Details
- **User Information**: Customer details and history
- **Issue Description**: Detailed problem description
- **Attachments**: Screenshots, documents, logs
- **Conversation History**: All messages and responses
- **Related Information**: User's application status, account details

#### Ticket Actions
- **Assign Ticket**: Assign to specific admin
- **Respond to Ticket**: Send message to user
- **Change Status**: Update ticket progress
- **Add Internal Notes**: Private admin comments
- **Escalate Ticket**: Move to higher priority
- **Close Ticket**: Mark as resolved

### Support Workflows

#### Processing Support Ticket
1. Navigate to Support tab
2. Review new/open tickets
3. Select ticket for processing
4. Read issue description and user details
5. Check user's account status and history
6. Respond to user with solution
7. Update ticket status
8. Add internal notes if needed
9. Close ticket when resolved

#### Escalating Complex Issues
1. Identify complex technical issues
2. Add detailed internal notes
3. Change priority to "High" or "Urgent"
4. Assign to technical team member
5. Monitor ticket progress
6. Coordinate with development team if needed

---

## 8. Settings & Configuration

### Purpose
System configuration, user preferences, and administrative settings.

### Features

#### System Settings
- **API Configuration**: Endpoint management
- **Notification Settings**: Email and push notification preferences
- **Security Settings**: Password policies, session management
- **Backup Configuration**: Data backup schedules

#### User Preferences
- **Dashboard Layout**: Customize dashboard appearance
- **Notification Preferences**: Choose notification types
- **Language Settings**: Interface language selection
- **Theme Settings**: Light/dark mode preferences

### Settings Workflows

#### Updating System Configuration
1. Navigate to Settings tab
2. Select configuration category
3. Modify settings as needed
4. Save changes
5. System applies new configuration
6. Confirmation message displayed

---

## Error Handling & Edge Cases

### Authentication Errors
- **Token Expiration**: Automatic redirect to login
- **Invalid Credentials**: Clear error messages
- **Session Timeout**: Graceful session management

### Data Loading Errors
- **Network Issues**: Retry mechanisms and offline indicators
- **Server Errors**: User-friendly error messages
- **Empty States**: Appropriate empty state messages

### Permission Errors
- **Insufficient Permissions**: Clear access denied messages
- **Role Restrictions**: Feature-specific access controls

---

## Technical Architecture

### Frontend Components
- **React Components**: Modular, reusable UI components
- **State Management**: Local state with React hooks
- **API Integration**: Axios for HTTP requests
- **Authentication**: JWT token-based authentication
- **File Upload**: Firebase Storage integration

### Backend Integration
- **RESTful APIs**: Standard HTTP methods
- **Real-time Updates**: WebSocket connections
- **File Management**: Firebase Storage for media
- **Database Operations**: MongoDB integration

### Security Features
- **Role-based Access**: Admin/Super Admin permissions
- **Token Authentication**: Secure API communication
- **Input Validation**: Client and server-side validation
- **CSRF Protection**: Cross-site request forgery prevention

---

## User Experience Guidelines

### Navigation
- **Intuitive Menu**: Clear navigation structure
- **Breadcrumbs**: Show current location
- **Quick Actions**: Common actions easily accessible

### Feedback
- **Loading States**: Visual feedback during operations
- **Success Messages**: Confirmation of completed actions
- **Error Messages**: Clear, actionable error information

### Responsiveness
- **Mobile Support**: Responsive design for all devices
- **Touch Interactions**: Mobile-friendly touch targets
- **Adaptive Layout**: Layout adjusts to screen size

This documentation provides a comprehensive overview of all admin dashboard features and workflows, suitable for creating detailed UML diagrams and system documentation.
