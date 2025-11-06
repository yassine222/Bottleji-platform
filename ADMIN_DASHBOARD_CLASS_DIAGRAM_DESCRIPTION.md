# Admin Dashboard Class Diagram Description

This document provides a detailed description of all TypeScript interfaces, React components, services, and utilities in the Next.js Admin Dashboard for creating a comprehensive class diagram.

---

## TypeScript Interfaces (Types)

### 1. User
**File**: `src/types/index.ts`  
**Description**: Represents a user in the admin dashboard

#### Fields:
- **id**: string
- **email**: string
- **name**: string
- **phone**: string? (optional)
- **address**: string? (optional)
- **profilePhoto**: string? (optional)
- **roles**: string[] (array of role strings)
- **collectorSubscriptionType**: string? (optional)
- **isProfileComplete**: boolean
- **isAccountLocked**: boolean? (optional)
- **warningCount**: number? (optional)
- **createdAt**: string
- **updatedAt**: string

---

### 2. Drop
**File**: `src/types/index.ts`  
**Description**: Represents a drop/collection dropoff

#### Fields:
- **id**: string
- **userId**: string
- **imageUrl**: string
- **numberOfBottles**: number
- **numberOfCans**: number
- **bottleType**: string
- **notes**: string? (optional)
- **leaveOutside**: boolean
- **status**: string (enum: 'pending' | 'accepted' | 'collected' | 'cancelled' | 'expired')
- **location**: object
  - **latitude**: number
  - **longitude**: number
- **createdAt**: string
- **updatedAt**: string

---

### 3. CollectorApplication
**File**: `src/types/index.ts`  
**Description**: Represents a collector application

#### Fields:
- **id**: string
- **userId**: string | object (can be populated user object with id, name, email)
- **status**: string (enum: 'pending' | 'approved' | 'rejected')
- **idCardPhoto**: string
- **selfieWithIdPhoto**: string
- **idCardNumber**: string? (optional)
- **idCardType**: string? (optional)
- **idCardExpiryDate**: string? (optional)
- **idCardIssuingAuthority**: string? (optional)
- **idCardBackPhoto**: string? (optional)
- **passportIssueDate**: string? (optional)
- **passportExpiryDate**: string? (optional)
- **passportMainPagePhoto**: string? (optional)
- **rejectionReason**: string? (optional)
- **appliedAt**: string
- **reviewedAt**: string? (optional)
- **reviewedBy**: string? (optional)
- **reviewNotes**: string? (optional)
- **createdAt**: string
- **updatedAt**: string

---

### 4. TrainingContent
**File**: `src/types/index.ts`  
**Description**: Represents training content

#### Fields:
- **id**: string
- **title**: string
- **content**: string
- **category**: string
- **isActive**: boolean
- **createdAt**: string
- **updatedAt**: string

---

### 5. SupportTicket
**File**: `src/types/index.ts`  
**Description**: Represents a support ticket

#### Fields:
- **id**: string
- **userId**: string
- **subject**: string
- **message**: string
- **status**: string (enum: 'open' | 'in_progress' | 'resolved' | 'closed')
- **priority**: string (enum: 'low' | 'medium' | 'high')
- **responses**: SupportResponse[] (array of responses)
- **createdAt**: string
- **updatedAt**: string

---

### 6. SupportResponse
**File**: `src/types/index.ts`  
**Description**: Represents a response to a support ticket

#### Fields:
- **id**: string
- **ticketId**: string
- **responderId**: string
- **responderName**: string
- **response**: string
- **createdAt**: string

---

### 7. AdminUser
**File**: `src/types/index.ts`  
**Description**: Represents an admin user

#### Fields:
- **id**: string
- **email**: string
- **name**: string
- **role**: string (enum: 'admin' | 'moderator')
- **permissions**: string[]
- **createdAt**: string
- **updatedAt**: string

---

### 8. DashboardStats
**File**: `src/types/index.ts`  
**Description**: Represents dashboard statistics

#### Fields:
- **totalUsers**: number
- **totalDrops**: number
- **totalApplications**: number
- **totalTickets**: number
- **pendingApplications**: number
- **pendingTickets**: number
- **recentActivity**: ActivityItem[] (array)

---

### 9. ActivityItem
**File**: `src/types/index.ts`  
**Description**: Represents an activity item in the dashboard

#### Fields:
- **id**: string
- **type**: string (enum: 'user_registration' | 'drop_created' | 'application_submitted' | 'ticket_created')
- **description**: string
- **timestamp**: string
- **userId**: string? (optional)
- **userName**: string? (optional)

---

