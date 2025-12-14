# APNs Configuration Values for Render

## ✅ Key ID (from filename)
```
4YF5542553
```

## 📋 Team ID
**You need to get this from Apple Developer Portal:**
1. Go to: https://developer.apple.com/account
2. Log in
3. Look at **top right corner** - you'll see "Team ID: XXXXX"
4. Copy that Team ID here: `_________________`

## 🔑 Bundle ID
```
com.example.botleji.BottlejiLiveActivityWidget
```

## 📝 Key Content
Your key content is in the file. For Render:
1. Copy the ENTIRE content from `AuthKey_4YF5542553.p8`
2. Include `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
3. Paste it as the value for `APNS_KEY_CONTENT`

---

## 🎯 Render Environment Variables to Add:

### Variable 1:
- **Key**: `APNS_KEY_ID`
- **Value**: `4YF5542553`

### Variable 2:
- **Key**: `APNS_TEAM_ID`
- **Value**: `YOUR_TEAM_ID_HERE` (get from Apple Developer Portal)

### Variable 3:
- **Key**: `APNS_BUNDLE_ID`
- **Value**: `com.example.botleji.BottlejiLiveActivityWidget`

### Variable 4:
- **Key**: `APNS_KEY_CONTENT`
- **Value**: (paste the ENTIRE content from AuthKey_4YF5542553.p8 file)

