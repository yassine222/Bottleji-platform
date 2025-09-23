const { MongoClient } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

async function addPhoneVerificationFields() {
  let client;
  try {
    console.log('🔍 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB successfully');

    const db = client.db();
    const usersCollection = db.collection('users');

    // Check how many users exist
    const totalUsers = await usersCollection.countDocuments();
    console.log(`📊 Total users in database: ${totalUsers}`);

    // Check how many users already have the new fields
    const usersWithPhoneVerified = await usersCollection.countDocuments({
      $or: [
        { isPhoneVerified: { $exists: true } },
        { phoneVerificationId: { $exists: true } }
      ]
    });
    console.log(`📊 Users with phone verification fields: ${usersWithPhoneVerified}`);

    // Add the new fields to all users that don't have them
    const result = await usersCollection.updateMany(
      {
        $or: [
          { isPhoneVerified: { $exists: false } },
          { phoneVerificationId: { $exists: false } }
        ]
      },
      {
        $set: {
          isPhoneVerified: false,
          phoneVerificationId: null
        }
      }
    );

    console.log(`✅ Migration completed successfully!`);
    console.log(`📊 Users updated: ${result.modifiedCount}`);
    console.log(`📊 Users matched: ${result.matchedCount}`);

    // Verify the migration
    const usersAfterMigration = await usersCollection.countDocuments({
      $and: [
        { isPhoneVerified: { $exists: true } },
        { phoneVerificationId: { $exists: true } }
      ]
    });
    console.log(`📊 Users with phone verification fields after migration: ${usersAfterMigration}`);

    // Show sample user to verify fields were added
    const sampleUser = await usersCollection.findOne({});
    if (sampleUser) {
      console.log('📋 Sample user fields:');
      console.log(`   - isPhoneVerified: ${sampleUser.isPhoneVerified}`);
      console.log(`   - phoneVerificationId: ${sampleUser.phoneVerificationId}`);
      console.log(`   - phoneNumber: ${sampleUser.phoneNumber}`);
    }

  } catch (error) {
    console.error('❌ Error during migration:', error);
    throw error;
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 MongoDB connection closed');
    }
  }
}

// Run the migration if this script is executed directly
if (require.main === module) {
  console.log('🚀 Starting phone verification fields migration...');
  addPhoneVerificationFields()
    .then(() => {
      console.log('✅ Migration completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addPhoneVerificationFields };
