# Exact Steps: Create Widget Extension Target in Xcode

## Prerequisites
- Xcode 14.1 or later (you have Xcode 16 ✅)
- iPhone 14 Pro or later for testing
- iOS 16.1+ on device

---

## Step 1: Open Xcode Workspace

1. **Open Terminal** (or use your current terminal)
2. **Navigate to iOS folder:**
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios
   ```
3. **Open Xcode workspace:**
   ```bash
   open Runner.xcworkspace
   ```
   ⚠️ **IMPORTANT:** Use `.xcworkspace` NOT `.xcodeproj`

---

## Step 2: Create Widget Extension Target

1. **In Xcode menu bar:**
   - Click **File** → **New** → **Target...**
   - (Or press: `⌘ + Shift + N`)

2. **Select Widget Extension:**
   - In the template chooser, scroll down to **"Application Extension"** section
   - Select **"Widget Extension"**
   - Click **"Next"** button (bottom right)

3. **Configure Target:**
   - **Product Name:** Type `LiveActivityWidgetExtension`
   - **Team:** Select your development team (same as Runner)
   - **Organization Identifier:** Should auto-fill (same as Runner)
   - **Language:** Select **Swift**
   - **Include Configuration Intent:** ✅ **UNCHECK this** (we don't need it)
   - Click **"Finish"** button

4. **Activate Scheme:**
   - Xcode will show a popup: **"Activate 'LiveActivityWidgetExtension' scheme?"**
   - Click **"Activate"**

---

## Step 3: Find the Widget Extension File

1. **In Xcode Project Navigator** (left sidebar):
   - Look for a new folder called **`LiveActivityWidgetExtension`**
   - It should be at the same level as `Runner`, `Pods`, etc.
   - Expand it by clicking the arrow ▶️

2. **Inside `LiveActivityWidgetExtension` folder:**
   - You'll see files like:
     - `LiveActivityWidgetExtension.swift` (or similar name)
     - `Info.plist`
     - `Assets.xcassets`
   - **Click on the `.swift` file** (the widget file)

---

## Step 4: Replace Widget Extension Code

1. **Select ALL code in the widget file:**
   - Click in the editor
   - Press `⌘ + A` (Select All)
   - Press `Delete` or `Backspace`

2. **Copy this ENTIRE code block:**

```swift
import WidgetKit
import SwiftUI
import ActivityKit

// IMPORTANT: This must match LiveActivityManager.swift exactly
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
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island) - Shows timer
                Text(context.state.elapsedTime)
                    .font(.caption2)
                    .foregroundColor(.primary)
            } minimal: {
                // Minimal view (when multiple activities)
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

3. **Paste the code:**
   - Press `⌘ + V` to paste
   - The file should now contain only this code

4. **Save the file:**
   - Press `⌘ + S`

---

## Step 5: Configure Widget Extension Info.plist

1. **In Project Navigator:**
   - Find `LiveActivityWidgetExtension` folder
   - Click on **`Info.plist`** (inside the extension folder)

2. **Add Live Activities Support:**
   - Right-click in the editor → **Add Row**
   - **Key:** Type `NSSupportsLiveActivities`
   - **Type:** Should auto-set to `Boolean`
   - **Value:** Check the checkbox (set to `YES`)
   - Press `⌘ + S` to save

   **OR** if you see the file as source code:
   - Add this before `</dict>`:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

---

## Step 6: Build Widget Extension Target

1. **Select Widget Extension Scheme:**
   - At the top of Xcode, next to the play/stop buttons
   - Click the scheme dropdown (shows "Runner" or similar)
   - Select **"LiveActivityWidgetExtension"**

2. **Build the Extension:**
   - Press `⌘ + B` (or Product → Build)
   - Wait for build to complete
   - Should see "Build Succeeded" ✅

3. **Switch Back to Runner Scheme:**
   - Click scheme dropdown again
   - Select **"Runner"**

---

## Step 7: Build and Run Main App

1. **Select Runner Scheme:**
   - Make sure **"Runner"** is selected in scheme dropdown

2. **Build:**
   - Press `⌘ + B` to build
   - Wait for build to complete

3. **Run on Device:**
   - Connect your iPhone 14 Pro+
   - Select your device from device dropdown (next to scheme)
   - Press `⌘ + R` (or click Play button)
   - App should install on device

---

## Step 8: Verify It Works

1. **On your iPhone:**
   - Open the app
   - Start a collection navigation

2. **Check Dynamic Island:**
   - Should see **green map pin icon** on left
   - Should see **timer** (e.g., "12:34") on right
   - **Tap the Dynamic Island** → Should expand showing:
     - Address (left)
     - Timer (right)
     - Distance and ETA (bottom)

3. **Check Lock Screen:**
   - Lock your phone
   - Swipe up on lock screen
   - Should see Live Activity banner with all info

---

## Troubleshooting

### Error: "Cannot find 'CollectionActivityAttributes'"
- **Fix:** Make sure the struct is defined in the Widget Extension file (it should be in the code above)

### Error: "Multiple '@main' attributes"
- **Fix:** The Widget Extension should have `@main`, and Runner should NOT have `@main` in any Swift file

### Widget Extension not appearing in scheme dropdown
- **Fix:** Make sure you activated the scheme when creating the target

### Still no UI showing
1. **Clean Build:**
   - Press `Shift + ⌘ + K` (Clean Build Folder)
   - Delete app from device
   - Rebuild and reinstall

2. **Check Console:**
   - In Xcode, open Console (View → Debug Area → Activate Console)
   - Look for ActivityKit errors

3. **Verify Device:**
   - iPhone 14 Pro or later
   - iOS 16.1 or later

---

## Visual Guide: What You Should See

### In Xcode Project Navigator:
```
Runner.xcworkspace
├── Runner
│   ├── AppDelegate.swift
│   ├── LiveActivityManager.swift
│   ├── LiveActivityPlugin.swift
│   └── ...
├── LiveActivityWidgetExtension  ← NEW TARGET
│   ├── LiveActivityWidgetExtension.swift  ← Widget code here
│   ├── Info.plist  ← Has NSSupportsLiveActivities
│   └── Assets.xcassets
└── Pods
```

### On iPhone Dynamic Island:
- **Compact:** [🟢] [12:34]
- **Expanded:** [Collection | Address] [Timer | 12:34] [📍 1.2 km | ⏰ 5 min]

---

## Summary Checklist

- [ ] Opened `Runner.xcworkspace` (not .xcodeproj)
- [ ] Created Widget Extension target named `LiveActivityWidgetExtension`
- [ ] Activated the scheme when prompted
- [ ] Replaced widget file code with the code above
- [ ] Added `NSSupportsLiveActivities = YES` to extension Info.plist
- [ ] Built Widget Extension target (⌘B)
- [ ] Built Runner target (⌘B)
- [ ] Ran app on iPhone 14 Pro+
- [ ] Started navigation and saw Dynamic Island UI

---

**Once you complete these steps, the Dynamic Island should display the timer, distance, and ETA!**

