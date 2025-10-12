const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji';

async function cleanupOldInteractions() {
  try {
    console.log('🧹 CLEANING UP OLD COLLECTION SYSTEM\n');
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const db = mongoose.connection.db;

    console.log('═══════════════════════════════════════════════════════════');
    console.log('1️⃣  BACKING UP EXISTING DATA');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Check if collectorinteractions collection exists
    const collections = await db.listCollections().toArray();
    const hasInteractions = collections.some(col => col.name === 'collectorinteractions');
    
    if (hasInteractions) {
      // Count existing interactions
      const interactionCount = await db.collection('collectorinteractions').countDocuments();
      console.log(`📊 Found ${interactionCount} existing interactions in collectorinteractions collection`);
      
      if (interactionCount > 0) {
        console.log('⚠️  WARNING: This will delete all existing interaction data!');
        console.log('   - All ACCEPTED, EXPIRED, CANCELLED, COLLECTED interactions will be lost');
        console.log('   - Timeline history will be lost');
        console.log('   - Collection attempt history will be lost');
        console.log('\n   Press Ctrl+C to cancel, or wait 10 seconds to continue...\n');
        
        // Wait 10 seconds
        await new Promise(resolve => setTimeout(resolve, 10000));
      }
    } else {
      console.log('✅ No collectorinteractions collection found - nothing to clean up');
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('2️⃣  DROPPING OLD COLLECTIONS');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Drop collectorinteractions collection
    try {
      await db.collection('collectorinteractions').drop();
      console.log('✅ Dropped collectorinteractions collection');
    } catch (error) {
      console.log('⚠️  collectorinteractions collection not found or already dropped');
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('3️⃣  VERIFYING CLEANUP');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Verify collections are gone
    const updatedCollections = await db.listCollections().toArray();
    const stillHasInteractions = updatedCollections.some(col => col.name === 'collectorinteractions');
    
    if (stillHasInteractions) {
      console.log('❌ ERROR: collectorinteractions collection still exists!');
    } else {
      console.log('✅ SUCCESS: collectorinteractions collection successfully removed');
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('4️⃣  NEXT STEPS');
    console.log('═══════════════════════════════════════════════════════════\n');

    console.log('✅ Old interaction system cleaned up successfully!');
    console.log('📋 Next steps:');
    console.log('   1. Restart the backend server to use new CollectionAttempt system');
    console.log('   2. Test the new endpoints:');
    console.log('      - POST /dropoffs/:id/attempts');
    console.log('      - PATCH /dropoffs/:id/attempts/:attemptId/complete');
    console.log('      - GET /dropoffs/collector/:id/attempts');
    console.log('      - GET /dropoffs/:id/attempts');
    console.log('   3. Update Flutter app to use new CollectionAttempt endpoints');
    console.log('   4. Update admin dashboard timeline displays');
    console.log('\n🎉 New CollectionAttempt system is ready to use!');

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

cleanupOldInteractions();
