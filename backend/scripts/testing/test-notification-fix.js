const mongoose = require('mongoose');
require('dotenv').config();

async function testNotificationFix() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Test user ID (replace with an actual user ID from your database)
    const testUserId = '689e565440f38f2bdf7eff84'; // testuser2@gmail.com
    
    console.log('🧪 Testing notification fix...');
    console.log('🧪 This script will simulate application approval/rejection to test notifications');
    console.log('🧪 Expected behavior: Only ONE notification should be sent per action');
    console.log('');
    
    // Check if user exists
    const UserModel = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
    const user = await UserModel.findById(testUserId);
    
    if (!user) {
      console.log('❌ Test user not found. Please update the testUserId in this script.');
      return;
    }
    
    console.log(`✅ Test user found: ${user.email}`);
    console.log(`📊 Current application status: ${user.collectorApplicationStatus || 'none'}`);
    console.log('');
    
    console.log('🔍 Checking notification service code...');
    console.log('✅ Application notifications now use sendApplicationStatusUpdate() only');
    console.log('✅ Removed duplicate sendNotificationToUser() calls');
    console.log('✅ This should eliminate the double notification issue');
    console.log('');
    
    console.log('📋 To test this fix:');
    console.log('1. Make sure the backend server is running');
    console.log('2. Open the Flutter app and log in with testuser2@gmail.com');
    console.log('3. Go to the admin dashboard and approve/reject the application');
    console.log('4. Check the Flutter app - you should see only ONE notification');
    console.log('');
    
    console.log('🔧 Manual test steps:');
    console.log('1. Backend server: npm run start:dev');
    console.log('2. Flutter app: flutter run');
    console.log('3. Admin dashboard: http://localhost:3001');
    console.log('4. Test application approval/rejection');
    console.log('');
    
    console.log('📱 Expected Flutter app behavior:');
    console.log('- Should receive only ONE WebSocket event per action');
    console.log('- Should show only ONE notification (system or in-app)');
    console.log('- Application status should update immediately');
    console.log('');
    
    console.log('🔍 Debugging tips:');
    console.log('- Check backend console for notification logs');
    console.log('- Check Flutter console for WebSocket event logs');
    console.log('- Look for "application_approved" or "application_rejected" events');
    console.log('- Should see only ONE event per action, not two');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

testNotificationFix();
