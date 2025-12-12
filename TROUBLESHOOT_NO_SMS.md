# Troubleshooting: No SMS Received

## The reCAPTCHA Error is Fixed! ✅

Great news - the reCAPTCHA SDK error is gone, which means:
- ✅ reCAPTCHA Enterprise SDK is properly linked
- ✅ Firebase Phone Auth is working
- ✅ App verification is successful

## But SMS Not Arriving

If you're not receiving SMS, check these:

---

## Step 1: Check Flutter Console Logs

Look for these messages in your Flutter console:

### ✅ **If you see this:**
```
✅ PhoneVerificationService: SMS code sent successfully!
✅ PhoneVerificationService: VerificationId: ...
```
**Meaning:** Firebase successfully sent the SMS. The issue is with SMS delivery, not your app.

### ❌ **If you see this:**
```
❌ PhoneVerificationService: Verification failed!
❌ PhoneVerificationService: Error code: ...
```
**Meaning:** There's an error preventing SMS from being sent. Check the error code.

---

## Step 2: Common Issues

### Issue 1: SMS Quota Exceeded

**Check Firebase Console:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: **botleji**
3. Go to **Usage and Billing** → **Authentication**
4. Check **SMS quota** - is it exceeded?

**Solution:**
- Free tier has limited SMS per day
- Upgrade to Blaze plan for more SMS
- Or wait until quota resets

### Issue 2: Invalid Phone Number Format

**Check logs:**
- Look for: `❌ PhoneVerificationService: Phone number format is invalid`
- Verify phone number includes country code: `+49XXXXXXXXXX` (for Germany)

**Solution:**
- Ensure phone number starts with `+`
- Include country code (e.g., `+49` for Germany)
- Remove spaces, dashes, parentheses

### Issue 3: Too Many Requests (Rate Limited)

**Check logs:**
- Look for: `❌ PhoneVerificationService: Rate limit exceeded`

**Solution:**
- Wait 1-2 minutes before trying again
- Firebase limits requests per phone number

### Issue 4: Carrier Blocking SMS

**Possible causes:**
- Carrier blocking short codes
- International SMS blocked
- Spam filters

**Solution:**
- Check phone settings for blocked numbers
- Try from a different carrier/phone
- Check if other SMS messages work

### Issue 5: Silent Push Notification Failed

**For iOS:**
- Firebase first tries silent push notification
- If that fails, it should fall back to reCAPTCHA
- If reCAPTCHA also fails, SMS won't be sent

**Check:**
- Is Background App Refresh enabled?
- Is the app running on a physical device?
- Are APNs properly configured?

---

## Step 3: Check Firebase Console

### Check Authentication Logs:

1. **Firebase Console:**
   - Authentication → **Users** tab
   - Look for any error messages
   - Check if phone number appears in logs

### Check SMS Delivery Status:

1. **Firebase Console:**
   - Go to **Usage and Billing** → **Authentication**
   - Check **SMS sent** count
   - See if SMS was actually sent

### Check Phone Sign-in Settings:

1. **Firebase Console:**
   - Authentication → Sign-in method → Phone
   - Verify Phone sign-in is **enabled**
   - Check for any restrictions

---

## Step 4: Test with Test Phone Number

While troubleshooting, use Firebase test phone numbers:

1. **Firebase Console:**
   - Authentication → Sign-in method → Phone
   - Scroll to **"Phone numbers for testing"**
   - Add: `+1 650-555-3434` with code `123456`

2. **Test in app:**
   - Use: `+16505553434`
   - Code: `123456`
   - This bypasses SMS delivery entirely

---

## Step 5: Verify Phone Number Format

**For German numbers:**
- ✅ Correct: `+491234567890` (11 digits after +49)
- ❌ Wrong: `01234567890` (missing country code)
- ❌ Wrong: `491234567890` (missing +)

**Check logs:**
- Look for: `📱 PhoneLoginScreen: Final phone number being sent: +49...`
- Verify it starts with `+49` and has correct length

---

## Step 6: Check What Callback Was Called

### If `codeSent` was called:
- ✅ Firebase sent the SMS
- ⚠️ Issue is with SMS delivery (carrier, spam filter, etc.)

### If `verificationFailed` was called:
- ❌ Firebase couldn't send SMS
- Check the error code in logs

### If `codeAutoRetrievalTimeout` was called:
- ⚠️ SMS might have been sent but not received
- Try entering code manually

---

## Quick Checklist

- [ ] Check Flutter console for error messages
- [ ] Verify phone number format (starts with +, includes country code)
- [ ] Check Firebase Console → Usage and Billing for SMS quota
- [ ] Check Firebase Console → Authentication → Users for errors
- [ ] Try test phone number to verify app works
- [ ] Check if Background App Refresh is enabled (iOS)
- [ ] Verify APNs is configured (for silent push)
- [ ] Wait 1-2 minutes and try again (rate limiting)

---

## Most Common Causes

1. **SMS Quota Exceeded** (free tier limit)
2. **Invalid Phone Number Format** (missing country code)
3. **Rate Limiting** (too many requests)
4. **Carrier Blocking** (spam filters)

Check the logs first to see which one applies! 🔍

