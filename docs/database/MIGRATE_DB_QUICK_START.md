# Quick Start: Migrate Database to Production

## Step 1: Get Your Production MongoDB URI

From your Render dashboard or MongoDB Atlas, get your production MongoDB connection string.

Example format:
```
mongodb+srv://username:password@cluster.mongodb.net/bottleji?retryWrites=true&w=majority
```

## Step 2: Run the Migration

### Option A: One-Line Command

```bash
cd backend
SOURCE_MONGODB_URI="mongodb://localhost:27017/bottleji" \
DEST_MONGODB_URI="your-production-uri-here" \
node scripts/database/migrate-to-production.js
```

### Option B: Using .env File

1. Create or edit `backend/.env`:
```env
SOURCE_MONGODB_URI=mongodb://localhost:27017/bottleji
DEST_MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/bottleji?retryWrites=true&w=majority
```

2. Run:
```bash
cd backend
node scripts/database/migrate-to-production.js
```

## Step 3: Wait for Migration

The script will:
- ✅ Connect to both databases
- ✅ Migrate all collections
- ✅ Show progress for each collection
- ✅ Verify the migration
- ✅ Display a summary

## Step 4: Verify

After migration, check your production database to ensure all data is present.

---

**Note**: Replace `bottleji` with your actual database name if different.

