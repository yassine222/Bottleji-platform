# Environment Variables & API Keys Management Guide

## 🔐 Overview

This guide explains how to securely manage sensitive API keys and configuration for deployment.

## 📋 Required Environment Variables

### Critical (Required for Production)

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `JWT_SECRET` | Secret key for JWT token signing | `your-super-secret-jwt-key-min-32-chars` | ✅ Yes |
| `MONGODB_URI` | MongoDB connection string | `mongodb://user:pass@host:27017/dbname` | ✅ Yes |
| `NODE_ENV` | Environment mode | `production` | ✅ Yes |

### Optional (But Recommended)

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `PORT` | Server port | `3000` | ❌ No (default: 3000) |
| `JWT_EXPIRES_IN` | JWT token expiration | `7d` | ❌ No (default: 7d) |
| `EMAIL_USER` | Gmail account for sending emails | `your-email@gmail.com` | ❌ No |
| `EMAIL_PASS` | Gmail app password | `your-app-password` | ❌ No |
| `GOOGLE_MAPS_API_KEY` | Google Maps API key | `AIza...` | ❌ No |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Firebase service account JSON (stringified) | `{"type":"service_account",...}` | ❌ No* |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins | `https://app.example.com,https://admin.example.com` | ❌ No (required in production) |

*Firebase can use either `FIREBASE_SERVICE_ACCOUNT_KEY` env var OR `firebase-service-account.json` file

## 🚀 Deployment Methods

### Method 1: Environment Variables (Recommended for Cloud)

**Best for**: Heroku, Railway, Render, AWS, DigitalOcean, etc.

#### Steps:
1. Set environment variables in your hosting platform's dashboard
2. No files needed - everything is in the platform's environment

#### Example (Heroku):
```bash
heroku config:set JWT_SECRET=your-secret-key
heroku config:set MONGODB_URI=mongodb://...
heroku config:set NODE_ENV=production
```

#### Example (Railway/Render):
- Use the web dashboard to add environment variables
- Or use their CLI if available

### Method 2: .env File (Local Development)

**Best for**: Local development, Docker Compose

#### Steps:
1. Create `.env` file in `backend/` directory
2. Add your variables (see `.env.example`)
3. **NEVER commit `.env` to git** (already in `.gitignore`)

#### Example `.env`:
```env
NODE_ENV=development
PORT=3000
JWT_SECRET=your-development-secret-key-change-in-production
MONGODB_URI=mongodb://localhost:27017/eco_collect
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
GOOGLE_MAPS_API_KEY=your-google-maps-key
ALLOWED_ORIGINS=http://localhost:3001,http://localhost:3000
```

### Method 3: Docker Secrets (Docker Swarm/Kubernetes)

**Best for**: Docker Swarm, Kubernetes

#### Steps:
1. Create secrets in Docker/Kubernetes
2. Mount secrets as environment variables or files

#### Example (Docker Swarm):
```bash
echo "your-secret" | docker secret create jwt_secret -
```

### Method 4: Cloud Secrets Manager (Enterprise)

**Best for**: AWS, GCP, Azure

#### AWS Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name bottleji/jwt-secret \
  --secret-string "your-secret-key"
```

#### Google Cloud Secret Manager:
```bash
gcloud secrets create jwt-secret --data-file=- <<< "your-secret-key"
```

## 📁 File-Based Secrets (Alternative)

### Firebase Service Account

**Option A: Environment Variable (Recommended for Production)**
```bash
# Set as single-line JSON string
export FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"..."}'
```

**Option B: File (Development Only)**
- Place `firebase-service-account.json` in `backend/` directory
- **NEVER commit to git** (already in `.gitignore`)
- File is automatically detected if env var is not set

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Use strong, random secrets (min 32 characters for JWT_SECRET)
- ✅ Use different secrets for development and production
- ✅ Rotate secrets periodically
- ✅ Use environment variables in production
- ✅ Use secrets management services (AWS Secrets Manager, etc.)
- ✅ Restrict access to secrets (principle of least privilege)
- ✅ Log which environment variables are loaded (but not their values)
- ✅ Validate environment variables on startup

### ❌ DON'T:
- ❌ Commit `.env` files to git
- ❌ Commit `firebase-service-account.json` to git
- ❌ Hardcode secrets in source code
- ❌ Share secrets via email/chat
- ❌ Use production secrets in development
- ❌ Log secret values
- ❌ Store secrets in client-side code

## 🛠️ Setup Instructions by Platform

### Heroku
1. Go to your app → Settings → Config Vars
2. Add each environment variable
3. Deploy - variables are automatically available

### Railway
1. Go to your project → Variables
2. Add each environment variable
3. Redeploy if needed

### Render
1. Go to your service → Environment
2. Add each environment variable
3. Save and redeploy

### DigitalOcean App Platform
1. Go to App Settings → App-Level Environment Variables
2. Add each variable
3. Redeploy

### AWS EC2 / VPS
1. SSH into your server
2. Create `/etc/environment` or use systemd service file
3. Or use `.env` file (ensure proper permissions: `chmod 600 .env`)

### Docker
```dockerfile
# Dockerfile
ENV NODE_ENV=production

# docker-compose.yml
services:
  backend:
    environment:
      - JWT_SECRET=${JWT_SECRET}
      - MONGODB_URI=${MONGODB_URI}
    env_file:
      - .env
```

## 🔍 Verification

After deployment, verify environment variables are loaded:

1. Check application logs on startup
2. The app will log which environment it's running in
3. Missing required variables will cause startup to fail with clear error messages

## 📝 Environment Variable Checklist

Before deploying to production:

- [ ] `JWT_SECRET` is set and is at least 32 characters
- [ ] `MONGODB_URI` is set and points to production database
- [ ] `NODE_ENV` is set to `production`
- [ ] `ALLOWED_ORIGINS` is set with your production domains
- [ ] `EMAIL_USER` and `EMAIL_PASS` are set (if using email)
- [ ] `GOOGLE_MAPS_API_KEY` is set (if using maps)
- [ ] `FIREBASE_SERVICE_ACCOUNT_KEY` is set (if using Firebase)
- [ ] All secrets are different from development
- [ ] `.env` file is in `.gitignore` (verify it's not committed)
- [ ] `firebase-service-account.json` is in `.gitignore`

## 🚨 Troubleshooting

### "JWT_SECRET is not defined"
- Set `JWT_SECRET` environment variable
- Restart the application

### "Email service disabled"
- Set `EMAIL_USER` and `EMAIL_PASS`
- For Gmail, use an App Password (not your regular password)

### "Firebase Admin SDK not initialized"
- Set `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable, OR
- Place `firebase-service-account.json` in backend root

### "Invalid credentials" errors
- Check that `MONGODB_URI` is correct
- Verify database user has proper permissions

## 📚 Additional Resources

- [NestJS Configuration](https://docs.nestjs.com/techniques/configuration)
- [12-Factor App: Config](https://12factor.net/config)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

