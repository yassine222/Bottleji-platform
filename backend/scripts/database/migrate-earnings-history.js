const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

async function migrateEarningsHistory() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db();
    const usersCollection = db.collection('users');
    const earningsSessionsCollection = db.collection('earningssessions');

    console.log('\n📊 Step 1: Initializing earningsHistory for all users...');
    
    // Initialize earningsHistory as empty array for all users that don't have it
    const initResult = await usersCollection.updateMany(
      {
        $or: [
          { earningsHistory: { $exists: false } },
          { earningsHistory: null }
        ]
      },
      {
        $set: {
          earningsHistory: []
        }
      }
    );
    console.log(`✅ Initialized earningsHistory for ${initResult.modifiedCount} users`);

    // Also ensure totalEarnings exists
    const totalEarningsResult = await usersCollection.updateMany(
      {
        $or: [
          { totalEarnings: { $exists: false } },
          { totalEarnings: null }
        ]
      },
      {
        $set: {
          totalEarnings: 0
        }
      }
    );
    console.log(`✅ Initialized totalEarnings for ${totalEarningsResult.modifiedCount} users`);

    console.log('\n📊 Step 2: Migrating existing earnings sessions to users\' earningsHistory...');
    
    // Get all earnings sessions
    const earningsSessions = await earningsSessionsCollection.find({}).toArray();
    console.log(`📦 Found ${earningsSessions.length} earnings sessions to migrate`);

    let migratedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Group sessions by userId
    const sessionsByUser = {};
    for (const session of earningsSessions) {
      const userId = session.userId?.toString();
      if (!userId) {
        console.log(`⚠️ Session ${session._id} has no userId, skipping`);
        skippedCount++;
        continue;
      }

      if (!sessionsByUser[userId]) {
        sessionsByUser[userId] = [];
      }
      sessionsByUser[userId].push(session);
    }

    console.log(`📊 Found ${Object.keys(sessionsByUser).length} unique users with earnings sessions`);

    // Migrate sessions for each user
    for (const [userId, sessions] of Object.entries(sessionsByUser)) {
      try {
        // Get current user earningsHistory
        const user = await usersCollection.findOne({ _id: new ObjectId(userId) });
        if (!user) {
          console.log(`⚠️ User ${userId} not found, skipping sessions`);
          skippedCount += sessions.length;
          continue;
        }

        const existingHistory = user.earningsHistory || [];
        
        // Convert sessions to earningsHistory format
        const newEntries = sessions.map(session => {
          // Normalize date to start of day
          const sessionDate = new Date(session.date);
          sessionDate.setHours(0, 0, 0, 0);

          return {
            date: sessionDate,
            earnings: session.sessionEarnings || 0,
            collectionCount: session.collectionCount || 0,
            startTime: session.startTime || sessionDate,
            lastCollectionTime: session.lastCollectionTime || sessionDate,
            isActive: session.isActive || false,
          };
        });

        // Merge with existing history (avoid duplicates by date)
        const mergedHistory = [...existingHistory];
        for (const newEntry of newEntries) {
          const existingIndex = mergedHistory.findIndex(entry => {
            if (!entry || !entry.date) return false;
            const entryDate = new Date(entry.date);
            entryDate.setHours(0, 0, 0, 0);
            return entryDate.getTime() === newEntry.date.getTime();
          });

          if (existingIndex >= 0) {
            // Update existing entry if session is more recent
            const existingEntry = mergedHistory[existingIndex];
            const existingLastTime = existingEntry.lastCollectionTime 
              ? new Date(existingEntry.lastCollectionTime).getTime() 
              : 0;
            const newLastTime = newEntry.lastCollectionTime.getTime();
            
            if (newLastTime > existingLastTime) {
              mergedHistory[existingIndex] = newEntry;
              console.log(`   ↻ Updated entry for ${newEntry.date.toISOString().split('T')[0]}`);
            } else {
              console.log(`   ⏭️  Skipped older entry for ${newEntry.date.toISOString().split('T')[0]}`);
            }
          } else {
            // Add new entry
            mergedHistory.push(newEntry);
            console.log(`   ➕ Added entry for ${newEntry.date.toISOString().split('T')[0]}`);
          }
        }

        // Sort by date (newest first)
        mergedHistory.sort((a, b) => {
          const dateA = new Date(a.date).getTime();
          const dateB = new Date(b.date).getTime();
          return dateB - dateA;
        });

        // Update user with merged history
        await usersCollection.updateOne(
          { _id: new ObjectId(userId) },
          {
            $set: {
              earningsHistory: mergedHistory
            }
          }
        );

        migratedCount += sessions.length;
        console.log(`✅ Migrated ${sessions.length} sessions for user ${userId} (${user.email || 'unknown'})`);
      } catch (error) {
        console.error(`❌ Error migrating sessions for user ${userId}:`, error);
        errorCount += sessions.length;
      }
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   ✅ Migrated: ${migratedCount} sessions`);
    console.log(`   ⏭️  Skipped: ${skippedCount} sessions`);
    console.log(`   ❌ Errors: ${errorCount} sessions`);
    console.log(`   📝 Total sessions processed: ${earningsSessions.length}`);

    console.log('\n✅ Migration completed successfully!');
    console.log('\n💡 Note: Existing earnings sessions in the EarningsSession collection are preserved.');
    console.log('   The earningsHistory array in users is now the primary source for earnings display.');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

// Run migration
migrateEarningsHistory()
  .then(() => {
    console.log('\n🎉 Migration script completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Migration script failed:', error);
    process.exit(1);
  });

