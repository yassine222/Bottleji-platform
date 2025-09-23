const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function clearSessionInvalidation() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');

    // Find the user
    const user = await usersCollection.findOne({ email: 'testuser2@gmail.com' });
    
    if (!user) {
      console.log('❌ User testuser2@gmail.com not found');
      return;
    }

    console.log('\n🔍 Current user data:');
    console.log(`Email: ${user.email}`);
    console.log(`sessionInvalidatedAt: ${user.sessionInvalidatedAt}`);

    if (!user.sessionInvalidatedAt) {
      console.log('\n✅ Session is not invalidated, no fix needed');
      return;
    }

    console.log('\n⚠️ Session is currently invalidated');

    // Clear the session invalidation
    const updateResult = await usersCollection.updateOne(
      { email: 'testuser2@gmail.com' },
      {
        $unset: {
          sessionInvalidatedAt: 1
        }
      }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ Session invalidation cleared successfully!');
      console.log('   - Removed sessionInvalidatedAt field');
      
      // Verify the fix
      const updatedUser = await usersCollection.findOne({ email: 'testuser2@gmail.com' });
      console.log('\n🔍 Updated user data:');
      console.log(`Email: ${updatedUser.email}`);
      console.log(`sessionInvalidatedAt: ${updatedUser.sessionInvalidatedAt || 'NOT SET'}`);
      
      console.log('\n💡 User can now login normally');
      console.log('   - Try logging in with testuser2@gmail.com');
      console.log('   - The phone verification status should be correct');
      
    } else {
      console.log('\n❌ Failed to clear session invalidation');
    }

  } catch (error) {
    console.error('❌ Clear failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the clear
clearSessionInvalidation().then(() => {
  console.log('Clear script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Clear script failed:', error);
  process.exit(1);
});
