# Class Diagram Description for Bottleji Platform Database Schema

This document provides a detailed description of all MongoDB collections/schemas, their fields, relationships, and enums for creating a comprehensive class diagram.

---

## Enumerations (Enums)

### 1. UserRole
**Type**: Enum  
**Values**:
- HOUSEHOLD = 'household'
- COLLECTOR = 'collector'
- SUPPORT_AGENT = 'support_agent'
- MODERATOR = 'moderator'
- ADMIN = 'admin'
- SUPER_ADMIN = 'super_admin'

### 2. CollectorApplicationStatus
**Type**: Enum  
**Values**:
- PENDING = 'pending'
- APPROVED = 'approved'
- REJECTED = 'rejected'

### 3. BottleType
**Type**: Enum  
**Values**:
- PLASTIC = 'plastic'
- CAN = 'can'
- MIXED = 'mixed'

### 4. DropoffStatus
**Type**: Enum  
**Values**:
- PENDING = 'pending'
- ACCEPTED = 'accepted'
- COLLECTED = 'collected'
- CANCELLED = 'cancelled'
- EXPIRED = 'expired'
- STALE = 'stale'

### 5. CancellationReason
**Type**: Enum  
**Values**:
- NO_ACCESS = 'noAccess'
- NOT_FOUND = 'notFound'
- ALREADY_COLLECTED = 'alreadyCollected'
- WRONG_LOCATION = 'wrongLocation'
- UNSAFE = 'unsafe'
- OTHER = 'other'

### 6. ReportReason
**Type**: Enum  
**Values**:
- INAPPROPRIATE_IMAGE = 'inappropriate_image'
- FAKE_DROP = 'fake_drop'
- AMOUNT_MISMATCH = 'amount_mismatch'
- WRONG_LOCATION = 'wrong_location'
- ALREADY_COLLECTED = 'already_collected'
- DANGEROUS_LOCATION = 'dangerous_location'
- OTHER = 'other'

### 7. ReportStatus
**Type**: Enum  
**Values**:
- PENDING = 'pending'
- REVIEWED = 'reviewed'
- DISMISSED = 'dismissed'
- ACTION_TAKEN = 'action_taken'

### 8. RewardCategory
**Type**: Enum  
**Values**:
- COLLECTOR = 'collector'
- HOUSEHOLD = 'household'

### 9. RedemptionStatus
**Type**: Enum  
**Values**:
- PENDING = 'pending'
- APPROVED = 'approved'
- PROCESSING = 'processing'
- SHIPPED = 'shipped'
- DELIVERED = 'delivered'
- CANCELLED = 'cancelled'
- REJECTED = 'rejected'

### 10. NotificationType
**Type**: Enum  
**Values**:
- ORDER_APPROVED = 'order_approved'
- ORDER_REJECTED = 'order_rejected'
- ORDER_SHIPPED = 'order_shipped'
- ORDER_DELIVERED = 'order_delivered'
- POINTS_EARNED = 'points_earned'
- SYSTEM_ANNOUNCEMENT = 'system_announcement'
- USER_DELETED = 'user_deleted'
- APPLICATION_APPROVED = 'application_approved'
- APPLICATION_REJECTED = 'application_rejected'
- APPLICATION_REVERSED = 'application_reversed'

### 11. NotificationPriority
**Type**: Enum  
**Values**:
- LOW = 'low'
- MEDIUM = 'medium'
- HIGH = 'high'
- URGENT = 'urgent'

### 12. TicketStatus
**Type**: Enum  
**Values**:
- OPEN = 'open'
- IN_PROGRESS = 'in_progress'
- ON_HOLD = 'on_hold'
- RESOLVED = 'resolved'
- CLOSED = 'closed'

### 13. TicketPriority
**Type**: Enum  
**Values**:
- LOW = 'low'
- MEDIUM = 'medium'
- HIGH = 'high'
- URGENT = 'urgent'

### 14. TicketCategory
**Type**: Enum  
**Values**:
- AUTHENTICATION = 'authentication'
- APP_TECHNICAL = 'app_technical'
- DROP_CREATION = 'drop_creation'
- COLLECTION_NAVIGATION = 'collection_navigation'
- COLLECTOR_APPLICATION = 'collector_application'
- PAYMENT_REWARDS = 'payment_rewards'
- STATISTICS_HISTORY = 'statistics_history'
- ROLE_SWITCHING = 'role_switching'
- COMMUNICATION = 'communication'
- GENERAL_SUPPORT = 'general_support'

