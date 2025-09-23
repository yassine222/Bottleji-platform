const fs = require('fs');
const path = require('path');

const oldIP = '172.20.10.12';
const newIP = '192.168.1.40';

const filesToUpdate = [
  '../botleji/lib/features/auth/controllers/collector_subscription_controller.dart',
  '../botleji/lib/features/auth/data/repositories/auth_repository_impl.dart',
  '../botleji/lib/features/auth/data/datasources/auth_api_client.dart',
  '../botleji/lib/core/services/notification_service.dart',
  '../botleji/lib/core/services/phone_verification_service.dart',
  '../botleji/lib/core/config/environment.dart'
];

function updateFile(filePath) {
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

console.log(`🔄 Updating IP addresses from ${oldIP} to ${newIP}...\n`);

let updatedCount = 0;
filesToUpdate.forEach(file => {
  if (updateFile(file)) {
    updatedCount++;
  }
});

console.log(`\n📊 Summary: Updated ${updatedCount} out of ${filesToUpdate.length} files`);
console.log(`🎯 All Flutter app files now point to your new local IP: ${newIP}`);
