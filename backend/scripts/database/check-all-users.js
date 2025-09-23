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

async function checkAllUsers() {
  try {
    console.log('📊 Checking all users...\n');
    
    const users = await User.find({});
    
    if (users.length === 0) {
      console.log('❌ No users found in database');
      return;
    }
    
    users.forEach((user, index) => {
      console.log(`👤 User ${index + 1}:`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Name: ${user.name}`);
      console.log(`   Roles: ${JSON.stringify(user.roles)}`);
      console.log(`   Is Profile Complete: ${user.isProfileComplete}`);
      console.log(`   Created At: ${user.createdAt}`);
      console.log(`   Updated At: ${user.updatedAt}`);
      console.log('---');
    });
    
    console.log(`✅ Found ${users.length} users total`);
    
  } catch (error) {
    console.error('❌ Error checking users:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

checkAllUsers(); 