#!/usr/bin/env node

const { migrateUsers } = require('./dist/migrations/user-migration');

console.log('🚀 Starting user migration...');

migrateUsers()
  .then(() => {
    console.log('🎉 Migration completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  }); 