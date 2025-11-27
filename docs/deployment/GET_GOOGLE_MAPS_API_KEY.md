# 🗺️ How to Get Google Maps API Key for Backend

Since you need it for accurate route duration calculations, here's how to get and set it up.

---

## 📋 Step 1: Get Google Maps API Key

### Option A: Use Existing Key (If You Have One)

If your mobile app already has a Google Maps API key, you can:
- ✅ Use the **same key** for backend (simpler)
- ✅ Or create a **separate key** for backend (more secure)

### Option B: Create New API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Create a new project (or select existing):
   - Click "Select a project" → "New Project"
   - Name: `Bottleji Backend` (or your choice)
   - Click "Create"

4. Enable Required APIs:
   - Go to "APIs & Services" → "Library"
   - Search for "Distance Matrix API"
   - Click on it → Click "Enable"
   - Also enable "Maps JavaScript API" (if not already enabled)

5. Create API Key:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the API key (looks like: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)

6. (Optional) Restrict the Key:
   - Click on the API key to edit it
   - Under "API restrictions":
     - Select "Restrict key"
     - Choose: "Distance Matrix API" (for backend)
   - Under "Application restrictions":
     - Select "IP addresses (web servers, cron jobs, etc.)"
     - Add Render's IP ranges (or leave open for now)
   - Click "Save"

---

## 📋 Step 2: Add to Render

1. Go to Render dashboard → Your service
2. Click "Environment" tab
3. Click "Add Environment Variable"
4. Enter:
   - **Key**: `GOOGLE_MAPS_API_KEY`
   - **Value**: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` (your API key)
5. Click "Save Changes"
6. Render will auto-redeploy

---

## 🔍 Verify It Works

After deployment, check logs:

```bash
# In Render logs, you should see:
✅ Route duration calculated: 15 minutes  (instead of default 20)
```

Instead of:
```
⚠️ Google Maps API key not found, using default 20 minutes
```

---

## 💰 API Costs

**Distance Matrix API Pricing:**
- First 40,000 requests/month: **FREE**
- After that: $5 per 1,000 requests

**For your use case:**
- Each collector accepting a drop = 1 API call
- If you have 100 collections/day = ~3,000/month
- **Well within free tier!** ✅

---

## 🔒 Security Best Practices

### If Using Same Key for Mobile + Backend:
- ⚠️ Less secure (key exposed in mobile app)
- ✅ Simpler to manage
- ✅ Fine for development/small apps

### If Using Separate Keys (Recommended):
- ✅ More secure
- ✅ Can restrict backend key to Distance Matrix API only
- ✅ Can restrict mobile key to Maps JavaScript API only
- ✅ Better for production

---

## 📝 Quick Steps Summary

1. **Get API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable "Distance Matrix API"
   - Create API Key

2. **Add to Render**:
   - Environment Variables → Add
   - Key: `GOOGLE_MAPS_API_KEY`
   - Value: Your API key
   - Save

3. **Verify**:
   - Check logs after deployment
   - Should see route calculations working

---

## ✅ That's It!

Once added, your backend will:
- ✅ Calculate accurate route durations
- ✅ Set dynamic timeouts based on actual driving time
- ✅ Better user experience for collectors

**Need help with any step?** Let me know! 🚀