---

## Main Schema Classes

### 1. User
**Collection Name**: users  
**Extends**: Document (Mongoose)  
**Description**: Represents a user in the system (household, collector, or admin)

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **email**: string (required, unique)
- **password**: string (required)
- **name**: string? (optional)
- **phoneNumber**: string? (optional)
- **isPhoneVerified**: boolean (default: false)
- **phoneVerificationId**: string? (optional)
- **address**: string? (optional)
- **profilePhoto**: string? (optional)
- **roles**: UserRole[] (array, default: [HOUSEHOLD])
- **collectorApplication**: CollectorApplication? (embedded, optional)
- **collectorApplicationStatus**: CollectorApplicationStatus? (optional)
- **collectorApplicationId**: string? (optional)
- **collectorApplicationAppliedAt**: Date? (optional)
- **collectorApplicationRejectionReason**: string? (optional)
- **collectorSubscriptionType**: string (enum: 'basic' | 'premium', default: 'basic')
- **isProfileComplete**: boolean (default: false)
- **verificationOTP**: string? (optional)
- **otpExpiresAt**: Date? (optional)
- **otpAttempts**: number (default: 0)
- **isVerified**: boolean (default: false)
- **resetPasswordOtp**: string? (optional)
- **resetPasswordOtpExpiry**: Date? (optional)
- **mustChangePassword**: boolean (default: false)
- **warningCount**: number (default: 0)
- **isAccountLocked**: boolean (default: false)
- **accountLockedUntil**: Date? (optional)
- **warnings**: any[] (array, default: [])
- **isDeleted**: boolean (default: false)
- **deletedAt**: Date? (optional)
- **deletedBy**: string? (optional)
- **sessionInvalidatedAt**: Date? (optional)
- **totalDropsCollected**: number (default: 0)
- **totalDropsCreated**: number (default: 0)
- **totalPointsEarned**: number (default: 0)
- **currentPoints**: number (default: 0)
- **currentTier**: number (default: 1)
- **lastDropCollectedAt**: Date? (optional, default: Date.now)
- **lastDropCreatedAt**: Date? (optional, default: Date.now)
- **rewardHistory**: any[] (array, default: [])
- **createdAt**: Date (default: Date.now)
- **updatedAt**: Date (default: Date.now)

#### Operations (Methods):
- **create**(createUserDto: CreateUserDto): Promise<User>
- **findAll**(): Promise<User[]>
- **findOne**(id: string): Promise<User>
- **findByEmail**(email: string): Promise<User | null>
- **findByPhone**(phoneNumber: string): Promise<User | null>
- **findByVerificationToken**(token: string): Promise<User | null>
- **update**(id: string, updateData: Partial<User>): Promise<User>
- **remove**(id: string): Promise<User>
- **unlockAccount**(userId: string): Promise<User>

#### Relationships:
- **Embedded**: Contains `CollectorApplication` (optional)
- **Referenced By**: 
  - Dropoff.userId → User
  - CollectionAttempt.collectorId → User
  - CollectorApplication.userId → User
  - RewardRedemption.userId → User
  - Notification.userId → User
  - SupportTicket.userId → User
  - SupportTicket.assignedTo → User
  - SupportTicket.createdBy → User
  - SupportTicket.lastUpdatedBy → User
  - SupportTicket.escalatedTo → User
  - SupportTicket.deletedBy → User

---

### 2. CollectorApplication (Embedded in User)
**Type**: Embedded Schema  
**Description**: Collector application information embedded in User document

#### Fields:
- **status**: CollectorApplicationStatus (default: PENDING)
- **idCardPhoto**: string (required)
- **selfieWithIdPhoto**: string (required)
- **rejectionReason**: string? (optional)
- **appliedAt**: Date (default: Date.now)
- **reviewedAt**: Date? (optional)

---

