# Android Phone Sign-In - Database Schema & Data

## What Gets Stored in Database

### Scenario 1: NEW USER (Phone Signup)

**When:** User enters phone number that doesn't exist in database

**API Call:** `POST /auth/phone/signup`
```json
{
  "phoneNumber": "+21612345678",
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

**Backend Processing:**
1. Normalizes phone number: `+21612345678` → `+21612345678` (removes spaces, keeps + and digits)
2. Checks if phone exists → Not found
3. Creates new user record

**Database Record Created:**
```javascript
{
  // Required fields
  "_id": ObjectId("..."),                    // Auto-generated MongoDB ID
  "email": "phone_21612345678@bottleji.temp", // Temporary email (digits from phone)
  "password": "hashed_random_password",       // Random password (bcrypt hashed)
  
  // Phone fields
  "phoneNumber": "+21612345678",             // Normalized phone number
  "isPhoneVerified": true,                    // ✅ Set to true (verified via Firebase)
  "phoneVerificationId": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...", // Firebase token
  
  // Registration tracking
  "registeredWithPhone": true,              // ✅ Marks as phone-registered user
  "isVerified": true,                        // ✅ Account is verified (phone verification counts)
  
  // Profile fields (empty initially)
  "name": null,                              // Will be filled in profile setup
  "address": null,                           // Will be filled in profile setup
  "profilePhoto": null,                      // Optional, can be added later
  
  // Email verification (for when user adds email later)
  "isEmailVerified": false,                 // Email not added yet
  "emailVerificationOTP": null,
  "emailOtpExpiresAt": null,
  "emailOtpAttempts": 0,
  
  // Roles & Permissions
  "roles": ["household"],                    // Default role
  "collectorSubscriptionType": "basic",      // Default subscription
  
  // Profile completion
  "isProfileComplete": false,                // Will be true after profile setup
  
  // Collector application (null for household users)
  "collectorApplication": null,
  "collectorApplicationStatus": null,
  "collectorApplicationId": null,
  "collectorApplicationAppliedAt": null,
  "collectorApplicationReviewedAt": null,
  "collectorApplicationRejectionReason": null,
  
  // Account status
  "isDeleted": false,                        // Soft delete flag
  "deletedAt": null,
  "deletedBy": null,
  "sessionInvalidatedAt": null,
  
  // Account lock (for collectors with warnings)
  "isAccountLocked": false,
  "accountLockedUntil": null,
  "warningCount": 0,
  
  // Password reset (not used for phone users)
  "resetPasswordOtp": null,
  "resetPasswordOtpExpiry": null,
  
  // Phone OTP fields (not used for Firebase auth)
  "phoneVerificationOtp": null,
  "phoneOtpExpiresAt": null,
  "phoneOtpAttempts": 0,
  
  // Email OTP fields (for email/password users, not phone users)
  "verificationOTP": null,
  "otpExpiresAt": null,
  "otpAttempts": 0,
  
  // Admin fields
  "mustChangePassword": false,
  
  // Timestamps
  "createdAt": ISODate("2024-01-15T10:30:00.000Z"),  // Current timestamp
  "updatedAt": ISODate("2024-01-15T10:30:00.000Z")   // Current timestamp
}
```

---

### Scenario 2: EXISTING USER (Phone Login)

**When:** User enters phone number that already exists in database

**API Call:** `POST /auth/phone/login`
```json
{
  "phoneNumber": "+21612345678",
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

**Backend Processing:**
1. Normalizes phone number: `+21612345678` → `+21612345678`
2. Finds existing user by phone number
3. Updates verification fields
4. Returns user data + JWT token

**Database Record Updated:**
```javascript
{
  // Updated fields
  "isPhoneVerified": true,                    // ✅ Updated to true
  "phoneVerificationId": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...", // ✅ Updated with new Firebase token
  "updatedAt": ISODate("2024-01-15T11:45:00.000Z")  // ✅ Updated timestamp
  
  // All other fields remain unchanged
  // (email, password, name, address, roles, etc. stay the same)
}
```

---

## Key Differences: Android vs iOS

### Android (Real Firebase Phone Auth):
- ✅ `isPhoneVerified`: `true` (verified via Firebase)
- ✅ `phoneVerificationId`: Real Firebase JWT token (long string starting with `eyJ...`)
- ✅ `registeredWithPhone`: `true`
- ✅ `isVerified`: `true`

### iOS (Debug Mode - Hardcoded OTP):
- ✅ `isPhoneVerified`: `true` (bypassed verification)
- ✅ `phoneVerificationId`: Debug token like `ios-debug-token-1234567890`
- ✅ `registeredWithPhone`: `true`
- ✅ `isVerified`: `true`

**Result:** Both create the same database structure, only the `phoneVerificationId` format differs.

---

## Phone Number Normalization

**Input Examples:**
- `+216 12 345 678` → `+21612345678`
- `21612345678` → `+21612345678` (if no +, adds it)
- `012345678` → `+21612345678` (if starts with 0, assumes local format)

**Stored in DB:** Always normalized format: `+21612345678`

---

## Temporary Email Format

**Pattern:** `phone_{digits}@bottleji.temp`

**Examples:**
- Phone: `+21612345678` → Email: `phone_21612345678@bottleji.temp`
- Phone: `+491234567890` → Email: `phone_491234567890@bottleji.temp`

**Purpose:**
- Required field (email is unique and required in schema)
- User can add real email in profile setup
- Prevents email/password login (user must use phone login)

---

## Random Password Generation

**Format:** `{random1}{random2}!@#`

**Example:** `a7b9c2d4e5f6!@#`

**Purpose:**
- Required field (password is required in schema)
- User cannot login with this password
- Only used for schema compliance

---

## Profile Setup (After Phone Sign-In)

**When user completes profile setup:**

**API Call:** `POST /auth/setup-profile`
```json
{
  "name": "John Doe",
  "phoneNumber": "+21612345678",  // Already verified, just included
  "address": "123 Main St, Tunis",
  "email": "john@example.com"     // Optional - user can add email
}
```

**Database Record Updated:**
```javascript
{
  "name": "John Doe",                        // ✅ Updated
  "address": "123 Main St, Tunis",           // ✅ Updated
  "email": "phone_21612345678@bottleji.temp", // ✅ Stays same (or updated if user added email)
  "isProfileComplete": true,                 // ✅ Updated to true
  "updatedAt": ISODate("2024-01-15T12:00:00.000Z") // ✅ Updated
}
```

**If user adds email:**
```javascript
{
  "email": "john@example.com",              // ✅ Updated from temp email
  "isEmailVerified": false,                  // Email not verified yet (soft verification)
  "emailVerificationOTP": "123456",         // OTP sent for verification
  "emailOtpExpiresAt": ISODate("2024-01-15T12:15:00.000Z"),
  "emailOtpAttempts": 0
}
```

---

## Complete Example: Full User Journey

### Step 1: Phone Signup (Android)
```javascript
{
  "_id": ObjectId("65a1b2c3d4e5f6g7h8i9j0k1"),
  "email": "phone_21612345678@bottleji.temp",
  "password": "$2b$10$randomHashedPassword...",
  "phoneNumber": "+21612345678",
  "isPhoneVerified": true,
  "phoneVerificationId": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMzQ1Njc4OTA...",
  "registeredWithPhone": true,
  "isVerified": true,
  "name": null,
  "address": null,
  "isProfileComplete": false,
  "roles": ["household"],
  "collectorSubscriptionType": "basic",
  "createdAt": ISODate("2024-01-15T10:30:00.000Z"),
  "updatedAt": ISODate("2024-01-15T10:30:00.000Z")
}
```

### Step 2: Profile Setup
```javascript
{
  // ... same as above, plus:
  "name": "Ahmed Ben Ali",
  "address": "15 Rue de la République, Tunis 1000",
  "isProfileComplete": true,
  "updatedAt": ISODate("2024-01-15T10:35:00.000Z")
}
```

### Step 3: Add Email (Optional)
```javascript
{
  // ... same as above, plus:
  "email": "ahmed.benali@example.com",  // Updated from temp email
  "isEmailVerified": false,             // Not verified yet
  "emailVerificationOTP": "123456",
  "emailOtpExpiresAt": ISODate("2024-01-15T10:40:00.000Z"),
  "updatedAt": ISODate("2024-01-15T10:40:00.000Z")
}
```

### Step 4: Verify Email (Optional)
```javascript
{
  // ... same as above, plus:
  "isEmailVerified": true,              // ✅ Verified
  "emailVerificationOTP": null,           // Cleared after verification
  "emailOtpExpiresAt": null,
  "emailOtpAttempts": 0,
  "updatedAt": ISODate("2024-01-15T10:42:00.000Z")
}
```

---

## Important Notes

### 1. Phone Number Uniqueness
- Phone numbers are normalized before storage
- `+216 12 345 678` and `+21612345678` are treated as the same
- Database enforces uniqueness on normalized phone number

### 2. Email Uniqueness
- Temporary email (`phone_XXX@bottleji.temp`) is unique per phone number
- If user adds real email, it must be unique across all users
- Backend validates email uniqueness before allowing update

### 3. Login Restrictions
- Users with `registeredWithPhone: true` **CANNOT** login with email/password
- They must always use phone + OTP login
- Backend enforces this in `login()` and password reset endpoints

### 4. Firebase Token
- `phoneVerificationId` stores the Firebase JWT token
- Token is updated on each login
- **TODO:** Backend should verify token with Firebase Admin SDK (currently trusts client)

### 5. Profile Completion
- `isProfileComplete: false` until user provides name, phone, and address
- User is redirected to profile setup if incomplete
- After setup, `isProfileComplete: true`

---

## MongoDB Query Examples

### Find all phone-registered users:
```javascript
db.users.find({ "registeredWithPhone": true })
```

### Find user by phone number:
```javascript
db.users.findOne({ "phoneNumber": "+21612345678" })
```

### Find users with verified phone but incomplete profile:
```javascript
db.users.find({ 
  "isPhoneVerified": true, 
  "isProfileComplete": false 
})
```

### Find users who added email but didn't verify:
```javascript
db.users.find({ 
  "registeredWithPhone": true,
  "isEmailVerified": false,
  "email": { $not: { $regex: "@bottleji.temp$" } }
})
```

---

## Summary

**On Android Phone Sign-In:**

1. **New User:** Creates record with:
   - Temporary email: `phone_{digits}@bottleji.temp`
   - Normalized phone: `+21612345678`
   - `isPhoneVerified: true`
   - `phoneVerificationId: {Firebase JWT token}`
   - `registeredWithPhone: true`
   - `isProfileComplete: false`

2. **Existing User:** Updates:
   - `isPhoneVerified: true`
   - `phoneVerificationId: {new Firebase JWT token}`
   - `updatedAt: {current timestamp}`

3. **After Profile Setup:** Updates:
   - `name`, `address`, `isProfileComplete: true`
   - Optionally: `email` (if user adds one)

**All other fields use schema defaults or remain unchanged.**

