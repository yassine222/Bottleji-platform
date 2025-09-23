const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
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

async function checkUserPassword() {
  try {
    const userEmail = 'yassineromd789@gmail.com';
    
    const user = await User.findOne({ email: userEmail });
    
    if (!user) {
      console.log('User not found.');
      return;
    }

    console.log('User found:', {
      email: user.email,
      name: user.name,
      roles: user.roles,
      hasPassword: !!user.password
    });

    // Test with a common password
    const testPasswords = ['123456', 'password', 'admin', 'test'];
    
    for (const testPassword of testPasswords) {
      const isValid = await bcrypt.compare(testPassword, user.password);
      if (isValid) {
        console.log(`✅ Password found: ${testPassword}`);
        return;
      }
    }
    
    console.log('❌ None of the test passwords worked.');
    console.log('You need to use the actual password you set when creating the account.');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkUserPassword(); 