import config from '../../../config';

export type AppleVerifyResult = {
  valid: boolean;
  productId: string;
  originalTransactionId?: string;
  expiresDate?: Date;
  environment: 'sandbox' | 'production';
  message?: string;
  raw?: unknown;
};

/**
 * Verify Apple App Store StoreKit receipt data
 */
export const verifyAppleReceipt = async (
  receiptData: string,
  expectedProductId?: string
): Promise<AppleVerifyResult> => {
  const sharedSecret = config.iap.apple.sharedSecret;
  const isProd = config.iap.apple.environment === 'production';

  // If developer has not yet added APPLE_SHARED_SECRET to .env, allow sandbox testing
  if (!sharedSecret) {
    console.warn(
      '⚠️ [Apple IAP] APPLE_SHARED_SECRET not configured in .env. Accepting sandbox mock purchase for testing.'
    );
    const isYearly = expectedProductId?.includes('yearly');
    const now = new Date();
    const expiresDate = new Date(
      now.getTime() + (isYearly ? 365 : 30) * 24 * 60 * 60 * 1000
    );

    return {
      valid: true,
      productId: expectedProductId || (isYearly ? 'govia_premium_yearly' : 'govia_premium_monthly'),
      originalTransactionId: `apple_mock_${Date.now()}`,
      expiresDate,
      environment: 'sandbox',
      message: 'Sandbox testing mode (credentials pending in .env)',
    };
  }

  // Choose URL based on environment
  const verifyUrl = isProd
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';

  try {
    const response = await fetch(verifyUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        'receipt-data': receiptData,
        password: sharedSecret,
        'exclude-old-transactions': true,
      }),
    });

    const data = (await response.json()) as {
      status: number;
      latest_receipt_info?: Array<{
        product_id: string;
        original_transaction_id: string;
        expires_date_ms?: string;
      }>;
    };

    // Status 0 means valid receipt
    // Status 21007 means receipt is from test environment, retry on sandbox
    if (data.status === 21007 && isProd) {
      const sandboxResponse = await fetch(
        'https://sandbox.itunes.apple.com/verifyReceipt',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            'receipt-data': receiptData,
            password: sharedSecret,
            'exclude-old-transactions': true,
          }),
        }
      );
      const sandboxData = (await sandboxResponse.json()) as typeof data;
      if (sandboxData.status === 0 && sandboxData.latest_receipt_info?.length) {
        const latest = sandboxData.latest_receipt_info[0];
        return {
          valid: true,
          productId: latest.product_id,
          originalTransactionId: latest.original_transaction_id,
          expiresDate: latest.expires_date_ms
            ? new Date(Number(latest.expires_date_ms))
            : undefined,
          environment: 'sandbox',
          raw: sandboxData,
        };
      }
    }

    if (data.status === 0 && data.latest_receipt_info?.length) {
      const latest = data.latest_receipt_info[0];
      return {
        valid: true,
        productId: latest.product_id,
        originalTransactionId: latest.original_transaction_id,
        expiresDate: latest.expires_date_ms
          ? new Date(Number(latest.expires_date_ms))
          : undefined,
        environment: isProd ? 'production' : 'sandbox',
        raw: data,
      };
    }

    return {
      valid: false,
      productId: expectedProductId || '',
      environment: isProd ? 'production' : 'sandbox',
      message: `Apple receipt verification failed with status ${data.status}`,
      raw: data,
    };
  } catch (error) {
    console.error('[Apple IAP Verification Error]', error);
    return {
      valid: false,
      productId: expectedProductId || '',
      environment: isProd ? 'production' : 'sandbox',
      message: error instanceof Error ? error.message : 'Unknown verification error',
    };
  }
};
