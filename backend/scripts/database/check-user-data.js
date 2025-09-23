require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function checkUserData() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    // Get user by email
    const user = await User.findOne({ email: 'yassineromd789@gmail.com' });
    
    if (user) {
      const userDoc = user.toObject();
      console.log('📊 User data:');
      console.log(`   Email: ${userDoc.email}`);
      console.log(`   Name: ${userDoc.name}`);
      console.log(`   Roles: ${JSON.stringify(userDoc.roles)}`);
      console.log(`   Has collector role: ${userDoc.roles.includes('collector')}`);
      console.log(`   Phone: ${userDoc.phone}`);
      console.log(`   Address: ${userDoc.address}`);
      console.log(`   Profile Photo: ${userDoc.profilePhoto}`);
      console.log(`   Created At: ${userDoc.createdAt}`);
      console.log(`   Updated At: ${userDoc.updatedAt}`);
    } else {
      console.log('❌ User not found');
    }

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkUserData(); 