const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function forceRefreshUserSession() {
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
    console.log(`   Email: ${user.email}`);
    console.log(`   Phone Number: ${user.phoneNumber || 'NOT SET'}`);
    console.log(`   isPhoneVerified: ${user.isPhoneVerified}`);
    console.log(`   isProfileComplete: ${user.isProfileComplete}`);
    console.log(`   Name: ${user.name || 'NOT SET'}`);
    console.log(`   Address: ${user.address || 'NOT SET'}`);

    // Force session invalidation by setting sessionInvalidatedAt
    const updateResult = await usersCollection.updateOne(
      { email: 'testuser2@gmail.com' },
      {
        $set: {
          sessionInvalidatedAt: new Date()
        }
      }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ User session invalidated successfully!');
      console.log('   - Set sessionInvalidatedAt to force logout');
      
      // Verify the update
      const updatedUser = await usersCollection.findOne({ email: 'testuser2@gmail.com' });
      console.log('\n🔍 Updated user data:');
      console.log(`   Email: ${updatedUser.email}`);
      console.log(`   Phone Number: ${updatedUser.phoneNumber || 'NOT SET'}`);
      console.log(`   isPhoneVerified: ${updatedUser.isPhoneVerified}`);
      console.log(`   isProfileComplete: ${updatedUser.isProfileComplete}`);
      console.log(`   sessionInvalidatedAt: ${updatedUser.sessionInvalidatedAt}`);
      
      console.log('\n💡 Instructions for the user:');
      console.log('   1. Close the app completely');
      console.log('   2. Clear app data/cache if possible');
      console.log('   3. Restart the app');
      console.log('   4. Login again with testuser2@gmail.com');
      console.log('   5. The app should now show the correct profile status');
      
    } else {
      console.log('\n❌ Failed to invalidate user session');
    }

  } catch (error) {
    console.error('❌ Session invalidation failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the session invalidation
forceRefreshUserSession().then(() => {
  console.log('Session invalidation script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Session invalidation script failed:', error);
  process.exit(1);
});
