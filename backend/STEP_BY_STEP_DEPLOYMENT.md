# 🚀 Step-by-Step Deployment Guide

Follow these steps in order to deploy your backend to production.

---

## 📋 STEP 1: Prepare Your Code

### 1.1 Verify Code is Ready
```bash
cd backend

# Check for any uncommitted changes
git status

# Make sure you're on the right branch
git branch
```

### 1.2 Build the Application
```bash
# Install dependencies
npm install

# Build the application
npm run build

# Verify build succeeded (check for dist/ folder)
ls -la dist/
```

### 1.3 Run Tests (if you have them)
```bash
npm test
```

**✅ Checkpoint**: Build completes without errors

---

## 📋 STEP 2: Choose Your Hosting Platform

Select one of these platforms:

- **Heroku** - Easy, free tier available
- **Railway** - Modern, good free tier
- **Render** - Simple, free tier available
- **DigitalOcean App Platform** - Reliable, paid
- **VPS (Ubuntu Server)** - Full control, requires setup

**For this guide, we'll cover the most common: Heroku, Railway, and VPS**

---

## 📋 STEP 3: Prepare Environment Variables

### 3.1 Generate Strong Secrets

```bash
# Generate a strong JWT secret (32+ characters)
# Option 1: Using openssl
openssl rand -base64 32

# Option 2: Using node
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Save this somewhere safe - you'll need it!
```

### 3.2 List All Required Variables

Create a list with your values:

```
JWT_SECRET=<generated-secret-from-step-3.1>
MONGODB_URI=<your-production-database-uri>
NODE_ENV=production
PORT=3000
JWT_EXPIRES_IN=7d
ALLOWED_ORIGINS=https://your-app-domain.com,https://your-admin-domain.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-gmail-app-password
GOOGLE_MAPS_API_KEY=your-google-maps-key
FIREBASE_SERVICE_ACCOUNT_KEY=<firebase-json-as-string>
```

**✅ Checkpoint**: You have all values ready

---

## 📋 STEP 4: Set Up Database

### 4.1 Choose Database Provider

Options:
- **MongoDB Atlas** (Recommended - Free tier available)
- **Self-hosted MongoDB**
- **Other MongoDB cloud providers**

### 4.2 Create Production Database

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a new cluster (free tier is fine)
3. Create a database user
4. Whitelist IP addresses (or use 0.0.0.0/0 for cloud hosting)
5. Get connection string

**Connection string format:**
```
mongodb+srv://username:password@cluster.mongodb.net/database-name?retryWrites=true&w=majority
```

### 4.3 Test Database Connection

```bash
# Test locally first
export MONGODB_URI="your-connection-string"
npm run start:dev
# Check logs - should connect successfully
```

**✅ Checkpoint**: Database connection works

---

## 📋 STEP 5: Deploy to Platform

Choose your platform and follow the corresponding section:

---

### 🟣 OPTION A: Deploy to Heroku

#### Step 5A.1: Install Heroku CLI
```bash
# macOS
brew tap heroku/brew && brew install heroku

# Or download from: https://devcenter.heroku.com/articles/heroku-cli
```

#### Step 5A.2: Login to Heroku
```bash
heroku login
```

#### Step 5A.3: Create Heroku App
```bash
# Create app
heroku create your-app-name

# Or if you already have an app
heroku git:remote -a your-app-name
```

#### Step 5A.4: Set Environment Variables
```bash
# Set each variable one by one
heroku config:set JWT_SECRET="your-jwt-secret"
heroku config:set MONGODB_URI="your-mongodb-uri"
heroku config:set NODE_ENV="production"
heroku config:set ALLOWED_ORIGINS="https://your-domain.com"
heroku config:set EMAIL_USER="your-email@gmail.com"
heroku config:set EMAIL_PASS="your-app-password"
heroku config:set GOOGLE_MAPS_API_KEY="your-key"
heroku config:set FIREBASE_SERVICE_ACCOUNT_KEY="your-firebase-json"

# Verify all variables are set
heroku config
```

