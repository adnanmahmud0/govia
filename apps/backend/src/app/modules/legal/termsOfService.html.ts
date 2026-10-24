export const getTermsOfServiceHtml = (): string => {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Terms of Service - GoVia</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #1550A6;
      --text-main: #0F172A;
      --text-muted: #475569;
      --bg-page: #F8FAFC;
      --card-bg: #FFFFFF;
      --border: #E2E8F0;
      --radius: 16px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, sans-serif;
      background-color: var(--bg-page);
      color: var(--text-main);
      line-height: 1.65;
    }
    header {
      background: linear-gradient(135deg, #0F2D6B 0%, #1550A6 100%);
      color: white;
      padding: 50px 20px;
      text-align: center;
    }
    header h1 { font-family: 'Outfit', sans-serif; font-size: 32px; font-weight: 700; margin-bottom: 8px; }
    header p { color: rgba(255, 255, 255, 0.85); font-size: 14px; }
    .container { max-width: 860px; margin: -25px auto 60px; padding: 0 20px; }
    .card { background: var(--card-bg); border-radius: var(--radius); padding: 36px; border: 1px solid var(--border); box-shadow: 0 4px 20px rgba(0,0,0,0.04); }
    h2 { font-family: 'Outfit', sans-serif; font-size: 20px; margin: 28px 0 12px; color: var(--text-main); }
    p, li { color: var(--text-muted); font-size: 15px; margin-bottom: 12px; }
    ul { margin: 10px 0 16px 20px; }
    footer { text-align: center; padding: 30px; font-size: 13px; color: #94A3B8; }
  </style>
</head>
<body>
  <header>
    <h1>GoVia Terms of Service</h1>
    <p>Effective Date: October 24, 2026</p>
  </header>
  <div class="container">
    <div class="card">
      <h2>1. Agreement to Terms</h2>
      <p>By downloading, accessing, or using GoVia, you agree to be bound by these Terms of Service. If you do not agree, do not use the Platform.</p>

      <h2>2. Description of Services</h2>
      <p>GoVia is an emergency communication and roadside legal protection network that enables motorists and citizens to designate preferred attorneys and licensed bail bond agents, initiate encounter recording, and contact emergency networks.</p>

      <h2>3. Legal Advice Disclaimer</h2>
      <p>GoVia is a technology platform connecting users with independent licensed attorneys and bail bond agents. GoVia itself does not provide legal advice or act as a law firm. An attorney-client relationship is formed exclusively between the user and the designated legal counsel.</p>

      <h2>4. User Conduct & Responsibilities</h2>
      <p>You agree to provide accurate registration information and not use the service for unlawful purposes, deceptive claims, or to interfere with emergency law enforcement operations.</p>

      <h2>5. Subscription & Service Fees</h2>
      <p>Platform service charges grant priority coverage and dispatch functionality. Fees are billed on a 30-day recurring basis via Stripe and may be cancelled at any time through account settings.</p>

      <h2>6. Contact Us</h2>
      <p>For questions regarding these Terms, contact us at <a href="mailto:support@govia.app" style="color:#1550A6;">support@govia.app</a>.</p>
    </div>
  </div>
  <footer>
    &copy; 2026 GoVia Inc. • <a href="/privacy-policy" style="color:#1550A6;">Privacy Policy</a>
  </footer>
</body>
</html>`;
};
