# Referral System Implementation Plan

## Overview
A referral system that allows users to invite friends and earn rewards when their referrals sign up and complete their first activity.

---

## 1. Database Schema Changes

### 1.1 User Schema Updates (`user.schema.ts`)
Add the following fields to the User model:

```typescript
// Referral System Fields
@Prop({ unique: true, sparse: true })
referralCode?: string; // Unique code for each user (e.g., "BOTLEJI-ABC123")

@Prop({ ref: 'User' })
referredBy?: string; // User ID who referred this user

@Prop({ default: 0 })
totalReferrals: number; // Total number of successful referrals

@Prop({ default: 0 })
totalReferralPointsEarned: number; // Total points earned from referrals

@Prop({ type: [Object], default: [] })
referralHistory: Array<{
  referredUserId: string;
  referredUserEmail: string;
  pointsEarned: number;
  earnedAt: Date;
  status: 'pending' | 'completed' | 'cancelled'; // pending until first activity
}>;
```

### 1.2 New Referral Schema (`referral.schema.ts`)
Create a separate collection to track referral events:

```typescript
@Schema({ timestamps: true })
export class Referral extends Document {
  @Prop({ required: true, ref: 'User' })
  referrerId: string; // User who shared the code

  @Prop({ required: true, ref: 'User' })
  referredUserId: string; // User who used the code

  @Prop({ required: true })
  referralCode: string; // The code that was used

  @Prop({ required: true, enum: ['pending', 'completed', 'cancelled'], default: 'pending' })
  status: string;

  @Prop({ default: 0 })
  pointsAwarded: number; // Points awarded to referrer

  @Prop()
  completedAt?: Date; // When the referral was completed (first activity)

  @Prop()
  cancelledAt?: Date; // If referral was cancelled

  @Prop()
  cancelledReason?: string;
}
```

---

## 2. Referral Code Generation

### 2.1 Code Format
- **Format**: `BOTLEJI-{6-8 alphanumeric characters}`
- **Example**: `BOTLEJI-A1B2C3`, `BOTLEJI-XYZ789`
- **Uniqueness**: Must be unique across all users
- **Generation**: Auto-generated on user registration or profile completion

### 2.2 Code Generation Logic
```typescript
// Backend service method
async generateReferralCode(userId: string): Promise<string> {
  let code: string;
  let isUnique = false;
  
  while (!isUnique) {
    // Generate random 6-8 character alphanumeric string
    const randomPart = this.generateRandomString(6);
    code = `BOTLEJI-${randomPart}`;
    
    // Check if code exists
    const existingUser = await this.userModel.findOne({ referralCode: code });
    isUnique = !existingUser;
  }
  
  // Save code to user
  await this.userModel.findByIdAndUpdate(userId, { referralCode: code });
  return code;
}
```

---

## 3. Referral Flow

### 3.1 User Registration with Referral Code
**Flow:**
1. New user registers via `/auth/register`
2. Optional: User enters referral code during registration
3. If code provided:
   - Validate code exists and belongs to an active user
   - Create `Referral` document with status `pending`
   - Link `referredBy` field in new user's profile
4. Generate referral code for new user
5. Send welcome notification

**API Endpoint:**
```
POST /auth/register
Body: {
  email: string,
  password: string,
  referralCode?: string  // Optional
}
```

### 3.2 Referral Completion Trigger
**When does a referral become "completed"?**

**Option A: First Drop Created (Household)**
- When referred user creates their first drop
- Award points to referrer immediately

**Option B: First Drop Collected (Collector)**
- When referred user collects their first drop
- Award points to referrer immediately

**Option C: First Activity (Either Mode)**
- When referred user completes their first activity (drop created OR collected)
- Award points to referrer immediately

**Recommended: Option C** - More inclusive, works for both modes

### 3.3 Points Award Logic
```typescript
async completeReferral(referredUserId: string): Promise<void> {
  // Find referral record
  const referral = await this.referralModel.findOne({
    referredUserId,
    status: 'pending'
  });
  
  if (!referral) return; // No referral found
  
  // Award points to referrer
  const pointsToAward = 500; // Configurable
  
  await this.userModel.findByIdAndUpdate(
    referral.referrerId,
    {
      $inc: {
        currentPoints: pointsToAward,
        totalReferralPointsEarned: pointsToAward,
        totalReferrals: 1
      },
      $push: {
        referralHistory: {
          referredUserId,
          referredUserEmail: referredUser.email,
          pointsEarned: pointsToAward,
          earnedAt: new Date(),
          status: 'completed'
        }
      }
    }
  );
  
  // Update referral status
  await this.referralModel.findByIdAndUpdate(referral._id, {
    status: 'completed',
    pointsAwarded: pointsToAward,
    completedAt: new Date()
  });
  
  // Send notification to referrer
  await this.notificationsService.create({
    userId: referral.referrerId,
    type: 'referral_completed',
    title: 'Referral Reward Earned!',
    message: `You earned ${pointsToAward} points! ${referredUser.email} completed their first activity.`,
    data: {
      pointsEarned: pointsToAward,
      referredUserEmail: referredUser.email
    }
  });
}
```

