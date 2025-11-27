# Database Migration Guide: Local to Production

This guide explains how to migrate your local MongoDB database to production.

## Prerequisites

1. **MongoDB Connection Strings**:
   - Local database URI (source)
   - Production database URI (destination)

2. **Access**:
   - Read access to local database
   - Write access to production database

## Quick Start

### Option 1: Using Environment Variables

1. **Set environment variables**:
   ```bash
   export SOURCE_MONGODB_URI="mongodb://localhost:27017/bottleji"
   export DEST_MONGODB_URI="mongodb+srv://user:password@cluster.mongodb.net/bottleji?retryWrites=true&w=majority"
   ```

2. **Run the migration**:
   ```bash
   cd backend
   node scripts/database/migrate-to-production.js
   ```

### Option 2: Using .env File

1. **Add to your `.env` file**:
   ```env
   SOURCE_MONGODB_URI=mongodb://localhost:27017/bottleji
   DEST_MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/bottleji?retryWrites=true&w=majority
   ```

2. **Run the migration**:
   ```bash
   cd backend
   node scripts/database/migrate-to-production.js
   ```

## Getting Your Production MongoDB URI

### From MongoDB Atlas

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Click on your cluster
3. Click "Connect"
4. Choose "Connect your application"
5. Copy the connection string
6. Replace `<password>` with your database password
7. Replace `<dbname>` with your database name (e.g., `bottleji`)

Example:
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bottleji?retryWrites=true&w=majority
```

### From Render (If using Render's MongoDB)

1. Go to your Render dashboard
2. Find your MongoDB service
3. Copy the "Internal Connection String" or "External Connection String"
4. Use it as `DEST_MONGODB_URI`

## What Gets Migrated

The script migrates all collections, including:

- ✅ `users` - All user accounts
- ✅ `temporarysignups` - Pending signups
- ✅ `collectorapplications` - Collector applications
- ✅ `dropoffs` - All dropoff records
- ✅ `collectorinteractions` - Collector interactions
- ✅ `collectionattempts` - Collection attempts
- ✅ `notifications` - User notifications
- ✅ `rewarditems` - Reward catalog
- ✅ `rewardredemptions` - Reward redemptions
- ✅ `earningssessions` - Earnings sessions
- ✅ `supporttickets` - Support tickets
- ✅ `ticketmessages` - Ticket messages
- ✅ `trainingmaterials` - Training materials
- ✅ `shippinglabels` - Shipping labels
- ✅ Any other collections in your database

## Migration Behavior

- **Duplicate Handling**: By default, existing documents are skipped (not overwritten)
- **Batch Processing**: Documents are processed in batches of 1000 for efficiency
- **Progress Tracking**: Real-time progress updates during migration
- **Error Handling**: Errors are logged but don't stop the migration
- **Verification**: After migration, counts are compared between source and destination

## Safety Features

1. **Read-Only Source**: The script only reads from the source database
2. **Duplicate Protection**: Existing documents in production are not overwritten by default
3. **Transaction Safety**: Each document is processed individually
4. **Error Recovery**: Failed documents are logged but don't stop the process

## Troubleshooting

### Error: "DEST_MONGODB_URI is required"

**Solution**: Set the `DEST_MONGODB_URI` environment variable:
```bash
export DEST_MONGODB_URI="your-production-uri"
```

### Error: "Authentication failed"

**Solution**: 
- Check your MongoDB username and password
- Ensure your IP is whitelisted in MongoDB Atlas
- Verify the connection string format

### Error: "Connection timeout"

**Solution**:
- Check your internet connection
- Verify the MongoDB URI is correct
- Check if MongoDB Atlas allows connections from your IP

### Count Mismatch After Migration

**Possible Causes**:
- Some documents failed to migrate (check error logs)
- Duplicate documents were skipped
- Documents were deleted during migration

**Solution**: Review the migration output for errors and warnings.

## Advanced Options

### Overwrite Existing Documents

To update existing documents instead of skipping them, modify the script:

```javascript
await migrateCollection(collectionName, { skipDuplicates: false });
```

### Custom Batch Size

To change the batch size:

```javascript
await migrateCollection(collectionName, { batchSize: 500 });
```

### Migrate Specific Collections Only

Edit the `COLLECTIONS_TO_MIGRATE` array in the script to include only the collections you want.

## Post-Migration Checklist

After migration, verify:

1. ✅ User accounts are accessible
2. ✅ Dropoffs are visible
3. ✅ Collector applications are present
4. ✅ Notifications are working
5. ✅ Rewards system is functional
6. ✅ Support tickets are accessible

## Rollback

If something goes wrong:

1. **Option 1**: Restore from a MongoDB backup (if you have one)
2. **Option 2**: Delete the production database and re-run migration
3. **Option 3**: Manually fix specific collections

## Best Practices

1. **Backup First**: Always backup your production database before migration
2. **Test Migration**: Test the migration script on a staging environment first
3. **Monitor**: Watch the migration progress and logs
4. **Verify**: Always verify the migration results
5. **Document**: Keep a record of what was migrated and when

## Support

If you encounter issues:

1. Check the error messages in the console
2. Review the migration logs
3. Verify your MongoDB connection strings
4. Check MongoDB Atlas logs for connection issues

