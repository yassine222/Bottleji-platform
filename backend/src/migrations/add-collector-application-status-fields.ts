import { MongoClient } from 'mongodb';

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function addCollectorApplicationStatusFields() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');
    const applicationsCollection = db.collection('collectorapplications');

    console.log('\n🔍 Checking existing users...');
    const users = await usersCollection.find({}).toArray();
    console.log(`Found ${users.length} users`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const user of users) {
      try {
        // Check if user already has the new fields
        if (user.collectorApplicationStatus !== undefined) {
          console.log(`⏭️  User ${user.email}: Already has collectorApplicationStatus field, skipping`);
          skippedCount++;
          continue;
        }

        // Find the user's collector application
        const application = await applicationsCollection.findOne({ userId: user._id });
        
        if (application) {
          // User has an application, set the status fields
          const updateData: any = {
            collectorApplicationStatus: application.status,
            collectorApplicationId: application._id.toString(),
            collectorApplicationAppliedAt: application.appliedAt,
          };

          if (application.rejectionReason) {
            updateData.collectorApplicationRejectionReason = application.rejectionReason;
          }

          await usersCollection.updateOne(
            { _id: user._id },
            { $set: updateData }
          );

          console.log(`✅ User ${user.email}: Updated with application status ${application.status}`);
          updatedCount++;
        } else {
          // User has no application, set default values
          await usersCollection.updateOne(
            { _id: user._id },
            { 
              $set: {
                collectorApplicationStatus: null,
                collectorApplicationId: null,
                collectorApplicationAppliedAt: null,
                collectorApplicationRejectionReason: null,
              }
            }
          );

          console.log(`✅ User ${user.email}: Set default values (no application)`);
          updatedCount++;
        }
      } catch (error) {
        console.log(`❌ Error updating user ${user.email}: ${error.message}`);
      }
    }

    console.log(`\n📊 Migration Summary:`);
    console.log(`   ✅ Updated: ${updatedCount} users`);
    console.log(`   ⏭️  Skipped: ${skippedCount} users`);
    console.log(`   💡 All users now have the new collector application status fields!`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('\n🔌 Disconnected from MongoDB');
    }
  }
}

// Run the migration
addCollectorApplicationStatusFields().then(() => {
  console.log('\n✅ Migration completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Migration failed:', error);
  process.exit(1);
});
