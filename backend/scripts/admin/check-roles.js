require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function checkRoles() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    // Get all users and their roles
    const users = await User.find({});
    console.log(`📊 Found ${users.length} users:`);
    
    users.forEach((user, index) => {
      const userDoc = user.toObject();
      console.log(`${index + 1}. ${userDoc.email}:`);
      console.log(`   - Roles: ${JSON.stringify(userDoc.roles)}`);
      console.log(`   - Roles type: ${typeof userDoc.roles}`);
      console.log(`   - Roles is array: ${Array.isArray(userDoc.roles)}`);
      console.log(`   - Has old role field: ${!!userDoc.role}`);
      console.log(`   - Collector Application: ${JSON.stringify(userDoc.collectorApplication)}`);
      console.log(`   - Subscription Type: ${userDoc.collectorSubscriptionType}`);
      console.log('');
    });

    await connection.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkRoles(); 