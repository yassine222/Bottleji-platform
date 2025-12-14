# 🔍 Widget Update Debugging Guide

## Problem
Push notifications ARE being received, but Live Activity widget is NOT updating.

## What to Check

### 1. Check Xcode Console for Widget Logs

When a push notification arrives, you should see:
```
✅ ContentState decoded: activityType=dropTimeline, status=accepted, statusText=Accepted, ...
🔄 Widget re-rendering: status=accepted, statusText=Accepted, ...
```

**If you see "ContentState decoded" but NOT "Widget re-rendering":**
- Widget decoded the push but isn't re-rendering
- This is a SwiftUI rendering issue

**If you DON'T see "ContentState decoded":**
- Widget isn't receiving the push notification
- Or decoding is failing silently

### 2. Check the Payload Structure

The backend sends:
```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "update",
    "content-state": {
      "activityType": "dropTimeline",
      "status": "accepted",
      "statusText": "Accepted",
      "collectorName": "John Doe",
      "timeAgo": "Just now",
      "distanceRemaining": 290.88
    }
  }
}
```

**ActivityKit expects the `content-state` to be at the root level of the payload, not nested in `aps`.**

### 3. Potential Issue: Payload Structure

The `live_activities` package might expect a different payload structure. ActivityKit's native format is:

```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "update"
  },
  "content-state": {
    "activityType": "dropTimeline",
    "status": "accepted",
    ...
  }
}
```

But Firebase Admin SDK might be wrapping it differently.

### 4. Check if Widget is Active

If the Live Activity has ended or been dismissed, push notifications are ignored.

### 5. Add More Debugging

Add this to see what's actually being decoded:

```swift
init(from decoder: Decoder) throws {
    print("🔍 [ContentState] Starting decode...")
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // Log all available keys
    print("🔍 [ContentState] Available keys: \(container.allKeys)")
    
    // ... rest of decoding
}
```


