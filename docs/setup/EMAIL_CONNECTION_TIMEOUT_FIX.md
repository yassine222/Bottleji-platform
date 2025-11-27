# Fix Email Connection Timeout

## Problem: Connection Timeout to Gmail SMTP

If you see:
```
❌ Email service initialization failed: Connection timeout
```

This usually means **Render's network is blocking outbound SMTP connections** to Gmail.

---

## Solution 1: Updated Code (Already Applied)

The code now tries:
1. **Port 465 (SSL)** - More reliable for cloud hosting
2. **Port 587 (STARTTLS)** - Fallback option
3. **Connection timeouts** - Prevents hanging

**Wait for Render to redeploy** and check logs again.

---

## Solution 2: Use Alternative Email Service

If Gmail SMTP still doesn't work, use a cloud email service designed for applications:

### Option A: SendGrid (Recommended)

1. **Sign up**: https://sendgrid.com/
2. **Get API Key**:
   - Dashboard → Settings → API Keys
   - Create API Key with "Mail Send" permissions
3. **Update Render Environment Variables**:
   ```
   EMAIL_USER=apikey
   EMAIL_PASS=your-sendgrid-api-key
   ```
4. **Update email.service.ts**:
   ```typescript
   host: 'smtp.sendgrid.net',
   port: 587,
   secure: false,
   ```

### Option B: Mailgun

1. **Sign up**: https://www.mailgun.com/
2. **Get SMTP credentials** from dashboard
3. **Update Render Environment Variables**:
   ```
   EMAIL_USER=postmaster@your-domain.mailgun.org
   EMAIL_PASS=your-mailgun-password
   ```
4. **Update email.service.ts**:
   ```typescript
   host: 'smtp.mailgun.org',
   port: 587,
   secure: false,
   ```

### Option C: AWS SES

1. **Set up AWS SES**
2. **Get SMTP credentials**
3. **Update configuration** accordingly

---

## Solution 3: Check Render Network Settings

Some Render plans might have network restrictions. Check:
- Render Dashboard → Your Service → Settings
- Look for "Network" or "Firewall" settings
- Ensure outbound SMTP (ports 465, 587) is allowed

---

## Quick Test

After the code update deploys, check Render logs:

**Success:**
```
✅ SMTP connection successful on port 465
✅ Email service initialized successfully
```

**Still Failing:**
```
⚠️ SMTP configuration 1 failed: Connection timeout
⚠️ SMTP configuration 2 failed: Connection timeout
```

If still failing → Use SendGrid or Mailgun (Solution 2).

---

## Why This Happens

- **Gmail SMTP** is designed for personal use
- **Cloud hosting providers** (like Render) often block SMTP to prevent spam
- **Professional email services** (SendGrid, Mailgun) are designed for applications
- They have better deliverability and reliability

---

## Recommendation

If Gmail continues to timeout:
1. ✅ **Use SendGrid** (free tier: 100 emails/day)
2. ✅ Better deliverability
3. ✅ Designed for applications
4. ✅ More reliable from cloud hosting

---

## Next Steps

1. **Wait for Render redeployment** (2-5 minutes)
2. **Check logs** - see if port 465 works
3. **If still timing out** - switch to SendGrid (5 minutes setup)