### 3. CollectorApplication (Standalone Collection)
**Collection Name**: collectorapplications  
**Extends**: Document (Mongoose)  
**Description**: Standalone collector application collection

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **userId**: Types.ObjectId (required, ref: 'User')
- **status**: CollectorApplicationStatus (default: PENDING)
- **idCardPhoto**: string (required)
- **selfieWithIdPhoto**: string (required)
- **idCardNumber**: string? (optional)
- **idCardType**: string? (optional, e.g., "National ID", "Passport", "Driver's License")
- **idCardExpiryDate**: Date? (optional)
- **idCardIssuingAuthority**: string? (optional)
- **idCardBackPhoto**: string? (optional)
- **passportIssueDate**: Date? (optional)
- **passportExpiryDate**: Date? (optional)
- **passportMainPagePhoto**: string? (optional)
- **rejectionReason**: string? (optional)
- **appliedAt**: Date (default: Date.now)
- **reviewedAt**: Date? (optional)
- **reviewedBy**: Types.ObjectId? (optional, ref: 'User')
- **reviewNotes**: string? (optional)
- **createdAt**: Date (default: Date.now)
- **updatedAt**: Date (default: Date.now)

#### Operations (Methods):
- **createApplication**(userId: string, applicationData: object): Promise<CollectorApplication>
- **getApplicationByUserId**(userId: string): Promise<CollectorApplication | null>
- **getApplicationById**(applicationId: string): Promise<CollectorApplication | null>
- **getAllApplications**(status?: CollectorApplicationStatus): Promise<CollectorApplication[]>
- **getPendingApplications**(): Promise<CollectorApplication[]>
- **approveApplication**(applicationId: string, adminId: string, notes?: string): Promise<CollectorApplication>
- **rejectApplication**(applicationId: string, adminId: string, rejectionReason: string, notes?: string): Promise<CollectorApplication>
- **reverseApproval**(applicationId: string, adminId: string, notes?: string): Promise<CollectorApplication>
- **updateApplication**(applicationId: string, updateData: object): Promise<CollectorApplication>
- **getApplicationStats**(): Promise<object>

#### Relationships:
- **userId** → User (Many-to-One)
- **reviewedBy** → User (Many-to-One, optional)
- **Referenced By**: SupportTicket.relatedApplicationId → CollectorApplication

---

### 4. Dropoff
**Collection Name**: dropoffs  
**Extends**: Document (Mongoose)  
**Description**: Represents a drop created by a household user

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **userId**: string (required)
- **imageUrl**: string (required)
- **numberOfBottles**: number (required, default: 0)
- **numberOfCans**: number (required, default: 0)
- **bottleType**: BottleType (required)
- **notes**: string? (optional)
- **leaveOutside**: boolean (required, default: false)
- **location**: object (required)
  - **type**: string (enum: 'Point', default: 'Point')
  - **coordinates**: number[] (required, [longitude, latitude])
- **address**: string? (optional)
- **status**: DropoffStatus (required, default: PENDING)
- **cancellationCount**: number (default: 0)
- **isSuspicious**: boolean (default: false)
- **suspiciousReason**: string? (optional)
- **isCensored**: boolean (default: false)
- **censorReason**: string? (optional)
- **censoredBy**: string? (optional)
- **censoredAt**: Date? (optional)
- **cancelledByCollectorIds**: string[] (array, default: [])
- **collectedBy**: string? (optional)
- **collectedAt**: Date? (optional)
- **cancellationHistory**: array (default: [])
  - **collectorId**: string (required)
  - **reason**: CancellationReason (required)
  - **cancelledAt**: Date (required)
  - **notes**: string? (optional)
  - **location**: object? (optional)
    - **type**: string (enum: 'Point', default: 'Point')
    - **coordinates**: number[] (optional)
- **createdAt**: Date (optional, auto-generated)
- **updatedAt**: Date (optional, auto-generated)

