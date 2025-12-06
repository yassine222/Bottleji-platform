# Where Does reCAPTCHA Appear?

## reCAPTCHA Display Location

### **reCAPTCHA appears as a SYSTEM-LEVEL OVERLAY/DIALOG**

reCAPTCHA is **NOT** displayed within your app's UI. Instead, Firebase SDK shows it as a **system-level overlay** that appears **on top of your app**.

---

## Visual Flow

### Step-by-Step User Experience:

#### 1. User is on Phone Login Screen
```
┌─────────────────────────────────┐
│  Phone Login Screen             │
│                                 │
│  [Phone Number Input]           │
│  [+216] [12345678]              │
│                                 │
│  [Send OTP Button]              │
│                                 │
└─────────────────────────────────┘
```

#### 2. User Taps "Send OTP"

#### 3. If Auto-Verification Fails → reCAPTCHA Appears

**reCAPTCHA appears as a FULL-SCREEN OVERLAY:**

```
┌─────────────────────────────────┐
│  🔒 reCAPTCHA Overlay           │
│  (System-level, on top of app)  │
│                                 │
│  ┌─────────────────────────┐   │
│  │  reCAPTCHA Challenge     │   │
│  │                         │   │
│  │  ☐ I'm not a robot      │   │
│  │                         │   │
│  │  [Verify]               │   │
│  └─────────────────────────┘   │
│                                 │
│  (Your app is behind this)      │
└─────────────────────────────────┘
```

#### 4. User Completes reCAPTCHA

#### 5. reCAPTCHA Disappears → SMS Sent

#### 6. User Returns to Phone Login Screen
```
┌─────────────────────────────────┐
│  Phone Login Screen             │
│                                 │
│  [OTP Code Input]               │
│  [1] [2] [3] [4] [5] [6]       │
│                                 │
│  [Verify Code Button]           │
│                                 │
└─────────────────────────────────┘
```

---

## Technical Details

### How Firebase Shows reCAPTCHA:

#### **Android:**
- Firebase SDK opens a **WebView** (in-app browser)
- WebView displays Google's reCAPTCHA page
- WebView appears as a **full-screen overlay** on top of your app
- User interacts with reCAPTCHA in the WebView
- After completion, WebView closes automatically
- Your app continues normally

#### **iOS:**
- Firebase SDK opens **SFSafariViewController** (Safari in-app)
- Safari displays Google's reCAPTCHA page
- Safari appears as a **modal overlay** on top of your app
- User interacts with reCAPTCHA in Safari
- After completion, Safari closes automatically
- Your app continues normally

---

## What You See

### **reCAPTCHA Challenge Types:**

#### Type 1: Simple Checkbox
```
┌─────────────────────────────────┐
│  reCAPTCHA                      │
│                                 │
│  ☐ I'm not a robot              │
│                                 │
│  [Privacy] [Terms]              │
└─────────────────────────────────┘
```
- User clicks checkbox
- Usually completes instantly (if trusted)
- SMS sent immediately

#### Type 2: Image Selection Challenge
```
┌─────────────────────────────────┐
│  reCAPTCHA                      │
│                                 │
│  Select all images with:        │
│  🚦 Traffic lights              │
│                                 │
│  [Image Grid]                   │
│  [ ] [ ] [ ]                    │
│  [ ] [ ] [ ]                    │
│                                 │
│  [Verify]                       │
└─────────────────────────────────┘
```
- User selects matching images
- Takes 10-30 seconds
- SMS sent after completion

---

## Code Behavior

### What Happens in Your Code:

```dart
// User taps "Send OTP"
await PhoneVerificationService.sendSMSVerification(
  phoneNumber: phoneNumber,
  onCodeSent: (verificationId) {
    // This callback is called AFTER reCAPTCHA (if it appeared)
    // OR immediately if no reCAPTCHA was needed
    setState(() {
      _isCodeSent = true;
    });
  },
  onError: (error) {
    // Called if reCAPTCHA fails or other errors
  },
);
```

