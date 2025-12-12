# Set FIREBASE_SERVICE_ACCOUNT_KEY in Render

## Problem

You're seeing this error:
```
Firebase Admin SDK initialized but project ID is missing!
```

This means the `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable is **not set** in your Render dashboard.

## Solution: Add Firebase Service Account Key to Render

### Step 1: Get Your Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **botleji**
3. Click the **gear icon** (⚙️) → **Project settings**
4. Go to **"Service accounts"** tab
5. Click **"Generate new private key"**
6. Click **"Generate key"** in the dialog
7. A JSON file will download (e.g., `botleji-firebase-adminsdk-xxxxx.json`)

### Step 2: Copy the JSON Content

1. Open the downloaded JSON file
2. **Copy the ENTIRE content** (all of it, from `{` to `}`)
3. It should look like this:
   ```json
   {
     "type": "service_account",
     "project_id": "botleji",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@botleji.iam.gserviceaccount.com",
     ...
   }
   ```

### Step 3: Add to Render Environment Variables

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click on your **backend service** (the NestJS service)
3. Go to **"Environment"** tab (in the left sidebar)
4. Scroll to **"Environment Variables"** section
5. Click **"Add Environment Variable"**
6. Enter:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT_KEY`
   - **Value**: Paste the **ENTIRE JSON** as a **single line** (no line breaks)
   
   ⚠️ **Important**: 
   - Remove all line breaks
   - Make it one continuous line
   - Keep all the quotes and structure intact
   
   Example format:
   ```
   {"type":"service_account","project_id":"botleji","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
   ```

7. Click **"Save Changes"**
8. Render will **automatically redeploy** your service

### Step 4: Verify It Works

After deployment completes:

1. Check **Render logs** for:
   ```
   ✅ Using FIREBASE_SERVICE_ACCOUNT_KEY from environment variable
   ✅ Project ID: botleji
   ✅ Firebase Admin SDK initialized successfully with service account
   ✅ Firebase Project ID: botleji
   ```

2. **Test a notification** (e.g., lock/unlock a user from admin dashboard)

3. Check logs for:
   ```
   ✅ FCM notification sent successfully to user [userId]
   ```

## Alternative: Use Service Account File (Not Recommended for Render)

If you prefer using a file instead of environment variable:

1. Add `firebase-service-account.json` to your backend directory
2. **Add to `.gitignore`** (IMPORTANT - never commit this file!)
3. The code will automatically detect it

⚠️ **However**, this is **NOT recommended** for Render because:
- Files in the repo are public (even if in .gitignore, they shouldn't be in the repo)
- Environment variables are more secure
- Environment variables are easier to manage

## Troubleshooting

### Still seeing "project ID is missing"?

1. **Check the environment variable is set:**
   - Go to Render → Environment tab
   - Verify `FIREBASE_SERVICE_ACCOUNT_KEY` exists
   - Check the value starts with `{"type":"service_account"`

2. **Check the JSON is valid:**
   - Make sure it's a single line (no line breaks)
   - Make sure all quotes are properly escaped
   - Make sure it starts with `{` and ends with `}`

3. **Check Render logs:**
   - Look for initialization logs
   - Should see: `✅ Using FIREBASE_SERVICE_ACCOUNT_KEY from environment variable`
   - Should see: `✅ Project ID: botleji`

### JSON parsing error?

- Make sure the JSON is on **one line** (no line breaks)
- Make sure all quotes are properly formatted
- Try copying the JSON again from the downloaded file

### Still not working?

1. **Check backend logs** for detailed error messages
2. **Verify the service account key** is valid (download a new one if needed)
3. **Make sure you're using the correct Firebase project** (botleji)

---

**Once you add the environment variable and redeploy, FCM notifications should work!** 🎉

