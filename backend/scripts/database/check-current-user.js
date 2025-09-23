const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function checkCurrentUser() {
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

    console.log('\n🔍 Current user data for testuser2@gmail.com:');
    console.log('='.repeat(50));
    console.log(`Email: ${user.email}`);
    console.log(`Name: ${user.name || 'NOT SET'}`);
    console.log(`Phone Number: ${user.phoneNumber || 'NOT SET'}`);
    console.log(`Address: ${user.address || 'NOT SET'}`);
    console.log(`isPhoneVerified: ${user.isPhoneVerified}`);
    console.log(`isProfileComplete: ${user.isProfileComplete}`);
    console.log(`isVerified: ${user.isVerified}`);
    console.log(`Roles: ${user.roles ? user.roles.join(', ') : 'NOT SET'}`);
    console.log(`sessionInvalidatedAt: ${user.sessionInvalidatedAt || 'NOT SET'}`);
    console.log(`Created At: ${user.createdAt}`);
    console.log(`Updated At: ${user.updatedAt}`);
    console.log('='.repeat(50));

    // Check if profile should be complete
    const hasRequiredFields = user.name && user.phoneNumber && user.address;
    const isPhoneVerified = user.isPhoneVerified === true;
    
    console.log('\n📊 Profile Analysis:');
    console.log(`Has required fields (name, phone, address): ${hasRequiredFields ? '✅ YES' : '❌ NO'}`);
    console.log(`Phone is verified: ${isPhoneVerified ? '✅ YES' : '❌ NO'}`);
    console.log(`Profile marked complete: ${user.isProfileComplete ? '✅ YES' : '❌ NO'}`);
    
    if (user.isProfileComplete && !hasRequiredFields) {
      console.log('\n⚠️ ISSUE: Profile marked complete but missing required fields!');
    } else if (!user.isProfileComplete && hasRequiredFields && isPhoneVerified) {
      console.log('\n⚠️ ISSUE: Profile has all required fields but not marked complete!');
    } else if (user.isProfileComplete && hasRequiredFields && isPhoneVerified) {
      console.log('\n✅ Profile is correctly marked as complete');
    } else {
      console.log('\nℹ️ Profile is correctly marked as incomplete');
    }

    console.log('\n💡 Expected App Behavior:');
    if (user.isProfileComplete) {
      console.log('   - App should show "Edit Profile" button');
      console.log('   - User should be able to edit their profile');
    } else {
      console.log('   - App should show "Complete Profile" screen');
      console.log('   - User should be required to fill missing fields');
    }

  } catch (error) {
    console.error('❌ Check failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the check
checkCurrentUser().then(() => {
  console.log('Check completed');
  process.exit(0);
}).catch((error) => {
  console.error('Check failed:', error);
  process.exit(1);
});
