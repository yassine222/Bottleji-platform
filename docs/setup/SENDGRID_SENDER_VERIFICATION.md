# SendGrid Sender Verification Setup

## Important: SendGrid Requires Verified Sender

When using SendGrid, you **must verify a sender email address** before sending emails.

---

## Step 1: Verify Sender in SendGrid

1. Go to SendGrid Dashboard: https://app.sendgrid.com/
2. Click **"Settings"** → **"Sender Authentication"**
3. Choose one:

### Option A: Single Sender Verification (Easiest)
1. Click **"Verify a Single Sender"**
2. Fill in the form:
   - **From Email**: `noreply@bottleji.com` (or your email)
   - **From Name**: `Bottleji`
   - **Reply To**: (same as from email)
   - **Company Address**: Your address
3. Click **"Create"**
4. **Check your email** and click the verification link
5. ✅ Sender verified!

### Option B: Domain Authentication (Better for production)
1. Click **"Authenticate Your Domain"**
2. Follow the DNS setup instructions
3. Add DNS records to your domain
4. ✅ Domain verified!

---

## Step 2: Add to Render Environment Variables

After verifying your sender, add to Render:

1. Go to Render Dashboard → Your Service → Environment
2. Add:
   ```
   SENDGRID_FROM_EMAIL=your-verified-email@example.com
   ```
   Or use:
   ```
   EMAIL_FROM=your-verified-email@example.com
   ```

**Example:**
```
EMAIL_USER=apikey
EMAIL_PASS=SG.xxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@bottleji.com
USE_SENDGRID=true
```

---

## How It Works

### With Gmail:
- `from: your-email@gmail.com` (uses EMAIL_USER directly)

### With SendGrid:
- `from: verified-email@example.com` (uses SENDGRID_FROM_EMAIL)
- Must be a verified sender in SendGrid

---

## Quick Setup Checklist

- [ ] Sign up for SendGrid
- [ ] Verify a sender email (Single Sender or Domain)
- [ ] Get SendGrid API key
- [ ] Add to Render:
  - `EMAIL_USER=apikey`
  - `EMAIL_PASS=sendgrid-api-key`
  - `SENDGRID_FROM_EMAIL=your-verified-email@example.com`
  - `USE_SENDGRID=true`
- [ ] Wait for redeployment
- [ ] Test email sending

---

## Common Issues

### "Sender not verified"
- You must verify the sender email in SendGrid first
- Check SendGrid dashboard → Sender Authentication

### "Invalid from address"
- Make sure `SENDGRID_FROM_EMAIL` matches a verified sender
- Check for typos in the email address

### Emails going to spam
- Verify your domain (not just single sender)
- Set up SPF/DKIM records
- Use a proper domain email (not Gmail)

---

## Default Fallback

If `SENDGRID_FROM_EMAIL` is not set, the code will use:
- `noreply@bottleji.com` (default)

**But you still need to verify this email in SendGrid!**

---

## Recommendation

For production:
1. ✅ Use your own domain (e.g., `bottleji.com`)
2. ✅ Set up domain authentication in SendGrid
3. ✅ Use `noreply@bottleji.com` as sender
4. ✅ Better deliverability and branding

