# 🧹 Cleanup Cycle - Complete Explanation

## 📋 What is the Cleanup Cycle?

The cleanup cycle is a **background job** that runs automatically on the backend server to detect and handle **expired drop collections**.

---

## ⏰ How It Works

### **1. Timeout System**

When a collector accepts a drop, they have a **limited time** to complete the collection:

```
Collector accepts drop at 5:00 PM
↓
Timeout = 1 minute (testing) or 40 minutes (production)
↓
If not completed by 5:01 PM → Drop EXPIRES ⏰
```

**Timeout Calculation:**
- **Testing Mode**: 1 minute total (1 min route + 0 min buffer)
- **Production Mode**: 40 minutes total (20 min route + 20 min buffer)

### **2. Cleanup Job**

The cleanup job runs **periodically** to check for expired collections:

```
Every 1 minute (testing) or 10 minutes (production)
↓
Check all ACCEPTED interactions
↓
If time elapsed > timeout → Process expiration
```

**Cleanup Schedule:**
- **Testing Mode**: Runs every 1 minute
- **Production Mode**: Runs every 10 minutes
- **Initial Run**: 5 seconds after server startup

### **3. Expiration Process**

When a drop expires, the cleanup performs these steps:

```
1. ✅ Set drop status back to PENDING (available for others)
2. ✅ Create EXPIRED interaction (record in history)
3. ✅ Add warning to collector (penalty system)
4. ✅ Delete old ACCEPTED interaction (clean up database)
```

---

## 🔍 Example Timeline

### **Testing Mode (1 minute timeout):**

```
5:00:00 PM - Collector accepts drop
            ↓ [ACCEPTED interaction created]
            ↓ [Drop status: PENDING → ACCEPTED]
            ↓
5:01:00 PM - Timeout reached! ⏰
            ↓
5:01:30 PM - Cleanup cycle runs
            ↓ [Detects expired drop]
            ↓ [Drop status: ACCEPTED → PENDING]
            ↓ [Creates EXPIRED interaction]
            ↓ [Adds warning to collector]
            ↓ [Deletes old ACCEPTED interaction]
            ↓
5:01:30 PM - ✅ Cleanup complete
```

### **Production Mode (40 minute timeout):**

```
5:00:00 PM - Collector accepts drop
            ↓
5:40:00 PM - Timeout reached! ⏰
            ↓
5:50:00 PM - Cleanup cycle runs (every 10 min)
            ↓ [Processes expiration]
            ↓
5:50:00 PM - ✅ Cleanup complete
```

---

## 🐛 The Bug We Fixed

### **Problem:**
- Cleanup was creating EXPIRED interactions ✅
- But NOT deleting old ACCEPTED interactions ❌
- This caused **44 orphaned interactions** in the database

### **Impact:**
- Database bloat (unnecessary data)
- Confusing timeline display
- Inaccurate interaction counts
- Cleanup kept finding same interactions

### **Solution:**
```typescript
// After creating EXPIRED interaction
await this.interactionModel.findByIdAndDelete(interaction._id).exec();
console.log(`🗑️ Deleted old ACCEPTED interaction ${interaction._id}`);
```

---

## 📊 Database States

### **Before Expiration:**
```
Dropoffs Collection:
  - Drop A: status = "accepted"

CollectorInteractions Collection:
  - Interaction 1: type = "accepted", dropoffId = A, collectorId = X
```

### **After Expiration (OLD - BUGGY):**
```
Dropoffs Collection:
  - Drop A: status = "pending" ✅

CollectorInteractions Collection:
  - Interaction 1: type = "accepted", dropoffId = A, collectorId = X ❌ ORPHANED!
  - Interaction 2: type = "expired", dropoffId = A, collectorId = X ✅

Users Collection:
  - User X: warnings = [{ reason: "...", date: "..." }] ✅
```

### **After Expiration (NEW - FIXED):**
```
Dropoffs Collection:
  - Drop A: status = "pending" ✅

CollectorInteractions Collection:
  - Interaction 2: type = "expired", dropoffId = A, collectorId = X ✅

Users Collection:
  - User X: warnings = [{ reason: "...", date: "..." }] ✅
```

---

## 🚀 Testing vs Production

| Setting | Testing | Production |
|---------|---------|------------|
| **Timeout** | 1 minute | 40 minutes |
| **Cleanup Interval** | 1 minute | 10 minutes |
| **Purpose** | Fast feedback for development | Real-world usage |
| **Max Wait** | ~2 minutes | ~50 minutes |

### **⚠️ Important:**
Before deploying to production, change these values back:

```typescript
// In dropoffs.service.ts

// Line ~685: Timeout
const routeDurationMinutes = 20; // Change from 1 to 20
let bufferMinutes = 20; // Change from 0 to 20

// Line ~191: Cleanup interval
setInterval(async () => {
  // ...
}, 10 * 60 * 1000); // Change from 1 * 60 * 1000 to 10 * 60 * 1000
```

---

## 🔧 Monitoring & Debugging

### **Server Logs:**

The cleanup cycle logs everything:

```
🚀 Starting cleanup task - will run every 1 minute (TESTING MODE)
⏰ Cleanup task triggered at: 2025-10-12T19:00:00.000Z
📊 Total accepted interactions in database: 44
📊 Found 44 accepted interactions to check
🔍 Checking interaction 68ebf33aa871850c1f1f18de for drop 6888d37d8759a7d9d48b4912
⏰ Should expire: true
🔄 Processing expired drop 6888d37d8759a7d9d48b4912 for collector 6835e7cac36086e385a9d4df
✅ EXPIRED interaction created for drop 6888d37d8759a7d9d48b4912
🗑️ Deleted old ACCEPTED interaction 68ebf33aa871850c1f1f18de
✅ Drop 6888d37d8759a7d9d48b4912 timed out after 1 minutes, set back to PENDING
🧹 Cleaned up 1 expired accepted drops
```

### **Investigation Script:**

Run the deep investigation script to check cleanup health:

```bash
cd backend
node deep-cleanup-investigation.js
```

This will show:
- Current configuration
- Accepted interactions (should be 0 or very few)
- Expired interactions (should match expected count)
- Orphaned interactions (should be 0)
- Recommendations

---

## ✅ Expected Behavior

### **Healthy System:**
- ✅ 0-2 ACCEPTED interactions at any time (recent accepts)
- ✅ EXPIRED interactions created for timeouts
- ✅ Warnings added to collectors
- ✅ Drops return to PENDING status
- ✅ No orphaned interactions

### **Unhealthy System:**
- ❌ Many ACCEPTED interactions (>5)
- ❌ Old ACCEPTED interactions (>2 minutes in testing)
- ❌ Missing EXPIRED interactions
- ❌ Missing warnings on users
- ❌ Drops stuck in ACCEPTED status

---

## 🎯 Summary

**The cleanup cycle is a critical system that:**
1. Ensures drops don't stay locked forever
2. Penalizes collectors who don't complete collections
3. Keeps the database clean and accurate
4. Provides a fair system for all users

**Testing mode (1 min) allows us to:**
- Test the system quickly
- Verify warnings are added
- Debug issues faster
- Iterate on features

**Production mode (40 min) provides:**
- Realistic timeouts for collectors
- Fair penalty system
- Smooth user experience
- Reliable drop collection flow