#### Operations (Methods):
- **create**(createDropoffDto: CreateDropoffDto): Promise<Dropoff>
- **findAll**(): Promise<Dropoff[]>
- **findOne**(id: string): Promise<Dropoff>
- **findByUser**(userId: string): Promise<Dropoff[]>
- **findByStatus**(status: string): Promise<Dropoff[]>
- **findAvailableForCollectors**(excludeCollectorId?: string): Promise<Dropoff[]>
- **findAcceptedByCollector**(collectorId: string): Promise<Dropoff[]>
- **updateStatus**(id: string, status: string): Promise<Dropoff>
- **update**(id: string, updateDropoffDto: any): Promise<Dropoff>
- **assignCollector**(id: string, collectorId: string): Promise<Dropoff>
- **confirmCollection**(id: string): Promise<Dropoff>
- **cancelAcceptedDrop**(id: string, reason?: string, cancelledByCollectorId?: string): Promise<Dropoff>
- **remove**(id: string): Promise<Dropoff>
- **createCollectionAttempt**(dropoffId: string, collectorId: string): Promise<CollectionAttempt>
- **completeCollectionAttempt**(attemptId: string, outcome: 'expired' | 'cancelled' | 'collected', details: any): Promise<CollectionAttempt>
- **getCollectorAttempts**(collectorId: string, page: number, limit: number): Promise<object>
- **getDropoffAttempts**(dropoffId: string): Promise<CollectionAttempt[]>
- **getCollectionAttemptStats**(collectorId: string): Promise<object>
- **getUserDropStats**(userId: string, timeRange?: string): Promise<object>
- **getCollectorStats**(collectorId: string, timeRange?: string): Promise<object>
- **getCollectorHistory**(collectorId: string, status?: string, timeRange?: string, page: number, limit: number): Promise<object>
- **getDropInteractionTimeline**(dropoffId: string): Promise<object>
- **getCollectionInteractionTimeline**(collectionId: string): Promise<object>
- **reportDrop**(dropId: string, collectorId: string, reason: string, details?: string): Promise<DropReport>
- **getDropReports**(dropId: string): Promise<DropReport[]>
- **getPendingReports**(): Promise<DropReport[]>
- **cleanupExpiredAcceptedDrops**(): Promise<void>
- **cleanupExpired**(): Promise<void>

#### Relationships:
- **userId** → User (Many-to-One)
- **Referenced By**: 
  - CollectionAttempt.dropoffId → Dropoff
  - DropReport.dropId → Dropoff
  - SupportTicket.relatedDropId → Dropoff

#### Indexes:
- location: '2dsphere' (for geospatial queries)

---

### 5. CollectionAttempt
**Collection Name**: collectionattempts  
**Extends**: Document (Mongoose)  
**Description**: Represents a collector's attempt to collect a drop (replaces CollectorInteraction)

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **dropoffId**: Types.ObjectId (required, ref: 'Dropoff')
- **collectorId**: Types.ObjectId (required, ref: 'User')
- **status**: string (enum: 'active' | 'completed', default: 'active')
- **outcome**: string? (enum: 'expired' | 'cancelled' | 'collected' | null, default: null)
- **timeline**: TimelineEvent[] (array, default: [])
- **acceptedAt**: Date (required)
- **completedAt**: Date? (optional, default: null)
- **durationMinutes**: number? (optional, default: null)
- **dropSnapshot**: DropSnapshot (required, embedded)
- **attemptNumber**: number (default: 1)
- **cancellationCount**: number (default: 0)
- **createdAt**: Date (optional, auto-generated)
- **updatedAt**: Date (optional, auto-generated)

#### Operations (Methods):
- **createCollectionAttempt**(dropoffId: string, collectorId: string): Promise<CollectionAttempt>
- **completeCollectionAttempt**(attemptId: string, outcome: 'expired' | 'cancelled' | 'collected', details: any): Promise<CollectionAttempt>
- **getCollectorAttempts**(collectorId: string, page: number, limit: number): Promise<object>
- **getDropoffAttempts**(dropoffId: string): Promise<CollectionAttempt[]>
- **getCollectionAttemptStats**(collectorId: string): Promise<object>
- **getCollectionInteractionTimeline**(collectionId: string): Promise<object>

#### Relationships:
- **dropoffId** → Dropoff (Many-to-One)
- **collectorId** → User (Many-to-One)
- **Referenced By**: SupportTicket.relatedCollectionId → CollectionAttempt

#### Embedded Classes:
- **TimelineEvent** (embedded in timeline array)
- **DropSnapshot** (embedded, required)

#### Indexes:
- dropoffId: 1
- collectorId: 1
- status: 1
- outcome: 1
- acceptedAt: -1
- completedAt: -1

---

### 6. TimelineEvent (Embedded in CollectionAttempt)
**Type**: Embedded Schema  
**Description**: Timeline event for collection attempt history

#### Fields:
- **event**: string (enum: 'accepted' | 'cancelled' | 'expired' | 'collected', required)
- **timestamp**: Date (required)
- **collector**: object (required)
  - **id**: Types.ObjectId
  - **name**: string
  - **email**: string
