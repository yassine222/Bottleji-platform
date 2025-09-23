const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function syncAllApplicationStatuses() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');
    const applicationsCollection = db.collection('collectorapplications');

    // Get all users who have collector applications
    const usersWithApplications = await usersCollection.find({
      $or: [
        { collectorApplicationStatus: { $exists: true } },
        { collectorApplicationId: { $exists: true } }
      ]
    }).toArray();

    console.log(`\n🔍 Found ${usersWithApplications.length} users with application data`);

    let updatedCount = 0;
    let errorCount = 0;

    for (const user of usersWithApplications) {
      try {
        // Find the user's collector application
        const application = await applicationsCollection.findOne({ userId: user._id });
        
        if (application) {
          // Check if there's a mismatch
          const userStatus = user.collectorApplicationStatus || 'not_set';
          const appStatus = application.status;
          
          if (userStatus !== appStatus) {
            console.log(`\n⚠️  Mismatch found for ${user.email}:`);
            console.log(`   User status: ${userStatus}`);
            console.log(`   App status: ${appStatus}`);
            
            // Update the user's application status
            const updateResult = await usersCollection.updateOne(
              { _id: user._id },
              {
                $set: {
                  collectorApplicationStatus: appStatus,
                  collectorApplicationId: application._id.toString(),
                  collectorApplicationAppliedAt: application.appliedAt,
                  collectorApplicationRejectionReason: application.rejectionReason || null,
                }
              }
            );

            if (updateResult.modifiedCount > 0) {
              console.log(`   ✅ Updated to: ${appStatus}`);
              updatedCount++;
            } else {
              console.log(`   ❌ Failed to update`);
              errorCount++;
            }
          } else {
            console.log(`✅ ${user.email}: Status consistent (${appStatus})`);
          }
        } else {
          // User has application status but no actual application
          console.log(`\n⚠️  Orphaned status for ${user.email}:`);
          console.log(`   User status: ${user.collectorApplicationStatus}`);
          console.log(`   No application found in database`);
          
          // Clear the orphaned status
          const updateResult = await usersCollection.updateOne(
            { _id: user._id },
            {
              $unset: {
                collectorApplicationStatus: 1,
                collectorApplicationId: 1,
                collectorApplicationAppliedAt: 1,
                collectorApplicationRejectionReason: 1,
              }
            }
          );

          if (updateResult.modifiedCount > 0) {
            console.log(`   ✅ Cleared orphaned status`);
            updatedCount++;
          } else {
            console.log(`   ❌ Failed to clear status`);
            errorCount++;
          }
        }
      } catch (error) {
        console.log(`❌ Error processing ${user.email}: ${error.message}`);
        errorCount++;
      }
    }

    // Also check for applications without user status
    const allApplications = await applicationsCollection.find({}).toArray();
    console.log(`\n🔍 Found ${allApplications.length} total applications`);

    for (const application of allApplications) {
      const user = await usersCollection.findOne({ _id: application.userId });
      if (user && (!user.collectorApplicationStatus || user.collectorApplicationStatus !== application.status)) {
        console.log(`\n⚠️  Application without user status for ${user.email}:`);
        console.log(`   Application status: ${application.status}`);
        console.log(`   User status: ${user.collectorApplicationStatus || 'Not set'}`);
        
        // Update user status
        const updateResult = await usersCollection.updateOne(
          { _id: user._id },
          {
            $set: {
              collectorApplicationStatus: application.status,
              collectorApplicationId: application._id.toString(),
              collectorApplicationAppliedAt: application.appliedAt,
              collectorApplicationRejectionReason: application.rejectionReason || null,
            }
          }
        );

        if (updateResult.modifiedCount > 0) {
          console.log(`   ✅ Updated user status to: ${application.status}`);
          updatedCount++;
        } else {
          console.log(`   ❌ Failed to update user status`);
          errorCount++;
        }
      }
    }

    console.log(`\n📊 Sync Summary:`);
    console.log(`   ✅ Updated: ${updatedCount} users`);
    console.log(`   ❌ Errors: ${errorCount} users`);
    console.log(`   💡 All application statuses should now be consistent!`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

syncAllApplicationStatuses().then(() => {
  console.log('\n✅ Sync completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Sync failed:', error);
  process.exit(1);
});
