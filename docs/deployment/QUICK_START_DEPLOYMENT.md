# ⚡ Quick Start - Deploy in 10 Minutes

Follow these steps to deploy quickly. Choose your platform and follow the steps.

---

## 🎯 Before You Start

**What you need:**
- ✅ Code is ready and tested
- ✅ MongoDB database (Atlas or other)
- ✅ Account on hosting platform (Heroku/Railway/Render)

**Time needed:** 10-15 minutes

---

## 🚀 Quick Deploy to Heroku (Easiest)

### Step 1: Install Heroku CLI
```bash
# macOS
brew install heroku

# Or download from: https://devcenter.heroku.com/articles/heroku-cli
```

### Step 2: Login
```bash
heroku login
```

### Step 3: Create App
```bash
cd backend
heroku create your-app-name
```

### Step 4: Set Secrets (Copy-paste these, replace values)
```bash
heroku config:set JWT_SECRET="$(openssl rand -base64 32)"
heroku config:set MONGODB_URI="your-mongodb-connection-string"
heroku config:set NODE_ENV="production"
heroku config:set ALLOWED_ORIGINS="https://your-domain.com"
```

### Step 5: Deploy
```bash
git push heroku main
```

### Step 6: Check Status
```bash
heroku logs --tail
heroku open
```

**Done!** Your API is live at: `https://your-app-name.herokuapp.com/api`

---

## 🚂 Quick Deploy to Railway

### Step 1: Go to Railway
Visit [railway.app](https://railway.app) and sign up with GitHub

### Step 2: Create Project
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your repo

### Step 3: Configure
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`

### Step 4: Add Variables
Go to Variables tab, add:
```
JWT_SECRET=<generate-with: openssl rand -base64 32>
MONGODB_URI=<your-mongodb-uri>
NODE_ENV=production
ALLOWED_ORIGINS=<your-domains>
```

### Step 5: Deploy
Railway auto-deploys! Check the logs.

**Done!** Your API URL is in the dashboard.

---

## 🎨 Quick Deploy to Render

### Step 1: Go to Render
Visit [render.com](https://render.com) and sign up

### Step 2: Create Web Service
1. Click "New" → "Web Service"
2. Connect GitHub repo

### Step 3: Configure
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`

### Step 4: Add Environment Variables
Add all variables in the Environment section

### Step 5: Deploy
Click "Create Web Service"

**Done!** Your API is live!

---

## 🔑 Generate Secrets Quickly

```bash
# JWT Secret (32+ characters)
openssl rand -base64 32

# Or with Node
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## ✅ Verify It Works

```bash
# Test your API
curl https://your-api-url.com/api

# Should return something (or 404 if no root endpoint, that's OK)
```

---

## 🐛 Common Issues

**"JWT_SECRET is not defined"**
→ Set the environment variable in your platform

**"Cannot connect to database"**
→ Check MONGODB_URI is correct and database allows connections

**"Build failed"**
→ Check logs, usually missing dependencies or TypeScript errors

---

## 📝 Next Steps

1. Update your Flutter app with the production API URL
2. Test signup/login
3. Monitor logs for errors
4. Set up monitoring (optional)

---

**Need more details?** See `STEP_BY_STEP_DEPLOYMENT.md` for comprehensive guide.

