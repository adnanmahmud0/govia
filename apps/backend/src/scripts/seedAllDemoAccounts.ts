import mongoose from 'mongoose';
import config from '../config';
import { seedDemoAccounts, demoAccounts } from '../DB/seedAdmin';
import { User } from '../app/modules/user/user.model';

async function main() {
  console.log('Connecting to MongoDB at:', config.database_url ? 'Configured URL' : 'None');
  await mongoose.connect(config.database_url as string);
  console.log('MongoDB connected.');

  console.log(`Seeding ${demoAccounts.length} demo accounts across all roles...`);
  await seedDemoAccounts();

  console.log('--- SEEDED DEMO ACCOUNTS ---');
  const allUsers = await User.find(
    { email: { $in: demoAccounts.map(a => a.email) } },
    { name: 1, email: 1, role: 1, verified: 1, status: 1, shortHexId: 1, phoneNumber: 1 }
  );

  for (const u of allUsers) {
    console.log(
      `[${u.role.padEnd(26)}] ${u.email.padEnd(28)} | ${u.name.padEnd(28)} | verified: ${u.verified} | status: ${u.status}`
    );
  }

  await mongoose.disconnect();
  console.log('Seeding completed successfully!');
  process.exit(0);
}

main().catch(err => {
  console.error('Seeding error:', err);
  process.exit(1);
});
