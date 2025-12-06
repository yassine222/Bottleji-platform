# Testing Live Activities on iOS Simulator

## ✅ What Works on Simulator

1. **Lock Screen Live Activities**
   - ✅ Fully supported
   - ✅ Can see the Live Activity banner
   - ✅ Updates work correctly
   - ✅ Dismissal works correctly

2. **Notification Banner Live Activities**
   - ✅ Works when app is in background
   - ✅ Shows in notification center

## ❌ What Doesn't Work on Simulator

1. **Dynamic Island**
   - ❌ Not available on simulator
   - ❌ Requires physical iPhone 14 Pro/Max or later
   - ❌ Compact/Expanded/Minimal views won't show

## How to Test on Simulator

### Step 1: Use Correct Simulator

1. **Open Xcode**
2. **Select Simulator:**
   - Device: iPhone 14 Pro or iPhone 15 Pro (or any iOS 16.1+ device)
   - iOS Version: 16.1 or later
   - **Note:** Even though Dynamic Island won't work, Lock Screen Live Activities will

### Step 2: Enable Live Activities in Simulator

1. **Settings → Face ID & Passcode** (or Touch ID & Passcode)
2. Scroll to "Allow Access When Locked"
3. Enable "Live Activities" (if available)

### Step 3: Test Lock Screen Live Activity

1. **Run your app** on the simulator
2. **Start a collection** (navigate to a drop)
3. **Lock the simulator:**
   - Press `Cmd + L` or
   - Hardware → Lock
4. **Check Lock Screen:**
   - You should see the Live Activity banner
   - It should show "Active Collection" with timer, distance, ETA

### Step 4: Test Updates

1. **Keep simulator locked**
2. **Watch the Live Activity**
3. **It should update every 5 seconds** with new distance/ETA
4. **Timer should countdown**

### Step 5: Test Dismissal

1. **Complete the collection** (or cancel/expire)
2. **Live Activity should disappear** from Lock Screen
3. **Check console logs** for dismissal confirmation

## What You'll See on Simulator

### ✅ Lock Screen
- Live Activity banner appears
- Shows all information (timer, distance, ETA)
- Updates correctly
- Dismisses when collection ends

### ❌ Dynamic Island
- Nothing appears in the notch area
- Compact/Expanded views don't show
- This is expected - Dynamic Island requires physical device

## Console Logs to Check

When testing on simulator, you should see:
```
✅ Global Live Activity started for drop: [dropId]
✅ Dynamic Island activity started successfully
✅ Activity ID: [id]
```

Even though Dynamic Island won't show, the activity is created and Lock Screen Live Activity will work.

## Limitations

1. **No Dynamic Island testing** - Must use physical device
2. **Performance may differ** - Simulator is slower than real device
3. **Some features may behave differently** - Always test on device for production

## Recommendation

- **Use Simulator for:**
  - Initial development
  - Testing Lock Screen Live Activities
  - Debugging code logic
  - UI layout testing

- **Use Physical Device for:**
  - Dynamic Island testing
  - Final verification
  - Performance testing
  - Production readiness

## Quick Test Checklist

- [ ] Simulator running iOS 16.1+
- [ ] App runs without errors
- [ ] Start collection navigation
- [ ] Lock simulator (Cmd+L)
- [ ] See Live Activity on Lock Screen
- [ ] Activity updates correctly
- [ ] Activity dismisses when collection ends

## Troubleshooting Simulator Issues

### Issue: Live Activity doesn't appear on Lock Screen

**Solutions:**
1. Make sure simulator is locked (Cmd+L)
2. Check iOS version is 16.1+
3. Verify Live Activities are enabled in Settings
4. Check console for errors
5. Clean build and rebuild

### Issue: Activity appears but doesn't update

**Solutions:**
1. Check console logs for update calls
2. Verify `GlobalLiveActivityManager` is running
3. Check timer is updating (every 5 seconds)
4. Verify network/location permissions

### Issue: Activity doesn't dismiss

**Solutions:**
1. Check `completeCollection()` is being called
2. Verify `GlobalLiveActivityManager` listener is working
3. Check console for dismissal logs
4. Manually dismiss in code if needed

## Summary

✅ **Lock Screen Live Activities work on simulator**
❌ **Dynamic Island requires physical device**

Use simulator for development, but always test Dynamic Island on a real iPhone 14 Pro or later.

