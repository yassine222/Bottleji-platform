const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('🔗 Connected to MongoDB'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Define User Schema
const userSchema = new mongoose.Schema({
  email: String,
  password: String,
  name: String,
  phone: String,
  address: String,
  profilePhoto: String,
  roles: [String],
  collectorSubscriptionType: String,
  isProfileComplete: Boolean,
  createdAt: Date,
  updatedAt: Date,
});

const User = mongoose.model('User', userSchema);

async function resetTestUserPassword() {
  try {
    console.log('🔧 Resetting password for testuser@gmail.com...\n');
    
    const user = await User.findOne({ email: 'testuser@gmail.com' });
    
    if (!user) {
      console.log('❌ User testuser@gmail.com not found');
      return;
    }
    
    console.log(`👤 Found user: ${user.email}`);
    console.log(`   Current roles: ${JSON.stringify(user.roles)}`);
    
    // Hash new password
    const newPassword = '123456';
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await User.updateOne(
      { email: 'testuser@gmail.com' },
      { password: hashedPassword }
    );
    
    console.log(`✅ Password reset for ${user.email} to: ${newPassword}`);
    
  } catch (error) {
    console.error('❌ Error resetting password:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

resetTestUserPassword(); 