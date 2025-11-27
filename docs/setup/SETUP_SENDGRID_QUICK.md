# Quick Setup: SendGrid Email Service

## Why SendGrid?

- ✅ **Works from Render** (no connection timeouts)
- ✅ **Free tier**: 100 emails/day
- ✅ **Designed for applications**
- ✅ **Better deliverability**
- ✅ **Easy setup** (5 minutes)

---

## Step 1: Create SendGrid Account

1. Go to: https://signup.sendgrid.com/
2. Sign up (free account)
3. Verify your email address

---

## Step 2: Create API Key

1. Go to SendGrid Dashboard: https://app.sendgrid.com/
2. Click **"Settings"** → **"API Keys"**
3. Click **"Create API Key"**
4. Name it: **"Bottleji Backend"**
5. Select **"Full Access"** (or at least "Mail Send")
6. Click **"Create & View"**
7. **Copy the API key** (you'll only see it once!)

---

## Step 3: Update Render Environment Variables

1. Go to: https://dashboard.render.com/
2. Select your **`bottleji-api`** service
3. Go to **"Environment"** tab
4. **Update or add** these variables:

   **EMAIL_USER:**
   - Key: `EMAIL_USER`
   - Value: `apikey` (literally the word "apikey")

   **EMAIL_PASS:**
   - Key: `EMAIL_PASS` (or `MAIL_PASS` if that's what you have)
   - Value: `your-sendgrid-api-key-here` (the API key you copied)

5. **Optional** (to explicitly use SendGrid):
   - Key: `SMTP_PROVIDER`
   - Value: `sendgrid`

6. Click **"Save Changes"**
7. Render will automatically redeploy

---

## Step 4: Verify It's Working

After deployment (2-5 minutes), check Render logs:

**Success:**
```
[EmailService] 🔍 Checking email configuration...
[EmailService]    EMAIL_USER/MAIL_USER: ✅ Set
[EmailService]    EMAIL_PASS/MAIL_PASS: ✅ Set
[EmailService] 🔌 Trying SMTP configuration 1/2 (port 587)...
[EmailService] ✅ SMTP connection successful on port 587
[EmailService] ✅ Email service initialized successfully
```

---

## Step 5: Test Email Sending

1. Try signing up a new user
2. Check the email inbox for OTP code
3. Email should arrive within seconds

---

## SendGrid Configuration Summary

**In Render Environment Variables:**
```
EMAIL_USER=apikey
EMAIL_PASS=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

That's it! The code automatically detects SendGrid when `EMAIL_USER=apikey`.

---

## Troubleshooting

### "Authentication failed"
- Make sure `EMAIL_USER=apikey` (exactly "apikey")
- Verify the API key is correct
- Check API key has "Mail Send" permissions

### "Connection timeout"
- SendGrid should work from Render
- If still timing out, check Render network settings
- Try the alternative port (465)

### Emails not arriving
- Check SendGrid dashboard → Activity
- Verify sender email is verified in SendGrid
- Check spam folder

---

## SendGrid Free Tier Limits

- **100 emails/day** (free tier)
- **40,000 emails** for first 30 days
- Perfect for development and small production

---

## That's It!

Once you add the environment variables to Render, the email service will automatically use SendGrid instead of Gmail. No code changes needed - just update the environment variables!

