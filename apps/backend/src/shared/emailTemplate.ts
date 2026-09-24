import { ICreateAccount, IResetPassword } from '../types/emailTamplate';

const createAccount = (values: ICreateAccount) => {
  const currentYear = new Date().getFullYear();
  const data = {
    to: values.email,
    subject: 'Verify your Govia account',
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verify Your Govia Account</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F4F6FA; margin: 0; padding: 40px 16px; color: #0A192F;">
  <div style="width: 100%; max-width: 520px; margin: 0 auto; background-color: #FFFFFF; border-radius: 16px; border: 1px solid #BDD2F0; padding: 36px 28px; box-shadow: 0 4px 16px rgba(21, 80, 166, 0.08); box-sizing: border-box;">
    
    <!-- Brand Header -->
    <div style="text-align: center; margin-bottom: 24px;">
      <img src="https://adnan5000.binarybards.online/uploads/logo.png" alt="Govia Logo" width="60" height="60" style="display: block; margin: 0 auto 10px; border-radius: 12px; object-fit: contain;" />
      <h1 style="color: #1550A6; font-size: 24px; font-weight: 800; margin: 0; letter-spacing: 0.5px;">GOVIA</h1>
    </div>

    <!-- Main Content -->
    <div style="text-align: center;">
      <h2 style="color: #0A192F; font-size: 20px; font-weight: 700; margin: 0 0 10px 0;">Verify Your Account</h2>
      <p style="color: #5F6E80; font-size: 14px; line-height: 1.5; margin: 0 0 24px 0;">
        Hey ${values.name || 'there'}, thank you for signing up with Govia.<br/>
        Please enter the single-use verification code below to confirm your account:
      </p>

      <!-- 4-Digit OTP Display -->
      <div style="background-color: #E8EEF8; border: 2px solid #1550A6; border-radius: 12px; padding: 16px 24px; text-align: center; margin: 20px auto; max-width: 240px;">
        <span style="font-size: 32px; font-weight: 800; letter-spacing: 10px; color: #1550A6; font-family: 'Courier New', Courier, monospace; display: inline-block; padding-left: 10px;">${values.otp}</span>
      </div>

      <p style="color: #5F6E80; font-size: 13px; margin: 16px 0 0 0;">
        ⏱️ This code is valid for <strong>3 minutes</strong>.
      </p>
    </div>

    <!-- Divider & Security Notice -->
    <div style="border-top: 1px solid #E8EEF8; margin-top: 28px; padding-top: 20px; text-align: center;">
      <p style="color: #90A0B3; font-size: 12px; line-height: 1.4; margin: 0;">
        If you did not request this verification code, please ignore this email.
      </p>
    </div>

  </div>

  <!-- Footer -->
  <div style="text-align: center; margin-top: 20px;">
    <p style="color: #90A0B3; font-size: 12px; margin: 0;">
      © ${currentYear} Govia. All rights reserved.
    </p>
  </div>
</body>
</html>`,
  };
  return data;
};

const resetPassword = (values: IResetPassword) => {
  const currentYear = new Date().getFullYear();
  const data = {
    to: values.email,
    subject: 'Reset your Govia password',
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Govia Password</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F4F6FA; margin: 0; padding: 40px 16px; color: #0A192F;">
  <div style="width: 100%; max-width: 520px; margin: 0 auto; background-color: #FFFFFF; border-radius: 16px; border: 1px solid #BDD2F0; padding: 36px 28px; box-shadow: 0 4px 16px rgba(21, 80, 166, 0.08); box-sizing: border-box;">
    
    <!-- Brand Header -->
    <div style="text-align: center; margin-bottom: 24px;">
      <img src="https://adnan5000.binarybards.online/uploads/logo.png" alt="Govia Logo" width="60" height="60" style="display: block; margin: 0 auto 10px; border-radius: 12px; object-fit: contain;" />
      <h1 style="color: #1550A6; font-size: 24px; font-weight: 800; margin: 0; letter-spacing: 0.5px;">GOVIA</h1>
    </div>

    <!-- Main Content -->
    <div style="text-align: center;">
      <h2 style="color: #0A192F; font-size: 20px; font-weight: 700; margin: 0 0 10px 0;">Reset Your Password</h2>
      <p style="color: #5F6E80; font-size: 14px; line-height: 1.5; margin: 0 0 24px 0;">
        We received a request to reset your password.<br/>
        Please enter the single-use verification code below to proceed:
      </p>

      <!-- 4-Digit OTP Display -->
      <div style="background-color: #E8EEF8; border: 2px solid #1550A6; border-radius: 12px; padding: 16px 24px; text-align: center; margin: 20px auto; max-width: 240px;">
        <span style="font-size: 32px; font-weight: 800; letter-spacing: 10px; color: #1550A6; font-family: 'Courier New', Courier, monospace; display: inline-block; padding-left: 10px;">${values.otp}</span>
      </div>

      <p style="color: #5F6E80; font-size: 13px; margin: 16px 0 0 0;">
        ⏱️ This code is valid for <strong>3 minutes</strong>.
      </p>
    </div>

    <!-- Divider & Security Notice -->
    <div style="border-top: 1px solid #E8EEF8; margin-top: 28px; padding-top: 20px; text-align: center;">
      <p style="color: #90A0B3; font-size: 12px; line-height: 1.4; margin: 0;">
        If you did not request a password reset, please ignore this email. Your account remains secure.
      </p>
    </div>

  </div>

  <!-- Footer -->
  <div style="text-align: center; margin-top: 20px;">
    <p style="color: #90A0B3; font-size: 12px; margin: 0;">
      © ${currentYear} Govia. All rights reserved.
    </p>
  </div>
</body>
</html>`,
  };
  return data;
};

export const emailTemplate = {
  createAccount,
  resetPassword,
};
