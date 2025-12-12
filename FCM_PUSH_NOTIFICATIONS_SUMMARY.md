# FCM Push Notifications - Detailed Summary

## Overview

**All notifications in Bottleji are sent via FCM (Firebase Cloud Messaging) as push notifications**, with WebSocket as a fallback when FCM fails or the user doesn't have an FCM token.

**Delivery Method:**
1. **PRIMARY:** FCM Push Notification (works even when app is closed)
2. **FALLBACK:** WebSocket (only if FCM fails and user is connected)
3. **STORAGE:** All notifications are saved to database regardless of delivery method

---

## 📋 Complete List of Push Notification Types

### 1. 🏠 Drop Management Notifications

#### 1.1 `drop_accepted`
- **When:** Collector accepts a drop from a household user
- **Sent to:** Household user (drop creator)
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 477)
- **Message:** "A collector has accepted your drop and is on their way"
- **Data includes:**
  - `dropId`
  - `collectorId`
  - `dropTitle`

#### 1.2 `drop_collected`
- **When:** Collector successfully collects a drop
- **Sent to:** Household user (drop creator)
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 614-639)
- **Message:** "Your drop was collected!"
- **Data includes:**
  - `dropId`
  - Points earned (if applicable)

#### 1.3 `drop_collected_with_rewards`
- **When:** Drop collected and household user earned points (no tier upgrade)
- **Sent to:** Household user
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 629)
- **Message:** "Your drop was collected! You earned X points for contributing to recycling."
- **Data includes:**
  - `dropId`
  - `pointsAwarded`
  - `totalPoints`
  - `currentTier`
  - `tierUpgraded: false`

#### 1.4 `drop_collected_with_tier_upgrade`
- **When:** Drop collected and household user upgraded to a new tier
- **Sent to:** Household user
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 614)
- **Message:** "Your drop was collected! You earned X points and reached [Tier Name]!"
- **Data includes:**
  - `dropId`
  - `pointsAwarded`
  - `totalPoints`
  - `newTier`
  - `tierUpgraded: true`

#### 1.5 `drop_cancelled`
- **When:** Collector cancels a drop collection
- **Sent to:** Household user (drop creator)
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 793)
- **Message:** "Drop Cancelled" (with reason)
- **Data includes:**
  - `dropId`
  - `reason`
  - `dropTitle`
  - `cancelledBy`
  - `totalCancellations`

#### 1.6 `drop_expired`
- **When:** Drop collection time expires
- **Sent to:** Household user (drop creator)
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (expiry logic)
- **Message:** "Your drop collection has expired"
- **Data includes:**
  - `dropId`

#### 1.7 `drop_near_expiring`
- **When:** Drop collection time is running low (warning notification)
- **Sent to:** Collector only
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 970)
- **Message:** "You have X minutes remaining to collect this drop"
- **Data includes:**
  - `dropId`
  - `collectorId`
  - `dropTitle`
  - `timeRemainingMinutes`

#### 1.8 `drop_censored`
- **When:** Drop image is censored by admin
- **Sent to:** Household user (drop creator)
- **Priority:** High
- **Location:** `backend/src/modules/admin/drops-management.controller.ts`
- **Message:** "Your drop image was censored"
- **Data includes:**
  - `dropId`
  - `reason`

#### 1.9 `drop_flagged`
- **When:** Drop is flagged due to multiple cancellations
- **Sent to:** Household user (drop creator)
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 826)
- **Message:** "Your drop was flagged due to multiple cancellations. It will be hidden from the map."
- **Data includes:**
  - `dropId`
  - `totalCancellations`
  - `dropTitle`
  - `reason`

---

### 2. 🔒 Account Management Notifications

#### 2.1 `account_locked`
- **When:** Admin locks a user's account
- **Sent to:** User whose account was locked
- **Priority:** **URGENT** (highest priority)
- **Location:** `backend/src/modules/admin/admin.service.ts` (line 540)
- **Message:** "Your account has been locked by an administrator. Reason: [reason]. Your account will be unlocked in 30 days."
- **Data includes:**
  - `isAccountLocked: true`
  - `accountLockedUntil` (ISO date)
  - `warningCount`
  - `reason`

