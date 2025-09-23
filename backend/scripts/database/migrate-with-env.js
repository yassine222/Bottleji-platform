#!/usr/bin/env node

require('dotenv').config();
const { exec } = require('child_process');

console.log('🚀 Starting user migration with environment variables...');
console.log('MongoDB URI:', process.env.MONGODB_URI ? 'Set' : 'Not set');

// Run the migration using ts-node with environment variables
const command = 'npx ts-node src/migrations/user-migration.ts';

exec(command, { 
  cwd: __dirname,
  env: process.env 
}, (error, stdout, stderr) => {
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