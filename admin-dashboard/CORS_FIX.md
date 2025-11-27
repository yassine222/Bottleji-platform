# CORS Configuration Fix

## Problem
The admin dashboard cannot connect to the production API because CORS is blocking the request.

## Root Cause
The backend CORS configuration in production requires `ALLOWED_ORIGINS` environment variable to be set. If not set, it defaults to an empty array, blocking all origins.

## Solution

### Option 1: Add Admin Dashboard URL to Backend CORS (Recommended for Production)

On Render, add/update the `ALLOWED_ORIGINS` environment variable in your backend service:

**Value format** (comma-separated):
```
https://your-admin-dashboard-url.onrender.com,http://localhost:3001,http://localhost:3000
```

**For local development**, include:
- `http://localhost:3001` (admin dashboard dev server)
- `http://localhost:3000` (if you have other local services)

**For production**, include:
- Your deployed admin dashboard URL (e.g., `https://bottleji-admin.onrender.com`)

### Option 2: Temporary Local Development Fix

If you're running the admin dashboard locally and need to test against production API, you can temporarily modify the backend CORS to allow all origins (NOT RECOMMENDED FOR PRODUCTION):

In `backend/src/main.ts`, change:
```typescript
const allowedOrigins = process.env.NODE_ENV === 'production'
  ? (process.env.ALLOWED_ORIGINS?.split(',') || ['*']) // TEMPORARY: Allow all
  : true;
```

**⚠️ WARNING**: This is insecure for production. Only use for local testing.

## Steps to Fix

1. Go to your Render dashboard
2. Select your backend service (`bottleji-api`)
3. Go to "Environment" tab
4. Add/Update `ALLOWED_ORIGINS`:
   - For local dev: `http://localhost:3001,http://localhost:3000`
   - For production: `https://your-admin-dashboard-url.onrender.com`
5. Save and redeploy

## Verify

After updating, test the connection:
```bash
curl -X GET https://bottleji-api.onrender.com/api \
  -H "Origin: http://localhost:3001" \
  -v
```

You should see `Access-Control-Allow-Origin` header in the response.

