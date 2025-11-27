# Collection Session Value Calculation - Proposal

## Problem
We need to show a floating card with the total value collected in a collector's current session, but collectors have different work schedules, making it unclear when a session starts and ends.

## Proposed Solutions

### Option 1: **Daily Session (Recommended)**
**How it works:**
- Session = All collections completed today (from midnight to now)
- Resets automatically at midnight
- Simple and clear for users

**Pros:**
- ✅ Simple to understand
- ✅ No ambiguity about session boundaries
- ✅ Works for all work schedules
- ✅ Easy to implement

**Cons:**
- ❌ Doesn't account for collectors who work across midnight
- ❌ Resets even if collector is still working

**Implementation:**
- Filter collections where `completedAt` is today
- Sum up values of all completed collections

---

### Option 2: **Active Session with Inactivity Timeout**
**How it works:**
- Session starts when collector accepts their first drop
- Session continues as long as they keep collecting
- Session ends after X hours of inactivity (e.g., 3-4 hours)
- If they accept a new drop after inactivity, a new session starts

**Pros:**
- ✅ Flexible for different work schedules
- ✅ Accounts for breaks/lunch
- ✅ More accurate for actual work sessions

**Cons:**
- ❌ More complex to implement
- ❌ Requires tracking session start time
- ❌ May confuse users if session ends unexpectedly

**Implementation:**
- Track session start time (first accepted drop today)
- Check if last collection was within X hours
- If yes, include all collections since session start
- If no, start new session

---

### Option 3: **Continuous Session Until Long Break**
**How it works:**
- Session starts when collector accepts first drop
- Continues until they haven't collected anything for 6+ hours
- More lenient than Option 2

**Pros:**
- ✅ Very flexible
- ✅ Accounts for long breaks
- ✅ Good for part-time collectors

**Cons:**
- ❌ May include collections from different days
- ❌ Less clear session boundaries

---

### Option 4: **Manual Session Management**
**How it works:**
- Collector can manually start/end a session
- Button to "Start Work Session" and "End Work Session"
- Shows total value for current active session

**Pros:**
- ✅ Full control for collectors
- ✅ Most accurate
- ✅ Can track multiple sessions per day

**Cons:**
- ❌ Requires user action
- ❌ May forget to start/end session
- ❌ More UI complexity

---

## Recommendation: **Option 1 (Daily Session) + Option 2 (Hybrid)**

**Best approach:** Combine both options:
1. **Primary:** Show "Today's Total Value" (Option 1)
2. **Secondary:** Show "Active Session Value" if they have an active collection (Option 2)

This gives collectors:
- Clear daily total (resets at midnight)
- Current session value if actively collecting

---

## Implementation Plan

1. Create a `CollectionSessionCalculator` utility class
2. Add methods:
   - `calculateTodayTotalValue(List<CollectionAttempt> attempts)`
   - `calculateActiveSessionValue(List<CollectionAttempt> attempts, DateTime? sessionStart)`
3. Add floating card widget to stats screen (collector mode)
4. Display both "Today's Total" and "Active Session" if applicable

---

## UI Design

Floating card should show:
- **Today's Total Value:** X.XX TND
- **Collections Today:** X drops
- **Active Session:** Y.XX TND (if applicable)

Position: Bottom-right corner, above the bottom navigation bar
