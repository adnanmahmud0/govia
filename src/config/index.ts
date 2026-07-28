import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
const envPath = fs.existsSync(path.join(process.cwd(), '.env')) 
  ? path.join(process.cwd(), '.env') 
  : path.join(process.cwd(), '..', '.env');
dotenv.config({ path: envPath });

export default {
  ip_address: process.env.IP_ADDRESS,
  database_url: process.env.DATABASE_URL,
  node_env: process.env.NODE_ENV,
  port: process.env.PORT || '1000',
  bcrypt_salt_rounds: process.env.BCRYPT_SALT_ROUNDS || '10',
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
  zoom: {
    accountId: process.env.ZOOM_ACCOUNT_ID,
    clientId: process.env.ZOOM_CLIENT_ID,
    clientSecret: process.env.ZOOM_CLIENT_SECRET,
  },
  ai: {
    baseUrl: process.env.AI_PROVIDER_BASE_URL || 'https://api.openai.com/v1',
    apiKey: process.env.AI_API_KEY,
    modelName: process.env.AI_MODEL_NAME || 'gpt-3.5-turbo',
  },
};
