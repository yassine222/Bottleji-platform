# SendGrid Single Sender Setup (No Domain Needed)

## ✅ Perfect for You: Single Sender Verification

You **don't need a domain**! SendGrid allows you to verify a single email address instead.

---

## Step-by-Step: Single Sender Setup

### Step 1: Verify Single Sender in SendGrid

1. Go to SendGrid Dashboard: https://app.sendgrid.com/
2. Click **"Settings"** → **"Sender Authentication"**
3. Click **"Verify a Single Sender"**
4. Fill in the form:

   **From Email Address**: 
   - Use your Gmail or any email you own
   - Example: `bottleji.app@gmail.com` or `your-email@gmail.com`
   
   **From Name**: 
   - `Bottleji` (or your app name)
   
   **Reply To**: 
   - Same as From Email (or leave blank)
   
   **Company Address**: 
   - Your address (can be any address)
   
   **City, State, Zip, Country**: 
   - Fill in your location

5. Click **"Create"**

### Step 2: Verify Your Email

1. **Check your email inbox** (the one you entered)
2. You'll receive a verification email from SendGrid
3. **Click the verification link** in the email
4. ✅ **Sender Verified!**

---

## Step 3: Update Render Environment Variables

After verification, add to Render:

1. Go to Render Dashboard → Your Service → Environment
2. Add/Update:

   ```
   EMAIL_USER=apikey
   EMAIL_PASS=your-sendgrid-api-key
   SENDGRID_FROM_EMAIL=your-verified-email@gmail.com
   USE_SENDGRID=true
   ```

   **Important**: `SENDGRID_FROM_EMAIL` must be the **exact email** you verified in SendGrid.

---

## Example Setup

If you verified `bottleji.app@gmail.com`:

**Render Environment Variables:**
```
EMAIL_USER=apikey
EMAIL_PASS=SG.xxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=bottleji.app@gmail.com
USE_SENDGRID=true
```

---

## That's It!

- ✅ No domain needed
- ✅ Works with Gmail or any email
- ✅ Takes 2 minutes
- ✅ Ready to send emails

---

## Benefits of Single Sender

- ✅ **Quick setup** (2 minutes vs hours for domain)
- ✅ **No domain required**
- ✅ **Works immediately**
- ✅ **Perfect for development and small apps**

---

## Limitations

- ⚠️ **Lower sending limits** (but still plenty for most apps)
- ⚠️ **Less professional** than domain (but still works great)
- ⚠️ **Can't use custom domain emails** (must use verified email)

For most apps, single sender is perfect!

---

## Quick Checklist

- [ ] Go to SendGrid → Sender Authentication
- [ ] Click "Verify a Single Sender"
- [ ] Enter your email address
- [ ] Fill in the form
- [ ] Check email and click verification link
- [ ] Add `SENDGRID_FROM_EMAIL` to Render (use verified email)
- [ ] Wait for Render redeployment
- [ ] Test email sending

---

## Troubleshooting

### "Email not verified"
- Check your spam folder for verification email
- Make sure you clicked the verification link
- Try resending verification email from SendGrid

### "Sender not verified" error
- Make sure `SENDGRID_FROM_EMAIL` matches the verified email exactly
- Check for typos in the email address
- Verify the sender is verified in SendGrid dashboard

---

## Recommendation

**Use Single Sender** if:
- ✅ You don't have a domain
- ✅ You're in development/testing
- ✅ You want quick setup
- ✅ You don't need custom domain emails

**Consider Domain Authentication later** if:
- You get a domain in the future
- You need higher sending limits
- You want more professional branding

For now, **Single Sender is perfect!**