- **details**: object (required)
  - **reason**: string? (optional, for cancelled/expired)
  - **notes**: string? (optional)
  - **location**: object? (optional)
    - **lat**: number
    - **lng**: number

---

### 7. DropSnapshot (Embedded in CollectionAttempt)
**Type**: Embedded Schema  
**Description**: Snapshot of drop information at the time of collection attempt

#### Fields:
- **imageUrl**: string (required)
- **numberOfBottles**: number (required)
- **numberOfCans**: number (required)
- **bottleType**: string (required)
- **location**: object (required)
  - **lat**: number
  - **lng**: number
- **address**: string? (optional)
- **notes**: string? (optional)
- **leaveOutside**: boolean? (optional)
- **createdBy**: object (required)
  - **id**: Types.ObjectId
  - **name**: string
  - **email**: string
- **createdAt**: Date (required)

---

### 8. DropReport
**Collection Name**: dropreports  
**Extends**: Document (Mongoose)  
**Description**: Reports filed by collectors about problematic drops

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **dropId**: string (required)
- **reportedBy**: string (required, Collector ID)
- **reason**: ReportReason (required)
- **details**: string? (optional, additional details from reporter)
- **status**: ReportStatus (required, default: PENDING)
- **reviewedBy**: string? (optional, Admin ID)
- **reviewedAt**: Date? (optional)
- **actionTaken**: string? (optional, what action admin took)
- **adminNotes**: string? (optional)
- **createdAt**: Date (optional, auto-generated)
- **updatedAt**: Date (optional, auto-generated)

#### Operations (Methods):
- **reportDrop**(dropId: string, collectorId: string, reason: ReportReason, details?: string): Promise<DropReport>
- **getDropReports**(dropId: string): Promise<DropReport[]>
- **getPendingReports**(): Promise<DropReport[]>

#### Relationships:
- **dropId** → Dropoff (Many-to-One)
- **reportedBy** → User (Many-to-One, collector)

---

### 9. RewardItem
**Collection Name**: rewarditems  
**Extends**: Document (Mongoose)  
**Description**: Reward items available in the reward shop

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **name**: string (required, trimmed)
- **description**: string (required, trimmed)
- **category**: RewardCategory (required)
- **subCategory**: string (required, trimmed)
- **pointCost**: number (required, min: 0)
- **stock**: number (required, min: 0, default: 0)
- **imageUrl**: string? (optional, trimmed)
- **isActive**: boolean (default: true)
- **isFootwear**: boolean (default: false, only relevant for Equipment subcategory)
- **isJacket**: boolean (default: false, only relevant for Equipment subcategory)
- **isBottoms**: boolean (default: false, only relevant for Equipment subcategory)
- **totalRedemptions**: number (default: 0)
- **createdAt**: Date (default: Date.now)
- **updatedAt**: Date (default: Date.now)

#### Operations (Methods):
- **create**(createRewardItemDto: CreateRewardItemDto): Promise<RewardItem>
- **findAll**(filters?: RewardItemFilters): Promise<object>
- **findOne**(id: string): Promise<RewardItem>
- **update**(id: string, updateRewardItemDto: UpdateRewardItemDto): Promise<RewardItem>
- **remove**(id: string): Promise<void>
- **toggleActive**(id: string): Promise<RewardItem>
- **updateStock**(id: string, newStock: number): Promise<RewardItem>
- **getStats**(): Promise<object>
- **findByCategory**(category: RewardCategory): Promise<RewardItem[]>
- **findBySubCategory**(subCategory: string): Promise<RewardItem[]>
- **findAvailableForUser**(filters?: object): Promise<RewardItem[]>

#### Relationships:
- **Referenced By**: RewardRedemption.rewardItemId → RewardItem

#### Indexes:
- category: 1, isActive: 1
- subCategory: 1
- pointCost: 1
- createdAt: -1

---

### 10. RewardRedemption
**Collection Name**: rewardredemptions  
**Extends**: Document (Mongoose)  
**Description**: User redemption requests for reward items

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **userId**: string (required, ref: 'User')
- **rewardItemId**: string (required, ref: 'RewardItem')
- **rewardItemName**: string (required)
- **pointsSpent**: number (required, min: 0)
- **status**: RedemptionStatus (required, default: PENDING)
- **deliveryAddress**: object (required, embedded)
  - **street**: string (required)
  - **city**: string (required)
  - **state**: string (required)
  - **zipCode**: string (required)
  - **country**: string (required)
  - **phoneNumber**: string (required)
  - **additionalNotes**: string? (optional)