#### Step 5A.5: Configure Buildpacks
```bash
# Set Node.js buildpack
heroku buildpacks:set heroku/nodejs
```

#### Step 5A.6: Deploy
```bash
# Deploy to Heroku
git push heroku main

# Or if your branch is called master
git push heroku master
```

#### Step 5A.7: Verify Deployment
```bash
# Check logs
heroku logs --tail

# Open app
heroku open
```

**✅ Checkpoint**: App is running on Heroku

---

### 🟢 OPTION B: Deploy to Railway

#### Step 5B.1: Create Railway Account
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub

#### Step 5B.2: Create New Project
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Select your repository
4. Select the `backend` folder (or root if backend is root)

#### Step 5B.3: Configure Build Settings
1. Go to Settings → Build
2. Build Command: `npm install && npm run build`
3. Start Command: `npm run start:prod`
4. Root Directory: `backend` (if backend is a subfolder)

#### Step 5B.4: Set Environment Variables
1. Go to Variables tab
2. Add each variable:
   - `JWT_SECRET` = your-secret
   - `MONGODB_URI` = your-uri
   - `NODE_ENV` = production
   - `ALLOWED_ORIGINS` = your-domains
   - (Add all other variables)

#### Step 5B.5: Deploy
1. Railway auto-deploys on push
2. Or click "Deploy" button
3. Watch deployment logs

#### Step 5B.6: Get Your URL
1. Go to Settings → Networking
2. Generate domain or use custom domain

**✅ Checkpoint**: App is running on Railway

---

### 🔵 OPTION C: Deploy to Render

