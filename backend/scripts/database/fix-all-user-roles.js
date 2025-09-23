const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('🔗 Connected to MongoDB'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Define User Schema
const userSchema = new mongoose.Schema({
  email: String,
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

async function fixAllUserRoles() {
  try {
    console.log('🔧 Fixing duplicate roles for all users...\n');
    
    const users = await User.find({});
    
    if (users.length === 0) {
      console.log('❌ No users found in database');
      return;
    }
    
    for (const user of users) {
      console.log(`👤 Processing user: ${user.email}`);
      console.log(`   Current roles: ${JSON.stringify(user.roles)}`);
      
      // Remove duplicates while preserving order
      const uniqueRoles = [];
      for (const role of user.roles) {
        if (!uniqueRoles.includes(role)) {
          uniqueRoles.push(role);
        }
      }
      
      console.log(`   Fixed roles: ${JSON.stringify(uniqueRoles)}`);
      
      // Update user with unique roles
      await User.updateOne(
        { _id: user._id },
        { roles: uniqueRoles }
      );
      
      console.log(`   ✅ Updated user ${user.email}`);
      console.log('---');
    }
    
    console.log(`✅ Fixed roles for ${users.length} users`);
    
    // Show final state
    console.log('\n📊 Final user roles:');
    const updatedUsers = await User.find({});
    updatedUsers.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.email}: ${JSON.stringify(user.roles)}`);
    });
    
  } catch (error) {
    console.error('❌ Error fixing user roles:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

fixAllUserRoles(); 