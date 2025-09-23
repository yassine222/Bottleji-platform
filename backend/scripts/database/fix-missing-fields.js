const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function fixMissingFields() {
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
    console.log(`isPhoneVerified: ${user.isPhoneVerified}`);
    console.log(`phoneVerificationId: ${user.phoneVerificationId}`);
    console.log(`sessionInvalidatedAt: ${user.sessionInvalidatedAt}`);
    console.log(`deletedAt: ${user.deletedAt}`);
    console.log(`deletedBy: ${user.deletedBy}`);

    // Check what fields are missing
    const missingFields = [];
    if (user.deletedAt === undefined) missingFields.push('deletedAt');
    if (user.deletedBy === undefined) missingFields.push('deletedBy');

    if (missingFields.length === 0) {
      console.log('\n✅ All fields are present, no fix needed');
      return;
    }

    console.log(`\n⚠️ Missing fields: ${missingFields.join(', ')}`);

    // Fix the missing fields by setting them to null
    const updateResult = await usersCollection.updateOne(
      { email: 'testuser2@gmail.com' },
      {
        $set: {
          deletedAt: null,
          deletedBy: null
        }
      }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ Missing fields fixed successfully!');
      console.log('   - Set deletedAt: null');
      console.log('   - Set deletedBy: null');
      
      // Verify the fix
      const updatedUser = await usersCollection.findOne({ email: 'testuser2@gmail.com' });
      console.log('\n🔍 Updated user data:');
      console.log(`Email: ${updatedUser.email}`);
      console.log(`isPhoneVerified: ${updatedUser.isPhoneVerified}`);
      console.log(`phoneVerificationId: ${updatedUser.phoneVerificationId}`);
      console.log(`sessionInvalidatedAt: ${updatedUser.sessionInvalidatedAt}`);
      console.log(`deletedAt: ${updatedUser.deletedAt}`);
      console.log(`deletedBy: ${updatedUser.deletedBy}`);
      
      console.log('\n💡 Now the user should have all required fields');
      console.log('   - Try logging in again with testuser2@gmail.com');
      console.log('   - The phone verification status should be correct');
      
    } else {
      console.log('\n❌ Failed to fix missing fields');
    }

  } catch (error) {
    console.error('❌ Fix failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the fix
fixMissingFields().then(() => {
  console.log('Fix script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Fix script failed:', error);
  process.exit(1);
});
