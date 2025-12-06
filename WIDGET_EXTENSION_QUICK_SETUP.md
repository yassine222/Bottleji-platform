# Widget Extension Quick Setup - FIX "No Info Displaying"

## Current Status
✅ Activity is created (clicking notch navigates to app)
❌ No UI displaying in Dynamic Island
**Cause:** Widget Extension is missing or not configured

## Solution: Create Widget Extension

### Step 1: Create Widget Extension Target

1. **Open Xcode:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```

2. **Create New Target:**
   - **File → New → Target**
   - Select **"Widget Extension"**
   - Click **"Next"**

3. **Configure:**
   - **Product Name:** `LiveActivityWidgetExtension`
   - **Organization Identifier:** (same as Runner)
   - **Language:** Swift
   - ✅ **Check "Include Configuration Intent"** (optional)
   - Click **"Finish"**

4. **Activate Scheme:**
   - Xcode asks: "Activate 'LiveActivityWidgetExtension' scheme?"
   - Click **"Activate"**

### Step 2: Replace Widget Extension Code

1. **In Xcode Project Navigator:**
   - Find the new `LiveActivityWidgetExtension` folder
   - Open the main widget file (usually `LiveActivityWidgetExtension.swift`)

2. **Replace ALL contents** with this code:

```swift
import WidgetKit
import SwiftUI
import ActivityKit

// IMPORTANT: This must match the attributes in LiveActivityManager.swift
struct CollectionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: String  // "12:34"
        var distance: String     // "1.2 km"
        var eta: String          // "5 min"
    }
    
    var dropId: String
    var dropAddress: String
    var transportMode: String
}

@available(iOS 16.1, *)
struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CollectionActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("Collection in Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 16) {
                    Label(context.state.elapsedTime, systemImage: "timer")
                    Label(context.state.distance, systemImage: "location.fill")
                    Label(context.state.eta, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.attributes.dropAddress)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.elapsedTime)
                            .font(.headline)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(context.state.distance)
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(context.state.eta)
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            } compactLeading: {
                // Compact leading (left side)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Compact trailing (right side) - Shows timer
                Text(context.state.elapsedTime)
                    .font(.caption2)
                    .foregroundColor(.primary)
            } minimal: {
                // Minimal view
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

@main
struct LiveActivityWidgetExtension: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LiveActivityWidget()
        }
    }
}
```

### Step 3: Update Widget Extension Info.plist

1. **Select Widget Extension target**
2. **Go to Info tab**
3. **Add to Info.plist:**
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

### Step 4: Build Both Targets

1. **Select Runner scheme** (main app)
2. **Product → Build** (Cmd+B)
3. **Select LiveActivityWidgetExtension scheme**
4. **Product → Build** (Cmd+B)
5. **Select Runner scheme again**
6. **Product → Run** (Cmd+R)

### Step 5: Test

1. **Run app on device**
2. **Start collection navigation**
3. **Check Dynamic Island:**
   - Should show timer on right side
   - Tap to expand - shows full info
4. **Check Lock Screen:**
   - Swipe up to see Live Activity

## Important Notes

### The Widget Extension MUST:
- ✅ Be a separate target (not in Runner)
- ✅ Have the same `CollectionActivityAttributes` struct
- ✅ Include `@main` struct with `WidgetBundle`
- ✅ Have `NSSupportsLiveActivities = true` in Info.plist
- ✅ Be built and included in the app

### Common Issues:

**Issue:** "Cannot find 'CollectionActivityAttributes'"
- **Fix:** Make sure the struct is defined in the Widget Extension file

**Issue:** Widget Extension not building
- **Fix:** Check that Widget Extension target is selected and build it separately

**Issue:** Still no UI showing
- **Fix:** 
  1. Clean build folder (Shift+Cmd+K)
  2. Delete app from device
  3. Rebuild and reinstall
  4. Restart device

## Verification

After setup, when you start navigation, you should see:
- **Dynamic Island:** Timer on right, icon on left
- **Tap Dynamic Island:** Expands to show full info
- **Lock Screen:** Live Activity banner

If you still don't see it, check console logs for errors.

