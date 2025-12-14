# Restore Cursor Debug Panel

## Flutter/Dart Execution Controls

The panel you're looking for is the **Flutter Run and Debug** controls. Here's how to restore it:

### Method 1: Open Run and Debug View

1. **Press**: `Cmd+Shift+D` (or `Ctrl+Shift+D` on Windows/Linux)
2. This opens the **Run and Debug** sidebar
3. At the top, you'll see:
   - Device selector dropdown
   - Configuration selector (Debug/Profile/Release)
   - Play button to run

### Method 2: Check Bottom Panel

1. **Press**: `Cmd+J` (or `Ctrl+J`) to toggle bottom panel
2. Look for tabs at the bottom:
   - **Terminal**
   - **Problems**
   - **Output**
   - **Debug Console**
   - **Flutter** (if Flutter extension is active)

### Method 3: View Menu

1. Go to **View** → **Run and Debug**
2. Or **View** → **Open View...** → Search for "Flutter"

### Method 4: Command Palette

1. **Press**: `Cmd+Shift+P` (or `Ctrl+Shift+P`)
2. Type: `Flutter: Select Device`
3. Or: `Flutter: Run Flutter`

---

## For iOS Console Logs (Xcode Required)

**Important**: For viewing **iOS widget extension crash logs** and **Xcode console output**, you need to use **Xcode**, not Cursor:

1. Open your project in **Xcode**:
   ```bash
   open botleji/ios/Runner.xcworkspace
   ```

2. Connect your iOS device

3. Select your device from the device dropdown (top toolbar)

4. Select **Runner** scheme (not the widget extension)

5. Run the app from Xcode

6. Open **Console**:
   - **View** → **Debug Area** → **Activate Console**
   - Or press `Shift+Cmd+Y`

7. Filter logs:
   - Type "LiveActivityWidgetExtension" in the search box
   - Look for crash logs or errors

---

## Alternative: Flutter Logs in Cursor

If you just want Flutter/Dart logs (not iOS native logs):

1. Open Terminal in Cursor: `View` → `Terminal` or `Ctrl+` `
2. Run: `flutter run` (this will show device selection)
3. Or run: `flutter logs` to see device logs

But **for widget extension crashes, you must use Xcode Console**.