- **selectedSize**: string? (optional, for wearable items)
- **sizeType**: string? (optional, 'footwear', 'jacket', 'bottoms')
- **trackingNumber**: string? (optional)
- **estimatedDelivery**: Date? (optional)
- **adminNotes**: string? (optional)
- **rejectionReason**: string? (optional)
- **approvedAt**: Date? (optional)
- **processingAt**: Date? (optional)
- **shippedAt**: Date? (optional)
- **deliveredAt**: Date? (optional)
- **rejectedAt**: Date? (optional)
- **cancelledAt**: Date? (optional)
- **createdAt**: Date (default: Date.now)
- **updatedAt**: Date (default: Date.now)

#### Operations (Methods):
- **redeemReward**(createRedemptionDto: CreateRedemptionDto): Promise<RewardRedemption>
- **getUserRedemptions**(userId: string): Promise<RewardRedemption[]>
- **getAllRedemptions**(filters?: object): Promise<object>
- **getRedemptionById**(redemptionId: string): Promise<RewardRedemption>
- **updateRedemptionStatus**(redemptionId: string, status: RedemptionStatus, updateData?: object): Promise<RewardRedemption>
- **cancelRedemption**(redemptionId: string, userId: string): Promise<RewardRedemption>
- **rejectRedemption**(redemptionId: string, reason: string): Promise<RewardRedemption>
- **approveRedemption**(redemptionId: string): Promise<RewardRedemption>
- **awardPointsForCollection**(collectorId: string, dropId: string): Promise<object>
- **awardPointsForDropCollected**(householdId: string, dropId: string): Promise<object>
- **getUserRewardStats**(userId: string): Promise<object>

#### Relationships:
- **userId** → User (Many-to-One)
- **rewardItemId** → RewardItem (Many-to-One)

#### Embedded Classes:
- **DeliveryAddress** (embedded object)

---

### 11. Notification
**Collection Name**: notifications  
**Extends**: Document (Mongoose)  
**Description**: User notifications (stored in database, also sent via WebSocket)

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **userId**: string (required, ref: 'User')
- **type**: NotificationType (required)
- **title**: string (required)
- **message**: string (required)
- **priority**: NotificationPriority (default: MEDIUM)
- **isRead**: boolean (default: false)
- **readAt**: Date? (optional)
- **data**: object? (optional, additional data for specific notification types)
  - **orderId**: string? (optional)
  - **pointsAmount**: number? (optional)
  - **trackingNumber**: string? (optional)
  - **rejectionReason**: string? (optional)
  - **[key: string]**: any (additional dynamic fields)
- **actions**: array? (optional, action buttons for notifications)
  - **label**: string
  - **action**: string
  - **url**: string? (optional)
- **expiresAt**: Date? (optional)
- **createdAt**: Date (default: Date.now)
- **updatedAt**: Date (default: Date.now)

#### Operations (Methods):
- **create**(createNotificationDto: CreateNotificationDto): Promise<Notification>
- **getUserNotifications**(userId: string, filters?: NotificationFiltersDto): Promise<object>
- **markAsRead**(notificationId: string, userId: string): Promise<Notification>
- **markAllAsRead**(userId: string): Promise<object>
- **delete**(notificationId: string, userId: string): Promise<void>
- **deleteAll**(userId: string): Promise<void>
- **getUnreadCount**(userId: string): Promise<number>
- **getNotificationById**(notificationId: string): Promise<Notification>

#### Relationships:
- **userId** → User (Many-to-One)

#### Indexes:
- userId: 1, createdAt: -1
- userId: 1, isRead: 1
- type: 1

---

### 12. SupportTicket
**Collection Name**: supporttickets  
**Extends**: Document (Mongoose)  
**Description**: Customer support tickets

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **userId**: Types.ObjectId (required, ref: 'User')
- **title**: string (required)
- **description**: string (required)
- **category**: TicketCategory (required)
- **priority**: TicketPriority (default: MEDIUM)
- **status**: TicketStatus (default: OPEN)
- **assignedTo**: Types.ObjectId? (optional, ref: 'User', default: null)
- **createdBy**: Types.ObjectId? (optional, ref: 'User', default: null)
- **lastUpdatedBy**: Types.ObjectId? (optional, ref: 'User', default: null)
- **tags**: string[] (array, default: [])
- **attachments**: string[] (array, default: [])
- **internalNotes**: array (default: [])
  - **note**: string
  - **addedBy**: Types.ObjectId
  - **addedAt**: Date