**Timeline:**
1. `sendSMSVerification()` is called
2. Firebase SDK tries auto-verification
3. **If auto-verification fails:**
   - Firebase SDK **automatically** opens reCAPTCHA overlay
   - User sees reCAPTCHA (you don't control this)
   - User completes reCAPTCHA
   - Firebase SDK closes reCAPTCHA overlay
4. SMS is sent
5. `onCodeSent()` callback is triggered
6. Your app shows OTP input field

**You don't see reCAPTCHA in your code** - Firebase handles it completely!

---

## Visual Examples

### Scenario 1: No reCAPTCHA (Auto-Verification Succeeds)

```
Time: 0s
┌─────────────────────────────────┐
│  Phone Login Screen             │
│  [Send OTP] ← User taps         │
└─────────────────────────────────┘

Time: 1s
┌─────────────────────────────────┐
│  Phone Login Screen             │
│  [Loading...]                   │
└─────────────────────────────────┘

Time: 2s
┌─────────────────────────────────┐
│  Phone Login Screen             │
│  [OTP Code Input] ← SMS sent!   │
└─────────────────────────────────┘
```

**No overlay appears!**

---

### Scenario 2: reCAPTCHA Appears (Auto-Verification Fails)

```
Time: 0s
┌─────────────────────────────────┐
│  Phone Login Screen             │
│  [Send OTP] ← User taps         │
└─────────────────────────────────┘

Time: 1s
┌─────────────────────────────────┐
│  🔒 reCAPTCHA OVERLAY           │
│  (Full-screen, system-level)    │
│                                 │
│  ☐ I'm not a robot              │
│                                 │
│  ← Your app is behind this      │
└─────────────────────────────────┘

Time: 3s (User completes reCAPTCHA)
┌─────────────────────────────────┐
│  🔒 reCAPTCHA OVERLAY           │
│  ✓ Verified!                    │
│  (Closing automatically...)     │
└─────────────────────────────────┘

Time: 4s
┌─────────────────────────────────┐
│  Phone Login Screen             │
│  [OTP Code Input] ← SMS sent!   │
└─────────────────────────────────┘
```

**Overlay appears and disappears automatically!**

---

## Important Notes

### ✅ **You Don't Control reCAPTCHA Display:**

- ❌ You can't customize where it appears
- ❌ You can't change its appearance
- ❌ You can't prevent it from appearing (if Firebase decides it's needed)
- ❌ You can't show it manually

### ✅ **Firebase SDK Handles Everything:**

- ✅ Automatically shows reCAPTCHA when needed
- ✅ Automatically closes reCAPTCHA after completion
- ✅ Automatically sends SMS after reCAPTCHA
- ✅ Your app continues normally after reCAPTCHA

### ✅ **User Experience:**

- User sees reCAPTCHA as a **system overlay** (not part of your app UI)
- User completes reCAPTCHA
- reCAPTCHA disappears
- User returns to your app (OTP input field is shown)

---

## Platform-Specific Behavior

### **Android:**
- reCAPTCHA appears in a **WebView overlay**
- Full-screen overlay
- Google's reCAPTCHA branding visible
- Can be dismissed (but SMS won't be sent)

### **iOS:**
- reCAPTCHA appears in **SFSafariViewController**
- Modal overlay (can swipe down to dismiss)
- Safari-like appearance
- Can be dismissed (but SMS won't be sent)

---

## Testing reCAPTCHA

### To See reCAPTCHA (for testing):

1. **Use an emulator** (always shows reCAPTCHA)
2. **Use debug build** (more likely to show)
3. **Remove SHA fingerprints** from Firebase (forces reCAPTCHA)
4. **First time use** (may show reCAPTCHA)

### To Avoid reCAPTCHA:

1. **Add SHA fingerprints** to Firebase Console ✅
2. **Use release build**
3. **Test on physical device**
4. **Wait after first use** (Firebase learns your app)

---

## Summary

**Where reCAPTCHA appears:**
- ✅ **System-level overlay** (not in your app UI)
- ✅ **Full-screen** on Android (WebView)
- ✅ **Modal overlay** on iOS (Safari)
- ✅ **On top of your app** (your app is behind it)
- ✅ **Automatically shown** by Firebase SDK
- ✅ **Automatically closed** after completion

**You don't need to:**
- ❌ Create UI for reCAPTCHA
- ❌ Handle reCAPTCHA display
- ❌ Manage reCAPTCHA lifecycle

**Firebase SDK does everything automatically!**

---

## Visual Summary

```
Your App UI
    ↓
User taps "Send OTP"
    ↓
Firebase SDK checks auto-verification
    ↓
┌─────────────────────────┐
│  Auto-verification      │
│  succeeds?              │
└─────────────────────────┘
    ↓                    ↓
   YES                  NO
    ↓                    ↓
SMS sent         reCAPTCHA overlay
directly         appears (system-level)
    ↓                    ↓
OTP input        User completes
shown            reCAPTCHA
                 ↓
                 Overlay closes
                 ↓
                 SMS sent
                 ↓
                 OTP input shown
```

---

**Bottom Line:** reCAPTCHA appears as a **system-level overlay** that Firebase SDK shows automatically when needed. You don't control it, and it appears **on top of your app**, not within your app's UI.

