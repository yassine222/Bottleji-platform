#!/usr/bin/env node

require('dotenv').config();
const { exec } = require('child_process');

console.log('🚀 Starting roles cleanup...');
console.log('MongoDB URI:', process.env.MONGODB_URI ? 'Set' : 'Not set');

// Run the cleanup migration using ts-node with environment variables
const command = 'npx ts-node src/migrations/cleanup-roles-migration.ts';

exec(command, { 
  cwd: __dirname,
  env: process.env 
}, (error, stdout, stderr) => {
  if (error) {
    console.error('❌ Cleanup failed:', error);
    process.exit(1);
  }
  
  if (stderr) {
    console.error('⚠️ Cleanup warnings:', stderr);
  }
  
  console.log('📤 Cleanup output:', stdout);
  console.log('🎉 Cleanup completed!');
}); 