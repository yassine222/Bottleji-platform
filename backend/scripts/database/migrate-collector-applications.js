require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function migrateCollectorApplications() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Define schemas
    const UserSchema = new Schema({}, { strict: false });
    const CollectorApplicationSchema = new Schema({
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
      status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
      idCardPhoto: String,
      selfieWithIdPhoto: String,
      rejectionReason: String,
      appliedAt: { type: Date, default: Date.now },
      reviewedAt: Date,
      reviewedBy: { type: Schema.Types.ObjectId, ref: 'User' },
      reviewNotes: String,
      createdAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now },
    });

    const User = model('User', UserSchema);
    const CollectorApplication = model('CollectorApplication', CollectorApplicationSchema);
    
    // Get all users with collector applications
    const users = await User.find({ 'collectorApplication': { $exists: true } });
    console.log(`📊 Found ${users.length} users with collector applications`);
    
    let migratedCount = 0;
    let skippedCount = 0;
    
    for (const user of users) {
      const userDoc = user.toObject();
      console.log(`\n🔄 Processing user: ${userDoc.email}`);
      
      if (userDoc.collectorApplication) {
        console.log(`   Application status: ${userDoc.collectorApplication.status}`);
        
        // Check if application already exists in new collection
        const existingApplication = await CollectorApplication.findOne({ userId: userDoc._id });
        
        if (existingApplication) {
          console.log(`   ⚠️ Application already exists in new collection, skipping`);
          skippedCount++;
          continue;
        }
        
        // Create new application in separate collection
        const newApplication = new CollectorApplication({
          userId: userDoc._id,
          status: userDoc.collectorApplication.status || 'pending',
          idCardPhoto: userDoc.collectorApplication.idCardPhoto || '',
          selfieWithIdPhoto: userDoc.collectorApplication.selfieWithIdPhoto || '',
          rejectionReason: userDoc.collectorApplication.rejectionReason,
          appliedAt: userDoc.collectorApplication.appliedAt || new Date(),
          reviewedAt: userDoc.collectorApplication.reviewedAt,
          reviewedBy: userDoc.collectorApplication.reviewedBy,
          reviewNotes: userDoc.collectorApplication.reviewNotes,
          createdAt: userDoc.collectorApplication.appliedAt || new Date(),
          updatedAt: new Date(),
        });
        
        await newApplication.save();
        console.log(`   ✅ Migrated application for ${userDoc.email}`);
        migratedCount++;
        
        // Remove collectorApplication from user document
        await User.updateOne(
          { _id: userDoc._id },
          { $unset: { collectorApplication: 1 } }
        );
        console.log(`   ✅ Removed collectorApplication from user document`);
      } else {
        console.log(`   ⚠️ No collector application found`);
        skippedCount++;
      }
    }
    
    console.log('\n✅ Migration completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Migrated: ${migratedCount} applications`);
    console.log(`   - Skipped: ${skippedCount} users`);
    
    // Verify the results
    console.log('\n🔍 Verifying migration results:');
    const totalApplications = await CollectorApplication.countDocuments();
    console.log(`   - Total applications in new collection: ${totalApplications}`);
    
    const applicationsByStatus = await CollectorApplication.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);
    console.log(`   - Applications by status:`);
    applicationsByStatus.forEach(status => {
      console.log(`     ${status._id}: ${status.count}`);
    });
    
    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during migration:', error);
  }
}

migrateCollectorApplications(); 