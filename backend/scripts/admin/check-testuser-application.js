const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function checkTestUserApplication() {
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

    console.log('\n👤 Test User Information:');
    console.log(`Email: ${user.email}`);
    console.log(`Name: ${user.name || 'Not set'}`);
    console.log(`Roles: ${user.roles.join(', ')}`);
    console.log(`Collector Application Status: ${user.collectorApplicationStatus || 'Not set'}`);
    console.log(`Collector Application ID: ${user.collectorApplicationId || 'Not set'}`);
    console.log(`Collector Application Applied At: ${user.collectorApplicationAppliedAt || 'Not set'}`);
    console.log(`Collector Application Rejection Reason: ${user.collectorApplicationRejectionReason || 'Not set'}`);

    // Find the user's collector application
    const application = await applicationsCollection.findOne({ userId: user._id });
    
    if (application) {
      console.log('\n📋 Collector Application Information:');
      console.log(`Application ID: ${application._id}`);
      console.log(`Status: ${application.status}`);
      console.log(`Applied At: ${application.appliedAt}`);
      console.log(`Reviewed At: ${application.reviewedAt || 'Not reviewed yet'}`);
      console.log(`Rejection Reason: ${application.rejectionReason || 'Not set'}`);
      console.log(`Review Notes: ${application.reviewNotes || 'Not set'}`);
      console.log(`ID Type: ${application.idCardType || 'Not set'}`);
      console.log(`ID Number: ${application.idCardNumber || 'Not set'}`);
    } else {
      console.log('\n❌ No collector application found for this user');
    }

    // Check if there's a mismatch between user status and application status
    if (user.collectorApplicationStatus && application) {
      const userStatus = user.collectorApplicationStatus.toLowerCase();
      const appStatus = application.status.toLowerCase();
      
      if (userStatus !== appStatus) {
        console.log('\n⚠️  STATUS MISMATCH DETECTED!');
        console.log(`User status: ${user.collectorApplicationStatus}`);
        console.log(`Application status: ${application.status}`);
        console.log('\n💡 This might be causing the navigation issues');
      } else {
        console.log('\n✅ Status consistency: User and application status match');
      }
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

checkTestUserApplication().then(() => {
  console.log('\n✅ Check completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Check failed:', error);
  process.exit(1);
});
