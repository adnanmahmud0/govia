import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

// Load .env from current directory or monorepo root
const envPath = fs.existsSync(path.join(process.cwd(), '.env')) 
  ? path.join(process.cwd(), '.env') 
  : path.join(process.cwd(), '..', '..', '.env');
dotenv.config({ path: envPath });

export default {
  ip_address: process.env.IP_ADDRESS,
  database_url: process.env.DATABASE_URL,
  node_env: process.env.NODE_ENV,
  enable_api_docs:
    process.env.ENABLE_API_DOCS !== 'false',
  port: process.env.PORT || '5000',
  bcrypt_salt_rounds: process.env.BCRYPT_SALT_ROUNDS || '10',
  branding: {
    projectName: process.env.PROJECT_NAME || 'Govia',
    logoUrl: process.env.BRAND_LOGO || '',
  },
  jwt: {
    jwt_secret: process.env.JWT_SECRET || 'dev-secret',
    jwt_expire_in: process.env.JWT_EXPIRE_IN || '1h',
    jwt_refresh_secret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret',
    jwt_refresh_expire_in: process.env.JWT_REFRESH_EXPIRE_IN || '7d',
  },
  email: {
    from: process.env.EMAIL_FROM,
    user: process.env.EMAIL_USER,
    port: process.env.EMAIL_PORT,
    host: process.env.EMAIL_HOST,
    pass: process.env.EMAIL_PASS,
  },
  super_admin: {
    email: process.env.SUPER_ADMIN_EMAIL,
    password: process.env.SUPER_ADMIN_PASSWORD,
  },
  livekit: {
    // LiveKit WebRTC Cloud credentials
    url: process.env.LIVEKIT_URL || 'wss://govia-0f13ke90.livekit.cloud',
    apiKey: process.env.LIVEKIT_API_KEY || 'API6NLt8C36WoQ8',
    apiSecret: process.env.LIVEKIT_API_SECRET || 'hhc2Hz8oTvHN6flpBOGWTxDBU2h9hOWHwRXUSh49DuY',
  },
  s3: {
    // Cloud storage for LiveKit Egress recordings (AWS S3, Cloudflare R2, or MinIO)
    bucket: process.env.S3_BUCKET || '',
    region: process.env.S3_REGION || 'us-east-1',
    accessKey: process.env.S3_ACCESS_KEY || '',
    secretKey: process.env.S3_SECRET_KEY || '',
    endpoint: process.env.S3_ENDPOINT || '',
  },
  ai: {
    baseUrl: process.env.AI_PROVIDER_BASE_URL || 'https://api.openai.com/v1',
    apiKey: process.env.AI_API_KEY,
    modelName: process.env.AI_MODEL_NAME || 'gpt-3.5-turbo',
  },
};