#### 2.2 `account_unlocked`
- **When:** Admin unlocks a user's account
- **Sent to:** User whose account was unlocked
- **Priority:** Medium
- **Location:** `backend/src/modules/admin/admin.service.ts` (line 584)
- **Message:** "Your account has been unlocked by an administrator. You can start collecting again!"
- **Data includes:**
  - `isAccountLocked: false`
  - `accountLockedUntil: null`
  - `warningCount`

#### 2.3 `warnings_reset`
- **When:** Admin resets all warnings for a user
- **Sent to:** User whose warnings were reset
- **Priority:** Medium
- **Location:** `backend/src/modules/admin/admin.service.ts` (line 622)
- **Message:** "All your warnings have been cleared by an administrator. Your account is now clean!"
- **Data includes:**
  - `warningCount: 0`
  - `warnings: []`
  - `isAccountLocked: false`
  - `accountLockedUntil: null`

#### 2.4 `account_restored`
- **When:** Admin restores a deleted account
- **Sent to:** User whose account was restored
- **Priority:** Medium
- **Location:** `backend/src/modules/admin/admin.service.ts` (line 706)
- **Message:** "Your account has been restored by an administrator. You can now log in and use your account again!"
- **Data includes:**
  - `restoredByAdminId`
  - `restoredAt` (ISO date)
  - `isDeleted: false`

#### 2.5 `user_deleted`
- **When:** Admin permanently deletes a user account
- **Sent to:** User whose account was deleted
- **Priority:** High
- **Location:** `backend/src/modules/notifications/notifications.service.ts` (line 214)
- **Message:** "Your account has been deleted by an administrator."
- **Data includes:**
  - Account deletion details

---

### 3. 🎁 Rewards & Orders Notifications

#### 3.1 `order_approved`
- **When:** Admin approves a reward redemption order
- **Sent to:** User who placed the order
- **Priority:** Medium
- **Location:** `backend/src/modules/rewards/rewards.service.ts` (line 973)
- **Message:** "Your order for [item] has been approved and is being prepared for shipment. Tracking: [tracking number]"
- **Data includes:**
  - `orderId`
  - `trackingNumber`
  - `rewardItemName`

#### 3.2 `order_rejected`
- **When:** Admin rejects a reward redemption order
- **Sent to:** User who placed the order
- **Priority:** Medium
- **Location:** `backend/src/modules/rewards/rewards.service.ts` (line 892)
- **Message:** "Your order for [item] was rejected: [reason]. [X] points have been refunded to your account."
- **Data includes:**
  - `orderId`
  - `rejectionReason`
  - `pointsAmount` (refunded)

#### 3.3 `points_earned`
- **When:** Collector earns points for collecting a drop
- **Sent to:** Collector
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 578)
- **Message:** "You earned X points for collecting this drop!"
- **Data includes:**
  - `pointsAwarded`
  - `totalPoints`
  - `currentTier`

#### 3.4 `tier_upgrade`
- **When:** Collector upgrades to a new tier
- **Sent to:** Collector
- **Priority:** Medium
- **Location:** `backend/src/modules/dropoffs/dropoffs.service.ts` (line 564)
- **Message:** "🎉 Tier Upgraded! Congratulations! You've reached [Tier Name]! You now earn X points per drop."
- **Data includes:**
  - `newTier`
  - `totalPoints`
  - `totalDrops`

---

### 4. 📝 Support Ticket Notifications

#### 4.1 `ticket_message`
- **When:** New message is sent in a support ticket (by admin or user)
- **Sent to:** Other party (if admin sends, user gets notified; if user sends, admin gets notified)
- **Priority:** Medium
- **Location:** `backend/src/modules/notifications/notifications.gateway.ts` (line 506)
- **Message:** "You have a new message on your support ticket"
- **Data includes:**
  - `ticketId`
  - `message` (full message object with sender, content, timestamp)

