require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function addCollectorRole() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const User = model('User', UserSchema);
    
    // Get all users
    const users = await User.find({});
    console.log(`📊 Found ${users.length} users to update`);
    
    for (const user of users) {
      const userDoc = user.toObject();
      console.log(`\n🔄 Processing user: ${userDoc.email}`);
      console.log(`   Current roles: ${JSON.stringify(userDoc.roles)}`);
      
      // Add collector role if not already present
      if (userDoc.roles && !userDoc.roles.includes('collector')) {
        const updatedRoles = [...userDoc.roles, 'collector'];
        console.log(`   Adding collector role: ${updatedRoles}`);
        
        await User.updateOne(
          { _id: userDoc._id },
          { $set: { roles: updatedRoles } }
        );
        
        console.log(`   ✅ Updated user ${userDoc.email}`);
      } else if (userDoc.roles && userDoc.roles.includes('collector')) {
        console.log(`   ✅ User already has collector role`);
      } else {
        // If no roles array, create one with both household and collector
        console.log(`   ⚠️ No roles array found, creating with both roles`);
        await User.updateOne(
          { _id: userDoc._id },
          { $set: { roles: ['household', 'collector'] } }
        );
        console.log(`   ✅ Updated user ${userDoc.email}`);
      }
    }
    
    console.log('\n✅ All users updated successfully!');
    
    // Verify the results
    console.log('\n🔍 Verifying updates:');
    const updatedUsers = await User.find({});
    updatedUsers.forEach((user, index) => {
      const userDoc = user.toObject();
      console.log(`${index + 1}. ${userDoc.email}:`);
      console.log(`   - Roles: ${JSON.stringify(userDoc.roles)}`);
      console.log(`   - Has collector role: ${userDoc.roles.includes('collector')}`);
    });
    
    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during update:', error);
  }
}

addCollectorRole(); 