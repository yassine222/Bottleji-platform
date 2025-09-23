require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function fixUserRoles() {
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
      console.log('📊 Current user roles:', userDoc.roles);
      
      // Remove duplicates and ensure we have both household and collector
      const uniqueRoles = [...new Set(['household', 'collector'])];
      
      // Update user with clean roles
      await User.updateOne(
        { email: 'yassineromd789@gmail.com' },
        { roles: uniqueRoles }
      );
      
      console.log('✅ Updated user roles to:', uniqueRoles);
    } else {
      console.log('❌ User not found');
    }

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

fixUserRoles(); 