---

### 5. 📋 Application Notifications

#### 5.1 `application_approved`
- **When:** Admin approves a collector application
- **Sent to:** Applicant
- **Priority:** Medium
- **Location:** `backend/src/modules/notifications/notifications.service.ts` (line 249)
- **Message:** "Your collector application has been approved!"
- **Data includes:**
  - Application details

#### 5.2 `application_rejected`
- **When:** Admin rejects a collector application
- **Sent to:** Applicant
- **Priority:** High
- **Location:** `backend/src/modules/notifications/notifications.service.ts` (line 290)
- **Message:** "Your collector application has been rejected."
- **Data includes:**
  - Rejection reason

#### 5.3 `application_reversed`
- **When:** Admin reverses an application decision
- **Sent to:** Applicant
- **Priority:** Medium
- **Location:** `backend/src/modules/notifications/notifications.service.ts` (line 332)
- **Message:** "Your collector application decision has been reversed."
- **Data includes:**
  - Application details

---

### 6. 🧪 Test Notifications

#### 6.1 `test`
- **When:** Admin sends a test notification
- **Sent to:** Any user (for testing purposes)
- **Priority:** Low
- **Location:** `backend/src/modules/notifications/notifications.gateway.ts` (line 135)
- **Message:** "This is a test notification"
- **Data includes:**
  - `test: true`

---

## 📊 Notification Priority Levels

| Priority | Notification Types |
|---------|-------------------|
| **URGENT** | `account_locked` |
| **HIGH** | `account_locked`, `drop_censored`, `application_rejected`, `user_deleted` |
| **MEDIUM** | All other notification types |
| **LOW** | `test` |

---

## 🔄 Delivery Flow

### Step 1: Primary Delivery (FCM)
```
Backend → FCMService.sendNotificationToUser()
  ↓
Firebase Admin SDK
  ↓
FCM/APNs (iOS) or FCM (Android)
  ↓
Device receives push notification
```

### Step 2: Fallback (WebSocket)
```
If FCM fails:
  ↓
Check if user is connected via WebSocket
  ↓
If connected: Send via WebSocket
  ↓
If not connected: Notification saved to database only
```

### Step 3: Storage
```
All notifications are saved to database
  ↓
User sees notification when they open the app
```

---

## 📱 Frontend Handling

All FCM notifications are received by:
- **File:** `botleji/lib/core/services/fcm_service.dart`
- **Handler:** `_handleFCMNotification()` method
- **Routing:** Notifications are routed to `NotificationService.handleNotificationFromFCM()`
- **Display:** Local notifications are shown using `LocalNotificationService`

---

## 🎯 Notification Types NOT Using Push (WebSocket Only)

These are **real-time features** that use WebSocket only (not push notifications):

1. **`typing_indicator`** - Shows when someone is typing in a support ticket
2. **`presence_indicator`** - Shows when admin/user is present in a support ticket
3. **`collector_location_update`** - Real-time collector location updates during collection
4. **`force_logout`** - Forces user logout (immediate action, not a notification)
5. **`admin_ticket_update`** - Broadcasts ticket updates to all admins (real-time)

---

## 📈 Statistics

- **Total Push Notification Types:** 23
- **Drop Management:** 9 types
- **Account Management:** 5 types
- **Rewards & Orders:** 4 types
- **Support Tickets:** 1 type
- **Applications:** 3 types
- **Test:** 1 type

---

## ✅ Summary

**ALL user-facing notifications use FCM push notifications** as the primary delivery method. This ensures users receive notifications even when:
- App is closed
- App is in background
- Device is locked
- User is offline (notification delivered when device comes online)

**WebSocket is only used for:**
- Real-time features (typing indicators, location updates)
- Fallback when FCM fails
- Admin broadcasts

---

**Last Updated:** December 12, 2025
**Status:** ✅ All notification types migrated to FCM

