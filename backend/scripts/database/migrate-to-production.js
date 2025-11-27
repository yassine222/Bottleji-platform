#!/usr/bin/env node

/**
 * Database Migration Script: Local to Production
 * 
 * This script migrates all data from your local MongoDB database to production.
 * 
 * Usage:
 *   SOURCE_MONGODB_URI="mongodb://localhost:27017/bottleji" \
 *   DEST_MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/bottleji" \
 *   node scripts/database/migrate-to-production.js
 * 
 * Or set environment variables in .env file:
 *   SOURCE_MONGODB_URI=mongodb://localhost:27017/bottleji
 *   DEST_MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/bottleji
 */

require('dotenv').config();
const { MongoClient } = require('mongodb');

// Get database URIs from environment variables
const SOURCE_URI = process.env.SOURCE_MONGODB_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';
const DEST_URI = process.env.DEST_MONGODB_URI || process.env.PRODUCTION_MONGODB_URI;

if (!DEST_URI) {
  console.error('❌ Error: DEST_MONGODB_URI or PRODUCTION_MONGODB_URI environment variable is required');
  console.error('   Please set your production MongoDB URI in the environment variables');
  process.exit(1);
}

// Collections to migrate (in order of dependencies)
const COLLECTIONS_TO_MIGRATE = [
  'users',
  'temporarysignups',
  'collectorapplications',
  'dropoffs',
  'collectorinteractions',
  'collectionattempts',
  'notifications',
  'rewarditems',
  'rewardredemptions',
  'earningssessions',
  'supporttickets',
  'ticketmessages',
  'trainingmaterials',
  'shippinglabels',
];

// Collections to skip (system collections)
const COLLECTIONS_TO_SKIP = [
  'system.indexes',
  'system.users',
  'system.version',
];

let sourceClient, destClient;
let sourceDb, destDb;

async function connectDatabases() {
  console.log('🔗 Connecting to databases...');
  console.log(`   Source: ${SOURCE_URI.replace(/\/\/.*@/, '//***:***@')}`);
  console.log(`   Destination: ${DEST_URI.replace(/\/\/.*@/, '//***:***@')}`);
  
  try {
    sourceClient = new MongoClient(SOURCE_URI);
    destClient = new MongoClient(DEST_URI);
    
    await sourceClient.connect();
    await destClient.connect();
    
    // Extract database names from URIs
    const sourceDbName = SOURCE_URI.split('/').pop().split('?')[0];
    const destDbName = DEST_URI.split('/').pop().split('?')[0];
    
    sourceDb = sourceClient.db(sourceDbName);
    destDb = destClient.db(destDbName);
    
    console.log(`✅ Connected to source database: ${sourceDbName}`);
    console.log(`✅ Connected to destination database: ${destDbName}`);
    
    return { sourceDb, destDb };
  } catch (error) {
    console.error('❌ Failed to connect to databases:', error.message);
    throw error;
  }
}

async function getCollectionNames() {
  const collections = await sourceDb.listCollections().toArray();
  return collections
    .map(c => c.name)
    .filter(name => !COLLECTIONS_TO_SKIP.includes(name))
    .filter(name => !name.startsWith('system.'));
}

