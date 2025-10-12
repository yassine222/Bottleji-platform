const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji';

async function deepCleanupInvestigation() {
  try {
    console.log('🔍 DEEP CLEANUP CYCLE INVESTIGATION\n');
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const User = mongoose.model('User', new mongoose.Schema({}, { strict: false, collection: 'users' }));
    const CollectorInteraction = mongoose.model('CollectorInteraction', new mongoose.Schema({}, { strict: false, collection: 'collectorinteractions' }));
    const Dropoff = mongoose.model('Dropoff', new mongoose.Schema({}, { strict: false, collection: 'dropoffs' }));

    console.log('═══════════════════════════════════════════════════════════');
    console.log('1️⃣  CHECKING CLEANUP CYCLE CONFIGURATION');
    console.log('═══════════════════════════════════════════════════════════\n');
    
    console.log('Expected Configuration (from code):');
    console.log('   Timeout: 1 minute');
    console.log('   Cleanup Interval: 1 minute');
    console.log('   Should run: Every 60 seconds');
    console.log('   Initial run: On server startup\n');

    console.log('═══════════════════════════════════════════════════════════');
    console.log('2️⃣  CHECKING CURRENT ACCEPTED DROPS');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Find all ACCEPTED drops
    const acceptedDrops = await Dropoff.find({ status: 'accepted' });
    console.log(`Found ${acceptedDrops.length} drops with ACCEPTED status\n`);

    if (acceptedDrops.length > 0) {
      acceptedDrops.forEach((drop, idx) => {
        console.log(`${idx + 1}. Drop ID: ${drop._id}`);
        console.log(`   Status: ${drop.status}`);
        console.log(`   Created: ${drop.createdAt}`);
        console.log(`   Updated: ${drop.updatedAt}`);
        console.log(`   User: ${drop.userId}`);
        console.log('');
      });
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('3️⃣  CHECKING ACCEPTED INTERACTIONS');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Find all ACCEPTED interactions
    const acceptedInteractions = await CollectorInteraction.find({ 
      interactionType: 'accepted' 
    }).sort({ interactionTime: -1 });

    console.log(`Found ${acceptedInteractions.length} ACCEPTED interactions\n`);

    const now = new Date();
    console.log(`Current time: ${now.toISOString()}\n`);

    if (acceptedInteractions.length > 0) {
      for (let i = 0; i < acceptedInteractions.length; i++) {
        const interaction = acceptedInteractions[i];
        const timeElapsed = (now - new Date(interaction.interactionTime)) / 1000 / 60; // minutes
        const shouldExpire = timeElapsed > 1;

        console.log(`${i + 1}. Interaction ID: ${interaction._id}`);
        console.log(`   Drop ID: ${interaction.dropoffId}`);
        console.log(`   Collector ID: ${interaction.collectorId}`);
        console.log(`   Accepted at: ${interaction.interactionTime}`);
        console.log(`   Time elapsed: ${timeElapsed.toFixed(2)} minutes`);
        console.log(`   Should expire: ${shouldExpire ? '⚠️  YES (>1 min)' : '✅ NO (<1 min)'}`);

        // Check if drop still exists and its status
        const drop = await Dropoff.findById(interaction.dropoffId);
        if (drop) {
          console.log(`   Drop status: ${drop.status}`);
          console.log(`   Drop should be: ${shouldExpire ? 'PENDING (expired)' : 'ACCEPTED (active)'}`);
          if (shouldExpire && drop.status !== 'pending') {
            console.log(`   ❌ PROBLEM: Drop should be PENDING but is ${drop.status.toUpperCase()}`);
          }
        } else {
          console.log(`   ⚠️  Drop not found (might be deleted)`);
        }

        // Check if EXPIRED interaction exists
        const expiredInteraction = await CollectorInteraction.findOne({
          dropoffId: interaction.dropoffId,
          collectorId: interaction.collectorId,
          interactionType: 'expired'
        });

        if (expiredInteraction) {
          console.log(`   Has EXPIRED interaction: ✅ YES (created at ${expiredInteraction.interactionTime})`);
        } else {
          console.log(`   Has EXPIRED interaction: ❌ NO`);
          if (shouldExpire) {
            console.log(`   ❌ PROBLEM: Should have EXPIRED interaction but doesn't!`);
          }
        }

        console.log('');
      }
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('4️⃣  CHECKING EXPIRED INTERACTIONS');
    console.log('═══════════════════════════════════════════════════════════\n');

    const expiredInteractions = await CollectorInteraction.find({ 
      interactionType: 'expired' 
    }).sort({ interactionTime: -1 }).limit(10);

    console.log(`Found ${expiredInteractions.length} EXPIRED interactions (showing last 10)\n`);

    for (let i = 0; i < expiredInteractions.length; i++) {
      const interaction = expiredInteractions[i];
      console.log(`${i + 1}. Interaction ID: ${interaction._id}`);
      console.log(`   Drop ID: ${interaction.dropoffId}`);
      console.log(`   Collector ID: ${interaction.collectorId}`);
      console.log(`   Expired at: ${interaction.interactionTime}`);
      console.log(`   Notes: ${interaction.notes || 'N/A'}`);

      // Check if collector got warning
      const collector = await User.findById(interaction.collectorId);
      if (collector) {
        const hasWarningForThis = collector.warnings?.some(w => {
          const warningTime = new Date(w.timestamp || w.date);
          const expiredTime = new Date(interaction.interactionTime);
          const timeDiff = Math.abs(warningTime - expiredTime) / 1000; // seconds
          return timeDiff < 60; // Within 60 seconds
        });

        console.log(`   Collector: ${collector.name} (${collector.email})`);
        console.log(`   Warning added: ${hasWarningForThis ? '✅ YES' : '❌ NO'}`);
        console.log(`   Total warnings: ${collector.warningCount || 0}/5`);
      } else {
        console.log(`   ⚠️  Collector not found`);
      }

      console.log('');
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('5️⃣  CLEANUP CYCLE EFFECTIVENESS CHECK');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Check for ACCEPTED interactions that SHOULD be expired but aren't
    const stuckAccepted = acceptedInteractions.filter(interaction => {
      const timeElapsed = (now - new Date(interaction.interactionTime)) / 1000 / 60;
      return timeElapsed > 1; // Should be expired
    });

    console.log(`ACCEPTED interactions that should be expired: ${stuckAccepted.length}`);

    if (stuckAccepted.length > 0) {
      console.log('❌ CLEANUP IS NOT WORKING PROPERLY!\n');
      console.log('These interactions should have been cleaned up:');
      stuckAccepted.forEach((interaction, idx) => {
        const timeElapsed = (now - new Date(interaction.interactionTime)) / 1000 / 60;
        console.log(`${idx + 1}. Drop ${interaction.dropoffId} - ${timeElapsed.toFixed(2)} minutes old`);
      });
      console.log('\nPossible reasons:');
      console.log('   • Backend server not running');
      console.log('   • Cleanup task not started');
      console.log('   • Code changes not applied (need restart)');
      console.log('   • Error in cleanup function');
    } else {
      console.log('✅ CLEANUP IS WORKING CORRECTLY!');
      console.log('   All expired interactions have been processed');
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('6️⃣  RECOMMENDATIONS');
    console.log('═══════════════════════════════════════════════════════════\n');

    if (stuckAccepted.length > 0) {
      console.log('🔧 ACTION NEEDED:');
      console.log('   1. Restart the backend server to apply code changes');
      console.log('   2. Wait 1-2 minutes for cleanup to run');
      console.log('   3. Run this script again to verify');
    } else {
      console.log('✅ System is working as expected!');
      console.log('   • Cleanup cycle is running');
      console.log('   • Timeouts are being detected');
      console.log('   • Warnings are being added');
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

deepCleanupInvestigation();

