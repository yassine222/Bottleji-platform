# 🔑 Which Google Maps API Key to Use for Backend?

You have 3 API keys. Here's which one to use for your backend:

---

## 🎯 Quick Answer

**Use: Browser Key** ✅

**Why:**
- Browser keys are less restricted
- Can work for server-side calls
- Most flexible option

**Or better: Create a Server Key** (recommended)

---

## 📋 Your Three Keys Explained

### 1. iOS Key
- **Purpose**: For iOS mobile app
- **Restrictions**: iOS apps only
- **Backend?**: ❌ Won't work (restricted to iOS)

### 2. Android Key
- **Purpose**: For Android mobile app
- **Restrictions**: Android apps only
- **Backend?**: ❌ Won't work (restricted to Android)

### 3. Browser Key
- **Purpose**: For web browsers
- **Restrictions**: HTTP referrers (websites)
- **Backend?**: ✅ **Can work** (but not ideal)

---

## ✅ Best Option: Create Server Key

For backend/server-side use, you should create a **Server Key** (also called "API Key" without platform restrictions).

### Why Server Key?
- ✅ Designed for server-side use
- ✅ Can be restricted to specific APIs (Distance Matrix API)
- ✅ Can be restricted to IP addresses (Render's IPs)
- ✅ More secure than browser key
- ✅ Better for production

---

## 🚀 How to Create Server Key

### Step 1: Go to Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" → "Credentials"

### Step 2: Create New API Key
1. Click "Create Credentials" → "API Key"
2. A new key will be created (unrestricted by default)

### Step 3: Restrict the Key (Recommended)
1. Click on the newly created key to edit it
2. Under "API restrictions":
   - Select "Restrict key"
   - Check only: **"Distance Matrix API"** ✅
   - (Uncheck others if checked)
3. Under "Application restrictions":
   - Select "IP addresses (web servers, cron jobs, etc.)"
   - Add Render's IP ranges (or leave open for now to test)
   - Or select "None" for now (less secure but easier)
4. Click "Save"

### Step 4: Copy the Key
- Copy the API key (starts with `AIzaSy...`)
- This is your **Server Key** for backend

---

## 🔄 Alternative: Use Browser Key (Quick Test)

If you want to test quickly without creating a new key:

1. **Try using your Browser Key** in Render
2. It might work if it's not too restricted
3. If it doesn't work, you'll see errors in logs
4. Then create a Server Key as above

**To test:**
- Add Browser Key to Render
- Check logs after deployment
- If you see route calculations working → ✅ Success!
- If you see API errors → Create Server Key

---

## 📋 Which Key Goes Where

| Location | Key Type | Key Name |
|----------|----------|----------|
| **iOS App** | iOS Key | Your iOS key |
| **Android App** | Android Key | Your Android key |
| **Web/Admin Dashboard** | Browser Key | Your Browser key |
| **Backend (Render)** | Server Key | New server key (or Browser key for testing) |

---

## 🔒 Security Recommendations

### For Production:
1. **Create separate Server Key** for backend
2. **Restrict to Distance Matrix API only**
3. **Restrict to Render IPs** (if possible)
4. **Don't use Browser Key** in backend (less secure)

### For Testing:
- ✅ Use Browser Key temporarily
- ✅ Then create proper Server Key

---

## ✅ Quick Steps

### Option A: Use Browser Key (Quick Test)
1. Copy your Browser Key
2. Add to Render: `GOOGLE_MAPS_API_KEY = your-browser-key`
3. Test and see if it works

### Option B: Create Server Key (Recommended)
1. Go to Google Cloud Console
2. Create new API Key (unrestricted)
3. Restrict to Distance Matrix API
4. Add to Render: `GOOGLE_MAPS_API_KEY = your-server-key`

---

## 🎯 Recommendation

**For now (quick deployment):**
- ✅ Use your **Browser Key** to test
- ✅ Add it to Render
- ✅ See if it works

**Later (production):**
- ✅ Create a **Server Key** specifically for backend
- ✅ Restrict it properly
- ✅ Replace Browser Key with Server Key

---

## 📝 Summary

**Your 3 keys:**
- iOS Key → iOS app ✅
- Android Key → Android app ✅
- Browser Key → Web/Admin + Backend (testing) ✅

**Best for Backend:**
- Server Key (create new one) ✅✅✅

**Quick start:**
- Use Browser Key now, create Server Key later

---

**Which do you want to use?** Browser Key for quick test, or create a Server Key? 🚀

