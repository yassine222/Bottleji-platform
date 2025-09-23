const http = require('http');

console.log('🔍 Testing Admin Login Endpoint...');

// Test with the admin user email
const testData = {
  email: 'yassineromd789@gmail.com',
  password: 'admin123456' // New password for admin login
};

const postData = JSON.stringify(testData);

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/admin/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  },
  timeout: 5000
};

const req = http.request(options, (res) => {
  console.log(`📡 Status Code: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('📄 Response Body:');
    try {
      const jsonResponse = JSON.parse(data);
      console.log(JSON.stringify(jsonResponse, null, 2));
      
      if (res.statusCode === 200) {
        console.log('\n✅ Admin login successful!');
        console.log('💡 You can now use these credentials in the admin dashboard');
      } else if (res.statusCode === 401) {
        console.log('\n❌ Invalid credentials');
        console.log('💡 Please check the password');
      } else if (res.statusCode === 403) {
        console.log('\n❌ Access denied - User is not an admin');
      }
    } catch (e) {
      console.log('Raw response:', data);
    }
  });
});

req.on('error', (e) => {
  console.log('❌ Request Error:', e.message);
});

req.on('timeout', () => {
  console.log('⏰ Request Timeout');
  req.destroy();
});

req.write(postData);
req.end();

console.log('✅ Request sent');
console.log('📧 Email:', testData.email);
console.log('🔑 Password:', testData.password);