- **messages**: array (default: [])
  - **message**: string
  - **senderId**: Types.ObjectId
  - **senderType**: string (enum: 'user' | 'agent' | 'system')
  - **sentAt**: Date
  - **isInternal**: boolean
- **resolvedAt**: Date? (optional, default: null)
- **closedAt**: Date? (optional, default: null)
- **dueDate**: Date? (optional, default: null)
- **estimatedResolutionTime**: string? (optional, default: null)
- **resolution**: string? (optional, default: null)
- **isEscalated**: boolean (default: false)
- **escalatedTo**: Types.ObjectId? (optional, default: null)
- **escalatedAt**: Date? (optional, default: null)
- **escalatedReason**: string? (optional, default: null)
- **isDeleted**: boolean (default: false)
- **deletedAt**: Date? (optional, default: null)
- **deletedBy**: Types.ObjectId? (optional, default: null)
- **relatedDropId**: Types.ObjectId? (optional, ref: 'Dropoff', default: null)
- **relatedCollectionId**: Types.ObjectId? (optional, ref: 'CollectionAttempt', default: null)
- **relatedApplicationId**: Types.ObjectId? (optional, ref: 'CollectorApplication', default: null)
- **relatedUserId**: Types.ObjectId? (optional, default: null)
- **contextMetadata**: any? (optional, default: null)
- **location**: object? (optional, default: null)
  - **latitude**: number
  - **longitude**: number
  - **address**: string
- **createdAt**: Date (optional, auto-generated)
- **updatedAt**: Date (optional, auto-generated)

#### Operations (Methods):
- **createTicket**(userId: string, title: string, description: string, category: TicketCategory, priority?: TicketPriority, attachments?: string[], contextMetadata?: any, relatedDropId?: string, relatedCollectionId?: string, relatedApplicationId?: string, location?: object): Promise<SupportTicket>
- **getTicketsByUser**(userId: string): Promise<SupportTicket[]>
- **getAllTickets**(status?: TicketStatus, priority?: TicketPriority, category?: TicketCategory, assignedTo?: string, page?: number, limit?: number): Promise<object>
- **getTicketById**(ticketId: string, userId?: string): Promise<SupportTicket>
- **updateTicketStatus**(ticketId: string, status: TicketStatus, updatedBy: string): Promise<SupportTicket>
- **assignTicket**(ticketId: string, assignedTo: string, assignedBy: string): Promise<SupportTicket>
- **addMessage**(ticketId: string, message: string, senderId: string, senderType: 'user' | 'agent' | 'system', isInternal?: boolean): Promise<SupportTicket>
- **addInternalNote**(ticketId: string, note: string, addedBy: string): Promise<SupportTicket>
- **escalateTicket**(ticketId: string, escalatedTo: string, reason: string, escalatedBy: string): Promise<SupportTicket>
- **resolveTicket**(ticketId: string, resolution: string, resolvedBy: string): Promise<SupportTicket>
- **closeTicket**(ticketId: string, closedBy: string): Promise<SupportTicket>
- **deleteTicket**(ticketId: string, deletedBy: string): Promise<void>
- **getTicketStats**(): Promise<object>

#### Relationships:
- **userId** → User (Many-to-One)
- **assignedTo** → User (Many-to-One, optional)
- **createdBy** → User (Many-to-One, optional)
- **lastUpdatedBy** → User (Many-to-One, optional)
- **escalatedTo** → User (Many-to-One, optional)
- **deletedBy** → User (Many-to-One, optional)
- **relatedDropId** → Dropoff (Many-to-One, optional)
- **relatedCollectionId** → CollectionAttempt (Many-to-One, optional)
- **relatedApplicationId** → CollectorApplication (Many-to-One, optional)

---

### 13. TrainingContent
**Collection Name**: trainingcontents  
**Extends**: Document (Mongoose)  
**Description**: Training and educational content for users