### 10. PaginatedResponse<T>
**File**: `src/types/index.ts`  
**Description**: Generic paginated response interface

#### Fields:
- **data**: T[] (generic array)
- **total**: number
- **page**: number
- **limit**: number
- **totalPages**: number

---

### 11. UserRole (Type)
**File**: `src/types/index.ts`  
**Description**: Type alias for user roles

#### Values:
- 'super_admin' | 'admin' | 'moderator' | 'support_agent' | 'collector' | 'household'

---

## React Components

### 12. AuthGuard
**File**: `src/components/auth/AuthGuard.tsx`  
**Type**: React Functional Component  
**Description**: Authentication guard component that protects routes

#### Props:
- **children**: React.ReactNode (required)

#### Operations:
- **Component Logic**: Checks authentication, redirects to login if not authenticated

---

### 13. AdminLayout
**File**: `src/components/layout/AdminLayout.tsx`  
**Type**: React Functional Component  
**Description**: Main layout wrapper for admin dashboard pages

#### Props:
- **children**: React.ReactNode (required)
- **activeTab**: string? (optional)
- **title**: string? (optional)

#### Operations:
- **Component Logic**: Renders Header, Sidebar, and page content

---

### 14. Header
**File**: `src/components/layout/Header.tsx`  
**Type**: React Functional Component  
**Description**: Dashboard header component

#### Props:
- **user**: User? (optional)
- **onLogout**: () => void (optional)

#### Operations:
- **Component Logic**: Displays user info, notifications, logout button

---

### 15. Sidebar
**File**: `src/components/layout/Sidebar.tsx`  
**Type**: React Functional Component  
**Description**: Navigation sidebar component

#### Props:
- **activeTab**: string (required)
- **onTabChange**: (tab: string) => void (required)
- **userRoles**: string[] (optional, default: [])

#### Operations:
- **Component Logic**: Renders navigation menu based on user roles

---

### 16. DashboardCharts
**File**: `src/components/dashboard/DashboardCharts.tsx`  
**Type**: React Functional Component  
**Description**: Charts and analytics visualization component

#### Props:
- **stats**: DashboardStats? (optional)
- **userGrowthData**: any[]? (optional)
- **dropActivityData**: any[]? (optional)

#### Operations:
- **Component Logic**: Renders charts using Recharts library

---

### 17. RewardImageUpload
**File**: `src/components/rewards/RewardImageUpload.tsx`  
**Type**: React Functional Component  
**Description**: Component for uploading reward item images

#### Props:
- **onImageUpload**: (imageUrl: string) => void (required)
- **currentImageUrl**: string? (optional)

#### Operations:
- **Component Logic**: Handles image upload to Firebase Storage

---

### 18. FileUpload
**File**: `src/components/training/FileUpload.tsx`  
**Type**: React Functional Component  
**Description**: Component for uploading training content files

#### Props:
- **onFileUpload**: (fileUrl: string) => void (required)
- **accept**: string? (optional)
- **fileType**: string? (optional)

#### Operations:
- **Component Logic**: Handles file upload (video, image, or story)

---

### 19. VideoModal
**File**: `src/components/training/VideoModal.tsx`  
**Type**: React Functional Component  
**Description**: Modal component for video playback

#### Props:
- **isOpen**: boolean (required)
- **onClose**: () => void (required)
- **videoUrl**: string (required)
- **title**: string? (optional)

#### Operations:
- **Component Logic**: Displays video in modal overlay

---

### 20. VideoPlayer
**File**: `src/components/training/VideoPlayer.tsx`  
**Type**: React Functional Component  
**Description**: Video player component

#### Props:
- **videoUrl**: string (required)
- **autoPlay**: boolean? (optional, default: false)
- **controls**: boolean? (optional, default: true)

#### Operations:
- **Component Logic**: Renders HTML5 video player

---

## Page Components (Next.js App Router Pages)

### 21. DashboardPage
**File**: `src/app/dashboard/page.tsx`  
**Type**: React Server/Client Component  
**Description**: Main dashboard page

#### Operations:
- **fetchDashboardStats**(): Promise<void>
- **fetchOrders**(): Promise<void>
- **handleDownloadShippingLabel**(redemptionId: string): Promise<void>
- **handleApproveRedemption**(redemptionId: string): Promise<void>
- **handleRejectRedemption**(redemptionId: string, reason: string): Promise<void>

#### State:
- **stats**: DashboardStats
- **orders**: RewardRedemption[]
- **loading**: boolean
- **error**: string | null

---

### 22. UsersPage
**File**: `src/app/users/page.tsx`  
**Type**: React Server/Client Component  
**Description**: User management page

