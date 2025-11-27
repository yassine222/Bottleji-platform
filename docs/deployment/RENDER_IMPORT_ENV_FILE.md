# 📄 Using Your .env File in Render

You're using the `.env` file in `backend/` directory. Here's what you have and how to use it in Render.

---

## 📋 Your Current .env File Contents

Your `.env` file in `backend/` contains:

```
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji
JWT_SECRET=bottleji-super-secret-jwt-key-2024-secure-auth-token
JWT_EXPIRES_IN=30d
EMAIL_USER=bottleji.tn@gmail.com
EMAIL_PASS=ojwi qbpy kbcs zplx
```

**Missing**: `GOOGLE_MAPS_API_KEY` (optional)

---

## 🚀 Option 1: Import .env File in Render (Easiest!)

Render has a feature to import from `.env` file:

### Steps:
1. In Render dashboard, go to your service
2. Click **"Environment"** tab
3. Look for **"Import from .env file"** or **"Upload .env"** button
4. Click it and upload your `backend/.env` file
5. Render will automatically add all variables
6. **IMPORTANT**: Update `NODE_ENV` to `production` (change from `development`)
7. **IMPORTANT**: Update `JWT_SECRET` to a production secret (use the generated one: `BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=`)

### After Import:
- ✅ All your variables will be there
- ✅ Just need to update `NODE_ENV` to `production`
- ✅ Update `JWT_SECRET` to production secret
- ✅ Optionally add `GOOGLE_MAPS_API_KEY` if you have it

---

## 🚀 Option 2: Add Variables Manually (More Control)

If you prefer to add them one by one:

### Required Variables:
```
JWT_SECRET = BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=
MONGODB_URI = mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji
NODE_ENV = production
```

### Recommended Variables:
```
EMAIL_USER = bottleji.tn@gmail.com
EMAIL_PASS = ojwi qbpy kbcs zplx
JWT_EXPIRES_IN = 30d
PORT = 3000
```

### Optional:
```
GOOGLE_MAPS_API_KEY = (add if you have it)
ALLOWED_ORIGINS = (add your frontend domains)
```

---

## ⚠️ Important Changes for Production

When deploying to production, you should:

### 1. Change NODE_ENV
```
Development: NODE_ENV=development
Production:  NODE_ENV=production  ← Change this!
```

### 2. Use Production JWT_SECRET
```
Development: JWT_SECRET=bottleji-super-secret-jwt-key-2024-secure-auth-token
Production:  JWT_SECRET=BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=  ← Use generated one!
```

### 3. Verify MongoDB URI
- Make sure your MongoDB Atlas cluster allows connections from Render's IPs
- In MongoDB Atlas, set IP whitelist to `0.0.0.0/0` (allow all) for now
- Or add Render's IP ranges later

---

## 📝 Complete Production Environment Variables

Here's what you should have in Render for production:

```
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji
JWT_SECRET=BGaywqfBGruNi65CntQer31n8MP9QbPmYTGEx7oAMho=
JWT_EXPIRES_IN=30d
EMAIL_USER=bottleji.tn@gmail.com
EMAIL_PASS=ojwi qbpy kbcs zplx
GOOGLE_MAPS_API_KEY=(optional - add if you have it)
ALLOWED_ORIGINS=(optional - add your frontend domains)
```

---

## ✅ Quick Steps

1. **In Render**, go to Environment Variables
2. **Click "Import from .env file"** (if available)
3. **Upload** your `backend/.env` file
4. **Update** `NODE_ENV` to `production`
5. **Update** `JWT_SECRET` to the generated production secret
6. **Add** `GOOGLE_MAPS_API_KEY` if you have it
7. **Save** and deploy!

---

## 🔒 Security Note

**Important**: 
- Your `.env` file contains sensitive data
- Never commit it to git (it's already in `.gitignore` ✅)
- Use different secrets for production
- The JWT_SECRET in your .env is for development - use a new one for production

---

## 📋 Summary

**Your .env file location**: `backend/.env`

**What to do**:
1. Import it to Render (easiest)
2. OR manually add each variable
3. Change `NODE_ENV` to `production`
4. Change `JWT_SECRET` to production secret
5. Add `GOOGLE_MAPS_API_KEY` if needed

That's it! 🚀

