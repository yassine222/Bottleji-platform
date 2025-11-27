# 🔐 Environment Variables for Render

Here's exactly what to put in Render's Environment Variables section.

---

## ✅ Required Variables (Must Have)

These are **required** - your app won't work without them:

### 1. JWT_SECRET
```
Key: JWT_SECRET
Value: BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=
```
**Or generate a new one:**
```bash
openssl rand -base64 32
```

### 2. MONGODB_URI
```
Key: MONGODB_URI
Value: mongodb+srv://username:password@cluster.mongodb.net/eco_collect?retryWrites=true&w=majority
```
**Replace:**
- `username` - Your MongoDB username
- `password` - Your MongoDB password
- `cluster` - Your MongoDB cluster name
- `eco_collect` - Your database name (or change it)

### 3. NODE_ENV
```
Key: NODE_ENV
Value: production
```

---

## 📋 Recommended Variables (Should Have)

These are recommended for production:

### 4. ALLOWED_ORIGINS
```
Key: ALLOWED_ORIGINS
Value: https://your-frontend-domain.com,https://your-admin-dashboard.com
```
**Examples:**
- If you have a Flutter web app: `https://your-app.web.app`
- If you have admin dashboard: `https://admin.yourdomain.com`
- Multiple domains: `https://app.com,https://admin.com`
- **Leave empty for now** if you don't know your domains yet (you can add later)

### 5. PORT
```
Key: PORT
Value: 3000
```
**Note:** Render sets this automatically, but you can set it explicitly if needed.

---

## 🔧 Optional Variables (Add If You Use These Features)

### 6. EMAIL_USER (If using email service)
```
Key: EMAIL_USER
Value: your-email@gmail.com
```
**For sending OTP emails via Gmail**

### 7. EMAIL_PASS (If using email service)
```
Key: EMAIL_PASS
Value: your-gmail-app-password
```
**Gmail App Password (not your regular password)**
- Get it from: Google Account → Security → App passwords
- Create an app password for "Mail"

### 8. GOOGLE_MAPS_API_KEY (If using maps)
```
Key: GOOGLE_MAPS_API_KEY
Value: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
**Get from:** [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### 9. FIREBASE_SERVICE_ACCOUNT_KEY (If using Firebase/FCM)
```
Key: FIREBASE_SERVICE_ACCOUNT_KEY
Value: {"type":"service_account","project_id":"your-project","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
```
**Important:** 
- Paste the ENTIRE JSON as a single-line string
- No line breaks
- Escape quotes if needed (Render usually handles this)

### 10. JWT_EXPIRES_IN (Optional - has default)
```
Key: JWT_EXPIRES_IN
Value: 7d
```
**Token expiration time:**
- `1h` = 1 hour
- `24h` = 24 hours
- `7d` = 7 days (default)
- `30d` = 30 days

---

## 📝 Step-by-Step: Adding Variables in Render

### Method 1: Add One by One

1. In Render dashboard, go to your service
2. Click **"Environment"** tab (or scroll to "Environment Variables")
3. Click **"Add Environment Variable"**
4. Enter **Key** and **Value**
5. Click **"Save Changes"**
6. Repeat for each variable

### Method 2: Add Multiple at Once

1. Go to **"Environment"** tab
2. Click **"Add Environment Variable"** for each one
3. Add all variables
4. Click **"Save Changes"** at the bottom
5. Service will auto-redeploy

---

## ✅ Minimum Setup (Get Started)

For a **minimum working setup**, add these 3:

```
JWT_SECRET = BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=
MONGODB_URI = mongodb+srv://user:pass@cluster.mongodb.net/eco_collect?retryWrites=true&w=majority
NODE_ENV = production
```

Everything else can be added later!

---

## 🎯 Complete Example (All Variables)

Here's what a complete setup looks like:

```
JWT_SECRET = BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=
MONGODB_URI = mongodb+srv://myuser:mypass@cluster0.xxxxx.mongodb.net/eco_collect?retryWrites=true&w=majority
NODE_ENV = production
ALLOWED_ORIGINS = https://myapp.web.app,https://admin.mydomain.com
PORT = 3000
EMAIL_USER = myemail@gmail.com
EMAIL_PASS = xxxx xxxx xxxx xxxx
GOOGLE_MAPS_API_KEY = AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
JWT_EXPIRES_IN = 7d
```

---

## 🔍 How to Get Each Value

### JWT_SECRET
```bash
# Generate in terminal
openssl rand -base64 32
```

### MONGODB_URI
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create cluster (free tier is fine)
3. Click "Connect" → "Connect your application"
4. Copy connection string
5. Replace `<password>` with your password
6. Replace `<dbname>` with `eco_collect`

### EMAIL_PASS (Gmail App Password)
1. Go to [Google Account](https://myaccount.google.com/)
2. Security → 2-Step Verification (must be enabled)
3. App passwords → Generate
4. Select "Mail" and "Other (Custom name)"
5. Copy the 16-character password

### GOOGLE_MAPS_API_KEY
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project or select existing
3. Enable Maps JavaScript API
4. Go to Credentials → Create API Key
5. Copy the key

### FIREBASE_SERVICE_ACCOUNT_KEY
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → Service Accounts
3. Click "Generate new private key"
4. Download JSON file
5. Copy entire JSON content
6. Paste as single-line string (remove line breaks)

---

## ⚠️ Important Notes

### Security
- ✅ Never commit these values to git
- ✅ Never share them publicly
- ✅ Use different values for development and production
- ✅ Rotate secrets periodically

### Formatting
- ✅ No quotes needed around values (Render handles this)
- ✅ No spaces around the `=` sign
- ✅ For JSON (Firebase), paste as single line
- ✅ For URLs, include the full connection string

### Testing
- After adding variables, check logs to verify they're loaded
- Look for: `Environment: production` in logs
- If you see "undefined", variable isn't set correctly

---

## 🐛 Troubleshooting

### "JWT_SECRET is not defined"
- Check variable name is exactly `JWT_SECRET` (case-sensitive)
- Verify value is set
- Redeploy after adding

### "Cannot connect to database"
- Verify `MONGODB_URI` is correct
- Check password is correct (no special characters need encoding)
- Verify MongoDB Atlas IP whitelist allows all: `0.0.0.0/0`

### "CORS errors"
- Add your frontend domain to `ALLOWED_ORIGINS`
- Format: `https://domain.com` (no trailing slash)
- Multiple domains: comma-separated, no spaces

---

## ✅ Quick Checklist

Before deploying, make sure you have:

- [ ] `JWT_SECRET` - Generated strong secret (32+ chars)
- [ ] `MONGODB_URI` - Valid MongoDB connection string
- [ ] `NODE_ENV` - Set to `production`
- [ ] `ALLOWED_ORIGINS` - Your frontend domains (or leave empty for now)
- [ ] Other variables if you use those features

---

## 🚀 Ready to Deploy!

Once you've added the required variables:
1. Click **"Save Changes"**
2. Render will automatically redeploy
3. Check logs to verify everything works
4. Test your API endpoints

**That's it!** Your environment variables are configured. 🎉

