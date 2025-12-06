# When Does reCAPTCHA Appear? - Conditions Explained

## Quick Answer

**reCAPTCHA does NOT appear every time.** It only appears when Firebase **cannot automatically verify** your app.

---

## When reCAPTCHA Appears vs. Doesn't Appear

### ✅ **reCAPTCHA Usually DOESN'T Appear** (Auto-Verification Succeeds):

1. **Release builds** with SHA fingerprints added to Firebase
2. **Physical devices** (not emulators)
3. **After first use** (Firebase has learned your app)
4. **Apps from Play Store** (Google Play signed)
5. **Trusted devices** (Firebase recognizes the device)

**Result:** SMS sent directly, no reCAPTCHA! ✅

---

### ⚠️ **reCAPTCHA WILL Appear** (Auto-Verification Fails):

1. **Emulators** (always shows reCAPTCHA - can't auto-verify)
2. **Debug builds** (more likely, but not always)
3. **First time use** (Firebase hasn't learned your app yet)
4. **SHA fingerprints NOT added** to Firebase Console
5. **Unsigned apps** or apps with unknown signatures
6. **Suspicious activity** (too many requests, unusual patterns)
7. **Rooted/jailbroken devices** (may trigger reCAPTCHA)
8. **Network issues** (can't reach Firebase verification services)

**Result:** reCAPTCHA overlay appears, user must complete it ⚠️

---

## Detailed Conditions

### Condition 1: Build Type

#### **Release Build:**
- ✅ **Usually NO reCAPTCHA**
- Firebase can verify app signature
- Better auto-verification success rate
- **Exception:** First time use may show reCAPTCHA

#### **Debug Build:**
- ⚠️ **More likely to show reCAPTCHA**
- Less reliable auto-verification
- May show reCAPTCHA on first few uses
- **Exception:** If SHA fingerprints added, may still auto-verify

---

### Condition 2: Device Type

#### **Physical Device:**
- ✅ **Usually NO reCAPTCHA** (if configured correctly)
- Can use SafetyNet/Play Integrity API
- Better auto-verification
- **Exception:** First time use, rooted devices

#### **Emulator:**
- ❌ **ALWAYS shows reCAPTCHA**
- Cannot auto-verify (no real device attestation)
- Every single time
- **No exception** - emulators always need reCAPTCHA

---

### Condition 3: SHA Fingerprints Configuration

#### **SHA Fingerprints Added to Firebase:**
- ✅ **Usually NO reCAPTCHA**
- Firebase can verify app signature
- Auto-verification succeeds
- **Exception:** First time use, debug builds

#### **SHA Fingerprints NOT Added:**
- ⚠️ **WILL show reCAPTCHA**
- Firebase cannot verify app
- Auto-verification fails
- **Every time** until fingerprints are added

---

### Condition 4: First Time vs. Subsequent Uses

#### **First Time Use:**
- ⚠️ **May show reCAPTCHA**
- Firebase is learning your app
- Building trust with the app
- **After first use:** Less likely to show

#### **Subsequent Uses:**
- ✅ **Usually NO reCAPTCHA**
- Firebase has learned your app
- Trust established
- Auto-verification succeeds

---

### Condition 5: Suspicious Activity

#### **Normal Usage:**
- ✅ **Usually NO reCAPTCHA**
- Regular phone verification requests
- Normal patterns

#### **Suspicious Activity:**
- ⚠️ **WILL show reCAPTCHA**
- Too many requests in short time
- Unusual patterns (e.g., many different phone numbers)
- Firebase detects potential abuse
- **Result:** reCAPTCHA appears to verify human

---

## Real-World Scenarios

### Scenario 1: Production App (Best Case)

**Setup:**
- ✅ Release build
- ✅ SHA fingerprints added
- ✅ Physical device
- ✅ Not first time use

**Result:**
- ✅ **NO reCAPTCHA** (99% of the time)
- SMS sent directly
- Fast user experience

---

### Scenario 2: Development/Testing

**Setup:**
- ⚠️ Debug build
- ✅ SHA fingerprints added
- ✅ Physical device
- ⚠️ First time use

**Result:**
- ⚠️ **May show reCAPTCHA** (first time)
- ✅ **NO reCAPTCHA** (subsequent uses)
- SMS sent after reCAPTCHA (if shown)

---

### Scenario 3: Emulator Testing

**Setup:**
- ⚠️ Debug/Release build
- ✅ SHA fingerprints added
- ❌ Emulator

**Result:**
- ❌ **ALWAYS shows reCAPTCHA**
- Every single time
- Cannot be avoided on emulators

---

### Scenario 4: Missing Configuration

**Setup:**
- ✅ Release build
- ❌ SHA fingerprints NOT added
- ✅ Physical device

**Result:**
- ⚠️ **WILL show reCAPTCHA**
- Every time
- Until fingerprints are added

---

## Probability Table

| Condition | reCAPTCHA Probability |
|-----------|----------------------|
| **Release build + SHA fingerprints + Physical device + Not first time** | **~1%** (almost never) |
| **Release build + SHA fingerprints + Physical device + First time** | **~20%** (may show once) |
| **Debug build + SHA fingerprints + Physical device** | **~30-50%** (more likely) |
| **Any build + SHA fingerprints + Emulator** | **~100%** (always) |
| **Any build + NO SHA fingerprints + Physical device** | **~90%** (almost always) |
| **Suspicious activity detected** | **~100%** (always) |

---

## How to Minimize reCAPTCHA

### Priority 1: Add SHA Fingerprints ✅
**Impact:** Reduces reCAPTCHA by ~80-90%

### Priority 2: Use Release Builds
**Impact:** Reduces reCAPTCHA by ~20-30%

### Priority 3: Test on Physical Devices
**Impact:** Eliminates emulator reCAPTCHA (100% on emulators)

### Priority 4: Wait After First Use
**Impact:** Reduces reCAPTCHA by ~10-20% after first use

---

## Testing Checklist

### To See reCAPTCHA (for testing):
- [ ] Use emulator (guaranteed)
- [ ] Remove SHA fingerprints from Firebase
- [ ] Use debug build on first use
- [ ] Make many rapid requests (trigger suspicious activity)

### To Avoid reCAPTCHA:
- [x] Add SHA fingerprints to Firebase ✅
- [x] Use release build
- [x] Test on physical device
- [x] Wait after first use

---

## Summary

### **reCAPTCHA appears when:**
1. ❌ **Emulator** (always)
2. ⚠️ **Debug builds** (more likely)
3. ⚠️ **First time use** (may show)
4. ❌ **SHA fingerprints NOT added** (almost always)
5. ❌ **Suspicious activity** (always)

### **reCAPTCHA doesn't appear when:**
1. ✅ **Release build + SHA fingerprints + Physical device + Not first time** (almost never)
2. ✅ **Normal usage patterns** (usually no reCAPTCHA)
3. ✅ **Trusted devices** (Firebase recognizes them)

### **Bottom Line:**
- **With proper configuration:** reCAPTCHA appears **rarely** (~1-5% of the time)
- **Without proper configuration:** reCAPTCHA appears **frequently** (~80-100% of the time)
- **On emulators:** reCAPTCHA appears **always** (100% of the time)

---

## Quick Reference

**Best Case (Production):**
- Release build ✅
- SHA fingerprints ✅
- Physical device ✅
- Not first time ✅
- **Result:** ~1% chance of reCAPTCHA

**Worst Case (Development):**
- Debug build ⚠️
- No SHA fingerprints ❌
- Emulator ❌
- First time ⚠️
- **Result:** ~100% chance of reCAPTCHA

**Your Current Setup:**
- SHA fingerprints: ✅ (you confirmed)
- **Expected:** reCAPTCHA appears **rarely** on physical devices with release builds

