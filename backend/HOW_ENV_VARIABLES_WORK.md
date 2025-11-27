# 🔌 How Environment Variables Connect to Backend

After adding environment variables in Render, here's how they automatically connect to your backend code.

---

## 🔄 Automatic Connection

**Good News**: It's **automatic**! You don't need to do anything special.

When Render starts your app, it:
1. ✅ Sets environment variables in the process
2. ✅ Your Node.js app automatically reads them via `process.env`
3. ✅ NestJS ConfigModule makes them available everywhere
4. ✅ Your code uses them directly

---

## 🎯 How It Works

### Step 1: Render Sets Variables
When Render runs your app, it sets environment variables in the process:
```bash
# Render does this automatically:
export JWT_SECRET="your-secret"
export MONGODB_URI="your-uri"
export NODE_ENV="production"
# etc...
```

### Step 2: Node.js Reads Them
Node.js automatically makes them available via `process.env`:
```javascript
process.env.JWT_SECRET  // ✅ Available!
process.env.MONGODB_URI // ✅ Available!
```

### Step 3: NestJS ConfigModule
Your `app.module.ts` has:
```typescript
ConfigModule.forRoot({
  isGlobal: true,  // Makes env vars available everywhere
  validationSchema: require('./config/validation.schema').validationSchema,
})
```

This makes environment variables available throughout your app!

### Step 4: Your Code Uses Them
Your code reads them like this:
```typescript
// Direct access:
const apiKey = process.env.GOOGLE_MAPS_API_KEY;

// Via ConfigService:
const jwtSecret = configService.get<string>('JWT_SECRET');
```

---

## 📍 Where Variables Are Used in Your Code

### 1. JWT_SECRET
**File**: `src/modules/auth/strategies/jwt.strategy.ts`
```typescript
const jwtSecret = configService.get<string>('JWT_SECRET');
```

**File**: `src/modules/auth/auth.module.ts`
```typescript
secret: configService.get<string>('JWT_SECRET'),
```

### 2. MONGODB_URI
**File**: `src/app.module.ts`
```typescript
MongooseModule.forRoot(process.env.MONGODB_URI || 'mongodb://localhost:27017/eco_collect'),
```

### 3. NODE_ENV
**File**: `src/main.ts`
```typescript
const allowedOrigins = process.env.NODE_ENV === 'production'
  ? (process.env.ALLOWED_ORIGINS?.split(',') || [])
  : true;
```

### 4. GOOGLE_MAPS_API_KEY
**File**: `src/modules/dropoffs/dropoffs.service.ts`
```typescript
const apiKey = process.env.GOOGLE_MAPS_API_KEY;
```

### 5. EMAIL_USER & EMAIL_PASS
**File**: `src/modules/email/email.service.ts`
```typescript
const emailUser = this.configService.get<string>('EMAIL_USER');
const emailPass = this.configService.get<string>('EMAIL_PASS');
```

### 6. PORT
**File**: `src/main.ts`
```typescript
const port = process.env.PORT ?? 3000;
await app.listen(port, '0.0.0.0');
```

---

## 🔍 How to Verify They're Connected

### Method 1: Check Logs
After deployment, check Render logs. You should see:
```
✅ Application is running on: http://0.0.0.0:3000/api
📝 Environment: production
```

If you see errors like:
```
❌ JWT_SECRET is not defined
```
Then the variable isn't set correctly.

### Method 2: Add Temporary Logging
You can temporarily add logging to verify (remove after testing):

```typescript
// In main.ts, add temporarily:
console.log('🔍 Environment Variables:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('JWT_SECRET:', process.env.JWT_SECRET ? '✅ Set' : '❌ Missing');
console.log('MONGODB_URI:', process.env.MONGODB_URI ? '✅ Set' : '❌ Missing');
```

---

## 🔄 Flow Diagram

```
Render Dashboard
    ↓
[Add Environment Variables]
    ↓
Render Sets: process.env.JWT_SECRET = "value"
    ↓
Node.js Process Starts
    ↓
NestJS App Initializes
    ↓
ConfigModule.forRoot() loads all env vars
    ↓
Your Code Reads: process.env.JWT_SECRET ✅
    ↓
App Uses Variables ✅
```

---

## ✅ What Happens Automatically

1. **Render sets variables** → You add them in dashboard
2. **Node.js reads them** → `process.env.VARIABLE_NAME`
3. **NestJS makes them global** → `ConfigModule.forRoot({ isGlobal: true })`
4. **Your code uses them** → Already coded to read from `process.env`

**No extra code needed!** It just works! 🎉

---

## 🐛 Troubleshooting

### Problem: Variable not found
**Check:**
1. Variable name is exact (case-sensitive): `JWT_SECRET` not `jwt_secret`
2. Variable is saved in Render
3. Service was redeployed after adding variable

### Problem: Wrong value
**Check:**
1. No extra spaces in value
2. No quotes around value (Render handles this)
3. Value is correct in Render dashboard

### Problem: App crashes on startup
**Check logs for:**
- Missing required variables (JWT_SECRET, MONGODB_URI)
- Invalid values (wrong format)
- Connection errors (MongoDB URI wrong)

---

## 📝 Summary

**How it works:**
1. ✅ You add variables in Render dashboard
2. ✅ Render sets them when app starts
3. ✅ Your code reads them via `process.env.VARIABLE_NAME`
4. ✅ Everything works automatically!

**No configuration needed** - just add variables in Render and they're automatically available in your code! 🚀

---

## ✅ Quick Checklist

After adding variables in Render:
- [ ] Variables are saved in Render
- [ ] Service redeploys automatically
- [ ] Check logs for any errors
- [ ] Verify app starts successfully
- [ ] Test API endpoints

**That's it!** The connection is automatic! ✨

