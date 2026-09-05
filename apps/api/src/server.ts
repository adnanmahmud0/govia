import { Server as HttpServer } from 'http';
import process from 'process';
import colors from 'colors';
import mongoose from 'mongoose';
import { Server as IOServer } from 'socket.io';
import app from './app';
import config from './config';
import { seedSuperAdmin } from './DB/seedAdmin';
import { socketHelper } from './helpers/socketHelper';
import { errorLogger, logger } from './shared/logger';

// Uncaught exception handling
process.on('uncaughtException', error => {
  errorLogger.error('UncaughtException Detected:', error);
  process.exit(1);
});

let server: HttpServer | null = null;

async function main() {
  const port =
    typeof config.port === 'number' ? config.port : Number(config.port) || 5000;
  const host = (config.ip_address as string) || '0.0.0.0';

  // Start HTTP Server
  server = app.listen(port, host, () => {
    logger.info(
      colors.yellow(
        `♻️  Govia API listening on http://${host === '0.0.0.0' ? 'localhost' : host}:${port}`
      )
    );
    logger.info(
      colors.cyan(
        `📖 Swagger UI Docs available at: http://${host === '0.0.0.0' ? 'localhost' : host}:${port}/api/v1/docs`
      )
    );
  });

  // Socket.IO Server for real-time messaging, emergency alerts, and meeting notifications
  const io = new IOServer(server as HttpServer, {
    pingTimeout: 60000,
    cors: {
      origin: '*',
    },
  });

  socketHelper.socket(io);
  // @ts-expect-error: attach io to global
  global.io = io;
  logger.info(colors.green('⚡ Socket.IO initialized and ready'));

  // Connect to MongoDB
  try {
    if (config.database_url) {
      await mongoose.connect(config.database_url as string);
      logger.info(colors.green('🚀 MongoDB connected successfully'));

      // Seed Super Admin if not already present
      await seedSuperAdmin();
    } else {
      logger.warn(colors.yellow('⚠️ DATABASE_URL not configured in environment'));
    }
  } catch (error) {
    errorLogger.error(colors.red('🤢 Failed to connect to MongoDB:'), error);
  }

  // Handle unhandled promise rejections
  process.on('unhandledRejection', error => {
    if (server) {
      server.close(() => {
        errorLogger.error('UnhandledRejection Detected:', error);
        process.exit(1);
      });
    } else {
      process.exit(1);
    }
  });
}

main();

// Graceful SIGTERM shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received. Closing HTTP server...');
  if (server) {
    server.close(() => {
      logger.info('HTTP server closed.');
    });
  }
});
