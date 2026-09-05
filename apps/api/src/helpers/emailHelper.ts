import nodemailer from 'nodemailer';
import config from '../config';
import { ISendEmail } from '../types/email';
import { debug, debugError } from '../shared/debug';

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
      debugError('email.transport.missing_config');
      if (process.env.NODE_ENV !== 'production') {
        debug('email.dev.dump', { to: values.to, subject: values.subject });
      }
      return;
    }
    const info = await transporter.sendMail({
      from: config.email.from || 'no-reply@example.com',
      to: values.to,
      subject: values.subject,
      html: values.html,
    });
    const preview = nodemailer.getTestMessageUrl(info);
    if (preview) {
      debug('email.preview', preview);
    }
  } catch (error) {
    debugError('email.send.failed', error);
    if (process.env.NODE_ENV !== 'production') {
      debug('email.dev.dump', { to: values.to, subject: values.subject });
    }
  }
};

export const emailHelper = {
  sendEmail,
};
