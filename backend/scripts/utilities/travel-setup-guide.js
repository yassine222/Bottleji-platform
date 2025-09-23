const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🌍 Travel Setup Guide for Bottleji Development');
console.log('==============================================\n');

// Get current location info
function getLocationInfo() {
  try {
    // Get public IP
    const publicIP = execSync('curl -s https://api.ipify.org', { encoding: 'utf8' }).trim();
    
    // Get local IP
    const localIP = execSync("ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1", { encoding: 'utf8' }).trim();
    
    return { publicIP, localIP };
  } catch (error) {
    return { publicIP: 'Unknown', localIP: 'Unknown' };
  }
}

const { publicIP, localIP } = getLocationInfo();

console.log('📍 Current Network Information:');
console.log(`   Public IP: ${publicIP}`);
console.log(`   Local IP: ${localIP}`);
console.log('');

console.log('📋 Complete Setup Checklist:');
console.log('============================\n');

console.log('1️⃣  MongoDB Atlas IP Whitelist:');
console.log('   • Go to https://cloud.mongodb.com');
console.log('   • Select your cluster');
console.log('   • Click "Network Access"');
console.log(`   • Add your public IP: ${publicIP}`);
console.log('   • Or temporarily allow: 0.0.0.0/0 (for testing)');
console.log('');

console.log('2️⃣  Update Flutter App IP Addresses:');
console.log('   • Run: npm run update-ip');
console.log('   • This will automatically update all hardcoded IPs');
console.log('');

console.log('3️⃣  Start Backend Server:');
console.log('   • Run: npm run start:dev:clean');
console.log('   • This kills any existing process and starts fresh');
console.log('');

console.log('4️⃣  Test Connections:');
console.log('   • Backend: http://localhost:3000/api');
console.log(`   • Flutter API: http://${localIP}:3000/api`);
console.log('   • MongoDB: Check backend logs for connection success');
console.log('');

console.log('5️⃣  Flutter App:');
console.log('   • Hot reload your Flutter app');
console.log('   • Test login and basic functionality');
console.log('');

console.log('🔧 Quick Commands:');
console.log('==================');
console.log('npm run update-ip          # Update IP addresses automatically');
console.log('npm run start:dev:clean    # Start backend server');
console.log('node get-current-ip.js     # Get your current public IP');
console.log('node setup-env.js          # Recreate .env file');
console.log('');

console.log('⚠️  Important Notes:');
console.log('===================');
console.log('• Run "npm run update-ip" every time you change networks');
console.log('• Keep your MongoDB Atlas IP whitelist updated');
console.log('• The .env file contains sensitive data - keep it secure');
console.log('• If you get connection timeouts, check your IP addresses');
console.log('');

console.log('🚀 Ready to develop! 🚀');
