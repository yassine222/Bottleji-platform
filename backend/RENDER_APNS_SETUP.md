# 📝 Step-by-Step: Configure APNs on Render

## Step 1: Get Your Key ID
1. Look at your `.p8` file filename
2. Format: `AuthKey_XXXXX.p8`
3. The `XXXXX` part is your Key ID
4. **Example**: If file is `AuthKey_ABCD1234EF.p8`, Key ID = `ABCD1234EF`

---

## Step 2: Get Your Team ID
1. Go to: https://developer.apple.com/account
2. Log in with your Apple Developer account
3. Look at **top right corner** - you'll see "Team ID: XXXXX"
4. Copy that Team ID

---

## Step 3: Get .p8 File Content
1. Open your `.p8` file in a text editor
2. **Copy the ENTIRE content** including:
   ```
   -----BEGIN PRIVATE KEY-----
   (lots of text here)
   -----END PRIVATE KEY-----
   ```
3. Keep it ready to paste

---

## Step 4: Open Render Dashboard
1. Go to: https://dashboard.render.com
2. Log in
3. Click on your **backend service** (the one that runs your NestJS API)

---

## Step 5: Go to Environment Tab
1. In your service page, click **"Environment"** in the left sidebar
2. You'll see a list of existing environment variables

---

## Step 6: Add APNs Environment Variables

Click **"Add Environment Variable"** for each one:

### Variable 1: APNS_KEY_ID
- **Key**: `APNS_KEY_ID`
- **Value**: Your Key ID from Step 1 (e.g., `ABCD1234EF`)
- Click **"Save Changes"**

### Variable 2: APNS_TEAM_ID
- Click **"Add Environment Variable"** again
- **Key**: `APNS_TEAM_ID`
- **Value**: Your Team ID from Step 2 (e.g., `XYZ9876ABC`)
- Click **"Save Changes"**

### Variable 3: APNS_BUNDLE_ID
- Click **"Add Environment Variable"** again
- **Key**: `APNS_BUNDLE_ID`
- **Value**: `com.example.botleji.BottlejiLiveActivityWidget`
- Click **"Save Changes"**

### Variable 4: APNS_KEY_CONTENT
- Click **"Add Environment Variable"** again
- **Key**: `APNS_KEY_CONTENT`
- **Value**: Paste the ENTIRE content of your .p8 file from Step 3
  - Include `-----BEGIN PRIVATE KEY-----`
  - Include all the text in between
  - Include `-----END PRIVATE KEY-----`
  - **Important**: Make sure there are NO extra spaces or line breaks at the start/end
- Click **"Save Changes"**

---

## Step 7: Verify All Variables Are Added

You should now see these 4 variables in your environment list:
- ✅ `APNS_KEY_ID`
- ✅ `APNS_TEAM_ID`
- ✅ `APNS_BUNDLE_ID`
- ✅ `APNS_KEY_CONTENT`

---

## Step 8: Redeploy Your Service

1. After adding all variables, Render will show a notification that changes require a redeploy
2. Click **"Manual Deploy"** → **"Deploy latest commit"**
   - OR Render might auto-deploy (wait a few minutes)
3. Wait for deployment to complete

---

## Step 9: Check Logs

1. After deployment, go to **"Logs"** tab in Render
2. Look for these messages:
   ```
   ✅ APNs provider initialized successfully
   ✅ APNs environment: Production (or Development)
   ✅ Bundle ID: com.example.botleji.BottlejiLiveActivityWidget
   ✅ Key ID: YOUR_KEY_ID
   ✅ Team ID: YOUR_TEAM_ID
   ```

If you see these messages, APNs is configured correctly! 🎉

---

## Troubleshooting

### ❌ "APNs provider not initialized"
- Check that all 4 environment variables are set
- Verify Key ID and Team ID are correct (no extra spaces)
- Check that APNS_KEY_CONTENT includes the BEGIN/END lines

### ❌ "APNs key file not found"
- You're using APNS_KEY_PATH instead of APNS_KEY_CONTENT
- Remove APNS_KEY_PATH and use APNS_KEY_CONTENT instead

### ❌ "Invalid key format"
- Make sure APNS_KEY_CONTENT includes the BEGIN and END lines
- No extra spaces before/after the content
- All line breaks should be preserved (Render handles this automatically)

---

## After Setup

Once configured, Live Activity updates will use direct APNs instead of FCM. You'll see logs like:
```
📤 [sendLiveActivityUpdate] Sending via direct APNs
✅ [sendLiveActivityUpdate] Live Activity update sent successfully
```

