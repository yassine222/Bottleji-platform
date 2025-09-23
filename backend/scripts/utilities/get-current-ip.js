const https = require('https');

async function getCurrentIP() {
  return new Promise((resolve, reject) => {
    https.get('https://api.ipify.org?format=json', (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          resolve(result.ip);
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', (error) => {
      reject(error);
    });
  });
}

async function main() {
  try {
    console.log('🌍 Getting your current IP address...');
    const ip = await getCurrentIP();
    console.log(`✅ Your current IP address is: ${ip}`);
    console.log('');
    console.log('📋 To add this IP to MongoDB Atlas:');
    console.log('   1. Go to https://cloud.mongodb.com');
    console.log('   2. Select your cluster');
    console.log('   3. Click "Network Access" in the left sidebar');
    console.log('   4. Click "Add IP Address"');
    console.log('   5. Add this IP:', ip);
    console.log('   6. Or temporarily allow access from anywhere by adding: 0.0.0.0/0');
    console.log('');
    console.log('⚠️  Note: If you\'re using a dynamic IP, you might need to update this regularly');
  } catch (error) {
    console.error('❌ Failed to get IP address:', error.message);
    console.log('');
    console.log('💡 Alternative: You can manually check your IP at https://whatismyipaddress.com/');
  }
}

main();
