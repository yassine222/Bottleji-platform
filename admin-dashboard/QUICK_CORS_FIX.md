# Quick CORS Fix

## Your Current Issue
- **Your origin**: `http://172.20.10.12:3001`
- **API URL**: `https://bottleji-api.onrender.com/api`
- **Problem**: Backend CORS is blocking your origin

## Immediate Fix

### Step 1: Go to Render Dashboard
1. Open https://dashboard.render.com
2. Select your backend service (`bottleji-api`)

### Step 2: Add Environment Variable
1. Go to **"Environment"** tab
2. Find or add `ALLOWED_ORIGINS`
3. Set the value to:
   ```
   http://localhost:3001,http://172.20.10.12:3001,http://localhost:3000
   ```
   (Add any other IPs/ports you use)

### Step 3: Redeploy
1. Click **"Manual Deploy"** → **"Deploy latest commit"**
2. Wait for deployment to complete (~2-3 minutes)

### Step 4: Test
Try logging in again - it should work now!

## Alternative: Use localhost Instead

If you're accessing the admin dashboard from the same machine, use:
```
http://localhost:3001
```
instead of `http://172.20.10.12:3001`

This way you only need `http://localhost:3001` in ALLOWED_ORIGINS.

## For Production Deployment

When you deploy the admin dashboard, add its production URL:
```
http://localhost:3001,http://172.20.10.12:3001,https://your-admin-dashboard.onrender.com
```

