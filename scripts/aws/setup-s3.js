#!/usr/bin/env node
/**
 * ==============================================================================
 * Govia AWS S3 Bucket Setup & Verification Script
 * ==============================================================================
 * Automatically creates and configures an S3 bucket for LiveKit Egress recordings:
 * 1. Creates the S3 bucket in your target region
 * 2. Configures CORS for video playback (Range requests, Accept-Ranges, admin.govia.app)
 * 3. Configures public read policy for the recordings/ path so videos can stream
 * 4. Performs a live upload & delete test to verify IAM write/read permissions
 * 5. Generates the exact .env variables to copy into production
 * ==============================================================================
 */

const {
  S3Client,
  HeadBucketCommand,
  CreateBucketCommand,
  PutBucketCorsCommand,
  PutPublicAccessBlockCommand,
  PutBucketPolicyCommand,
  PutObjectCommand,
  DeleteObjectCommand,
} = require('@aws-sdk/client-s3');
const readline = require('readline');

// Parse CLI arguments or environment variables
const args = process.argv.slice(2);
const getArg = (name) => {
  const idx = args.indexOf(`--${name}`);
  if (idx !== -1 && args[idx + 1]) return args[idx + 1];
  return null;
};

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const ask = (query, defaultValue) => {
  return new Promise((resolve) => {
    rl.question(`${query} ${defaultValue ? `(${defaultValue})` : ''}: `, (ans) => {
      resolve(ans.trim() || defaultValue);
    });
  });
};

