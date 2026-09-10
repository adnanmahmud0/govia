import nodemailer from 'nodemailer';
import config from '../config';
import { ISendEmail } from '../types/email';
import { errorLogger, logger } from '../shared/logger';
import { debug } from '../shared/debug';

const createConfiguredTransporter = async () => {
  const hasSmtpConfig =
    !!config.email.host && !!config.email.user && !!config.email.pass;
  if (hasSmtpConfig) {
    return nodemailer.createTransport({
      host: config.email.host,
      port: Number(config.email.port ?? 587),
      secure: false,
      auth: {
        user: config.email.user,
        pass: config.email.pass,
      },
    });
  }

  if (process.env.NODE_ENV !== 'production') {
    const testAccount = await nodemailer.createTestAccount();
    return nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass,
      },
    });
  }

  return null;
};

const sendEmail = async (values: ISendEmail) => {
  try {
    const transporter = await createConfiguredTransporter();
    if (!transporter) {
      errorLogger.error('Email transport missing configuration. Check EMAIL_HOST, EMAIL_USER, and EMAIL_PASS');
      return;
    }
    const info = await transporter.sendMail({
      from: config.email.from || 'no-reply@example.com',
      to: values.to,
      subject: values.subject,
      html: values.html,
    });
    logger.info(`📧 Email sent successfully to ${values.to} [Subject: "${values.subject}"]`);
    const preview = nodemailer.getTestMessageUrl(info);
    if (preview) {
      logger.info(`Email preview URL: ${preview}`);
    }
  } catch (error) {
    errorLogger.error(`❌ Email send failed to ${values.to}: ${error instanceof Error ? error.message : error}`);
    if (process.env.NODE_ENV !== 'production') {
      debug('email.dev.dump', { to: values.to, subject: values.subject });
    }
  }
};

export const emailHelper = {
  sendEmail,
};
