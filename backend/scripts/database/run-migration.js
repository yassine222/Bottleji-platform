const { exec } = require('child_process');
const path = require('path');

console.log('🚀 Starting user migration...');

// Run the migration using ts-node
const command = 'npx ts-node src/migrations/user-migration.ts';

exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
  if (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
  
  if (stderr) {
    console.error('⚠️ Migration warnings:', stderr);
  }
  
  console.log('📤 Migration output:', stdout);
  console.log('🎉 Migration completed!');
}); 