#### Fields:
- **id**: string (virtual, auto-generated from _id)
- **title**: string (required)
- **description**: string (required)
- **type**: string (enum: 'video' | 'image' | 'story', required)
- **category**: string (enum: 'getting_started' | 'advanced_features' | 'troubleshooting' | 'best_practices' | 'collector_application' | 'payments' | 'notifications', required)
- **mediaUrl**: string? (optional, for video/image URLs)
- **thumbnailUrl**: string? (optional, for video thumbnails)
- **content**: string? (optional, for text content or story content)
- **tags**: string[] (array, default: [])
- **createdBy**: string (required, User ID who created this content)
- **viewCount**: number (default: 0)
- **createdAt**: Date (optional, auto-generated)
- **updatedAt**: Date (optional, auto-generated)

#### Operations (Methods):
- **create**(createTrainingContentDto: CreateTrainingContentDto, createdBy: string): Promise<TrainingContent>
- **findAll**(params?: object): Promise<object>
- **findOne**(id: string): Promise<TrainingContent>
- **update**(id: string, updateTrainingContentDto: UpdateTrainingContentDto): Promise<TrainingContent>
- **remove**(id: string): Promise<void>
- **incrementViewCount**(id: string): Promise<TrainingContent>
- **getStats**(): Promise<object>
- **getCategories**(): Promise<object[]>
- **getFeaturedContent**(): Promise<TrainingContent[]>
- **getContentByCategory**(category: string): Promise<TrainingContent[]>

#### Relationships:
- **createdBy** → User (Many-to-One, string reference)

---

## Relationships Summary

### One-to-Many Relationships:
1. **User** → **Dropoff** (userId)
2. **User** → **CollectionAttempt** (collectorId)
3. **User** → **CollectorApplication** (userId)
4. **User** → **RewardRedemption** (userId)
5. **User** → **Notification** (userId)
6. **User** → **SupportTicket** (userId, assignedTo, createdBy, lastUpdatedBy, escalatedTo, deletedBy)
7. **User** → **TrainingContent** (createdBy)
8. **Dropoff** → **CollectionAttempt** (dropoffId)
9. **Dropoff** → **DropReport** (dropId)
10. **Dropoff** → **SupportTicket** (relatedDropId)
11. **RewardItem** → **RewardRedemption** (rewardItemId)
12. **CollectionAttempt** → **SupportTicket** (relatedCollectionId)
13. **CollectorApplication** → **SupportTicket** (relatedApplicationId)

### Embedded Relationships:
1. **User** contains **CollectorApplication** (embedded, optional)
2. **CollectionAttempt** contains **TimelineEvent[]** (embedded array)
3. **CollectionAttempt** contains **DropSnapshot** (embedded, required)
4. **RewardRedemption** contains **DeliveryAddress** (embedded object)
5. **Dropoff** contains **cancellationHistory[]** (embedded array)

---

## Class Diagram Structure Instructions

When creating the class diagram, follow these guidelines:

1. **Create separate classes for all enums** and show them as enumeration classes
2. **Show all fields** for each schema class with their types (string, number, boolean, Date, etc.)
3. **Use composition** (filled diamond) for embedded objects/arrays
4. **Use association** (arrow) for references (ref: 'User', ref: 'Dropoff', etc.)
5. **Show cardinality** (1..*, 0..1, etc.) on relationships
6. **Mark required fields** with required indicator or bold text
7. **Mark optional fields** with ? or optional indicator
8. **Group related classes** by package/module if using PlantUML packages
9. **Include embedded classes** (CollectorApplication embedded in User, DropSnapshot, TimelineEvent in CollectionAttempt, DeliveryAddress in RewardRedemption)
10. **Show inheritance** from Document (Mongoose Document) for all main schema classes
11. **Do NOT include CollectorInteraction** - it has been replaced by CollectionAttempt

---

## Key Points for Diagram Creation

- **Embedded vs Standalone**: CollectorApplication appears both as embedded in User and as a standalone collection - show both
- **Virtual Fields**: Include virtual `id` fields in class attributes (they are generated from _id)
- **Array Fields**: Show array types with [] notation (e.g., string[], UserRole[])
- **Object Fields**: For complex embedded objects, you can create separate classes or show as nested structures
- **Timestamps**: Include createdAt and updatedAt fields (auto-generated by Mongoose timestamps)
- **Indexes**: You can optionally show indexes as notes or exclude them from the diagram

---

**Total Collections**: 10 main collections  
**Total Enums**: 14 enums  
**Total Embedded Classes**: 5 embedded classes

