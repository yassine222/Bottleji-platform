require('dotenv').config();
const { connect, model, Schema } = require('mongoose');
const bcrypt = require('bcrypt');

async function createUser() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      name: String,
      phone: String,
      address: String,
      profilePhoto: String,
      roles: { type: [String], default: ['household'] },
      collectorSubscriptionType: { type: String, default: 'basic' },
      isProfileComplete: { type: Boolean, default: false },
      isVerified: { type: Boolean, default: true },
      isPhoneVerified: { type: Boolean, default: false },
      createdAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now }
    }, { timestamps: true });

    const User = model('User', UserSchema);
    
    // Create admin user
    const email = 'yassineromd789@gmail.com';
    const password = '123456';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const newUser = new User({
      email: email,
      password: hashedPassword,
      name: 'Admin User',
      roles: ['admin'],
      isVerified: true,
      isProfileComplete: true
    });
    
    await newUser.save();
    
    console.log('✅ User created successfully');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Roles: ${newUser.roles}`);

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

createUser();
