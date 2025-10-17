const axios = require('axios');

// Test script for reset warnings endpoint
async function testResetWarnings() {
  try {
    console.log('🧪 Testing Reset Warnings Endpoint...');
    
    // First, get a test user (you'll need to replace with actual user ID)
    const testUserId = '6835e7cac36086e385a9d4df'; // Replace with actual user ID
    
    // Test the reset warnings endpoint
    const response = await axios.put(`http://localhost:3000/admin/users/${testUserId}/reset-warnings`, {}, {
      headers: {
        'Authorization': 'Bearer YOUR_ADMIN_TOKEN_HERE', // Replace with actual admin token
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Reset warnings response:', response.data);
    console.log('✅ User warnings reset successfully!');
    
  } catch (error) {
    console.error('❌ Error testing reset warnings:', error.response?.data || error.message);
  }
}

// Uncomment the line below to run the test
// testResetWarnings();

console.log('📝 Test script created. To run:');
console.log('1. Replace testUserId with actual user ID');
console.log('2. Replace YOUR_ADMIN_TOKEN_HERE with actual admin JWT token');
console.log('3. Uncomment the testResetWarnings() call');
console.log('4. Run: node test-reset-warnings.js');
