const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function fixInconsistentUser() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');

    // Find the inconsistent user
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

    // Check the inconsistency
    const hasInconsistency = user.isPhoneVerified === true && (!user.phoneNumber || user.phoneNumber.trim() === '');
    
    if (!hasInconsistency) {
      console.log('\n✅ User data is consistent, no fix needed');
      return;
    }

    console.log('\n⚠️ Inconsistency detected:');
    console.log('   - Phone is marked as verified (isPhoneVerified: true)');
    console.log('   - But no phone number is set (phoneNumber is empty)');
    console.log('   - Profile is marked as complete but missing phone number');

    // Fix the inconsistency by resetting verification status
    const updateResult = await usersCollection.updateOne(
      { email: 'testuser2@gmail.com' },
      {
        $set: {
          isPhoneVerified: false,
          isProfileComplete: false,
          phoneVerificationId: null
        }
      }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ User data fixed successfully!');
      console.log('   - Set isPhoneVerified: false');
      console.log('   - Set isProfileComplete: false');
      console.log('   - Cleared phoneVerificationId');
      
      // Verify the fix
      const updatedUser = await usersCollection.findOne({ email: 'testuser2@gmail.com' });
      console.log('\n🔍 Updated user data:');
      console.log(`   Email: ${updatedUser.email}`);
      console.log(`   Phone Number: ${updatedUser.phoneNumber || 'NOT SET'}`);
      console.log(`   isPhoneVerified: ${updatedUser.isPhoneVerified}`);
      console.log(`   isProfileComplete: ${updatedUser.isProfileComplete}`);
      
      console.log('\n💡 Next steps:');
      console.log('   - User will need to add a phone number in the app');
      console.log('   - User will need to verify the phone number');
      console.log('   - Profile will be marked complete once phone is verified');
      
    } else {
      console.log('\n❌ Failed to update user data');
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
fixInconsistentUser().then(() => {
  console.log('Fix script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Fix script failed:', error);
  process.exit(1);
});
