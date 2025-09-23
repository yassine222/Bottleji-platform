const http = require('http');

console.log('🔍 Testing Admin Dashboard Connection...\n');

// Test different scenarios
const tests = [
  {
    name: '1. Basic API endpoint',
    url: 'http://172.20.10.12:3000/api',
    method: 'GET'
  },
  {
    name: '2. Admin login endpoint',
    url: 'http://172.20.10.12:3000/api/auth/admin/login',
    method: 'POST',
    data: JSON.stringify({
      email: 'yassineromd789@gmail.com',
      password: 'admin123456'
    })
  },
  {
    name: '3. Localhost admin login endpoint',
    url: 'http://localhost:3000/api/auth/admin/login',
    method: 'POST',
    data: JSON.stringify({
      email: 'yassineromd789@gmail.com',
      password: 'admin123456'
    })
  }
];

async function runTest(test) {
  return new Promise((resolve) => {
    console.log(`\n🧪 ${test.name}`);
    console.log(`   URL: ${test.url}`);
    console.log(`   Method: ${test.method}`);
    
    const url = new URL(test.url);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: test.method,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 5000
    };

    if (test.data) {
      options.headers['Content-Length'] = Buffer.byteLength(test.data);
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`   📡 Status: ${res.statusCode}`);
        
        if (res.statusCode === 200 || res.statusCode === 201) {
          console.log(`   ✅ Success!`);
          try {
            const jsonData = JSON.parse(data);
            if (jsonData.token) {
              console.log(`   🔑 Token received: ${jsonData.token.substring(0, 50)}...`);
            }
          } catch (e) {
            console.log(`   📄 Response: ${data.substring(0, 100)}...`);
          }
        } else {
          console.log(`   ❌ Error: ${res.statusCode}`);
          try {
            const jsonData = JSON.parse(data);
            console.log(`   📄 Error: ${jsonData.message || jsonData.error || data}`);
          } catch (e) {
            console.log(`   📄 Response: ${data.substring(0, 100)}...`);
          }
        }
        resolve();
      });
    });

    req.on('error', (e) => {
      console.log(`   ❌ Connection Error: ${e.message}`);
      resolve();
    });

    req.on('timeout', () => {
      console.log(`   ⏰ Timeout`);
      req.destroy();
      resolve();
    });

    if (test.data) {
      req.write(test.data);
    }
    req.end();
  });
}

async function runAllTests() {
  console.log('🚀 Starting connection tests...\n');
  
  for (const test of tests) {
    await runTest(test);
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second between tests
  }
  
  console.log('\n📋 Test Summary:');
  console.log('   - If test 1 fails: Backend server is not running');
  console.log('   - If test 2 fails: Admin login endpoint has issues');
  console.log('   - If test 3 fails: Localhost connection issue');
  console.log('\n💡 Troubleshooting Tips:');
  console.log('   1. Make sure backend server is running: npm run start:dev:clean');
  console.log('   2. Check if admin dashboard is using correct API URL');
  console.log('   3. Clear browser cache and localStorage');
  console.log('   4. Check browser console for CORS errors');
  console.log('   5. Verify admin credentials are correct');
}

runAllTests().then(() => {
  console.log('\n✅ All tests completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
