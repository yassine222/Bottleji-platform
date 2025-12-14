# Live Activity Widget - UI Elements and Field Changes

## Overview
The Live Activity widget displays drop status information for household users. It appears on:
- **Lock Screen** (main view)
- **Dynamic Island** (iPhone 14 Pro and later - compact, expanded, minimal views)

---

## 📱 UI Components

### **Lock Screen View** (Main Display)

#### **Static Elements** (Don't Change):
1. **Header Section:**
   - Bottleji logo (28x28, rounded corners)
   - "Bottleji" app name (bold headline)
   - "Drop Status" subtitle (caption)
   - **Estimated Value** (e.g., "2.50 TND") - shown in top right

#### **Dynamic Elements** (Change with Status):

1. **Status Indicator:**
   - **Circle dot** (10x10) - color changes based on status
   - **Status text** (large, bold) - e.g., "Created", "Accepted", "Collected"
   - **Collector name** (if accepted) - appears as "• Collector Name"

2. **Timeline Progress Bar:**
   - Visual progress indicator showing drop lifecycle stages
   - Stages: Created → Accepted → On Way → Collected
   - Colors change based on current status

3. **Time Ago:**
   - Clock icon
   - Time text (e.g., "Just now", "2 min ago", "5 min ago")

---

### **Dynamic Island Views** (iPhone 14 Pro+)

#### **Compact Leading** (Small pill on left):
- Bottleji logo (16x16)

#### **Compact Trailing** (Small pill on right):
- **Status text** (e.g., "Created", "Accepted") - color changes with status

#### **Expanded Leading** (Top left when expanded):
- Bottleji logo (22x22)
- "Bottleji" text

#### **Expanded Trailing** (Top right when expanded):
- **Estimated Value** (e.g., "2.50 TND")
- **Status text** (large, bold) - color changes with status

#### **Expanded Bottom** (Bottom section when expanded):
- Timeline progress bar
- **Collector name** (if accepted) - with person icon

#### **Minimal** (Tiny indicator):
- Bottleji logo (12x12)

---

## 🔄 Fields That Change

### **ContentState Fields** (Updated via Push Notifications):

| Field | Type | Description | Example Values |
|-------|------|-------------|----------------|
| `activityType` | String | Always "dropTimeline" for drops | "dropTimeline" |
| `status` | String? | Internal status code | "pending", "accepted", "collected", "cancelled", "expired" |
| `statusText` | String? | Display text | "Created", "Accepted", "On his way", "Collected", "Cancelled", "Expired" |
| `collectorName` | String? | Collector's name (only when accepted) | "Yassine Romdhane", null |
| `timeAgo` | String? | Time since last update | "Just now", "1 min ago", "5 min ago" |

### **Static Attributes** (Set at Creation, Don't Change):

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `dropId` | String | Drop identifier | "693ec9f7a633c2b089f8ef61" |
| `dropAddress` | String | Drop location address | "123 Main St" |
| `estimatedValue` | String | Estimated value in TND | "2.50 TND" |
| `createdAt` | String? | Creation timestamp | "2025-12-14T14:30:00Z" |

---

## 🎨 Status Colors

The widget uses different colors based on status:

| Status | Color | Used For |
|--------|-------|----------|
| `pending` | `.appSecondary` (Gray) | Status text, circle dot, timeline |
| `accepted` / `on_way` | `.appOrange` (Orange) | Status text, circle dot, timeline |
| `collected` | `.appPrimary` (Green) | Status text, circle dot, timeline |
| `cancelled` / `expired` | `.red` | Status text, circle dot, timeline |

---

## 📊 Timeline Progress Bar

The progress bar shows 4 stages:

1. **Created** (Stage 0) - Gray dot
2. **Accepted** (Stage 1) - Orange dot when active
3. **On Way** (Stage 2) - Orange dot when active
4. **Collected** (Stage 3) - Green dot when completed

**Visual Representation:**
```
● ──── ● ──── ● ──── ●
Created Accepted On Way Collected
```

- **Gray dots** = Not reached yet
- **Orange dots** = Current/active stage
- **Green dots** = Completed stage
- **Gray lines** = Not completed
- **Colored lines** = Completed path

---

## 🔄 Update Flow

### When Drop Status Changes:

1. **Backend sends APNs push notification** with new `ContentState`:
   ```json
   {
     "activityType": "dropTimeline",
     "status": "accepted",
     "statusText": "Accepted",
     "collectorName": "Yassine Romdhane",
     "timeAgo": "Just now"
   }
   ```

2. **ActivityKit receives push notification** and decodes `ContentState`

3. **Widget re-renders** with new state:
   - Status text changes: "Created" → "Accepted"
   - Status color changes: Gray → Orange
   - Collector name appears: "• Yassine Romdhane"
   - Timeline progress updates: Stage 1 becomes active
   - Time ago updates: "Just now" → "1 min ago"

---

## 📝 Example Status Transitions

### **Created → Accepted:**
- **Status text:** "Created" → "Accepted"
- **Color:** Gray → Orange
- **Collector name:** (none) → "• Yassine Romdhane"
- **Timeline:** Stage 0 → Stage 1 active
- **Time ago:** Updates to current time

### **Accepted → Collected:**
- **Status text:** "Accepted" → "Collected"
- **Color:** Orange → Green
- **Collector name:** "• Yassine Romdhane" → (remains)
- **Timeline:** Stage 1 → Stage 3 completed
- **Time ago:** Updates to current time

### **Accepted → Cancelled:**
- **Status text:** "Accepted" → "Cancelled"
- **Color:** Orange → Red
- **Collector name:** "• Yassine Romdhane" → (remains)
- **Timeline:** Stage 1 → (stops)
- **Time ago:** Updates to current time

---

## 🐛 Debugging

To see when the widget updates, check Xcode Console for:
- `🔄 Widget re-rendering: status=..., statusText=..., collectorName=..., timeAgo=...`
- `✅ ContentState decoded: activityType=..., status=..., statusText=...`

If you don't see these logs when status changes, the push notification might not be reaching the widget.


