# 🧹 Cleanup Task Explanation

## What is the Cleanup Task?

The **cleanup task** is a scheduled background job that runs automatically every 2 minutes to check for **expired accepted drops**.

### Purpose:
When a collector accepts a drop, they have a certain amount of time to collect it (based on route duration + buffer). If they don't collect it within that time, the drop should be set back to `PENDING` so other collectors can accept it.

### How It Works:

1. **Runs Every 2 Minutes**: `@Cron('*/2 * * * *')` - Scheduled task
2. **Finds All Accepted Drops**: Looks for drops with `ACCEPTED` status
3. **Checks Timeout**: Calculates if the collector's time has expired
4. **Sets Back to PENDING**: If expired, changes status back to `PENDING`
5. **Sends Notifications**: Notifies both the household user and collector
6. **Ends Live Activity**: Sends "end" event to dismiss the Live Activity

### Why It's Important:

- **Prevents Drops from Getting Stuck**: If a collector accepts but never collects, the drop would be stuck in "ACCEPTED" status forever
- **Fairness**: Other collectors can accept the drop if the first one doesn't collect in time
- **User Experience**: Household users see their drop become available again

## The Error You're Seeing:

The error occurs when the cleanup task tries to find accepted drops for a collector. The problem is:

1. The code gets `interaction.dropoffId` from the database
2. When Mongoose populates this field, it becomes a **full document object** instead of just an ObjectId
3. The code then tries to use this in a query: `_id: { $in: dropoffIds }`
4. Mongoose expects ObjectIds, but gets a full document → **Error!**

### The Fix:

I already fixed this in `findAcceptedByCollector()` method, but the error might be happening in a different place. Let me check if there are other places where this pattern occurs.

