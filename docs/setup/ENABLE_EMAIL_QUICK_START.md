# Quick Start: Enable Email Service

## Step-by-Step Guide to Enable Email Functionality

### Step 1: Get Gmail App Password

1. **Go to Google Account**
   - Visit: https://myaccount.google.com/
   - Sign in with the Gmail account you want to use

2. **Enable 2-Step Verification** (Required)
   - Go to: https://myaccount.google.com/security
   - Click on **"2-Step Verification"**
   - Follow the setup process if not already enabled

3. **Generate App Password**
   - Go to: https://myaccount.google.com/apppasswords
   - Or: Security → App passwords
   - Select **"Mail"** as the app
   - Select **"Other (Custom name)"** as device
   - Enter name: **"Bottleji Backend"**
   - Click **"Generate"**
   - **Copy the 16-character password** (you'll need this!)

### Step 2: Add Environment Variables to Render

1. **Go to Render Dashboard**
   - Visit: https://dashboard.render.com/
   - Select your backend service (bottleji-api)

2. **Navigate to Environment Tab**
   - Click on your service
   - Go to **"Environment"** tab in the left sidebar

3. **Add Environment Variables**
   Click **"Add Environment Variable"** and add:

   **Variable 1:**
   - Key: `EMAIL_USER`
   - Value: `your-email@gmail.com` (the Gmail address you used)

   **Variable 2:**
   - Key: `EMAIL_PASS`
   - Value: `xxxx xxxx xxxx xxxx` (the 16-character app password from Step 1)

4. **Save Changes**
   - Click **"Save Changes"**
   - Render will automatically redeploy your service

### Step 3: Verify Email Service is Working

1. **Check Render Logs**
   - Go to your service → **"Logs"** tab
   - Look for: `✅ Email service initialized successfully`
   - You should NOT see: `⚠️ Email service disabled`

2. **Test Email Sending**
   - Try signing up a new user
   - Check the email inbox for the OTP code
   - The code should arrive within seconds

### Troubleshooting

#### "Authentication failed" Error
- Make sure you're using an **App Password**, not your regular Gmail password
- Verify 2-Step Verification is enabled
- Regenerate the app password if needed

#### "Connection timeout" Error
- Check if your Gmail account allows "Less secure app access" (usually not needed with App Passwords)
- Verify the app password is correct

#### Still Not Working?
- Check Render logs for specific error messages
- Verify environment variables are set correctly (no extra spaces)
- Make sure the email address matches the one used to generate the app password

---

## Important Notes

- **App Passwords are 16 characters** (may be displayed as 4 groups of 4)
- **Never commit** `EMAIL_PASS` to git (it's already in .gitignore)
- **Use App Password**, not your regular Gmail password
- Render will **automatically redeploy** when you save environment variables

---

## After Setup

Once enabled, users will:
- ✅ Receive OTP codes via email during signup
- ✅ Receive password reset codes via email
- ✅ Receive admin invitation emails

The email service will be fully functional!

