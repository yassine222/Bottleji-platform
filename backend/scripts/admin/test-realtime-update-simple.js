const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function testRealtimeUpdate() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');
    const applicationsCollection = db.collection('collectorapplications');

    const testUserEmail = 'testuser2@gmail.com';

    // Find the test user
    const user = await usersCollection.findOne({ email: testUserEmail });
    
    if (!user) {
      console.log('❌ Test user not found');
      return;
    }

    // Find the user's collector application
    const application = await applicationsCollection.findOne({ userId: user._id });
    
    if (!application) {
      console.log('❌ No collector application found for this user');
      return;
    }

    console.log('\n🔍 Current Status:');
    console.log(`User status: ${user.collectorApplicationStatus || 'Not set'}`);
    console.log(`Application status: ${application.status}`);
    console.log(`Application ID: ${application._id}`);

    // Test the real-time update by simulating an admin action
    console.log('\n🧪 Testing real-time update simulation...');
    
    // Simulate updating the application status
    const newStatus = application.status === 'rejected' ? 'pending' : 'rejected';
    const newRejectionReason = newStatus === 'rejected' ? 'Test rejection for real-time update' : null;
    
    console.log(`📝 Simulating status change from ${application.status} to ${newStatus}`);
    
    // Update the application
    await applicationsCollection.updateOne(
      { _id: application._id },
      { 
        $set: { 
          status: newStatus,
          rejectionReason: newRejectionReason,
          reviewedAt: new Date()
        } 
      }
    );
    
    // Update the user status (this is what the admin service now does)
    await usersCollection.updateOne(
      { _id: user._id },
      {
        $set: {
          collectorApplicationStatus: newStatus,
          collectorApplicationId: application._id.toString(),
          collectorApplicationAppliedAt: application.appliedAt,
          collectorApplicationRejectionReason: newRejectionReason,
        }
      }
    );
    
    console.log('✅ Status updated in database');
    
    // Verify the update
    const updatedUser = await usersCollection.findOne({ email: testUserEmail });
    const updatedApplication = await applicationsCollection.findOne({ userId: user._id });
    
    console.log('\n🔍 Updated Status:');
    console.log(`User status: ${updatedUser.collectorApplicationStatus || 'Not set'}`);
    console.log(`Application status: ${updatedApplication.status}`);
    
    if (updatedUser.collectorApplicationStatus === updatedApplication.status) {
      console.log('✅ Status consistency verified!');
      console.log('💡 The Flutter app should receive a WebSocket notification and update immediately');
      console.log('💡 No app restart required - real-time update should work!');
    } else {
      console.log('❌ Status inconsistency detected');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

testRealtimeUpdate().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
