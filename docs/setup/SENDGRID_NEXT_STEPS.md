# SendGrid Setup - Next Steps

## After Creating Single Sender

### Step 1: Verify Your Email ✅

1. **Check your email inbox** (the one you used as "From Email Address")
2. Look for an email from **SendGrid** with subject like "Verify your sender identity"
3. **Click the verification link** in the email
4. You'll be redirected to SendGrid - should see "✅ Verified" or similar

**If you don't see the email:**
- Check spam/junk folder
- Wait a few minutes (can take 1-5 minutes)
- Check SendGrid dashboard → Sender Authentication → see if you can resend verification

---

### Step 2: Get SendGrid API Key 🔑

1. Go to SendGrid Dashboard: https://app.sendgrid.com/
2. Click **"Settings"** → **"API Keys"** (in left sidebar)
3. Click **"Create API Key"** button
4. Fill in:
   - **API Key Name**: `Bottleji Backend` (or any name)
   - **API Key Permissions**: Select **"Full Access"** (or at least "Mail Send")
5. Click **"Create & View"**
6. **COPY THE API KEY** - you'll only see it once!
   - It looks like: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Save it somewhere safe

---

### Step 3: Add to Render Environment Variables 🌐

1. Go to Render Dashboard: https://dashboard.render.com/
2. Click on your **`bottleji-api`** service
3. Go to **"Environment"** tab (left sidebar)
4. Add/Update these environment variables:

   **Variable 1:**
   - Key: `EMAIL_USER`
   - Value: `apikey` (literally the word "apikey")

   **Variable 2:**
   - Key: `EMAIL_PASS` (or `MAIL_PASS` if that's what you have)
   - Value: `SG.xxxxxxxxxxxxx` (your SendGrid API key from Step 2)

   **Variable 3:**
   - Key: `SENDGRID_FROM_EMAIL`
   - Value: `your-verified-email@gmail.com` (the exact email you verified in Step 1)

   **Variable 4:**
   - Key: `USE_SENDGRID`
   - Value: `true`

5. Click **"Save Changes"**
6. Render will automatically redeploy (takes 2-5 minutes)

---

### Step 4: Verify It's Working ✅

After Render redeploys:

1. **Check Render Logs**:
   - Go to your service → **"Logs"** tab
   - Look for:
     ```
     [EmailService] 🔍 Checking email configuration...
     [EmailService]    EMAIL_USER/MAIL_USER: ✅ Set
     [EmailService]    EMAIL_PASS/MAIL_PASS: ✅ Set
     [EmailService] 🔌 Trying SMTP configuration 1/2 (port 587)...
     [EmailService] ✅ SMTP connection successful on port 587
     [EmailService] ✅ Email service initialized successfully
     ```

2. **Test Email Sending**:
   - Try signing up a new user in your app
   - Check the email inbox for OTP code
   - Email should arrive within seconds!

---

## Complete Checklist

- [ ] ✅ Verified sender email in SendGrid (clicked verification link)
- [ ] ✅ Created SendGrid API key
- [ ] ✅ Copied API key (saved it)
- [ ] ✅ Added `EMAIL_USER=apikey` to Render
- [ ] ✅ Added `EMAIL_PASS=sendgrid-api-key` to Render
- [ ] ✅ Added `SENDGRID_FROM_EMAIL=verified-email@gmail.com` to Render
- [ ] ✅ Added `USE_SENDGRID=true` to Render
- [ ] ✅ Saved changes in Render (auto-redeploys)
- [ ] ✅ Waited for deployment (2-5 minutes)
- [ ] ✅ Checked Render logs - see "Email service initialized successfully"
- [ ] ✅ Tested by signing up a user - received OTP email

---

## Troubleshooting

### "Sender not verified"
- Make sure you clicked the verification link in your email
- Check SendGrid dashboard → Sender Authentication → should show "Verified"

### "Authentication failed"
- Double-check API key is correct (no extra spaces)
- Make sure API key has "Mail Send" permissions
- Verify `EMAIL_USER=apikey` (exactly "apikey")

### "Connection timeout"
- SendGrid should work from Render
- If still timing out, check Render network settings
- Try waiting a few minutes and redeploy

### "Invalid from address"
- Make sure `SENDGRID_FROM_EMAIL` matches the verified email exactly
- Check for typos
- Verify the sender is verified in SendGrid

---

## Summary

1. ✅ Verify email (click link in SendGrid email)
2. 🔑 Get API key (Settings → API Keys → Create)
3. 🌐 Add to Render (4 environment variables)
4. ✅ Test (sign up a user, check for email)

**That's it!** Your email service will be fully functional! 🎉

