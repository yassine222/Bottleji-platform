const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Get current local IP address
function getCurrentLocalIP() {
  try {
    // For macOS/Linux
    const ip = execSync("ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1", { encoding: 'utf8' }).trim();
    return ip;
  } catch (error) {
    console.error('❌ Could not get local IP address:', error.message);
    return null;
  }
}

// Files that need IP updates
const filesToUpdate = [
  '../botleji/lib/core/config/api_config.dart',
  '../botleji/lib/features/auth/controllers/collector_subscription_controller.dart',
  '../botleji/lib/features/auth/data/repositories/auth_repository_impl.dart',
  '../botleji/lib/features/auth/data/datasources/auth_api_client.dart',
  '../botleji/lib/core/services/notification_service.dart',
  '../botleji/lib/core/services/phone_verification_service.dart',
  '../botleji/lib/core/config/environment.dart'
];

// Update IP in a file
function updateFileIP(filePath, oldIP, newIP) {
  try {
    const fullPath = path.join(__dirname, filePath);
    let content = fs.readFileSync(fullPath, 'utf8');
    
    if (content.includes(oldIP)) {
      const newContent = content.replace(new RegExp(oldIP, 'g'), newIP);
      fs.writeFileSync(fullPath, newContent, 'utf8');
      console.log(`✅ Updated: ${filePath}`);
      return true;
    } else {
      console.log(`⏭️  No changes needed: ${filePath}`);
      return false;
    }
  } catch (error) {
    console.error(`❌ Error updating ${filePath}:`, error.message);
    return false;
  }
}

// Find current IP in files
function findCurrentIPInFiles() {
  const possibleIPs = new Set();
  
  filesToUpdate.forEach(filePath => {
    try {
      const fullPath = path.join(__dirname, filePath);
      const content = fs.readFileSync(fullPath, 'utf8');
      
      // Find IP addresses in the format 192.168.x.x or 172.x.x.x
      const ipMatches = content.match(/\b(?:192\.168\.|172\.|10\.)\d+\.\d+\.\d+\b/g);
      if (ipMatches) {
        ipMatches.forEach(ip => possibleIPs.add(ip));
      }
    } catch (error) {
      console.error(`❌ Error reading ${filePath}:`, error.message);
    }
  });
  
  return Array.from(possibleIPs);
}

// Main function
async function main() {
  console.log('🌍 Auto IP Update Tool');
  console.log('=====================\n');
  
  // Get current local IP
  const currentLocalIP = getCurrentLocalIP();
  if (!currentLocalIP) {
    console.log('❌ Could not determine your local IP address');
    console.log('💡 Please run this script when connected to your local network');
    return;
  }
  
  console.log(`📍 Your current local IP: ${currentLocalIP}`);
  
  // Find IPs currently in files
  const ipsInFiles = findCurrentIPInFiles();
  console.log(`🔍 IPs found in Flutter files: ${ipsInFiles.join(', ') || 'None'}`);
  
  if (ipsInFiles.length === 0) {
    console.log('✅ No IP addresses found in files - everything is up to date!');
    return;
  }
  
  // Check if update is needed
  const needsUpdate = ipsInFiles.some(ip => ip !== currentLocalIP);
  
  if (!needsUpdate) {
    console.log('✅ All files already have the correct IP address!');
    return;
  }
  
  console.log(`🔄 Updating IP addresses to: ${currentLocalIP}\n`);
  
  // Update all files
  let updatedCount = 0;
  ipsInFiles.forEach(oldIP => {
    filesToUpdate.forEach(file => {
      if (updateFileIP(file, oldIP, currentLocalIP)) {
        updatedCount++;
      }
    });
  });
  
  console.log(`\n📊 Summary: Updated ${updatedCount} files`);
  console.log(`🎯 All Flutter app files now point to: ${currentLocalIP}`);
  console.log('\n💡 Next steps:');
  console.log('   1. Hot reload your Flutter app');
  console.log('   2. Test the connection');
  console.log('   3. Run this script again when you travel to update IPs automatically');
}

// Run the script
main().catch(console.error);
