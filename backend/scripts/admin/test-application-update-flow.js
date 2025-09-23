const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function testApplicationUpdateFlow() {
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

    console.log('\n🔍 Current Status (Before Update):');
    console.log(`User status: ${user.collectorApplicationStatus || 'Not set'}`);
    console.log(`Application status: ${application.status}`);
    console.log(`Application ID: ${application._id}`);

    // Simulate user updating their rejected application
    console.log('\n🧪 Simulating user updating rejected application...');
    
    // Update the application (this is what happens when user updates)
    const updateData = {
      idCardPhoto: 'updated_photo_url',
      selfieWithIdPhoto: 'updated_selfie_url',
      idCardNumber: '87654321',
      idCardType: 'Passport',
      idCardExpiryDate: new Date('2026-12-31'),
      idCardIssuingAuthority: 'Updated Authority',
      status: 'pending', // This should be set to pending
      rejectionReason: undefined, // Clear rejection reason
      reviewedAt: undefined, // Clear review data
      reviewedBy: undefined,
      reviewNotes: undefined,
      appliedAt: new Date(), // Update applied date
    };

    // Update the application
    await applicationsCollection.updateOne(
      { _id: application._id },
      { $set: updateData }
    );
    
    // Update the user status (this is what the service now does)
    await usersCollection.updateOne(
      { _id: user._id },
      {
        $set: {
          collectorApplicationStatus: 'pending',
          collectorApplicationId: application._id.toString(),
          collectorApplicationAppliedAt: new Date(),
          collectorApplicationRejectionReason: undefined,
        }
      }
    );
    
    console.log('✅ Application updated in database');
    
    // Verify the update
    const updatedUser = await usersCollection.findOne({ email: testUserEmail });
    const updatedApplication = await applicationsCollection.findOne({ userId: user._id });
    
    console.log('\n🔍 Updated Status (After Update):');
    console.log(`User status: ${updatedUser.collectorApplicationStatus || 'Not set'}`);
    console.log(`Application status: ${updatedApplication.status}`);
    console.log(`Rejection reason: ${updatedUser.collectorApplicationRejectionReason || 'Not set'}`);
    
    if (updatedUser.collectorApplicationStatus === 'pending' && updatedApplication.status === 'pending') {
      console.log('✅ Status updated correctly to pending!');
      console.log('💡 The Flutter app should receive a WebSocket notification and update to "Under Review"');
      console.log('💡 The drawer should show "Under Review" instead of "Become Collector"');
    } else {
      console.log('❌ Status update failed');
      console.log(`Expected: pending, Got: User=${updatedUser.collectorApplicationStatus}, App=${updatedApplication.status}`);
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

testApplicationUpdateFlow().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
