const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function checkRedemptions() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const redemptionsCollection = db.collection('rewardredemptions');
    
    // Check if collection exists
    const collections = await db.listCollections().toArray();
    const redemptionCollectionExists = collections.some(col => col.name === 'rewardredemptions');
    
    console.log(`\n📊 Collection 'rewardredemptions' exists: ${redemptionCollectionExists}`);
    
    if (redemptionCollectionExists) {
      const count = await redemptionsCollection.countDocuments();
      console.log(`📈 Total redemptions: ${count}`);
      
      if (count > 0) {
        const sample = await redemptionsCollection.findOne();
        console.log('📋 Sample redemption:', JSON.stringify(sample, null, 2));
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

checkRedemptions();
