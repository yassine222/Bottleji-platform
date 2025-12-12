# Fix: Account Lock Notification Not Working

## Problem
When admin locks a user from the admin dashboard, the user doesn't receive a notification.

## Root Cause
The `banUser` method in `admin.service.ts` was **NOT sending a notification** when locking a user. It only updated the database.

## Solution
Added notification sending to the `banUser` method, similar to how `unbanUser` works.

## Changes Made

### Backend: `admin.service.ts`

**Before:**
```typescript
async banUser(userId: string, reason: string) {
  return await this.userModel.findByIdAndUpdate(
    userId,
    { 
      isAccountLocked: true,
      accountLockedUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      warnings: [{ reason, date: new Date() }],
    },
    { new: true }
  ).select('-password');
}
```

**After:**
```typescript
async banUser(userId: string, reason: string) {
  const user = await this.userModel.findByIdAndUpdate(...);
  
  if (user) {
    // Send notification via FCM
    await this.notificationsGateway.sendNotificationToUser(normalizedUserId, {
      type: 'account_locked',
      title: 'Account Locked',
      message: lockMessage,
      data: {
        isAccountLocked: true,
        accountLockedUntil: user.accountLockedUntil?.toISOString() || null,
        warningCount: user.warningCount || 0,
        reason: reason,
      },
      timestamp: new Date(),
    });
  }
  
  return user;
}
```

## How It Works Now

1. **Admin locks user** → `banUser()` is called
2. **Database updated** → User's `isAccountLocked` set to `true`
3. **FCM notification sent** → Uses `notificationsGateway.sendNotificationToUser()`
4. **User receives notification** → Even if app is closed (FCM works in background)
5. **Frontend handles it** → Shows notification and updates UI

## Notification Flow

```
Admin Dashboard → banUser() → notificationsGateway.sendNotificationToUser()
  → FCM Service → Firebase → User's Device → FCMService → NotificationService
  → Shows notification + updates UI
```

## Testing

1. **Lock a user from admin dashboard**
2. **Check user's device** - should receive notification
3. **Check app** - should show lock status and notification
4. **Check logs** - should see:
   - `🔒 Admin manually locked account: [userId]`
   - `✅ Lock notification sent to user [userId]`
   - `✅ FCM notification sent successfully`

## What's Fixed

✅ **Account lock notifications now work**
✅ **Uses FCM (works even when app is closed)**
✅ **Falls back to WebSocket if FCM fails**
✅ **Includes lock reason in notification**
✅ **Includes lock duration information**

---

**The notification should now work when admin locks a user!** 🎉

