import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { ProviderPaymentService } from './providerPayment.service';

const updatePricingProfile = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await ProviderPaymentService.updatePricingProfile(userId, req.body);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Service pricing profile updated successfully.',
    data: result,
  });
});

const createPayoutOnboard = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const returnUrl = req.body?.returnUrl as string | undefined;
  const result = await ProviderPaymentService.createStripeExpressAccount(userId, returnUrl);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Stripe Express onboarding link generated.',
    data: result,
  });
});

const getPayoutStatus = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await ProviderPaymentService.getStripeAccountStatus(userId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Stripe account status retrieved.',
    data: result,
  });
});

const getPayoutDashboardLink = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await ProviderPaymentService.getStripeDashboardLink(userId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Stripe dashboard login link generated.',
    data: result,
  });
});

const getProviderDirectory = catchAsync(async (req: Request, res: Response) => {
  const result = await ProviderPaymentService.getProviderDirectory(req.query);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Provider directory retrieved.',
    pagination: result.meta,
    data: result.data,
  });
});

const createCheckoutSession = catchAsync(async (req: Request, res: Response) => {
  const citizenId = req.user.id;
  const result = await ProviderPaymentService.createCheckoutSession(citizenId, req.body);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Checkout session created.',
    data: result,
  });
});

const verifySession = catchAsync(async (req: Request, res: Response) => {
  const sessionId = req.params.sessionId || (req.query.sessionId as string);
  const citizenId = (req.query.citizenId as string) || req.user?.id;

  const result = await ProviderPaymentService.verifyAndActivateSession(citizenId, sessionId);

  // If request accepts HTML (e.g. redirected from Stripe in WebView browser), send friendly confirmation page
  if (req.accepts('html')) {
    res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>GoVia Payment Complete</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #0F172A; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; text-align: center; }
            .card { background: #1E293B; padding: 32px 24px; border-radius: 20px; max-width: 400px; width: 100%; border: 1px solid #334155; }
            .icon { width: 64px; height: 64px; border-radius: 50%; background: #10B981; color: white; display: flex; align-items: center; justify-content: center; font-size: 32px; margin: 0 auto 16px; }
            h2 { margin: 0 0 8px; font-size: 22px; }
            p { color: #94A3B8; font-size: 14px; line-height: 1.5; margin: 0 0 24px; }
            .badge { display: inline-block; background: #0F172A; color: #38BDF8; padding: 6px 14px; border-radius: 12px; font-weight: 600; font-size: 13px; margin-bottom: 20px; }
            .btn { background: #1550A6; color: white; border: none; padding: 12px 24px; border-radius: 12px; font-size: 15px; font-weight: 600; cursor: pointer; text-decoration: none; display: block; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✓</div>
            <h2>Service Activated!</h2>
            <div class="badge">GoVia 24/7 Coverage Active</div>
            <p>Your preferred provider has been successfully linked to your profile with 30-day emergency priority dispatch.</p>
            <a class="btn" href="govia://payment-complete">Return to GoVia App</a>
          </div>
        </body>
      </html>
    `);
    return;
  }

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: result.message,
    data: result,
  });
});

const handleWebhook = async (req: Request & { rawBody?: string }, res: Response) => {
  const signature = req.headers['stripe-signature'] as string;
  const rawBody = req.rawBody || JSON.stringify(req.body);
  const result = await ProviderPaymentService.handleStripeWebhook(signature, rawBody);
  res.status(StatusCodes.OK).json(result);
};

const getCommission = catchAsync(async (req: Request, res: Response) => {
  const result = await ProviderPaymentService.getCommissionSetting();

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Commission setting retrieved.',
    data: result,
  });
});

const updateCommission = catchAsync(async (req: Request, res: Response) => {
  const adminId = req.user.id;
  const percent = Number(req.body.platformCommissionPercent);
  const result = await ProviderPaymentService.updateCommissionSetting(percent, adminId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Commission setting updated successfully.',
    data: result,
  });
});

const getTransactions = catchAsync(async (req: Request, res: Response) => {
  const result = await ProviderPaymentService.getTransactions(req.query);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Transactions retrieved.',
    pagination: result.meta,
    data: result.data,
  });
});

export const ProviderPaymentController = {
  updatePricingProfile,
  createPayoutOnboard,
  getPayoutStatus,
  getPayoutDashboardLink,
  getProviderDirectory,
  createCheckoutSession,
  verifySession,
  handleWebhook,
  getCommission,
  updateCommission,
  getTransactions,
};
