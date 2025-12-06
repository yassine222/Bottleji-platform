# Live Activity Widget - View Components Documentation

This document describes what information and components are displayed in each view size of the Live Activity widget.

---

## 📱 Collection Navigation Activity (Collector Mode)

### 1. **Minimal View** (Smallest - When multiple activities)
**Size:** ~12x12 pixels  
**Location:** Dynamic Island (when multiple Live Activities are active)

**Components:**
- ✅ **App Logo Icon** (`live_activity_icon_minimal.png`)
  - Size: 12x12 pixels
  - Corner radius: 2px
  - Shows only the icon

**When it appears:**
- When multiple Live Activities are running simultaneously
- iOS automatically switches to minimal view to save space

---

### 2. **Compact View** (Medium - Default Dynamic Island state)
**Size:** Split into two regions (leading + trailing)  
**Location:** Dynamic Island (default state when activity is active)

**Components:**

#### **Compact Leading** (Left side):
- ✅ **App Logo Icon** (`live_activity_icon_compact.png`)
  - Size: 16x16 pixels
  - Corner radius: 3px
  - Position: Left side of Dynamic Island

#### **Compact Trailing** (Right side):
- ✅ **ETA Countdown Timer**
  - Format: "12 min", "2 min", "Arriving", etc.
  - Font: `.caption`, semibold
  - Color: Orange (#FF9800)
  - Position: Right side of Dynamic Island

**Example Display:**
```
[Icon]                    [12 min]
```

**When it appears:**
- Default state when Live Activity is active
- Shows when user is not interacting with Dynamic Island
- Most common view users will see

---

### 3. **Expanded View** (Large - When user taps Dynamic Island)
**Size:** Full Dynamic Island area  
**Location:** Dynamic Island (expanded when tapped)

**Components:**

#### **Expanded Leading Region** (Left side):
- ✅ **App Logo Icon** (`live_activity_icon_expanded.png`)
  - Size: 16x16 pixels
  - Corner radius: 4px
- ✅ **"Botleji" Text**
  - Font: `.caption`
  - Color: Secondary (gray)
  - Position: Next to icon
- ✅ **"Botleji" Title**
  - Font: `.headline`, semibold
  - Color: Primary (black/white based on theme)
  - Line limit: 2 lines
  - Position: Below icon/text row

#### **Expanded Trailing Region** (Right side):
- ✅ **"Time left" Label**
  - Font: `.caption`
  - Color: Secondary (gray)
  - Position: Top right
- ✅ **ETA Countdown Timer**
  - Format: "12 min", "2 min", etc.
  - Font: `.title2`, bold
  - Color: Orange (#FF9800)
  - Position: Below "Time left" label

#### **Expanded Bottom Region** (Bottom section):
- ✅ **Progress Bar**
  - Height: 3px
  - Color: App primary (#00695C)
  - Shows collection progress (visual indicator)
- ✅ **Distance Info**
  - Icon: Location pin (blue)
  - Text: Distance to destination (e.g., "1.2 km", "359 m")
  - Font: `.subheadline`, medium
  - Color: Primary
- ✅ **Timer Info**
  - Icon: Clock (orange)
  - Text: "{ETA} left" (e.g., "12 min left")
  - Font: `.subheadline`, medium
  - Color: Primary

**Example Display:**
```
[Icon] Botleji          Time left
Botleji                 12 min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 1.2 km        ⏰ 12 min left
```

**When it appears:**
- When user taps on the Dynamic Island
- Shows full details of the collection
- User can interact with it

---

### 4. **Lock Screen Live Activity** (Banner)
**Size:** Full width banner  
**Location:** Lock Screen (when phone is locked)

**Components:**

#### **Header Row:**
- ✅ **App Logo Icon** (`AppLogo.png`)
  - Size: 24x24 pixels
  - Corner radius: 6px
- ✅ **"Botleji" Title**
  - Font: `.headline`, semibold
  - Color: Primary
- ✅ **ETA Countdown Timer** (Right side)
  - Format: "12 min", "2 min", etc.
  - Font: `.title2`, bold
  - Color: Orange (#FF9800)

#### **Progress Bar:**
- ✅ **Visual Progress Indicator**
  - Height: 4px
  - Color: App primary (#00695C)
  - Shows collection progress

#### **Info Row:**
- ✅ **Distance Info**
  - Icon: Location pin (blue)
  - Text: Distance to destination
  - Font: `.subheadline`, medium
- ✅ **Timer Info**
  - Icon: Clock (orange)
  - Text: ETA countdown (e.g., "12 min")
  - Font: `.subheadline`, medium

**Example Display:**
```
[Icon] Botleji                    12 min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 1.2 km              ⏰ 12 min
```

**When it appears:**
- When phone is locked
- When app is in background
- Always visible when collection is active

---

## 🏠 Drop Timeline Activity (Household Mode)

### 1. **Minimal View**
**Components:**
- ✅ **App Logo Icon** (`live_activity_icon_minimal.png`)
  - Size: 12x12 pixels

---

### 2. **Compact View**

#### **Compact Leading:**
- ✅ **App Logo Icon** (`live_activity_icon_compact.png`)
  - Size: 16x16 pixels

#### **Compact Trailing:**
- ✅ **Status Text**
  - Examples: "Created", "Accepted", "On his way", "Collected", "Expired", "Cancelled"
  - Font: `.caption2`, semibold
  - Color: Status-based (blue, orange, green, red)
  - Line limit: 1

**Example Display:**
```
[Icon]                    [On his way]
```

---

### 3. **Expanded View**

#### **Expanded Leading:**
- ✅ **App Logo Icon** (`live_activity_icon_expanded.png`)
  - Size: 16x16 pixels
- ✅ **"Drop Status" Text**
  - Font: `.caption`
  - Color: Secondary
- ✅ **"Active Collection" Title**
  - Font: `.headline`, semibold
  - Color: Primary

#### **Expanded Trailing:**
- ✅ **Estimated Value**
  - Format: "2.50 TND"
  - Font: `.caption`
  - Color: Secondary
- ✅ **Status Text**
  - Font: `.title3`, bold
  - Color: Status-based

#### **Expanded Bottom:**
- ✅ **Timeline Progress View**
  - Shows: Created → Accepted → On his way → Outcome
  - Visual progress indicators
- ✅ **Collector Name** (if available)
  - Icon: Person
  - Text: Collector's name
  - Font: `.subheadline`

---

## 📊 Summary Table

| View Type | Size | Components | When Visible |
|-----------|------|------------|--------------|
| **Minimal** | 12x12 | App logo only | Multiple activities |
| **Compact** | Split | Logo (left) + ETA (right) | Default Dynamic Island |
| **Expanded** | Full | Logo, Title, ETA, Progress, Distance, Timer | User taps Dynamic Island |
| **Lock Screen** | Banner | Logo, Title, ETA, Progress, Distance, Timer | Phone locked / Background |

---

## 🎨 Visual Hierarchy

### Information Priority:
1. **Most Important** (Always visible):
   - ETA Countdown Timer
   - App Logo

2. **Important** (Compact/Expanded):
   - Distance to destination
   - Collection status

3. **Details** (Expanded only):
   - Progress bar
   - Full address/status text
   - Additional context

---

## 🔄 Update Frequency

All views update every **5 seconds** with:
- New distance calculations
- Updated ETA countdown
- Progress bar updates

---

## 📝 Notes

- All views use theme-aware colors (light/dark mode support)
- Images are sized appropriately for each view
- Text truncates with ellipsis if too long
- Views automatically adapt to available space
- Deep linking: Tapping any view navigates to navigation screen

