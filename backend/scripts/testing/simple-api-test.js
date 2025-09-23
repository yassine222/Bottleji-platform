const http = require('http');

console.log('🔍 Testing API response...');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/profile',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer test-token',
    'Content-Type': 'application/json',
  },
  timeout: 5000, // 5 second timeout
};

const req = http.request(options, (res) => {
  console.log(`📡 Status Code: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('📄 Response Body:');
    console.log(data);
  });
});

req.on('error', (e) => {
  console.log('❌ Request Error:', e.message);
});

req.on('timeout', () => {
  console.log('⏰ Request Timeout');
  req.destroy();
});

req.end();

console.log('✅ Request sent');
