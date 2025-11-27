# 🎨 Deploy to Render - Step by Step

Follow these steps to deploy your backend to Render in 10 minutes.

---

## ✅ Pre-Checklist

Before starting, make sure you have:
- [x] Code builds successfully (`npm run build` works)
- [ ] Render account (we'll create it)
- [ ] MongoDB database (we'll set it up)
- [ ] GitHub repository with your code

---

## 📋 STEP 1: Create Render Account (2 minutes)

### 1.1 Go to Render
1. Open your browser
2. Go to: **https://render.com**
3. Click **"Get Started for Free"** or **"Sign Up"**

### 1.2 Sign Up
- Choose **"Sign up with GitHub"** (recommended)
- Authorize Render to access your GitHub account
- Complete the signup process

**✅ Checkpoint**: You're logged into Render dashboard

---

## 📋 STEP 2: Prepare Your Secrets (3 minutes)

### 2.1 Generate JWT Secret
Open your terminal and run:

```bash
# Generate a strong JWT secret
openssl rand -base64 32
```

**Copy this value** - you'll need it in Step 4!

### 2.2 Get MongoDB Connection String

**Option A: MongoDB Atlas (Recommended - Free)**
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Sign up or log in
3. Create a new cluster (Free tier M0 is fine)
4. Wait for cluster to be created (~5 minutes)
5. Click **"Connect"** → **"Connect your application"**
6. Copy the connection string
7. Replace `<password>` with your database user password
8. Replace `<dbname>` with `eco_collect` or your database name

**Format:** `mongodb+srv://username:password@cluster.mongodb.net/eco_collect?retryWrites=true&w=majority`

**Option B: Use Existing MongoDB**
- If you already have MongoDB, use that connection string

**✅ Checkpoint**: You have:
- JWT_SECRET (from step 2.1)
- MONGODB_URI (from step 2.2)

---

## 📋 STEP 3: Create Web Service on Render (2 minutes)

### 3.1 Create New Service
1. In Render dashboard, click **"New +"** button (top right)
2. **Select "Web Service"** ← This is the correct choice for your NestJS backend API
   - ❌ Don't choose "Static Site" (that's for frontend)
   - ❌ Don't choose "Background Worker" (that's for background tasks)
   - ❌ Don't choose "Cron Job" (that's for scheduled scripts)
   - ✅ **Choose "Web Service"** (for APIs that handle HTTP requests)

### 3.2 Connect Repository
1. If not connected, click **"Connect GitHub"**
2. Authorize Render to access your repositories
3. **IMPORTANT**: When authorizing, make sure to check ✅ **"Access private repositories"** or **"Grant access to private repositories"**
4. Select your repository from the list (both public AND private repos will appear)
5. Click **"Connect"**

**🔒 Note**: Your repository can stay private! Render supports private repositories. Just make sure to authorize private repo access.

### 3.3 Configure Service
Fill in these settings:

- **Name**: `bottleji-api` (or your preferred name)
- **Region**: Choose closest to you (e.g., `Oregon (US West)`)
- **Branch**: `main` or `master` (your main branch)
- **Root Directory**: `backend` ← **IMPORTANT! Set this to `backend`**
- **Runtime**: `Node`
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`

**⚠️ Important**: 
- Since your repo has multiple projects (backend, Flutter, admin-dashboard), you **MUST** set **Root Directory** to `backend`
- This tells Render to only deploy the backend folder and ignore the other projects
- Without this, Render will look for `package.json` in the root and fail

**✅ Checkpoint**: Service is configured (don't create yet!)

---

## 📋 STEP 4: Set Environment Variables (2 minutes)

### 4.1 Scroll to Environment Variables Section
Before clicking "Create Web Service", scroll down to **"Environment Variables"** section

### 4.2 Add Required Variables
Click **"Add Environment Variable"** for each:

#### Required Variables:

1. **JWT_SECRET**
   - Key: `JWT_SECRET`
   - Value: (paste the secret from Step 2.1)

2. **MONGODB_URI**
   - Key: `MONGODB_URI`
   - Value: (paste your MongoDB connection string from Step 2.2)

3. **NODE_ENV**
   - Key: `NODE_ENV`
   - Value: `production`

#### Recommended Variables:

4. **ALLOWED_ORIGINS**
   - Key: `ALLOWED_ORIGINS`
   - Value: `https://your-frontend-domain.com` (or leave empty for now, you can add later)

5. **PORT** (Optional - Render sets this automatically)
   - Key: `PORT`
   - Value: `3000` (or leave it - Render will set it)

#### Optional Variables (Add if you use these features):

6. **EMAIL_USER** (if using email service)
   - Key: `EMAIL_USER`
   - Value: `your-email@gmail.com`

7. **EMAIL_PASS** (if using email service)
   - Key: `EMAIL_PASS`
   - Value: `your-gmail-app-password`

