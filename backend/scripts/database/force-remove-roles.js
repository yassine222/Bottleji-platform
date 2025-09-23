require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function forceRemoveRoles() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    // Force remove roles array from all users
    const result = await User.updateMany(
      { roles: { $exists: true } },
      { $unset: { roles: 1 } }
    );
    
    console.log(`🗑️ Removed roles array from ${result.modifiedCount} users`);
    
    // Verify the structure
    const user = await User.findOne({});
    console.log('Updated user structure:', JSON.stringify({
      email: user.email,
      role: user.role,
      hasRoles: !!user.roles,
      rolesValue: user.roles
    }, null, 2));

    await connection.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

forceRemoveRoles(); 