---

## 4. Backend API Endpoints

### 4.1 Get User's Referral Code
```
GET /api/referrals/my-code
Response: {
  referralCode: string,
  totalReferrals: number,
  totalPointsEarned: number
}
```

### 4.2 Validate Referral Code
```
POST /api/referrals/validate
Body: { code: string }
Response: {
  valid: boolean,
  referrerName?: string  // If valid, show who referred them
}
```

### 4.3 Get Referral Statistics
```
GET /api/referrals/stats
Response: {
  totalReferrals: number,
  completedReferrals: number,
  pendingReferrals: number,
  totalPointsEarned: number,
  referralHistory: Array<{
    referredUserEmail: string,
    pointsEarned: number,
    earnedAt: Date,
    status: string
  }>
}
```

### 4.4 Share Referral Link
```
GET /api/referrals/share-link
Response: {
  referralCode: string,
  shareLink: string,  // e.g., "https://bottleji.com/register?ref=BOTLEJI-ABC123"
  shareMessage: string  // Pre-formatted message for sharing
}
```

---

## 5. Frontend Implementation

### 5.1 Refer and Earn Screen Updates
**Current State:**
- Shows hardcoded referral code `ECO2024`
- Share buttons (WhatsApp, SMS, More) - not implemented

**Updates Needed:**
1. **Fetch Real Referral Code**
   - Call `GET /api/referrals/my-code` on screen load
   - Display user's actual referral code
   - Show loading state while fetching

2. **Referral Statistics Card**
   - Add a new card showing:
     - Total referrals
     - Completed referrals
     - Total points earned from referrals

3. **Share Functionality**
   - **WhatsApp**: Use `url_launcher` package
   - **SMS**: Use `url_launcher` with `sms:` scheme
   - **More**: Use `share_plus` package for native share sheet
   - Pre-format message with referral code and link

4. **Referral History Section**
   - List of referrals with status (pending/completed)
   - Show points earned for each completed referral

### 5.2 Registration Screen Updates
**Add Referral Code Input:**
- Optional text field: "Have a referral code? (Optional)"
- Validate code on blur/change
- Show success/error message
- Pass code to registration API

### 5.3 Profile/Account Screen
**Add Referral Stats:**
- Show total referrals in profile stats
- Link to Refer and Earn screen

---

## 6. Integration Points

### 6.1 Registration Flow
**File:** `backend/src/modules/auth/auth.service.ts`
- Modify `register()` method to:
  1. Accept optional `referralCode` parameter
  2. Validate referral code if provided
  3. Create `Referral` document with status `pending`
  4. Generate referral code for new user

### 6.2 Drop Creation Flow
**File:** `backend/src/modules/dropoffs/dropoffs.service.ts`
- In `create()` method:
  - Check if user has pending referral
  - If yes, call `completeReferral()` after successful drop creation

### 6.3 Drop Collection Flow
**File:** `backend/src/modules/dropoffs/dropoffs.service.ts`
- In `confirmCollection()` method:
  - Check if collector has pending referral
  - If yes, call `completeReferral()` after successful collection

### 6.4 Notification Integration
**File:** `backend/src/modules/notifications/notifications.service.ts`
- Add new notification type: `REFERRAL_COMPLETED`
- Send notification when referral is completed
- Include points earned and referred user info

---

## 7. Admin Dashboard Integration

### 7.1 Referral Statistics
**New Tab/Section:** "Referrals"
- Total referrals across platform
- Top referrers (users with most referrals)
- Referral completion rate
- Points distributed via referrals

### 7.2 Referral Management
- View all referral records
- Filter by status (pending/completed/cancelled)
- Manually complete/cancel referrals (admin override)
- Export referral data

---

## 8. Security & Validation

### 8.1 Code Validation Rules
- Code must exist in database
- Code must belong to an active (non-deleted, non-locked) user
- User cannot use their own referral code
- Code can only be used once per user (prevent duplicate referrals)

### 8.2 Fraud Prevention
- Track IP addresses for referral registrations
- Rate limiting on referral code validation
- Monitor for suspicious patterns (same code used multiple times from same IP)
- Admin alerts for unusual referral activity

### 8.3 Points Award Validation
- Verify referral status is `pending` before awarding
- Ensure referred user actually completed activity (not just created account)
- Prevent duplicate point awards
- Log all point awards for audit trail

---

## 9. Configuration & Settings

