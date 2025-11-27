# Email Configuration: Local vs Production

## The Problem

- ✅ **Gmail works locally** (your computer can connect to Gmail SMTP)
- ❌ **Gmail doesn't work on Render** (Render's network blocks Gmail SMTP)

This is a common issue with cloud hosting providers.

---

## Solution: Use Different Services for Different Environments

### Local Development: Gmail
- Use Gmail SMTP (works fine from your computer)
- Keep your current `.env` file with Gmail credentials

### Production (Render): SendGrid
- Use SendGrid (designed for cloud hosting)
- Add SendGrid credentials to Render environment variables

---

## Setup Instructions

### Step 1: Keep Gmail for Local (Already Done)

Your `backend/.env` file:
```env
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=ojwi qbpy kbcs zplx
```

**This stays as-is** - it works locally!

---

### Step 2: Add SendGrid for Production (Render)

1. **Create SendGrid Account** (if you haven't):
   - Go to: https://signup.sendgrid.com/
   - Sign up (free)
   - Verify email

2. **Get SendGrid API Key**:
   - Dashboard → Settings → API Keys
   - Create API Key
   - Copy the key

3. **Add to Render Environment Variables**:
   - Go to: https://dashboard.render.com/
   - Select `bottleji-api` → Environment tab
   - Add:
     ```
     EMAIL_USER=apikey
     EMAIL_PASS=your-sendgrid-api-key
     USE_SENDGRID=true
     ```
   - Save (auto-redeploys)

---

## How It Works

### Local Development
- Reads from `backend/.env`
- Uses Gmail SMTP (`smtp.gmail.com`)
- Works perfectly ✅

### Production (Render)
- Reads from Render environment variables
- Detects `EMAIL_USER=apikey` → Uses SendGrid
- Or detects `USE_SENDGRID=true` → Uses SendGrid
- Works perfectly ✅

---

## Environment Variables Summary

### Local (.env file):
```env
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=ojwi qbpy kbcs zplx
```

### Production (Render):
```
EMAIL_USER=apikey
EMAIL_PASS=SG.xxxxxxxxxxxxx (SendGrid API key)
USE_SENDGRID=true
```

---

## Why This Works

- **Local**: Your computer can connect to Gmail SMTP
- **Render**: Render's network blocks Gmail, but allows SendGrid
- **Best of both worlds**: Gmail for dev, SendGrid for production

---

## Quick Setup Checklist

- [ ] Keep Gmail in local `.env` (already done)
- [ ] Sign up for SendGrid (free)
- [ ] Get SendGrid API key
- [ ] Add to Render:
  - `EMAIL_USER=apikey`
  - `EMAIL_PASS=sendgrid-api-key`
  - `USE_SENDGRID=true`
- [ ] Wait for Render redeployment
- [ ] Test email sending

---

## Result

- ✅ **Local development**: Uses Gmail (works)
- ✅ **Production**: Uses SendGrid (works)
- ✅ **No code changes needed** - automatic detection
- ✅ **Both environments work perfectly**

---

## Alternative: Force SendGrid in Production

If you want to always use SendGrid in production, just set:

```
USE_SENDGRID=true
```

In Render environment variables, and the code will automatically use SendGrid regardless of EMAIL_USER value.

