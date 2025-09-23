import { connect, model, Schema } from 'mongoose';
import * as dotenv from 'dotenv';

dotenv.config();

interface UserDocument {
  _id: string;
  email: string;
  role?: string;
  roles?: string[];
  collectorApplication?: any;
  collectorSubscriptionType?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

const UserSchema = new Schema({}, { strict: false });

async function convertToRoles() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI!);
    console.log('✅ Connected to MongoDB');

    const User = model('User', UserSchema);
    
    // Get all users
    const users = await User.find({});
    console.log(`📊 Found ${users.length} users to convert`);
    
    for (const user of users) {
      const userDoc = user.toObject() as any;
      console.log(`\n🔄 Processing user: ${userDoc.email}`);
      
      console.log(`   Current role: "${userDoc.role}"`);
      console.log(`   Has roles array: ${!!userDoc.roles}`);
      
      // Convert single role to roles array
      if (userDoc.role && !userDoc.roles) {
        const roles = [userDoc.role];
        console.log(`   Converting to roles: ${roles}`);
        
        await User.updateOne(
          { _id: userDoc._id },
          { 
            $set: { roles: roles },
            $unset: { role: 1 } // Remove the old role field
          }
        );
        
        console.log(`   ✅ Updated user ${userDoc.email}`);
      } else if (userDoc.roles) {
        console.log(`   ✅ User already has roles array: ${userDoc.roles}`);
      } else {
        // Default to household if no role found
        console.log(`   ⚠️ No role found, setting default: ["household"]`);
        await User.updateOne(
          { _id: userDoc._id },
          { $set: { roles: ['household'] } }
        );
      }
      
      // Ensure collectorApplication exists
      if (!userDoc.collectorApplication) {
        console.log(`   📝 Adding collectorApplication field`);
        await User.updateOne(
          { _id: userDoc._id },
          { 
            $set: { 
              collectorApplication: {
                status: 'pending',
                appliedAt: new Date()
              }
            } 
          }
        );
      }
      
      // Ensure collectorSubscriptionType exists
      if (!userDoc.collectorSubscriptionType) {
        console.log(`   📝 Adding collectorSubscriptionType field`);
        await User.updateOne(
          { _id: userDoc._id },
          { $set: { collectorSubscriptionType: 'basic' } }
        );
      }
    }
    
    console.log('\n✅ Migration completed successfully!');
    
    // Verify the results
    console.log('\n🔍 Verifying migration results:');
    const updatedUsers = await User.find({});
    updatedUsers.forEach((user, index) => {
      const userDoc = user.toObject() as any;
      console.log(`${index + 1}. ${userDoc.email}:`);
      console.log(`   - Roles: ${userDoc.roles}`);
      console.log(`   - Has old role field: ${!!userDoc.role}`);
      console.log(`   - Collector Application: ${!!userDoc.collectorApplication}`);
      console.log(`   - Subscription Type: ${userDoc.collectorSubscriptionType}`);
    });
    
    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during migration:', error);
  }
}

convertToRoles(); 