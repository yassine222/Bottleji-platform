require('dotenv').config();
const { MongoClient } = require('mongodb');

// Use the same MongoDB URI as your backend
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

async function addMissingUserFields() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db();
    const usersCollection = db.collection('users');

    // Get all users
    const users = await usersCollection.find({}).toArray();
    console.log(`📊 Found ${users.length} users to update`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const user of users) {
      try {
        const updates = {};

        // Add isDeleted field if missing
        if (user.isDeleted === undefined) {
          updates.isDeleted = false;
          console.log(`🗑️ Adding isDeleted=false for user: ${user.email}`);
        }

        // Add deletedAt field if missing
        if (user.deletedAt === undefined) {
          updates.deletedAt = null;
          console.log(`📅 Adding deletedAt=null for user: ${user.email}`);
        }

        // Add deletedBy field if missing
        if (user.deletedBy === undefined) {
          updates.deletedBy = null;
          console.log(`👤 Adding deletedBy=null for user: ${user.email}`);
        }

        // Add sessionInvalidatedAt field if missing
        if (user.sessionInvalidatedAt === undefined) {
          updates.sessionInvalidatedAt = null;
          console.log(`🔒 Adding sessionInvalidatedAt=null for user: ${user.email}`);
        }

        // Apply updates if any
        if (Object.keys(updates).length > 0) {
          await usersCollection.updateOne(
            { _id: user._id },
            { $set: updates }
          );
          updatedCount++;
          console.log(`✅ Updated user: ${user.email}`);
        } else {
          skippedCount++;
          console.log(`⏭️ Skipped user (all fields already exist): ${user.email}`);
        }

      } catch (error) {
        console.error(`❌ Error updating user ${user.email}:`, error);
      }
    }

    console.log('\n📈 Migration Summary:');
    console.log(`✅ Updated: ${updatedCount} users`);
    console.log(`⏭️ Skipped: ${skippedCount} users`);
    console.log(`📊 Total processed: ${users.length} users`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  addMissingUserFields()
    .then(() => {
      console.log('🎉 Migration completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addMissingUserFields };
