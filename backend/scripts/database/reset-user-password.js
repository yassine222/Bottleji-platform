require('dotenv').config();
const { connect, model, Schema } = require('mongoose');
const bcrypt = require('bcrypt');

async function resetUserPassword() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    // Get user by email
    const user = await User.findOne({ email: 'yassineromd789@gmail.com' });
    
    if (user) {
      // Hash new password
      const newPassword = '123456';
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      // Update user password
      await User.updateOne(
        { email: 'yassineromd789@gmail.com' },
        { password: hashedPassword }
      );
      
      console.log('✅ Password reset successfully');
      console.log(`   New password: ${newPassword}`);
      console.log(`   New hash: ${hashedPassword}`);
    } else {
      console.log('❌ User not found');
    }

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

resetUserPassword(); 