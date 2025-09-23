require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function fixLegacyCollectors() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const CollectorApplicationSchema = new Schema({}, { strict: false });
    
    const User = model('User', UserSchema);
    const CollectorApplication = model('CollectorApplication', CollectorApplicationSchema);
    
    // Find users who have collector role but no application status
    const legacyCollectors = await User.find({
      roles: { $in: ['collector'] },
      $or: [
        { collectorApplicationStatus: { $exists: false } },
        { collectorApplicationStatus: null }
      ]
    });
    
    console.log(`📊 Found ${legacyCollectors.length} legacy collectors to fix`);
    
    for (const user of legacyCollectors) {
      const userDoc = user.toObject();
      console.log(`\n🔄 Processing legacy collector: ${userDoc.email}`);
      console.log(`   Current roles: ${userDoc.roles}`);
      console.log(`   Application status: ${userDoc.collectorApplicationStatus || 'null'}`);
      
      // Create a collector application record for this legacy user
      const applicationData = {
        userId: userDoc._id,
        status: 'approved', // Legacy collectors are considered approved
        idCardPhoto: 'legacy-user-no-photo',
        selfieWithIdPhoto: 'legacy-user-no-photo',
        appliedAt: userDoc.createdAt || new Date(),
        reviewedAt: userDoc.createdAt || new Date(),
        reviewNotes: 'Legacy collector - automatically approved during migration',
        createdAt: userDoc.createdAt || new Date(),
        updatedAt: new Date()
      };
      
      // Check if application already exists
      const existingApplication = await CollectorApplication.findOne({ userId: userDoc._id });
      
      if (existingApplication) {
        console.log(`   ✅ Application already exists for ${userDoc.email}`);
        continue;
      }
      
      // Create the application
      const newApplication = new CollectorApplication(applicationData);
      const savedApplication = await newApplication.save();
      
      console.log(`   ✅ Created application: ${savedApplication._id}`);
      
      // Update user with application status
      await User.updateOne(
        { _id: userDoc._id },
        {
          $set: {
            collectorApplicationStatus: 'approved',
            collectorApplicationId: savedApplication._id.toString(),
            collectorApplicationAppliedAt: userDoc.createdAt || new Date(),
            collectorApplicationReviewedAt: userDoc.createdAt || new Date(),
            collectorApplicationRejectionReason: undefined
          }
        }
      );
      
      console.log(`   ✅ Updated user application status to approved`);
    }
    
    console.log('\n✅ Legacy collectors fixed successfully!');
    
    // Verify the results
    console.log('\n🔍 Verifying fixes:');
    const updatedUsers = await User.find({ roles: { $in: ['collector'] } });
    updatedUsers.forEach((user, index) => {
      const userDoc = user.toObject();
      console.log(`\n${index + 1}. ${userDoc.email}:`);
      console.log(`   Roles: ${userDoc.roles.join(', ')}`);
      console.log(`   Application Status: ${userDoc.collectorApplicationStatus || 'null'}`);
      console.log(`   Application ID: ${userDoc.collectorApplicationId || 'null'}`);
    });

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

fixLegacyCollectors();
