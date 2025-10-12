# 🔒 Account Lock System - Complete Documentation

## Overview
Automatic account locking system for collectors who accumulate 5 timeout warnings. Locks account for 24 hours and auto-unlocks after the period expires.

---

## 🎯 How It Works

### **Warning Accumulation:**
1. Collector accepts a drop → CollectionAttempt created
2. Collection timer expires (1 minute in testing, configurable) → Attempt marked as 'expired'
3. Warning automatically added to collector's account
4. Warning count incremented
5. **At 5 warnings** → Account automatically locked for 24 hours

### **Account Lock Behavior:**
- ✅ User can still login
- ✅ User can browse drops and use app features
- ❌ User **CANNOT** accept new drops
- ✅ Lock card displays in center of drops screens
- ✅ Lock persists across logout/login
- ✅ Auto-unlocks after 24 hours

### **Auto-Unlock Process:**
1. **On Login**: Check if `accountLockedUntil` has passed → auto-unlock
2. **Scheduled Task**: Runs every minute → checks all locked accounts → unlocks expired ones
3. **Welcome Card**: Shows when user opens app after being unlocked

---

## 📱 Frontend Components

### **Lock Notification Card** (`account_lock_card.dart`)
- Shows lock status with countdown timer
- Displays unlock time
- Explains why account is locked
- Can be dismissed but restriction persists
- Positioned in center of drops screens

### **Welcome Back Card** (`welcome_back_card.dart`)
- Shows when account is unlocked
- Celebration UI with success message
- Reminder to complete collections on time
- "Start Collecting" button to dismiss

### **User Model Updates** (`user_data.dart`)
```dart
// New fields
final bool isAccountLocked;
final DateTime? accountLockedUntil;
final int warningCount;

// Helper getters
bool get isCurrentlyLocked;  // Checks if lock hasn't expired yet
bool get wasRecentlyUnlocked;  // Detects if unlocked in last hour
```

### **Lock Checks in Drop Acceptance:**
- `drops_list_screen.dart` - Blocks accept button
- `drops_map_screen.dart` - Blocks accept button
- Shows snackbar: "Account temporarily locked until [time]"

---

## 🔧 Backend Implementation

### **Lock Trigger** (`dropoffs.service.ts`)
```typescript
// In addCollectorPenalty() method
isAccountLocked: collector.warningCount + 1 >= 5,
accountLockedUntil: collector.warningCount + 1 >= 5 
  ? new Date(Date.now() + 24 * 60 * 60 * 1000)  // 24 hours
  : undefined
```

### **Auto-Unlock on Login** (`auth.service.ts`)
```typescript
// In login() method
if (user.isAccountLocked && user.accountLockedUntil) {
  const now = new Date();
  if (now >= user.accountLockedUntil) {
    await this.usersService.unlockAccount(user.id);
  }
}
```

### **Scheduled Auto-Unlock** (`dropoffs.service.ts`)
```typescript
// Runs every minute
private async checkAndUnlockExpiredAccounts() {
  const expiredLocks = await this.userModel.find({
    isAccountLocked: true,
    accountLockedUntil: { $lte: new Date() }
  });
  
  for (const user of expiredLocks) {
    await unlockAccount(user._id);
    // Send push notification (TODO)
  }
}
```

### **Unlock Method** (`users.service.ts`)
```typescript
async unlockAccount(userId: string): Promise<User> {
  return this.userModel.findByIdAndUpdate(
    userId,
    {
      isAccountLocked: false,
      accountLockedUntil: null,
    },
    { new: true }
  );
}
```

---

## 🔄 Complete Flow

### **Scenario 1: User Gets 5th Warning**
```
1. Collection expires (5th time)
2. Backend:
   - Creates 'expired' outcome in CollectionAttempt
   - Calls addCollectorPenalty()
   - Increments warningCount to 5
   - Sets isAccountLocked = true
   - Sets accountLockedUntil = now + 24 hours
3. Frontend:
   - User's next API call gets updated user data
   - Detects isCurrentlyLocked = true
   - Shows lock card overlay
   - Disables all "Accept Drop" buttons
```

