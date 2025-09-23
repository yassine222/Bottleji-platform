const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function resetAdminPassword() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');

    const adminEmail = 'yassineromd789@gmail.com';
    const newPassword = 'admin123456'; // New password for admin login

    // Find the admin user
    const user = await usersCollection.findOne({ email: adminEmail });
    
    if (!user) {
      console.log('❌ Admin user not found');
      return;
    }

    console.log(`\n🔍 Found admin user: ${user.email}`);
    console.log(`Current roles: ${user.roles.join(', ')}`);

    // Hash the new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update the user's password
    const updateResult = await usersCollection.updateOne(
      { email: adminEmail },
      { $set: { password: hashedPassword } }
    );

    if (updateResult.modifiedCount > 0) {
      console.log('\n✅ Admin password reset successfully!');
      console.log(`📧 Email: ${adminEmail}`);
      console.log(`🔑 New Password: ${newPassword}`);
      console.log('\n💡 You can now use these credentials to login to the admin dashboard');
      console.log('   - Email: yassineromd789@gmail.com');
      console.log('   - Password: admin123456');
    } else {
      console.log('\n❌ Failed to reset password');
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

resetAdminPassword().then(() => {
  console.log('\n✅ Password reset completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Password reset failed:', error);
  process.exit(1);
});