### 9.1 Configurable Values
```typescript
// In backend config or environment variables
REFERRAL_POINTS_PER_REFERRAL = 500
REFERRAL_CODE_PREFIX = "BOTLEJI"
REFERRAL_CODE_LENGTH = 6
REFERRAL_COMPLETION_TRIGGER = "first_activity" // or "first_drop_created" or "first_drop_collected"
```

### 9.2 Feature Flags
- Enable/disable referral system
- Enable/disable referral code requirement
- Adjust points per referral
- Set maximum referrals per user (if needed)

---

## 10. Testing Checklist

### 10.1 Backend Tests
- [ ] Referral code generation (uniqueness)
- [ ] Code validation (valid/invalid codes)
- [ ] Registration with referral code
- [ ] Referral completion on first activity
- [ ] Points award to referrer
- [ ] Notification sending
- [ ] Prevent self-referral
- [ ] Prevent duplicate referrals

### 10.2 Frontend Tests
- [ ] Display user's referral code
- [ ] Share functionality (WhatsApp, SMS, More)
- [ ] Referral code input in registration
- [ ] Referral statistics display
- [ ] Referral history list

### 10.3 Integration Tests
- [ ] End-to-end referral flow
- [ ] Points awarded correctly
- [ ] Notifications sent
- [ ] Admin dashboard statistics

---

## 11. Migration Strategy

### 11.1 Existing Users
- Generate referral codes for all existing users
- Run migration script to create codes
- Set `totalReferrals` and `totalReferralPointsEarned` to 0

### 11.2 Migration Script
```typescript
// scripts/database/generate-referral-codes.js
async function generateReferralCodesForExistingUsers() {
  const users = await User.find({ referralCode: { $exists: false } });
  
  for (const user of users) {
    const code = await generateUniqueReferralCode();
    user.referralCode = code;
    await user.save();
  }
}
```

---

## 12. Future Enhancements (Post-MVP)

### 12.1 Tiered Rewards
- More points for multiple referrals (e.g., 500 for 1st, 600 for 2nd, etc.)
- Bonus points milestones (e.g., 1000 bonus at 10 referrals)

### 12.2 Referral Leaderboard
- Public leaderboard of top referrers
- Monthly/quarterly competitions
- Special rewards for top referrers

### 12.3 Referral Analytics
- Track referral sources (WhatsApp, SMS, etc.)
- Conversion rates by source
- Time to completion metrics

### 12.4 Two-Way Rewards
- Give bonus points to referred user on signup
- Give additional points when referred user reaches certain milestones

---

## 13. Implementation Phases

### Phase 1: Backend Foundation (Week 1)
- [ ] Add referral fields to User schema
- [ ] Create Referral schema
- [ ] Implement referral code generation
- [ ] Create referral service
- [ ] Add API endpoints

### Phase 2: Registration Integration (Week 1-2)
- [ ] Update registration endpoint
- [ ] Add referral validation
- [ ] Create referral records
- [ ] Test registration flow

### Phase 3: Completion Logic (Week 2)
- [ ] Integrate with drop creation
- [ ] Integrate with drop collection
- [ ] Implement points award
- [ ] Add notifications

### Phase 4: Frontend Implementation (Week 2-3)
- [ ] Update Refer and Earn screen
- [ ] Add referral code to registration
- [ ] Implement share functionality
- [ ] Add referral statistics

### Phase 5: Admin Dashboard (Week 3)
- [ ] Add referral statistics
- [ ] Create referral management UI
- [ ] Add export functionality

### Phase 6: Testing & Polish (Week 3-4)
- [ ] Comprehensive testing
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] Documentation

---

## 14. Dependencies

### Backend
- No new dependencies needed (using existing Mongoose, NestJS)

### Frontend
- `url_launcher` - For WhatsApp/SMS sharing
- `share_plus` - For native share sheet

---

## 15. Questions to Decide

1. **Referral Completion Trigger**: First activity (either mode) or specific to mode?
2. **Points Amount**: 500 points per referral (configurable)?
3. **Code Format**: `BOTLEJI-XXXXXX` or different format?
4. **Self-Referral**: Should we allow users to refer themselves? (Probably not)
5. **Maximum Referrals**: Should there be a limit per user?
6. **Referral Expiry**: Should referrals expire if not completed within X days?
7. **Admin Override**: Should admins be able to manually complete/cancel referrals?

---

## Summary

This referral system will:
- ✅ Generate unique referral codes for all users
- ✅ Track referrals from registration to completion
- ✅ Award points when referrals complete their first activity
- ✅ Provide sharing functionality (WhatsApp, SMS, native share)
- ✅ Show referral statistics to users
- ✅ Integrate with existing points/rewards system
- ✅ Send notifications for completed referrals
- ✅ Provide admin dashboard for management

**Estimated Development Time**: 3-4 weeks
**Complexity**: Medium
**Impact**: High (user acquisition and engagement)

