# APNs Service Setup for Live Activities

## Overview
The backend now uses **direct APNs** (Apple Push Notification service) for Live Activity updates instead of Firebase Cloud Messaging. Regular push notifications still use FCM.

## Environment Variables Required

Add these to your `.env` file or environment:

```env
# APNs Configuration (required for Live Activities)
APNS_KEY_ID=your_key_id_here
APNS_TEAM_ID=your_team_id_here
APNS_BUNDLE_ID=com.example.botleji.LiveActivityWidgetExtension

# APNs Key - choose ONE of these options:
# Option 1: Path to .p8 key file
APNS_KEY_PATH=./path/to/AuthKey_XXXXX.p8

# Option 2: Key content as string (with \n for newlines)
APNS_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----"

# Environment (optional, defaults to development)
NODE_ENV=production  # or development
```

## How to Get APNs Credentials

1. **Go to Apple Developer Portal**: https://developer.apple.com/account/resources/authkeys/list
2. **Create a new Key**:
   - Click the "+" button
   - Give it a name (e.g., "Live Activities Key")
   - Check "Apple Push Notifications service (APNs)"
   - Click "Continue" and "Register"
   - **Download the .p8 file** (you can only download it once!)
3. **Note the Key ID** (shown in the list after creation)
4. **Note your Team ID** (found in the top right of the portal)

## Configuration Options

### Option 1: Using Key File Path (Recommended for Development)
```env
APNS_KEY_ID=ABCD1234EF
APNS_TEAM_ID=XYZ9876ABC
APNS_KEY_PATH=./apns/AuthKey_ABCD1234EF.p8
APNS_BUNDLE_ID=com.example.botleji.LiveActivityWidgetExtension
```

### Option 2: Using Key Content (Recommended for Production)
```env
APNS_KEY_ID=ABCD1234EF
APNS_TEAM_ID=XYZ9876ABC
APNS_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APNS_BUNDLE_ID=com.example.botleji.LiveActivityWidgetExtension
NODE_ENV=production
```

## Bundle ID

Make sure `APNS_BUNDLE_ID` matches your widget extension's bundle ID:
- Check in Xcode: Select widget extension target → General → Bundle Identifier
- Default: `com.example.botleji.LiveActivityWidgetExtension`

## Verification

After setting up, check backend logs for:
```
✅ APNs provider initialized successfully
✅ APNs environment: Production/Development
✅ Bundle ID: com.example.botleji.LiveActivityWidgetExtension
✅ Key ID: ABCD1234EF
✅ Team ID: XYZ9876ABC
```

If you see warnings about missing configuration, check your environment variables.

## Testing

When a Live Activity update is sent, you should see logs like:
```
📤 [sendLiveActivityUpdate] Sending via direct APNs
📤 [sendLiveActivityUpdate] Topic: com.example.botleji.LiveActivityWidgetExtension
✅ [sendLiveActivityUpdate] Live Activity update sent successfully
```

## Troubleshooting

### Error: "APNs provider not initialized"
- Check that all required environment variables are set
- Verify the key file path is correct (if using `APNS_KEY_PATH`)
- Check that the key content is correct (if using `APNS_KEY_CONTENT`)

### Error: "BadDeviceToken"
- The push token is invalid or expired
- Token will be automatically marked as inactive in the database

### Error: "InvalidTopic"
- The bundle ID doesn't match the APNs topic
- Verify `APNS_BUNDLE_ID` matches your widget extension bundle ID

