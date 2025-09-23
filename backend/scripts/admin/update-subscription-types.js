const { MongoClient } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

async function updateSubscriptionTypes() {
  let client;
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db();
    const usersCollection = db.collection('users');

    // Find users with 'free' subscription type
    const usersWithFree = await usersCollection.find({ 
      collectorSubscriptionType: 'free' 
    }).toArray();

    console.log(`📊 Found ${usersWithFree.length} users with 'free' subscription type`);

    if (usersWithFree.length === 0) {
      console.log('✅ No users need to be updated');
      return;
    }

    // Update all users with 'free' to 'basic'
    const result = await usersCollection.updateMany(
      { collectorSubscriptionType: 'free' },
      { $set: { collectorSubscriptionType: 'basic' } }
    );

    console.log(`✅ Updated ${result.modifiedCount} users from 'free' to 'basic'`);

    // Also update users with 'pro' to 'premium' if any exist
    const usersWithPro = await usersCollection.find({ 
      collectorSubscriptionType: 'pro' 
    }).toArray();

    console.log(`📊 Found ${usersWithPro.length} users with 'pro' subscription type`);

    if (usersWithPro.length > 0) {
      const resultPro = await usersCollection.updateMany(
        { collectorSubscriptionType: 'pro' },
        { $set: { collectorSubscriptionType: 'premium' } }
      );
      console.log(`✅ Updated ${resultPro.modifiedCount} users from 'pro' to 'premium'`);
    }

    console.log('🎉 Subscription type migration completed successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  updateSubscriptionTypes()
    .then(() => {
      console.log('🎉 Migration completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { updateSubscriptionTypes };
