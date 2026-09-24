// Allowed origins for CORS
export const allowedOrigins: string[] = [
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:5000',
  'http://localhost:5001',
  'http://127.0.0.1:5000',
  'http://127.0.0.1:5001',
  'http://localhost:1000',
  'http://127.0.0.1:1000',
];

export const isOriginAllowed = (origin?: string): boolean => {
  if (!origin) return true; // allow non-browser clients (Postman/Flutter mobile app)
  if (allowedOrigins.includes(origin)) return true;

  // Allow local network origins in development
  if (process.env.NODE_ENV === 'development') {
    if (
      origin.startsWith('http://10.') ||
      origin.startsWith('https://10.') ||
      origin.startsWith('http://192.168.') ||
      origin.startsWith('https://192.168.') ||
      origin.startsWith('http://172.') ||
      origin.startsWith('https://172.')
    ) {
      return true;
    }
  }

  return true; // fallback allow for mobile & staging flexibility
};
