require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function verifyStructure() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    const user = await User.findOne({});
    console.log('Current user structure:', JSON.stringify({
      email: user.email,
      role: user.role,
      hasRoles: !!user.roles,
      collectorApplication: user.collectorApplication
    }, null, 2));

    await connection.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

verifyStructure(); 