const axios = require('axios');

async function testAdminDashboardLogin() {
  try {
    console.log('🧪 Testing Admin Dashboard Login...');
    console.log('📍 API URL: http://192.168.1.40:3000/api/auth/admin/login');
    
    const response = await axios.post('http://192.168.1.40:3000/api/auth/admin/login', {
      email: 'yassineromd789@gmail.com',
      password: 'admin123456'
    }, {
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Login successful!');
    console.log('📊 Response status:', response.status);
    console.log('🔑 Token received:', response.data.token ? 'Yes' : 'No');
    console.log('👤 User data received:', response.data.user ? 'Yes' : 'No');
    
    if (response.data.user) {
      console.log('👤 User details:');
      console.log('   - Email:', response.data.user.email);
      console.log('   - Name:', response.data.user.name);
      console.log('   - Roles:', response.data.user.roles);
      console.log('   - Is Admin:', response.data.user.roles.includes('admin'));
    }
    
    console.log('\n🎯 Admin Dashboard should now work!');
    console.log('📍 Try logging in at: http://localhost:3001/login');
    
  } catch (error) {
    console.error('❌ Login test failed:');
    
    if (error.code === 'ECONNABORTED') {
      console.error('   - Timeout error (server not responding)');
    } else if (error.code === 'ERR_NETWORK') {
      console.error('   - Network error (cannot connect to server)');
    } else if (error.response) {
      console.error('   - HTTP Error:', error.response.status);
      console.error('   - Response:', error.response.data);
    } else {
      console.error('   - Error:', error.message);
    }
    
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Make sure backend server is running: npm run start:dev');
    console.log('   2. Check if port 3000 is available');
    console.log('   3. Verify IP address is correct');
  }
}

testAdminDashboardLogin();