#### Operations:
- **fetchUsers**(page: number, limit: number): Promise<void>
- **handleBanUser**(userId: string, reason: string): Promise<void>
- **handleUnbanUser**(userId: string): Promise<void>
- **handleDeleteUser**(userId: string): Promise<void>
- **handleUpdateRoles**(userId: string, roles: string[]): Promise<void>

#### State:
- **users**: User[]
- **totalUsers**: number
- **currentPage**: number
- **loading**: boolean

---

### 23. DropsPage
**File**: `src/app/drops/page.tsx`  
**Type**: React Server/Client Component  
**Description**: Drops management page

#### Operations:
- **fetchDrops**(page: number, limit: number, status?: string): Promise<void>
- **handleDeleteDrop**(dropId: string): Promise<void>
- **handleCensorDrop**(dropId: string, reason: string): Promise<void>
- **handleViewDropDetails**(dropId: string): Promise<void>

#### State:
- **drops**: Drop[]
- **totalDrops**: number
- **filteredDrops**: Drop[]
- **loading**: boolean

---

### 24. ApplicationsPage
**File**: `src/app/applications/page.tsx`  
**Type**: React Server/Client Component  
**Description**: Collector applications management page

#### Operations:
- **fetchApplications**(status?: string): Promise<void>
- **handleApproveApplication**(applicationId: string): Promise<void>
- **handleRejectApplication**(applicationId: string, reason: string): Promise<void>
- **handleReverseApproval**(applicationId: string): Promise<void>

#### State:
- **applications**: CollectorApplication[]
- **pendingApplications**: CollectorApplication[]
- **loading**: boolean

---

### 25. SupportTicketsPage
**File**: `src/app/support-tickets/page.tsx`  
**Type**: React Server/Client Component  
**Description**: Support tickets management page

#### Operations:
- **fetchTickets**(status?: string, category?: string): Promise<void>
- **handleUpdateTicketStatus**(ticketId: string, status: string): Promise<void>
- **handleAssignTicket**(ticketId: string, assignedTo: string): Promise<void>
- **handleAddMessage**(ticketId: string, message: string): Promise<void>
- **handleResolveTicket**(ticketId: string, resolution: string): Promise<void>
- **handleCloseTicket**(ticketId: string): Promise<void>

#### State:
- **tickets**: SupportTicket[]
- **selectedTicket**: SupportTicket | null
- **loading**: boolean

---

### 26. RewardsPage
**File**: `src/app/rewards/page.tsx` (if exists, or in dashboard)  
**Type**: React Server/Client Component  
**Description**: Reward items and redemptions management page

#### Operations:
- **fetchRewardItems**(): Promise<void>
- **fetchRedemptions**(): Promise<void>
- **handleCreateRewardItem**(itemData: any): Promise<void>
- **handleUpdateRewardItem**(itemId: string, updateData: any): Promise<void>
- **handleDeleteRewardItem**(itemId: string): Promise<void>
- **handleApproveRedemption**(redemptionId: string): Promise<void>
- **handleRejectRedemption**(redemptionId: string, reason: string): Promise<void>

#### State:
- **rewardItems**: RewardItem[]
- **redemptions**: RewardRedemption[]
- **loading**: boolean

---

### 27. TrainingPage
**File**: `src/app/training/page.tsx`  
**Type**: React Server/Client Component  
**Description**: Training content management page

#### Operations:
- **fetchTrainingContent**(): Promise<void>
- **handleCreateContent**(contentData: any): Promise<void>
- **handleUpdateContent**(contentId: string, updateData: any): Promise<void>
- **handleDeleteContent**(contentId: string): Promise<void>
- **handleUploadFile**(file: File, type: string): Promise<void>

#### State:
- **trainingContent**: TrainingContent[]
- **loading**: boolean

---

## Service Classes

### 28. ApiService (axios instance)
**File**: `src/lib/api.ts`  
**Type**: Axios Instance  
**Description**: Centralized API client with interceptors

#### Configuration:
- **baseURL**: string (API_BASE_URL)
- **timeout**: number (30000ms)

#### Operations:
- **Request Interceptor**: Adds Authorization token from localStorage/sessionStorage
- **Response Interceptor**: Logs responses and handles errors

#### API Modules:
- **authAPI**: Authentication API methods
- **dashboardAPI**: Dashboard API methods
- **usersAPI**: Users API methods
- **dropsAPI**: Drops API methods
- **applicationsAPI**: Applications API methods
- **supportTicketsAPI**: Support tickets API methods
- **trainingAPI**: Training API methods
- **analyticsAPI**: Analytics API methods

---

