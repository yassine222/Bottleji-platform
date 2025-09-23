const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function checkAdminUsers() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');

    // Find all users with admin role
    const adminUsers = await usersCollection.find({ 
      roles: { $in: ['admin', 'ADMIN'] } 
    }).toArray();

    console.log('\n🔍 Admin Users Found:');
    console.log(`Total admin users: ${adminUsers.length}`);

    if (adminUsers.length === 0) {
      console.log('\n❌ No admin users found!');
      console.log('\n💡 To create an admin user:');
      console.log('1. First create a regular user through the app');
      console.log('2. Then run: node add-admin-role.js <email>');
      console.log('3. Or manually update the user in MongoDB:');
      console.log('   db.users.updateOne({email: "your-email@example.com"}, {$set: {roles: ["admin"]}})');
    } else {
      adminUsers.forEach((user, index) => {
        console.log(`\n${index + 1}. Admin User:`);
        console.log(`   Email: ${user.email}`);
        console.log(`   Name: ${user.name || 'Not set'}`);
        console.log(`   Roles: ${user.roles.join(', ')}`);
        console.log(`   Verified: ${user.isVerified}`);
        console.log(`   Profile Complete: ${user.isProfileComplete}`);
        console.log(`   Created: ${user.createdAt}`);
      });
    }

    // Also check for users that might be admins but with different role format
    const allUsers = await usersCollection.find({}).toArray();
    const potentialAdmins = allUsers.filter(user => 
      user.roles && 
      (user.roles.includes('admin') || 
       user.roles.includes('ADMIN') ||
       user.roles.some(role => role.toLowerCase() === 'admin'))
    );

    if (potentialAdmins.length > adminUsers.length) {
      console.log('\n⚠️  Found users with admin-like roles:');
      potentialAdmins.forEach(user => {
        if (!adminUsers.find(admin => admin.email === user.email)) {
          console.log(`   Email: ${user.email}, Roles: ${user.roles.join(', ')}`);
        }
      });
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

checkAdminUsers().then(() => {
  console.log('\n✅ Check completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Check failed:', error);
  process.exit(1);
});
