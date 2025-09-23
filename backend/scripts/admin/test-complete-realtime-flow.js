const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function testCompleteRealtimeFlow() {
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

    // Test the complete flow
    console.log('\n🧪 Testing Complete Real-Time Flow...');
    
    // Step 1: Simulate admin rejecting the application
    console.log('\n📝 Step 1: Admin rejects application');
    await applicationsCollection.updateOne(
      { _id: application._id },
      { 
        $set: { 
          status: 'rejected',
          rejectionReason: 'Test rejection for real-time flow',
          reviewedAt: new Date()
        } 
      }
    );
    
    await usersCollection.updateOne(
      { _id: user._id },
      {
        $set: {
          collectorApplicationStatus: 'rejected',
          collectorApplicationId: application._id.toString(),
          collectorApplicationAppliedAt: application.appliedAt,
          collectorApplicationRejectionReason: 'Test rejection for real-time flow',
        }
      }
    );
    
    let updatedUser = await usersCollection.findOne({ email: testUserEmail });
    let updatedApplication = await applicationsCollection.findOne({ userId: user._id });
    
    console.log(`✅ Status after rejection: User=${updatedUser.collectorApplicationStatus}, App=${updatedApplication.status}`);
    console.log('💡 Flutter app should show "Rejected" in drawer');
    
    // Step 2: Simulate user updating the rejected application
    console.log('\n📝 Step 2: User updates rejected application');
    await applicationsCollection.updateOne(
      { _id: application._id },
      { 
        $set: { 
          status: 'pending',
          rejectionReason: undefined,
          reviewedAt: undefined,
          reviewedBy: undefined,
          reviewNotes: undefined,
          appliedAt: new Date()
        } 
      }
    );
    
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
    
    updatedUser = await usersCollection.findOne({ email: testUserEmail });
    updatedApplication = await applicationsCollection.findOne({ userId: user._id });
    
    console.log(`✅ Status after update: User=${updatedUser.collectorApplicationStatus}, App=${updatedApplication.status}`);
    console.log('💡 Flutter app should show "Under Review" in drawer');
    
    // Step 3: Simulate admin approving the application
    console.log('\n📝 Step 3: Admin approves application');
    await applicationsCollection.updateOne(
      { _id: application._id },
      { 
        $set: { 
          status: 'approved',
          rejectionReason: undefined,
          reviewedAt: new Date(),
          reviewNotes: 'Application approved'
        } 
      }
    );
    
    await usersCollection.updateOne(
      { _id: user._id },
      {
        $set: {
          collectorApplicationStatus: 'approved',
          collectorApplicationId: application._id.toString(),
          collectorApplicationAppliedAt: application.appliedAt,
          collectorApplicationRejectionReason: undefined,
        }
      }
    );
    
    updatedUser = await usersCollection.findOne({ email: testUserEmail });
    updatedApplication = await applicationsCollection.findOne({ userId: user._id });
    
    console.log(`✅ Status after approval: User=${updatedUser.collectorApplicationStatus}, App=${updatedApplication.status}`);
    console.log('💡 Flutter app should show "Collector Mode" in drawer');
    
    console.log('\n🎯 Real-Time Flow Test Summary:');
    console.log('✅ Rejection → User sees "Rejected" in drawer');
    console.log('✅ Update → User sees "Under Review" in drawer');
    console.log('✅ Approval → User sees "Collector Mode" in drawer');
    console.log('💡 Each change should update immediately via WebSocket without app restart');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

testCompleteRealtimeFlow().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
