# Gmail SMTP Setup Guide

## 🔧 Fix Gmail SMTP Issues

### Step 1: Generate New App Password

1. **Go to Google Account Settings**
   - Visit: https://myaccount.google.com/
   - Sign in with: `bottleji.tn@gmail.com`

2. **Enable 2-Step Verification** (if not already enabled)
   - Go to Security → 2-Step Verification
   - Enable if not already active

3. **Generate App Password**
   - Go to Security → App passwords
   - Select "Mail" and "Other (Custom name)"
   - Name it: "Bottleji Backend"
   - Copy the generated 16-character password

4. **Update Environment Variables**
   ```bash
   # In backend/.env file
   EMAIL_PASS=your_new_16_character_app_password
   ```

### Step 2: Alternative Solutions

#### Option A: Use Gmail OAuth2 (More Secure)
```javascript
// In email.service.ts
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    type: 'OAuth2',
    user: 'bottleji.tn@gmail.com',
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret',
    refreshToken: 'your_refresh_token',
    accessToken: 'your_access_token'
  }
});
```

#### Option B: Use Different Email Service
```javascript
// Example: SendGrid, Mailgun, etc.
const transporter = nodemailer.createTransporter({
  host: 'smtp.sendgrid.net',
  port: 587,
  auth: {
    user: 'apikey',
    pass: 'your_sendgrid_api_key'
  }
});
```

### Step 3: Test Email Service

After updating the password, restart the server and test:

```bash
curl -X POST "http://localhost:3000/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User","password":"temp123456"}'
```

### Current Status
- ✅ User creation works
- ✅ OTP generation works  
- ❌ Email delivery fails (SMTP issue)
- ✅ Fallback to console logging works

### Next Steps
1. Generate new Gmail app password
2. Update EMAIL_PASS in .env
3. Restart server
4. Test email delivery