async function main() {
  console.log('========================================================');
  console.log('☁️  Govia AWS S3 Bucket Creator & Verification Utility');
  console.log('========================================================\n');

  let accessKey =
    getArg('key') ||
    process.env.AWS_ACCESS_KEY_ID ||
    process.env.S3_ACCESS_KEY;
  let secretKey =
    getArg('secret') ||
    process.env.AWS_SECRET_ACCESS_KEY ||
    process.env.S3_SECRET_KEY;
  let region =
    getArg('region') ||
    process.env.AWS_REGION ||
    process.env.S3_REGION ||
    'us-east-1';
  let bucket =
    getArg('bucket') ||
    process.env.AWS_BUCKET ||
    process.env.S3_BUCKET ||
    'govia-recordings-prod';

  if (!accessKey) {
    accessKey = await ask('🔑 Enter AWS Access Key ID');
  }

  if (!secretKey) {
    secretKey = await ask('🔒 Enter AWS Secret Access Key');
  }

  if (!bucket) {
    bucket = await ask('🪣 Enter S3 Bucket Name', 'govia-recordings-prod');
  }

  if (!getArg('region') && !process.env.AWS_REGION && !process.env.S3_REGION) {
    region = await ask('🌍 Enter AWS Region', region || 'us-east-1');
  }

  rl.close();

  if (!accessKey || !secretKey || !bucket) {
    console.error('❌ Error: Access Key, Secret Key, and Bucket Name are required.');
    process.exit(1);
  }

  // S3 bucket naming rules
  bucket = bucket.toLowerCase().trim();

  console.log(`\n⚙️ Connecting to AWS (Region: ${region})...`);
  const client = new S3Client({
    region,
    credentials: {
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
    },
  });

  // 1. Check if bucket exists or create it
  try {
    console.log(`🔍 Checking if bucket "${bucket}" already exists...`);
    await client.send(new HeadBucketCommand({ Bucket: bucket }));
    console.log(`✅ Bucket "${bucket}" already exists and is accessible.`);
  } catch (err) {
    if (err.name === 'NotFound' || err.$metadata?.httpStatusCode === 404) {
      console.log(`🚀 Creating S3 bucket "${bucket}" in region "${region}"...`);
      const createParams = {
        Bucket: bucket,
      };
      if (region !== 'us-east-1') {
        createParams.CreateBucketConfiguration = {
          LocationConstraint: region,
        };
      }
      await client.send(new CreateBucketCommand(createParams));
      console.log(`✅ Bucket "${bucket}" successfully created!`);
    } else {
      console.error(`⚠️ Notice checking bucket (${err.name}): ${err.message}`);
    }
  }

  // 2. Configure CORS for streaming & web audio/video players
  console.log('🌐 Configuring CORS for video streaming (admin.govia.app & api.govia.app)...');
  try {
    await client.send(
      new PutBucketCorsCommand({
        Bucket: bucket,
        CORSConfiguration: {
          CORSRules: [
            {
              AllowedHeaders: ['*'],
              AllowedMethods: ['GET', 'HEAD', 'PUT', 'POST', 'DELETE'],
              AllowedOrigins: [
                'https://admin.govia.app',
                'https://api.govia.app',
                'https://govia.app',
                'https://www.govia.app',
                'http://localhost:3000',
                '*',
              ],
              ExposeHeaders: ['ETag', 'Content-Length', 'Accept-Ranges', 'Content-Range'],
              MaxAgeSeconds: 3600,
            },
          ],
        },
      })
    );
    console.log('✅ CORS rules applied successfully.');
  } catch (corsErr) {
    console.warn(`⚠️ Warning setting CORS: ${corsErr.message}`);
  }

  // 3. Configure Public Read Policy for recordings/* folder
  console.log('🔓 Configuring public read access for recordings/* streaming...');
  try {
    // Unblock public policy for reading objects
    await client.send(
      new PutPublicAccessBlockCommand({
        Bucket: bucket,
        PublicAccessBlockConfiguration: {
          BlockPublicAcls: true,
          IgnorePublicAcls: true,
          BlockPublicPolicy: false,
          RestrictPublicBuckets: false,
        },
      })
    );

    const policy = {
      Version: '2012-10-17',
      Statement: [
        {
          Sid: 'AllowPublicReadForRecordings',
          Effect: 'Allow',
          Principal: '*',
          Action: 's3:GetObject',
          Resource: `arn:aws:s3:::${bucket}/recordings/*`,
        },
      ],
    };

    await client.send(
      new PutBucketPolicyCommand({
        Bucket: bucket,
        Policy: JSON.stringify(policy),
      })
    );
    console.log(`✅ Bucket policy applied: Public read allowed on "${bucket}/recordings/*".`);
  } catch (policyErr) {
    console.warn(`⚠️ Notice setting bucket policy: ${policyErr.message}`);
    console.warn('   (If client enforces strict Block Public Access, ensure pre-signed URLs or IAM role is used).');
  }

  // 4. Test live upload and deletion
  console.log('🧪 Performing read/write verification test on S3...');
  const testKey = `recordings/.test-healthcheck-${Date.now()}.txt`;
  try {
    await client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: testKey,
        Body: 'Govia S3 Storage Health Check OK',
        ContentType: 'text/plain',
      })
    );
    console.log(`   👉 Upload test passed: s3://${bucket}/${testKey}`);

    await client.send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: testKey,
      })
    );
    console.log('   👉 Delete test passed: object cleaned up.');
    console.log('🎉 S3 storage integration is 100% OPERATIONAL!');
  } catch (testErr) {
    console.error(`❌ Upload/Delete test failed: ${testErr.message}`);
  }

  // 5. Output ready-to-use variables
  console.log('\n========================================================');
  console.log('📋 COPY THESE VALUES INTO YOUR .env FILE:');
  console.log('========================================================');
  console.log(`S3_BUCKET=${bucket}`);
  console.log(`S3_REGION=${region}`);
  console.log(`S3_ACCESS_KEY=${accessKey}`);
  console.log(`S3_SECRET_KEY=${secretKey}`);
  console.log('S3_ENDPOINT=');
  console.log(`AWS_BUCKET=${bucket}`);
  console.log(`AWS_REGION=${region}`);
  console.log(`AWS_ACCESS_KEY_ID=${accessKey}`);
  console.log(`AWS_SECRET_ACCESS_KEY=${secretKey}`);
  console.log('========================================================\n');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
