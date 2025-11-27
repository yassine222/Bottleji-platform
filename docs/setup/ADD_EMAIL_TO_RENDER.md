# Add Email Credentials to Render

## ⚠️ Important: .env Files Are Local Only

Your `.env` file is **NOT deployed** to Render. It only works locally on your computer.

**You MUST add environment variables in Render dashboard separately.**

---

## Step-by-Step: Add Email to Render

### Step 1: Go to Render Dashboard

1. Visit: https://dashboard.render.com/
2. Sign in to your account
3. Click on your **`bottleji-api`** service

### Step 2: Go to Environment Tab

1. In your service page, click **"Environment"** in the left sidebar
2. You'll see a list of existing environment variables

### Step 3: Add EMAIL_USER

1. Click **"Add Environment Variable"** button
2. **Key**: `EMAIL_USER`
3. **Value**: Your Gmail address (e.g., `your-email@gmail.com`)
4. Click **"Save Changes"**

### Step 4: Add EMAIL_PASS

1. Click **"Add Environment Variable"** again
2. **Key**: `EMAIL_PASS`
3. **Value**: Your Gmail App Password (e.g., `ojwi qbpy kbcs zplx`)
   - **Important**: You can include or remove spaces - both work
   - Example: `ojwi qbpy kbcs zplx` or `ojw qbpykbcs zplx` both work
4. Click **"Save Changes"**

### Step 5: Wait for Redeployment

- Render will **automatically redeploy** when you save
- Wait 2-5 minutes for deployment to complete
- Check the **"Logs"** tab to see deployment progress

### Step 6: Verify It's Working

After deployment, check the logs. You should see:

```
[EmailService] 🔍 Checking email configuration...
[EmailService]    EMAIL_USER: ✅ Set
[EmailService]    EMAIL_PASS: ✅ Set
[EmailService] ✅ Email service initialized successfully
```

Instead of:

```
[EmailService]    EMAIL_USER: ❌ Missing
[EmailService]    EMAIL_PASS: ❌ Missing
```

---

## Visual Guide

```
Render Dashboard
  └── Your Service (bottleji-api)
      └── Environment Tab
          ├── Add Environment Variable
          │   ├── Key: EMAIL_USER
          │   └── Value: your-email@gmail.com
          └── Add Environment Variable
              ├── Key: EMAIL_PASS
              └── Value: ojwi qbpy kbcs zplx
```

---

## Common Mistakes

### ❌ Wrong: Only adding to .env file
- `.env` files are **local only**
- They don't get deployed to Render
- Render can't see your local `.env` file

### ✅ Correct: Adding to Render Environment Variables
- Add variables in Render dashboard
- They're available to your deployed app
- They persist across deployments

---

## Your Current Values

Based on your `.env` file:
- **EMAIL_USER**: (check your .env file for the email)
- **EMAIL_PASS**: `ojwi qbpy kbcs zplx`

**Add these exact values to Render Environment Variables.**

---

## After Adding to Render

1. ✅ Render automatically redeploys
2. ✅ Email service will detect the variables
3. ✅ OTP emails will start working
4. ✅ No code changes needed

---

## Quick Checklist

- [ ] Go to Render Dashboard
- [ ] Select `bottleji-api` service
- [ ] Go to "Environment" tab
- [ ] Add `EMAIL_USER` with your Gmail address
- [ ] Add `EMAIL_PASS` with `ojwi qbpy kbcs zplx`
- [ ] Save changes
- [ ] Wait for redeployment (2-5 minutes)
- [ ] Check logs to verify it's working

---

## Need Help?

If you still see "Missing" after adding to Render:
1. Check for typos in variable names (case-sensitive)
2. Make sure there are no extra spaces
3. Verify you saved the changes
4. Wait for redeployment to complete
5. Check Render logs for any errors

