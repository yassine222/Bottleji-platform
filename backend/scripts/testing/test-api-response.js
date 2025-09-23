const { MongoClient } = require('mongodb');
const { JwtService } = require('@nestjs/jwt');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function testApiResponse() {
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

    console.log('\n🔍 User data from database:');
    console.log(`Email: ${user.email}`);
    console.log(`isPhoneVerified: ${user.isPhoneVerified}`);
    console.log(`phoneNumber: ${user.phoneNumber}`);

    // Generate a JWT token for testing
    const jwt = require('jsonwebtoken');
    const JWT_SECRET = 'your-super-secret-jwt-key-change-this-in-production';
    
    const token = jwt.sign({
      sub: user._id.toString(),
      email: user.email,
      role: user.roles[0] || 'household',
    }, JWT_SECRET);

    console.log('\n🔑 Generated JWT token for testing');
    console.log(`Token: ${token.substring(0, 50)}...`);

    // Test the API response
    const https = require('https');
    const http = require('http');

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/profile',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };

    console.log('\n🌐 Testing API response...');
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`\n📡 API Response Status: ${res.statusCode}`);
        
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            console.log('\n✅ API Response:');
            console.log(JSON.stringify(response, null, 2));
            
            if (response.user) {
              console.log('\n🔍 User data from API:');
              console.log(`Email: ${response.user.email}`);
              console.log(`isPhoneVerified: ${response.user.isPhoneVerified}`);
              console.log(`phoneNumber: ${response.user.phoneNumber}`);
              
              if (response.user.isPhoneVerified !== undefined) {
                console.log('\n✅ SUCCESS: isPhoneVerified field is included in API response!');
              } else {
                console.log('\n❌ ERROR: isPhoneVerified field is missing from API response!');
              }
            }
          } catch (e) {
            console.log('\n❌ Failed to parse API response:', e);
            console.log('Raw response:', data);
          }
        } else {
          console.log('\n❌ API request failed');
          console.log('Response:', data);
        }
      });
    });

    req.on('error', (e) => {
      console.log('\n❌ Request failed:', e.message);
    });

    req.end();

  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

// Run the test
testApiResponse().then(() => {
  console.log('\nTest completed');
  process.exit(0);
}).catch((error) => {
  console.error('Test failed:', error);
  process.exit(1);
});