#### Step 5C.1: Create Render Account
1. Go to [render.com](https://render.com)
2. Sign up with GitHub

#### Step 5C.2: Create New Web Service
1. Click "New" → "Web Service"
2. Connect your GitHub repository
3. Select repository and branch

#### Step 5C.3: Configure Service
- **Name**: `bottleji-api` (or your choice)
- **Environment**: `Node`
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`
- **Root Directory**: `backend` (if backend is subfolder)

#### Step 5C.4: Set Environment Variables
1. Scroll to "Environment Variables"
2. Add each variable:
   - `JWT_SECRET`
   - `MONGODB_URI`
   - `NODE_ENV=production`
   - (Add all others)

#### Step 5C.5: Deploy
1. Click "Create Web Service"
2. Render will build and deploy
3. Watch build logs

#### Step 5C.6: Get Your URL
- Render provides a URL like: `your-app.onrender.com`
- Or add custom domain in Settings

**✅ Checkpoint**: App is running on Render

---

### ⚫ OPTION D: Deploy to VPS (Ubuntu Server)

#### Step 5D.1: Set Up Server
```bash
# SSH into your server
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js (v18 or v20)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 (process manager)
sudo npm install -g pm2

# Install Git
sudo apt install -y git
```

#### Step 5D.2: Clone Repository
```bash
# Create app directory
mkdir -p /var/www/bottleji-api
cd /var/www/bottleji-api

# Clone your repo
git clone https://github.com/your-username/your-repo.git .

# Or if using SSH
git clone git@github.com:your-username/your-repo.git .
```

#### Step 5D.3: Install Dependencies
```bash
cd backend
npm install --production
npm run build
```

#### Step 5D.4: Create Environment File
```bash
# Create .env file
nano .env

# Add all your environment variables:
JWT_SECRET=your-secret
MONGODB_URI=your-uri
NODE_ENV=production
# ... (add all others)

# Save and exit (Ctrl+X, Y, Enter)

# Set proper permissions
chmod 600 .env
```

#### Step 5D.5: Create PM2 Ecosystem File
```bash
# Create ecosystem file
nano ecosystem.config.js
```

Add this content:
```javascript
module.exports = {
  apps: [{
    name: 'bottleji-api',
    script: './dist/main.js',
    cwd: '/var/www/bottleji-api/backend',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production'
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
};
```

#### Step 5D.6: Start Application
```bash
# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Follow the instructions it gives you
```

#### Step 5D.7: Set Up Nginx (Reverse Proxy)
```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/bottleji-api
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/bottleji-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Step 5D.8: Set Up SSL (Let's Encrypt)
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

**✅ Checkpoint**: App is running on VPS

---

## 📋 STEP 6: Verify Deployment

### 6.1 Check Application Logs
```bash
# Heroku
heroku logs --tail

# Railway/Render
# Check logs in dashboard

# VPS
pm2 logs bottleji-api
```

### 6.2 Test API Endpoints

Test these endpoints:

```bash
# Health check (if you have one)
curl https://your-api-url.com/api

# Signup
curl -X POST https://your-api-url.com/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Login
curl -X POST https://your-api-url.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 6.3 Verify Environment Variables
```bash
# Heroku
heroku config

# Railway/Render
# Check in dashboard

# VPS
cd /var/www/bottleji-api/backend
cat .env
```

**✅ Checkpoint**: All endpoints work correctly

---

## 📋 STEP 7: Update Frontend

### 7.1 Update API Base URL

In your Flutter app (`botleji/lib/main.dart` or wherever you set the API URL):

```dart
// Change from local/development URL
// To your production URL
final apiBaseUrl = 'https://your-api-url.com/api';
```

### 7.2 Test Frontend Connection

1. Run your Flutter app
2. Try to signup/login
3. Verify it connects to production API

**✅ Checkpoint**: Frontend connects to production API

---

## 📋 STEP 8: Monitor and Maintain

### 8.1 Set Up Monitoring

- **Uptime Monitoring**: Use UptimeRobot, Pingdom, etc.
- **Error Tracking**: Consider Sentry
- **Logs**: Use platform's log viewer

### 8.2 Set Up Alerts

- Email alerts for downtime
- Error rate alerts
- Database connection alerts

### 8.3 Regular Maintenance

- Update dependencies regularly
- Monitor logs for errors
- Backup database regularly
- Rotate secrets periodically

---

## 🚨 Troubleshooting

### Problem: App won't start
**Solution:**
1. Check logs: `heroku logs --tail` or `pm2 logs`
2. Verify all environment variables are set
3. Check database connection
4. Verify build succeeded

### Problem: Database connection fails
**Solution:**
1. Verify `MONGODB_URI` is correct
2. Check database IP whitelist
3. Verify database credentials
4. Test connection locally first

### Problem: 401 Unauthorized errors
**Solution:**
1. Verify `JWT_SECRET` is set correctly
2. Check token expiration settings
3. Verify frontend is using correct API URL

### Problem: CORS errors
**Solution:**
1. Verify `ALLOWED_ORIGINS` includes your frontend domain
2. Check CORS configuration in `main.ts`
3. Ensure no trailing slashes in URLs

---

## ✅ Final Checklist

Before going live:

- [ ] Code is built successfully
- [ ] All environment variables are set
- [ ] Database is connected and working
- [ ] API endpoints are accessible
- [ ] Frontend is updated with production URL
- [ ] SSL/HTTPS is enabled
- [ ] Monitoring is set up
- [ ] Backups are configured
- [ ] Team is notified

---

## 🎉 You're Done!

Your backend is now deployed and running in production!

**Next Steps:**
1. Monitor logs for the first few days
2. Set up automated backups
3. Configure monitoring alerts
4. Document your deployment process for your team

---

## 📞 Need Help?

- Check `ENVIRONMENT_VARIABLES_GUIDE.md` for environment variable details
- Check `DEPLOYMENT_CHECKLIST.md` for a quick checklist
- Review application logs for specific errors
- Check platform-specific documentation

