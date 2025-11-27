# 📁 Deploying from Monorepo (Multiple Projects)

Your repository has multiple projects:
- `backend/` - NestJS API (what you want to deploy)
- `botleji/` - Flutter app (don't deploy to Render)
- `admin-dashboard/` - Next.js dashboard (could deploy separately)

Here's how to deploy **only the backend** from your monorepo.

---

## ✅ Solution: Set Root Directory

When configuring your Render Web Service, set the **Root Directory** to `backend`.

---

## 📋 Step-by-Step Configuration

### Step 1: Create Web Service
1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Select your repository (the one with all three projects)

### Step 2: Configure Service Settings

Fill in these settings:

- **Name**: `bottleji-api` (or your choice)
- **Region**: Choose closest to you
- **Branch**: `main` or `master`
- **Root Directory**: `backend` ← **IMPORTANT!**
- **Runtime**: `Node`
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`

### Step 3: Why Root Directory Matters

**Without Root Directory set:**
- ❌ Render looks for `package.json` in root
- ❌ Can't find it (it's in `backend/` folder)
- ❌ Build fails

**With Root Directory = `backend`:**
- ✅ Render changes to `backend/` folder first
- ✅ Finds `package.json` in `backend/`
- ✅ Runs build commands in `backend/`
- ✅ Everything works!

---

## 🎯 Visual Guide

Your repository structure:
```
your-repo/
├── backend/              ← Render deploys from here
│   ├── package.json
│   ├── src/
│   └── ...
├── botleji/              ← Ignored by Render
│   ├── lib/
│   └── ...
└── admin-dashboard/      ← Ignored by Render
    ├── package.json
    └── ...
```

When you set **Root Directory: `backend`**:
- Render only sees the `backend/` folder
- Flutter and admin-dashboard are ignored
- Build commands run in `backend/` context

---

## 📝 Complete Configuration Example

In Render dashboard, your settings should look like:

```
Name: bottleji-api
Region: Oregon (US West)
Branch: main
Root Directory: backend          ← Set this!
Runtime: Node
Build Command: npm install && npm run build
Start Command: npm run start:prod
```

---

## 🔍 Verify Root Directory is Set

After creating the service:

1. Go to your service in Render
2. Click **"Settings"** tab
3. Scroll to **"Build & Deploy"**
4. Check **"Root Directory"** shows: `backend`

If it's empty or wrong, edit it!

---

## 🚀 Deploy Admin Dashboard Separately (Optional)

If you want to deploy the admin dashboard too:

### Option 1: Deploy as Separate Web Service
1. Create another **Web Service** in Render
2. Use the same repository
3. Set **Root Directory**: `admin-dashboard`
4. Configure for Next.js:
   - Build Command: `npm install && npm run build`
   - Start Command: `npm run start` (or `npm run start:prod`)

### Option 2: Deploy as Static Site (If Admin is Static)
1. Create **Static Site** in Render
2. Set **Root Directory**: `admin-dashboard`
3. Build Command: `npm install && npm run build`
4. Publish Directory: `out` or `dist` (where Next.js builds)

---

## ✅ Checklist for Backend Deployment

When configuring your backend service:

- [ ] **Root Directory**: Set to `backend`
- [ ] **Build Command**: `npm install && npm run build`
- [ ] **Start Command**: `npm run start:prod`
- [ ] **Runtime**: `Node`
- [ ] Environment variables are set (JWT_SECRET, MONGODB_URI, etc.)

---

## 🐛 Common Issues

### Issue: "Cannot find package.json"
**Problem**: Root Directory not set or wrong
**Solution**: 
1. Go to Settings → Build & Deploy
2. Set Root Directory to `backend`
3. Save and redeploy

### Issue: "Build fails with module not found"
**Problem**: Build command running in wrong directory
**Solution**: Verify Root Directory is `backend`

### Issue: "Start command fails"
**Problem**: Start command looking for wrong path
**Solution**: 
- Start Command should be: `npm run start:prod`
- This runs `node dist/main` from `backend/` directory

---

## 📋 Summary

**For your backend:**
1. Create **Web Service**
2. Set **Root Directory**: `backend`
3. Configure build/start commands
4. Deploy!

**Your Flutter app:**
- Don't deploy to Render (it's a mobile app)
- Build locally or use CI/CD for app stores

**Your admin dashboard:**
- Can deploy separately as another Web Service
- Set Root Directory: `admin-dashboard`
- Or deploy as Static Site if it's static

---

## 🎯 Quick Answer

**In Render configuration:**
- **Root Directory**: `backend` ← This is the key!

That's it! Render will only deploy your backend, ignoring Flutter and admin-dashboard folders.

