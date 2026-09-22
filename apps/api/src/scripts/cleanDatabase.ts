import mongoose from 'mongoose';
import config from '../config';

async function main() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect(config.database_url as string);
  console.log('Connected.');

  const db = mongoose.connection.db;
  if (!db) {
    throw new Error('No DB connection');
  }

  // Collections to delete all data from (everything except users and community resources)
  const collectionsToClear = [
    'meetings',
    'conversations',
    'messages',
    'vaultitems',
    'vaultfolders',
    'aichats',
    'goviarecordings',
    'herohighlights',
    'tokens',
  ];

  console.log('\n--- CLEANING DATA (EXCEPT USERS & LOGIN INFO) ---');

  for (const colName of collectionsToClear) {
    try {
      const collection = db.collection(colName);
      const countBefore = await collection.countDocuments();
      if (countBefore > 0) {
        const result = await collection.deleteMany({});
        console.log(`[CLEARED] ${colName.padEnd(20)}: Removed ${result.deletedCount} documents (was ${countBefore})`);
      } else {
        console.log(`[EMPTY]   ${colName.padEnd(20)}: 0 documents`);
      }
    } catch (err) {
      console.warn(`Could not clear collection ${colName}:`, err);
    }
  }

  console.log('\n--- VERIFYING PRESERVED DATA ---');
  const userCount = await db.collection('users').countDocuments();
  console.log(`users collection: ${userCount} users preserved with full login credentials.`);

  const crCount = await db.collection('communityresources').countDocuments();
  console.log(`communityresources collection: ${crCount} system resources intact.`);

  console.log('\n--- FINAL STATUS OF ALL COLLECTIONS ---');
  const allCols = await db.listCollections().toArray();
  for (const col of allCols) {
    const c = await db.collection(col.name).countDocuments();
    console.log(`- ${col.name.padEnd(25)}: ${c} documents`);
  }

  await mongoose.disconnect();
  console.log('\nDatabase cleanup finished successfully.');
}

main().catch(err => {
  console.error('Error during cleanup:', err);
  process.exit(1);
});
