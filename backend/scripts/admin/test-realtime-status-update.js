const { MongoClient } = require('mongodb');
const http = require('http');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function testRealtimeStatusUpdate() {
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

    // Test the rejection API endpoint
    console.log('\n🧪 Testing rejection API...');
    
    const rejectionData = JSON.stringify({
      rejectionReason: 'Test rejection for real-time update verification',
      notes: 'This is a test rejection to verify real-time status updates'
    });

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/admin/collector-applications/${application._id}/reject`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token', // You'll need to replace this with a real admin token
        'Content-Length': Buffer.byteLength(rejectionData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📡 Rejection API Response Status: ${res.statusCode}`);
        
        if (res.statusCode === 200 || res.statusCode === 201) {
          console.log('✅ Rejection API call successful!');
          console.log('📄 Response:', data);
          
          // Check if the user status was updated
          setTimeout(async () => {
            const updatedUser = await usersCollection.findOne({ email: testUserEmail });
            console.log('\n🔍 Updated User Status:');
            console.log(`User status: ${updatedUser.collectorApplicationStatus || 'Not set'}`);
            console.log(`Rejection reason: ${updatedUser.collectorApplicationRejectionReason || 'Not set'}`);
            
            if (updatedUser.collectorApplicationStatus === 'rejected') {
              console.log('✅ User status updated successfully in database!');
              console.log('💡 The Flutter app should receive a WebSocket notification and update the drawer status');
            } else {
              console.log('❌ User status not updated in database');
            }
          }, 1000);
          
        } else {
          console.log('❌ Rejection API call failed');
          console.log('📄 Error Response:', data);
        }
      });
    });

    req.on('error', (e) => {
      console.log('❌ Request Error:', e.message);
    });

    req.write(rejectionData);
    req.end();

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

testRealtimeStatusUpdate().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