### 29. ApiEndpoints
**File**: `src/lib/apiEndpoints.ts`  
**Type**: Configuration Object  
**Description**: Centralized API endpoint configuration

#### Fields:
- **API_BASE_URL**: string
- **API_ENDPOINTS**: object
  - **AUTH**: object (LOGIN, PROFILE, CHANGE_PASSWORD, VERIFY_TOKEN)
  - **DASHBOARD**: object (STATS, ANALYTICS, ANALYTICS_BY_DATE)
  - **USERS**: object (GET_ALL, GET_BY_ID, UPDATE_ROLES, BAN_USER, etc.)
  - **DROPS**: object (GET_ALL, GET_BY_ID, UPDATE, DELETE, etc.)
  - **APPLICATIONS**: object (GET_ALL, GET_BY_ID, APPROVE, REJECT, etc.)
  - **SUPPORT**: object (GET_ALL, GET_BY_ID, UPDATE_STATUS, ASSIGN, etc.)
  - **TRAINING**: object (GET_ALL, CREATE, UPDATE, DELETE, etc.)
  - **REWARDS**: object (GET_ALL, CREATE, UPDATE, GET_REDEMPTIONS, etc.)

#### Operations:
- **buildApiUrl**(endpoint: string, params?: object): string
- **getEndpoint**(endpoint: string | function, ...args: any[]): string

---

## Utility Classes/Functions

### 30. dateUtils
**File**: `src/lib/dateUtils.ts`  
**Type**: Utility Functions  
**Description**: Date formatting and manipulation utilities

#### Operations:
- **formatDate**(date: Date | string): string
- **formatDateTime**(date: Date | string): string
- **getRelativeTime**(date: Date | string): string
- **isToday**(date: Date | string): boolean
- **isYesterday**(date: Date | string): boolean

---

### 31. Firebase Service
**File**: `src/lib/firebase.ts`  
**Type**: Firebase Configuration  
**Description**: Firebase configuration and storage utilities

#### Operations:
- **uploadFile**(file: File, path: string): Promise<string>
- **deleteFile**(fileUrl: string): Promise<void>
- **getFileUrl**(path: string): Promise<string>

---

## Relationships

### Component Relationships:
1. **AdminLayout** → **Header** (composition)
2. **AdminLayout** → **Sidebar** (composition)
3. **AdminLayout** → **Page Components** (composition)
4. **DashboardPage** → **DashboardCharts** (composition)
5. **TrainingPage** → **FileUpload** (composition)
6. **TrainingPage** → **VideoModal** (composition)
7. **VideoModal** → **VideoPlayer** (composition)
8. **RewardsPage** → **RewardImageUpload** (composition)

### Service Relationships:
1. **All Page Components** → **ApiService** (dependency)
2. **ApiService** → **ApiEndpoints** (dependency)
3. **All Components** → **TypeScript Interfaces** (usage)

### Type Relationships:
1. **User** used by: UsersPage, Header, AdminLayout
2. **Drop** used by: DropsPage
3. **CollectorApplication** used by: ApplicationsPage
4. **SupportTicket** used by: SupportTicketsPage
5. **DashboardStats** used by: DashboardPage, DashboardCharts
6. **TrainingContent** used by: TrainingPage
7. **PaginatedResponse<T>** used by: All list pages (generic)

---

## Class Diagram Structure Instructions

When creating the class diagram, follow these guidelines:

1. **Separate Interfaces from Components**: Show TypeScript interfaces as separate classes
2. **Show Component Props**: Include props as attributes or constructor parameters
3. **Show Component State**: Optionally show state as private attributes
4. **Show Operations**: Include main methods/functions for each component/service
5. **Use Composition for Component Hierarchy**: Use composition arrows for nested components
6. **Use Dependency for Service Usage**: Use dependency arrows from components to services
7. **Use Realization for Interfaces**: Components realize (implement) interfaces
8. **Group by Package**: Use packages to group:
   - Types/Interfaces
   - Components (Layout, Dashboard, Rewards, Training)
   - Services (API, Utilities)
   - Pages

---

## Key Points for Diagram Creation

- **React Components**: Show as classes with props as attributes and operations as methods
- **TypeScript Interfaces**: Show as abstract classes or interfaces
- **Services**: Show as utility/service classes with static methods or instance methods
- **API Methods**: Can be shown as operations in the ApiService class or as separate classes per module
- **State Management**: React state can be shown as private attributes or omitted for simplicity
- **Props**: Can be shown as constructor parameters or as attributes

---

**Total Interfaces**: 11  
**Total React Components**: 9  
**Total Page Components**: 7  
**Total Services**: 4  
**Total Utilities**: 2

**Total Classes**: 33