8. **GOOGLE_MAPS_API_KEY** (if using maps)
   - Key: `GOOGLE_MAPS_API_KEY`
   - Value: `your-google-maps-api-key`

9. **FIREBASE_SERVICE_ACCOUNT_KEY** (if using Firebase)
   - Key: `FIREBASE_SERVICE_ACCOUNT_KEY`
   - Value: `{"type":"service_account",...}` (entire JSON as single-line string)

**✅ Checkpoint**: All environment variables are added

---

## 📋 STEP 5: Create and Deploy (1 minute)

### 5.1 Create Service
1. Scroll to bottom
2. Click **"Create Web Service"**
3. Render will start building your application

### 5.2 Watch the Build
- You'll see build logs in real-time
- Wait for build to complete (usually 2-5 minutes)
- Look for: **"Build successful"** or **"Your service is live"**

**✅ Checkpoint**: Build completes successfully

---

## 📋 STEP 6: Get Your API URL (30 seconds)

### 6.1 Find Your URL
Once deployed, you'll see:
- **Service URL**: `https://your-app-name.onrender.com`
- Your API will be at: `https://your-app-name.onrender.com/api`

### 6.2 Test Your API
Open a new terminal and test:

```bash
# Test if API is running
curl https://your-app-name.onrender.com/api

# Or open in browser
# https://your-app-name.onrender.com/api
```

**✅ Checkpoint**: API is accessible

---

## 📋 STEP 7: Verify Everything Works (2 minutes)

### 7.1 Check Logs
1. In Render dashboard, click on your service
2. Go to **"Logs"** tab
3. Look for:
   - ✅ "Application is running on: http://0.0.0.0:PORT/api"
   - ✅ "Environment: production"
   - ❌ No error messages

### 7.2 Test Endpoints
Test these endpoints:

```bash
# Replace YOUR_URL with your Render URL
YOUR_URL="https://your-app-name.onrender.com/api"

# Test signup
curl -X POST $YOUR_URL/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123456"}'

# Test login
curl -X POST $YOUR_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123456"}'
```

**✅ Checkpoint**: Endpoints respond correctly

---

## 📋 STEP 8: Update Your Flutter App (1 minute)

### 8.1 Update API URL
In your Flutter app, find where you set the API base URL (usually in `main.dart` or a config file):

```dart
// Change from:
final apiBaseUrl = 'http://localhost:3000/api';
// or
final apiBaseUrl = 'https://your-old-url.com/api';

// To:
final apiBaseUrl = 'https://your-app-name.onrender.com/api';
```

### 8.2 Test Connection
1. Run your Flutter app
2. Try to sign up or log in
3. Verify it connects to Render API

**✅ Checkpoint**: Flutter app connects to production API

---

## 🎉 Done!

Your backend is now deployed on Render!

**Your API URL**: `https://your-app-name.onrender.com/api`

---

## 🐛 Troubleshooting

### Build Fails
**Problem**: Build fails with errors
**Solution**:
1. Check build logs in Render
2. Verify `npm run build` works locally
3. Check Root Directory is correct
4. Verify all dependencies are in `package.json`

### "JWT_SECRET is not defined"
**Problem**: App starts but shows this error
**Solution**:
1. Go to Environment Variables in Render
2. Verify `JWT_SECRET` is set
3. Redeploy the service

### Database Connection Fails
**Problem**: Can't connect to MongoDB
**Solution**:
1. Verify `MONGODB_URI` is correct
2. Check MongoDB Atlas IP whitelist (should allow all: `0.0.0.0/0`)
3. Verify database user password is correct
4. Test connection string locally first

### CORS Errors
**Problem**: Frontend can't connect due to CORS
**Solution**:
1. Add your frontend domain to `ALLOWED_ORIGINS`
2. Format: `https://your-frontend.com` (no trailing slash)
3. Redeploy

### Service Goes to Sleep (Free Tier)
**Problem**: Service is slow on first request
**Solution**:
- Free tier services sleep after 15 minutes of inactivity
- First request after sleep takes ~30 seconds to wake up
- Upgrade to paid plan for always-on service

---

## 📝 Next Steps

1. **Set up custom domain** (optional):
   - Go to Settings → Custom Domains
   - Add your domain

2. **Enable auto-deploy** (already enabled by default):
   - Every push to main branch auto-deploys

3. **Set up monitoring**:
   - Use Render's built-in monitoring
   - Or add external monitoring (UptimeRobot, etc.)

4. **Backup your database**:
   - Set up MongoDB Atlas backups
   - Or use MongoDB Atlas automated backups

---

## ✅ Final Checklist

- [ ] Render account created
- [ ] Web service created
- [ ] All environment variables set
- [ ] Build successful
- [ ] API is accessible
- [ ] Endpoints work correctly
- [ ] Flutter app updated with new URL
- [ ] Tested signup/login

**You're all set!** 🚀

