const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function fixTestUserApplicationStatus() {
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

    // Update the user's application status to match the application
    const updateResult = await usersCollection.updateOne(
      { email: testUserEmail },
      {
        $set: {
          collectorApplicationStatus: application.status,
          collectorApplicationId: application._id.toString(),
          collectorApplicationAppliedAt: application.appliedAt,
          collectorApplicationRejectionReason: application.rejectionReason || null,
        }
      }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ User application status updated successfully!');
      console.log(`Updated status: ${application.status}`);
      console.log(`Updated application ID: ${application._id}`);
      console.log(`Updated applied at: ${application.appliedAt}`);
      
      // Verify the update
      const updatedUser = await usersCollection.findOne({ email: testUserEmail });
      console.log('\n🔍 Updated User Information:');
      console.log(`Collector Application Status: ${updatedUser.collectorApplicationStatus}`);
      console.log(`Collector Application ID: ${updatedUser.collectorApplicationId}`);
      console.log(`Collector Application Applied At: ${updatedUser.collectorApplicationAppliedAt}`);
      console.log(`Collector Application Rejection Reason: ${updatedUser.collectorApplicationRejectionReason || 'Not set'}`);
      
      console.log('\n💡 The app drawer should now show the correct status!');
      console.log('   - If status is "pending" → Should show "Under Review"');
      console.log('   - If status is "rejected" → Should show "Rejected" with info icon');
      console.log('   - If status is "approved" → Should show "Collector Mode"');
      
    } else {
      console.log('\n❌ Failed to update user application status');
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

fixTestUserApplicationStatus().then(() => {
  console.log('\n✅ Fix completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Fix failed:', error);
  process.exit(1);
});