async function migrateCollection(collectionName, options = {}) {
  const { skipDuplicates = true, batchSize = 1000 } = options;
  
  console.log(`\n📦 Migrating collection: ${collectionName}`);
  
  const sourceCollection = sourceDb.collection(collectionName);
  const destCollection = destDb.collection(collectionName);
  
  // Get total count
  const totalCount = await sourceCollection.countDocuments();
  console.log(`   Total documents: ${totalCount}`);
  
  if (totalCount === 0) {
    console.log(`   ⏭️  Skipping empty collection`);
    return { inserted: 0, updated: 0, skipped: 0 };
  }
  
  let inserted = 0;
  let updated = 0;
  let skipped = 0;
  let processed = 0;
  
  // Process in batches
  const cursor = sourceCollection.find({}).batchSize(batchSize);
  
  for await (const doc of cursor) {
    try {
      // Remove _id to let MongoDB generate new one, or keep it if you want to preserve IDs
      const docToInsert = { ...doc };
      
      // Check if document already exists (by _id)
      const existing = await destCollection.findOne({ _id: doc._id });
      
      if (existing) {
        if (skipDuplicates) {
          skipped++;
        } else {
          // Update existing document
          await destCollection.replaceOne({ _id: doc._id }, docToInsert);
          updated++;
        }
      } else {
        // Insert new document
        await destCollection.insertOne(docToInsert);
        inserted++;
      }
      
      processed++;
      
      // Progress update every 100 documents
      if (processed % 100 === 0) {
        process.stdout.write(`\r   Progress: ${processed}/${totalCount} (${Math.round(processed/totalCount*100)}%)`);
      }
    } catch (error) {
      console.error(`\n   ❌ Error processing document ${doc._id}:`, error.message);
      skipped++;
    }
  }
  
  console.log(`\n   ✅ Completed: ${inserted} inserted, ${updated} updated, ${skipped} skipped`);
  
  return { inserted, updated, skipped };
}

async function migrateAllCollections() {
  console.log('\n🚀 Starting database migration...\n');
  
  const allCollections = await getCollectionNames();
  console.log(`📋 Found ${allCollections.length} collections to migrate`);
  
  // Prioritize collections with dependencies
  const orderedCollections = [
    ...COLLECTIONS_TO_MIGRATE.filter(c => allCollections.includes(c)),
    ...allCollections.filter(c => !COLLECTIONS_TO_MIGRATE.includes(c))
  ];
  
  const stats = {
    totalInserted: 0,
    totalUpdated: 0,
    totalSkipped: 0,
    collections: {}
  };
  
  for (const collectionName of orderedCollections) {
    try {
      const result = await migrateCollection(collectionName, { skipDuplicates: true });
      stats.totalInserted += result.inserted;
      stats.totalUpdated += result.updated;
      stats.totalSkipped += result.skipped;
      stats.collections[collectionName] = result;
    } catch (error) {
      console.error(`\n❌ Failed to migrate collection ${collectionName}:`, error.message);
      stats.collections[collectionName] = { error: error.message };
    }
  }
  
  return stats;
}

async function verifyMigration() {
  console.log('\n🔍 Verifying migration...\n');
  
  const sourceCollections = await getCollectionNames();
  
  for (const collectionName of sourceCollections) {
    const sourceCount = await sourceDb.collection(collectionName).countDocuments();
    const destCount = await destDb.collection(collectionName).countDocuments();
    
    const status = sourceCount === destCount ? '✅' : '⚠️';
    console.log(`   ${status} ${collectionName}: ${sourceCount} → ${destCount}`);
    
    if (sourceCount !== destCount) {
      console.log(`      ⚠️  Count mismatch!`);
    }
  }
}

async function main() {
  const startTime = Date.now();
  
  try {
    await connectDatabases();
    
    const stats = await migrateAllCollections();
    
    await verifyMigration();
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    
    console.log('\n' + '='.repeat(60));
    console.log('📊 Migration Summary');
    console.log('='.repeat(60));
    console.log(`   Total Inserted: ${stats.totalInserted}`);
    console.log(`   Total Updated: ${stats.totalUpdated}`);
    console.log(`   Total Skipped: ${stats.totalSkipped}`);
    console.log(`   Duration: ${duration}s`);
    console.log('='.repeat(60));
    console.log('\n✅ Migration completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  } finally {
    if (sourceClient) {
      await sourceClient.close();
      console.log('\n🔌 Disconnected from source database');
    }
    if (destClient) {
      await destClient.close();
      console.log('🔌 Disconnected from destination database');
    }
  }
}

// Run migration
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { migrateCollection, migrateAllCollections };

