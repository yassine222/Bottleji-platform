const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/botleji');

// User Schema (simplified for this script)
const userSchema = new mongoose.Schema({
  email: String,
  password: String,
  name: String,
  roles: [String],
  // ... other fields
});

const User = mongoose.model('User', userSchema);

async function addAdminRole() {
  try {
    // Find a user by email (replace with actual email)
    const userEmail = 'yassineromd789@gmail.com'; // Replace with your email
    
    const user = await User.findOne({ email: userEmail });
    
    if (!user) {
      console.log('User not found. Please check the email address.');
      return;
    }

    // Add admin role if not already present
    if (!user.roles.includes('admin')) {
      user.roles.push('admin');
      await user.save();
      console.log(`✅ Admin role added to user: ${user.email}`);
    } else {
      console.log(`ℹ️ User ${user.email} already has admin role`);
    }

    console.log('User roles:', user.roles);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

addAdminRole(); 