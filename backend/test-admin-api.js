const axios = require('axios');

async function testAdminAPI() {
  try {
    const baseURL = 'http://localhost:3000/api';
    
    console.log('🔍 Testing Admin API endpoints...');
    
    // Test getting all collector applications
    console.log('\n1. Testing GET /admin/collector-applications...');
    try {
      const response = await axios.get(`${baseURL}/admin/collector-applications`, {
        params: { page: 1, limit: 20 }
      });
      console.log('✅ Response status:', response.status);
      console.log('✅ Applications found:', response.data.applications?.length || 0);
      console.log('✅ Total applications:', response.data.total || 0);
      
      if (response.data.applications && response.data.applications.length > 0) {
        console.log('✅ First application:');
        console.log('   ID:', response.data.applications[0]._id);
        console.log('   User:', response.data.applications[0].userId?.email);
        console.log('   Status:', response.data.applications[0].status);
        console.log('   Created At:', response.data.applications[0].createdAt);
      }
    } catch (error) {
      console.log('❌ Error getting applications:', error.response?.status, error.response?.data?.message || error.message);
    }
    
    // Test getting application stats
    console.log('\n2. Testing GET /admin/collector-applications/stats...');
    try {
      const response = await axios.get(`${baseURL}/admin/collector-applications/stats`);
      console.log('✅ Response status:', response.status);
      console.log('✅ Stats:', response.data);
    } catch (error) {
      console.log('❌ Error getting stats:', error.response?.status, error.response?.data?.message || error.message);
    }
    
    // Test getting pending applications
    console.log('\n3. Testing GET /admin/collector-applications with status=pending...');
    try {
      const response = await axios.get(`${baseURL}/admin/collector-applications`, {
        params: { page: 1, limit: 20, status: 'pending' }
      });
      console.log('✅ Response status:', response.status);
      console.log('✅ Pending applications found:', response.data.applications?.length || 0);
      
      if (response.data.applications && response.data.applications.length > 0) {
        console.log('✅ Pending applications:');
        response.data.applications.forEach((app, index) => {
          console.log(`   ${index + 1}. ${app.userId?.email} - ${app.createdAt}`);
        });
      }
    } catch (error) {
      console.log('❌ Error getting pending applications:', error.response?.status, error.response?.data?.message || error.message);
    }
    
  } catch (error) {
    console.error('❌ General error:', error.message);
  }
}

testAdminAPI();
