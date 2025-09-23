const { MongoClient } = require('mongodb');

// MongoDB connection string
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function migrateAdminRoles() {
  const client = new MongoClient(MONGODB_URI);
  
  try {
    await client.connect();
    console.log('Connected to MongoDB');
    
    const db = client.db();
    const usersCollection = db.collection('users');
    
    // Find all users with admin role
    const adminUsers = await usersCollection.find({ roles: 'admin' }).toArray();
    console.log(`Found ${adminUsers.length} admin users`);
    
    // Update each admin user to super_admin role
    for (const user of adminUsers) {
      console.log(`Migrating user: ${user.email} (${user.name || 'No name'})`);
      
      const result = await usersCollection.updateOne(
        { _id: user._id },
        { 
          $set: { 
            roles: ['super_admin'],
            updatedAt: new Date()
          }
        }
      );
      
      if (result.modifiedCount > 0) {
        console.log(`✅ Successfully migrated ${user.email} to super_admin`);
      } else {
        console.log(`❌ Failed to migrate ${user.email}`);
      }
    }
    
    console.log('\n🎉 Migration completed!');
    console.log(`\nSummary:`);
    console.log(`- Total admin users found: ${adminUsers.length}`);
    console.log(`- All existing admin users have been upgraded to SUPER_ADMIN role`);
    console.log(`\nNew Role Hierarchy:`);
    console.log(`1. SUPER_ADMIN - Full system control (your current admins)`);
    console.log(`2. ADMIN - User and content management`);
    console.log(`3. MODERATOR - Content moderation only`);
    console.log(`4. SUPPORT_AGENT - Support ticket handling`);
    console.log(`5. COLLECTOR - Drop collection`);
    console.log(`6. HOUSEHOLD - Regular users`);
    
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await client.close();
    console.log('Disconnected from MongoDB');
  }
}

// Run the migration
migrateAdminRoles();
