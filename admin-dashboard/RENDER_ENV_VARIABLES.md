# Admin Dashboard Environment Variables for Render

## Required Environment Variables

### 1. API Configuration

#### `NEXT_PUBLIC_API_URL` (Optional - has default)
- **Description**: Base URL for the backend API
- **Default**: `https://bottleji-api.onrender.com/api`
- **Example**: `https://bottleji-api.onrender.com/api`
- **Note**: Only set this if your API is at a different URL

#### `NEXT_PUBLIC_WS_URL` (Optional - has default)
- **Description**: WebSocket URL for real-time features (chat, notifications)
- **Default**: Automatically derived from `NEXT_PUBLIC_API_URL` (converts https to wss)
- **Example**: `wss://bottleji-api.onrender.com/chat`
- **Note**: Only set this if you need a different WebSocket URL

### 2. Node Environment

#### `NODE_ENV` (Optional - Render sets automatically)
- **Description**: Environment mode
- **Default**: `production` (set automatically by Render)
- **Values**: `production`, `development`
- **Note**: Render automatically sets this to `production` for production builds

## Optional Environment Variables

### Firebase Configuration (Optional - has defaults)

These are only needed if you want to override the default Firebase configuration:

#### `NEXT_PUBLIC_FIREBASE_API_KEY`
- **Description**: Firebase API key
- **Default**: Hardcoded in `firebase.ts` (public key, safe to expose)

#### `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- **Description**: Firebase authentication domain
- **Default**: `botleji.firebaseapp.com`

#### `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- **Description**: Firebase project ID
- **Default**: `botleji`

#### `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
- **Description**: Firebase storage bucket
- **Default**: `botleji.firebasestorage.app`

#### `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- **Description**: Firebase messaging sender ID
- **Default**: `603427607468`

#### `NEXT_PUBLIC_FIREBASE_APP_ID`
- **Description**: Firebase app ID
- **Default**: Hardcoded in `firebase.ts`

## Minimal Configuration for Render

**You don't need to set any environment variables!** The admin dashboard will work with defaults:

- ✅ API URL defaults to `https://bottleji-api.onrender.com/api`
- ✅ WebSocket URL is automatically derived
- ✅ Firebase uses default configuration
- ✅ `NODE_ENV` is automatically set to `production` by Render

## When to Set Environment Variables

Only set environment variables if:

1. **Your API is at a different URL**: Set `NEXT_PUBLIC_API_URL`
2. **You have a custom WebSocket server**: Set `NEXT_PUBLIC_WS_URL`
3. **You're using a different Firebase project**: Set Firebase variables

## Render Configuration Steps

1. Go to your Render dashboard
2. Create a new **Web Service** (not Static Site - Next.js needs server)
3. Connect your GitHub repository
4. **Root Directory**: Set to `admin-dashboard`
5. **Build Command**: `npm install && npm run build`
6. **Start Command**: `npm start`
7. **Environment Variables**: Leave empty (or add only if needed)
8. Deploy!

## Example Render Configuration

```
Name: bottleji-admin-dashboard
Environment: Node
Build Command: npm install && npm run build
Start Command: npm start
Root Directory: admin-dashboard
```

**Environment Variables** (optional):
```
NEXT_PUBLIC_API_URL=https://bottleji-api.onrender.com/api
```

That's it! The dashboard will work with these defaults.

