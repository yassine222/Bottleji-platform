const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji';

async function testGroupedTimeline() {
  try {
    console.log('🔍 TESTING GROUPED TIMELINE DATA\n');
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const User = mongoose.model('User', new mongoose.Schema({}, { strict: false, collection: 'users' }));
    const CollectorInteraction = mongoose.model('CollectorInteraction', new mongoose.Schema({}, { strict: false, collection: 'collectorinteractions' }));
    const Dropoff = mongoose.model('Dropoff', new mongoose.Schema({}, { strict: false, collection: 'dropoffs' }));

    // Get a user who has warnings (likely has expired interactions)
    const userWithWarnings = await User.findOne({ warningCount: { $gt: 0 } });
    
    if (!userWithWarnings) {
      console.log('❌ No users with warnings found');
      await mongoose.disconnect();
      return;
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('Testing with user:');
    console.log('═══════════════════════════════════════════════════════════\n');
    console.log(`Name: ${userWithWarnings.name}`);
    console.log(`Email: ${userWithWarnings.email}`);
    console.log(`ID: ${userWithWarnings._id}`);
    console.log(`Warnings: ${userWithWarnings.warningCount || 0}/5\n`);

    // Get all interactions for this user
    const userObjectId = new mongoose.Types.ObjectId(userWithWarnings._id);
    
    const collectorInteractions = await Dropoff.aggregate([
      {
        $lookup: {
          from: 'collectorinteractions',
          localField: '_id',
          foreignField: 'dropoffId',
          as: 'interactions'
        }
      },
      {
        $unwind: '$interactions'
      },
      {
        $match: {
          'interactions.collectorId': userObjectId
        }
      },
      {
        $project: {
          dropoff: '$$ROOT',
          interaction: '$interactions'
        }
      },
      {
        $sort: { 'interaction.interactionTime': -1 }
      }
    ]);

    console.log('═══════════════════════════════════════════════════════════');
    console.log(`Found ${collectorInteractions.length} interactions for this user`);
    console.log('═══════════════════════════════════════════════════════════\n');

    // Group by dropoffId
    const interactionsByDrop = new Map();
    
    collectorInteractions.forEach(item => {
      const dropId = item.dropoff._id?.toString();
      if (!interactionsByDrop.has(dropId)) {
        interactionsByDrop.set(dropId, []);
      }
      interactionsByDrop.get(dropId).push(item);
    });

    console.log(`Grouped into ${interactionsByDrop.size} unique drops\n`);

    // Show each group
    let groupNum = 1;
    interactionsByDrop.forEach((items, dropId) => {
      // Sort interactions by time
      items.sort((a, b) => new Date(a.interaction.interactionTime).getTime() - new Date(b.interaction.interactionTime).getTime());
      
      console.log('═══════════════════════════════════════════════════════════');
      console.log(`GROUP ${groupNum}: Drop ${dropId}`);
      console.log('═══════════════════════════════════════════════════════════\n');
      
      const dropoff = items[0].dropoff;
      console.log(`Drop Details:`);
      console.log(`  Bottles: ${dropoff.numberOfBottles}`);
      console.log(`  Cans: ${dropoff.numberOfCans}`);
      console.log(`  Status: ${dropoff.status}`);
      console.log(`  Created: ${dropoff.createdAt}\n`);
      
      console.log(`Interactions (${items.length}):\n`);
      
      items.forEach((item, idx) => {
        const interaction = item.interaction;
        console.log(`  ${idx + 1}. ${interaction.interactionType.toUpperCase()}`);
        console.log(`     Time: ${interaction.interactionTime}`);
        if (interaction.notes) {
          console.log(`     Notes: ${interaction.notes}`);
        }
        if (interaction.cancellationReason) {
          console.log(`     Reason: ${interaction.cancellationReason}`);
        }
        console.log('');
      });
      
      // Determine final status
      const hasCollected = items.some(i => i.interaction.interactionType === 'collected');
      const hasCancelled = items.some(i => i.interaction.interactionType === 'cancelled');
      const hasExpired = items.some(i => i.interaction.interactionType === 'expired');
      
      let finalStatus = 'accepted';
      if (hasCollected) {
        finalStatus = 'collected';
      } else if (hasCancelled) {
        finalStatus = 'cancelled';
      } else if (hasExpired) {
        finalStatus = 'expired';
      }
      
      console.log(`  Final Status: ${finalStatus.toUpperCase()}`);
      console.log(`  Display: Collection ${finalStatus}\n`);
      
      groupNum++;
    });

    // Now check for EXPIRED interactions that should have ACCEPTED pairs
    console.log('═══════════════════════════════════════════════════════════');
    console.log('CHECKING FOR EXPIRED INTERACTIONS WITHOUT ACCEPTED');
    console.log('═══════════════════════════════════════════════════════════\n');

    const expiredInteractions = await CollectorInteraction.find({
      collectorId: userObjectId,
      interactionType: 'expired'
    }).sort({ interactionTime: -1 }).limit(5);

    console.log(`Found ${expiredInteractions.length} EXPIRED interactions (showing last 5)\n`);

    for (let i = 0; i < expiredInteractions.length; i++) {
      const expired = expiredInteractions[i];
      console.log(`${i + 1}. EXPIRED Interaction:`);
      console.log(`   ID: ${expired._id}`);
      console.log(`   Drop ID: ${expired.dropoffId}`);
      console.log(`   Time: ${expired.interactionTime}`);
      console.log(`   Notes: ${expired.notes || 'N/A'}`);
      
      // Look for corresponding ACCEPTED interaction
      const accepted = await CollectorInteraction.findOne({
        collectorId: userObjectId,
        dropoffId: expired.dropoffId,
        interactionType: 'accepted'
      });

      if (accepted) {
        console.log(`   ✅ Has ACCEPTED pair: ${accepted._id} (at ${accepted.interactionTime})`);
        
        // Check if they're in the same group
        const inGroup = interactionsByDrop.has(expired.dropoffId.toString());
        console.log(`   ${inGroup ? '✅' : '❌'} In grouped timeline: ${inGroup}`);
      } else {
        console.log(`   ❌ NO ACCEPTED pair found!`);
      }
      console.log('');
    }

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testGroupedTimeline();