### **Scenario 2: User Tries to Accept Drop While Locked**
```
1. User clicks "Accept Drop"
2. Flutter checks user.isCurrentlyLocked
3. If locked:
   - Shows snackbar: "Account locked until [time]"
   - Returns early (doesn't call API)
   - Drop remains unaccepted
```

### **Scenario 3: Lock Expires - User Logs In**
```
1. User logs in
2. Backend login():
   - Checks accountLockedUntil
   - Sees it's in the past
   - Calls unlockAccount()
   - Returns updated user data with isAccountLocked = false
3. Frontend:
   - Receives unlocked user data
   - user.wasRecentlyUnlocked = true
   - Shows WelcomeBackCard overlay
   - User can now accept drops again
```

### **Scenario 4: Lock Expires - User Already Logged In**
```
1. Scheduled task runs (every minute)
2. Backend finds expired locks
3. Auto-unlocks accounts
4. User's next API call returns updated data
5. Frontend detects wasRecentlyUnlocked
6. Shows WelcomeBackCard
7. User can accept drops again
```

---

## ⏱️ Timing Configuration

### **Testing Mode** (Current):
- Collection timeout: **1 minute**
- Cleanup task interval: **1 minute**
- Account lock duration: **24 hours**

### **Production Mode** (TODO):
- Collection timeout: **Configurable** (e.g., 30-60 minutes)
- Cleanup task interval: **10 minutes**
- Account lock duration: **24 hours**

---

## 🚧 TODO / Future Enhancements

1. **Push Notifications**:
   - Requires FCM token storage
   - Send when account gets locked
   - Send when account gets unlocked
   - Currently just logged to console

2. **Email Notifications**:
   - Send email when locked
   - Send email when unlocked
   - Include warning count and tips

3. **Warning Reset**:
   - Manual reset by admin (already in UI)
   - Auto-reset after X successful collections
   - Grace period for first-time collectors

4. **Lock Duration Customization**:
   - Configurable lock duration (24h, 48h, 7 days)
   - Progressive penalties (1st lock: 24h, 2nd lock: 48h, etc.)

---

## 📊 Database Fields

### **User Schema:**
```typescript
warningCount: number;          // 0-5
isAccountLocked: boolean;      // true when warningCount >= 5
accountLockedUntil: Date;      // unlock timestamp (now + 24 hours)
warnings: [                    // Array of warning objects
  {
    type: 'TIMEOUT_WARNING',
    reason: 'Collection expired',
    timestamp: Date,
    dropoffId: ObjectId
  }
]
```

---

## ✅ Implementation Status

- ✅ Backend warning system
- ✅ Auto-lock at 5 warnings
- ✅ Lock UI cards (lock & welcome back)
- ✅ Prevent drop acceptance when locked
- ✅ Auto-unlock on login
- ✅ Scheduled auto-unlock check
- ✅ Lock fields in login response
- ⏳ Push notifications (logged, not sent)
- ✅ Welcome card shown after unlock

---

## 🧪 Testing

1. **Test Lock Trigger:**
   - Accept a drop
   - Let it expire (wait 1 minute in testing mode)
   - Repeat 5 times
   - Account should be locked

2. **Test Lock Persistence:**
   - Get locked
   - Logout and login again
   - Should still be locked

3. **Test Auto-Unlock:**
   - Manually set accountLockedUntil to past time in database
   - Login or wait for cleanup task
   - Should auto-unlock

4. **Test UI:**
   - Locked: Should see lock card, disabled accept buttons
   - Unlocked: Should see welcome card on next app open

---

**Implementation Date**: October 12, 2025  
**System Version**: CollectionAttempt v2.0

