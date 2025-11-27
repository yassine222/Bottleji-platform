# 🚀 Deployment Checklist

Use this checklist before deploying to production.

## 📋 Pre-Deployment

### Environment Variables
- [ ] `JWT_SECRET` is set (minimum 32 characters, strong random string)
- [ ] `MONGODB_URI` is set and points to production database
- [ ] `NODE_ENV` is set to `production`
- [ ] `ALLOWED_ORIGINS` is set with production domains (comma-separated)
- [ ] `EMAIL_USER` and `EMAIL_PASS` are set (if using email service)
- [ ] `GOOGLE_MAPS_API_KEY` is set (if using maps)
- [ ] `FIREBASE_SERVICE_ACCOUNT_KEY` is set (if using Firebase)
- [ ] All secrets are different from development values
- [ ] All secrets are strong and unique

### Security
- [ ] `.env` file is in `.gitignore` (verify it's not committed)
- [ ] `firebase-service-account.json` is in `.gitignore` (verify it's not committed)
- [ ] No hardcoded secrets in source code
- [ ] CORS is configured for production (not allowing all origins)
- [ ] Database credentials are secure
- [ ] JWT secret is strong (32+ characters, random)

### Code
- [ ] All critical fixes from `FIXES_APPLIED.md` are in place
- [ ] Code is built successfully (`npm run build`)
- [ ] No TypeScript errors
- [ ] No linter errors
- [ ] Tests pass (if applicable)

### Database
- [ ] Production database is backed up
- [ ] Database connection string is correct
- [ ] Database user has proper permissions
- [ ] Database indexes are created
- [ ] Migrations are run (if needed)

### Dependencies
- [ ] All dependencies are up to date
- [ ] No known security vulnerabilities (`npm audit`)
- [ ] Production dependencies only (no dev dependencies)

## 🚀 Deployment Steps

### 1. Build the Application
```bash
cd backend
npm install --production
npm run build
```

### 2. Set Environment Variables
Based on your hosting platform:
- **Heroku**: Use `heroku config:set KEY=value`
- **Railway/Render**: Use web dashboard
- **VPS**: Set in systemd service file or `/etc/environment`
- **Docker**: Use `docker-compose.yml` or secrets

### 3. Start the Application
```bash
# Production start
npm run start:prod

# Or if using PM2
pm2 start dist/main.js --name bottleji-api
```

### 4. Verify Deployment
- [ ] Application starts without errors
- [ ] Health check endpoint responds (if implemented)
- [ ] Database connection is successful
- [ ] API endpoints are accessible
- [ ] Authentication works (login/signup)
- [ ] WebSocket connections work
- [ ] Email service works (if enabled)
- [ ] Firebase is initialized (if enabled)

## 🔍 Post-Deployment Verification

### API Tests
- [ ] `GET /api` - Health check
- [ ] `POST /api/auth/signup` - User signup
- [ ] `POST /api/auth/login` - User login
- [ ] `GET /api/auth/profile` - Protected route (with JWT)

### Monitoring
- [ ] Application logs are accessible
- [ ] Error logs are being captured
- [ ] Performance metrics are tracked (if applicable)
- [ ] Uptime monitoring is set up

### Security
- [ ] HTTPS is enabled
- [ ] CORS is properly configured
- [ ] Rate limiting is in place (if implemented)
- [ ] Input validation is working
- [ ] SQL injection protection (MongoDB injection protection)

## 📝 Platform-Specific Notes

### Heroku
```bash
# Set environment variables
heroku config:set JWT_SECRET=your-secret
heroku config:set MONGODB_URI=your-uri

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

### Railway
1. Connect your GitHub repository
2. Add environment variables in dashboard
3. Railway auto-deploys on push

### Render
1. Create new Web Service
2. Connect repository
3. Add environment variables
4. Set build command: `npm install && npm run build`
5. Set start command: `npm run start:prod`

### DigitalOcean App Platform
1. Create app from GitHub
2. Add environment variables
3. Set build command: `npm install && npm run build`
4. Set run command: `npm run start:prod`

### VPS (Ubuntu/Debian)
```bash
# Create systemd service
sudo nano /etc/systemd/system/botleji-api.service

# Add environment variables
[Service]
Environment="JWT_SECRET=your-secret"
Environment="MONGODB_URI=your-uri"
Environment="NODE_ENV=production"

# Start service
sudo systemctl start botleji-api
sudo systemctl enable botleji-api
```

## 🚨 Rollback Plan

If something goes wrong:
1. Revert to previous deployment
2. Check application logs
3. Verify environment variables
4. Check database connectivity
5. Review recent code changes

## 📞 Support

If deployment fails:
1. Check application logs
2. Verify all environment variables are set
3. Check database connectivity
4. Review error messages
5. Consult `ENVIRONMENT_VARIABLES_GUIDE.md`

## ✅ Final Checklist

Before going live:
- [ ] All environment variables are set correctly
- [ ] Application is running without errors
- [ ] All critical endpoints are tested
- [ ] Monitoring is set up
- [ ] Backup strategy is in place
- [ ] Rollback plan is ready
- [ ] Team is notified of deployment

---

**Remember**: Never commit sensitive data to git. Always use environment variables or secrets management services.

