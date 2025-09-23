const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

// Environment variables content
const envContent = `# Environment Configuration
NODE_ENV=development
PORT=3000

# MongoDB Atlas Connection String
MONGODB_URI=mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji

# JWT Configuration
JWT_SECRET=bottleji-super-secret-jwt-key-2024-secure-auth-token
JWT_EXPIRES_IN=7d

# Email Configuration
EMAIL_USER=bottleji.tn@gmail.com
EMAIL_PASS=ojwi qbpy kbcs zplx
`;

// Create .env file
const envPath = path.join(__dirname, '.env');
fs.writeFileSync(envPath, envContent);
console.log('✅ .env file created successfully');

// Test MongoDB connection
async function testConnection() {
  try {
    console.log('🔍 Testing MongoDB connection...');
    console.log('📍 Connection string:', process.env.MONGODB_URI || 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji');
    
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji', {
      serverSelectionTimeoutMS: 10000, // 10 seconds timeout
      socketTimeoutMS: 45000, // 45 seconds timeout
    });
    
    console.log('✅ MongoDB connection successful!');
    
    // Test a simple query
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    console.log('📊 Available collections:', collections.map(c => c.name));
    
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
    
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    
    if (error.message.includes('ECONNREFUSED')) {
      console.log('💡 This might be an IP whitelist issue. Please check:');
      console.log('   1. Go to MongoDB Atlas dashboard');
      console.log('   2. Navigate to Network Access');
      console.log('   3. Add your current IP address (Tunisia) to the IP Access List');
      console.log('   4. Or temporarily allow access from anywhere (0.0.0.0/0) for testing');
    }
    
    if (error.message.includes('timeout')) {
      console.log('⏰ Connection timeout. This could be due to:');
      console.log('   - Network connectivity issues');
      console.log('   - IP whitelist restrictions');
      console.log('   - MongoDB Atlas service issues');
    }
  }
}

// Run the test
testConnection();
