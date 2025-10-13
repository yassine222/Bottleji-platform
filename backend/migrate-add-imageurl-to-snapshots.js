const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'your-mongodb-uri';

async function migrateImageUrls() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const attemptsCollection = db.collection('collectionattempts');
    const dropsCollection = db.collection('dropoffs');

    // Get all collection attempts
    const attempts = await attemptsCollection.find({}).toArray();
    console.log(`📊 Found ${attempts.length} collection attempts`);

    let updated = 0;
    let skipped = 0;
    let notFound = 0;

    for (const attempt of attempts) {
      // Check if imageUrl already exists in dropSnapshot
      if (attempt.dropSnapshot?.imageUrl) {
        console.log(`⏭️  Attempt ${attempt._id} already has imageUrl, skipping`);
        skipped++;
        continue;
      }

      // Get the corresponding drop
      const drop = await dropsCollection.findOne({ 
        _id: mongoose.Types.ObjectId.isValid(attempt.dropoffId) 
          ? new mongoose.Types.ObjectId(attempt.dropoffId)
          : attempt.dropoffId
      });

      if (!drop) {
        console.log(`❌ Drop not found for attempt ${attempt._id} (dropId: ${attempt.dropoffId})`);
        notFound++;
        continue;
      }

      // Update the attempt with imageUrl and leaveOutside
      await attemptsCollection.updateOne(
        { _id: attempt._id },
        {
          $set: {
            'dropSnapshot.imageUrl': drop.imageUrl || '',
            'dropSnapshot.leaveOutside': drop.leaveOutside || false,
          }
        }
      );

      console.log(`✅ Updated attempt ${attempt._id} with imageUrl: ${drop.imageUrl?.substring(0, 50)}...`);
      updated++;
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ⏭️  Skipped (already has imageUrl): ${skipped}`);
    console.log(`   ❌ Drop not found: ${notFound}`);
    console.log(`   📝 Total processed: ${attempts.length}`);

    console.log('\n✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrateImageUrls();

