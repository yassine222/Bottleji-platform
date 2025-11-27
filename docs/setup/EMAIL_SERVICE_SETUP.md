# Email Service Setup Guide

## Current Status

The email service is **optional** and currently **disabled** in production. This is **not an error** - your application works fine without it.

### What Works Without Email Service

✅ User signup  
✅ OTP generation  
✅ Password reset codes  
✅ All API endpoints  
✅ All functionality  

### What's Different Without Email Service

When email service is disabled:
- OTP codes are **logged to console** instead of sent via email
- Password reset codes are **logged to console** instead of sent via email
- Admin invitations are **logged to console** instead of sent via email

**For production**, you'll want to enable email service so users receive OTP codes via email.

---

## How to Enable Email Service

### Step 1: Get Gmail App Password

1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Sign in with your Gmail account
3. Enable **2-Step Verification** (if not already enabled)
   - Go to **Security** → **2-Step Verification**
4. Generate **App Password**
   - Go to **Security** → **App passwords**
   - Select **"Mail"** and **"Other (Custom name)"**
   - Name it: "Bottleji Backend"
   - Copy the generated **16-character password**

### Step 2: Add Environment Variables to Render

1. Go to your Render dashboard
2. Select your backend service
3. Go to **Environment** tab
4. Add these environment variables:

```
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-16-character-app-password
```

5. Click **Save Changes**
6. Render will automatically redeploy

### Step 3: Verify Email Service

After deployment, check your logs. You should see:

```
✅ Email service initialized successfully
```

Instead of:

```
⚠️ Email service disabled: Missing EMAIL_USER or EMAIL_PASS environment variables
```

---

## Alternative Email Services

If you don't want to use Gmail, you can use other email services:

### SendGrid
```env
EMAIL_USER=apikey
EMAIL_PASS=your_sendgrid_api_key
```

Then update `email.service.ts` to use SendGrid SMTP:
```typescript
host: 'smtp.sendgrid.net',
port: 587,
```

### Mailgun
```env
EMAIL_USER=postmaster@your-domain.mailgun.org
EMAIL_PASS=your_mailgun_password
```

### AWS SES
Requires AWS credentials and SES configuration.

---

## Troubleshooting

### Error: "Authentication failed"

**Solution**: 
- Make sure you're using an **App Password**, not your regular Gmail password
- Verify 2-Step Verification is enabled
- Regenerate the app password if needed

### Error: "Connection timeout"

**Solution**:
- Check your firewall settings
- Verify SMTP ports (587, 465) are not blocked
- Try using port 465 with `secure: true`

### Emails Not Sending

**Solution**:
- Check Render logs for error messages
- Verify environment variables are set correctly
- Test with a simple email first

---

## Current Behavior (Without Email)

When email service is disabled, OTP codes are logged to the console. For example:

```
📧 Email service disabled - OTP would be sent to: user@example.com Code: 123456
```

You can manually check these codes in your Render logs if needed for testing.

---

## Recommendation

For **production**, enable email service so users receive OTP codes via email. For **development/testing**, the console logging is sufficient.

