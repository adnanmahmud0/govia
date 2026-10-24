export const getPrivacyPolicyHtml = (): string => {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Privacy Policy - GoVia</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #1550A6;
      --primary-dark: #0D3775;
      --primary-light: #EFF6FF;
      --accent: #2563EB;
      --text-main: #0F172A;
      --text-muted: #475569;
      --bg-page: #F8FAFC;
      --card-bg: #FFFFFF;
      --border: #E2E8F0;
      --radius: 16px;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg-page);
      color: var(--text-main);
      line-height: 1.65;
      -webkit-font-smoothing: antialiased;
    }

    header {
      background: linear-gradient(135deg, #0F2D6B 0%, #1550A6 100%);
      color: white;
      padding: 60px 24px 50px;
      text-align: center;
      position: relative;
      box-shadow: 0 4px 20px rgba(21, 80, 166, 0.15);
    }

    .brand-container {
      display: inline-flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 20px;
    }

    .brand-logo {
      width: 44px;
      height: 44px;
      background: rgba(255, 255, 255, 0.15);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Outfit', sans-serif;
      font-weight: 800;
      font-size: 22px;
      border: 1px solid rgba(255, 255, 255, 0.3);
    }

    .brand-title {
      font-family: 'Outfit', sans-serif;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }

    header h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 38px;
      font-weight: 700;
      margin-bottom: 12px;
      letter-spacing: -0.5px;
    }

    header p {
      color: rgba(255, 255, 255, 0.85);
      font-size: 15px;
      max-width: 600px;
      margin: 0 auto;
    }

    .effective-badge {
      display: inline-block;
      margin-top: 16px;
      padding: 6px 16px;
      background: rgba(255, 255, 255, 0.15);
      border-radius: 20px;
      font-size: 13px;
      font-weight: 500;
      backdrop-filter: blur(4px);
    }

    .container {
      max-width: 900px;
      margin: -30px auto 60px;
      padding: 0 20px;
      position: relative;
      z-index: 10;
    }

    .card {
      background: var(--card-bg);
      border-radius: var(--radius);
      padding: 40px;
      box-shadow: 0 4px 25px rgba(0, 0, 0, 0.05);
      border: 1px solid var(--border);
    }

    .quick-summary {
      background: var(--primary-light);
      border-left: 4px solid var(--primary);
      padding: 20px 24px;
      border-radius: 8px;
      margin-bottom: 35px;
    }

    .quick-summary h3 {
      font-size: 16px;
      font-weight: 700;
      color: var(--primary);
      margin-bottom: 8px;
    }

    .quick-summary p {
      font-size: 14px;
      color: #334155;
      margin: 0;
    }

    h2 {
      font-family: 'Outfit', sans-serif;
      font-size: 22px;
      font-weight: 700;
      color: var(--text-main);
      margin: 36px 0 16px;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    h2:first-of-type {
      margin-top: 10px;
    }

    .section-num {
      width: 28px;
      height: 28px;
      background: #E0E7FF;
      color: #3730A3;
      border-radius: 50%;
      font-size: 13px;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    p {
      margin-bottom: 16px;
      color: var(--text-muted);
      font-size: 15px;
    }

    ul {
      margin: 12px 0 20px 24px;
      color: var(--text-muted);
      font-size: 15px;
    }

    li {
      margin-bottom: 8px;
    }

    li strong {
      color: var(--text-main);
    }

    .highlight-box {
      background: #F1F5F9;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 18px 20px;
      margin: 20px 0;
    }

    .highlight-box h4 {
      font-size: 14px;
      font-weight: 700;
      color: var(--text-main);
      margin-bottom: 6px;
    }

    .highlight-box p {
      margin: 0;
      font-size: 13.5px;
      color: #475569;
    }

    .contact-box {
      background: #F8FAFC;
      border: 1px dashed var(--border);
      border-radius: 12px;
      padding: 24px;
      text-align: center;
      margin-top: 30px;
    }

    .contact-box a {
      color: var(--primary);
      font-weight: 600;
      text-decoration: none;
    }

    .contact-box a:hover {
      text-decoration: underline;
    }

    footer {
      text-align: center;
      padding: 30px 20px;
      font-size: 13px;
      color: #94A3B8;
      border-top: 1px solid var(--border);
    }

    @media (max-width: 640px) {
      header {
        padding: 40px 16px 40px;
      }
      header h1 {
        font-size: 28px;
      }
      .card {
        padding: 24px 18px;
      }
      h2 {
        font-size: 19px;
      }
    }
  </style>
</head>
<body>

  <header>
    <div class="brand-container">
      <div class="brand-logo">G</div>
      <div class="brand-title">GoVia</div>
    </div>
    <h1>Privacy Policy</h1>
    <p>Your privacy, safety, and data security are our top priorities. Learn how GoVia collects, protects, and handles your information.</p>
    <div class="effective-badge">Effective Date: October 24, 2026</div>
  </header>

  <div class="container">
    <div class="card">
      <div class="quick-summary">
        <h3>🛡️ Quick Privacy Commitment</h3>
        <p>GoVia is designed for roadside safety, emergency legal counsel, and bail bond dispatch. We <strong>never sell your personal data</strong>. Location and media recordings are collected strictly to protect you during active incidents and connect you with your chosen verified practitioners.</p>
      </div>

      <h2><span class="section-num">1</span> Introduction</h2>
      <p>GoVia Inc. ("GoVia", "we", "our", or "us") operates the GoVia mobile application and related web services (collectively, the "Platform"). This Privacy Policy explains our practices regarding the collection, use, disclosure, and protection of information when you access or use our Platform.</p>
      <p>By installing, accessing, or using GoVia, you agree to the collection and use of information in accordance with this Privacy Policy.</p>

      <h2><span class="section-num">2</span> Information We Collect</h2>
      <p>We collect several types of information from and about users of our Platform, including:</p>
      <ul>
        <li><strong>Account Information:</strong> Name, email address, phone number, password, user role (Citizen, Attorney, Bail Bondsman, or Officer), profile picture, and preferred providers.</li>
        <li><strong>Vehicle & Driver Details:</strong> Driver's license number, vehicle make, model, year, and license plate number for fast vehicle verification during roadside assistance.</li>
        <li><strong>Professional Credentials (Providers):</strong> Bar association number, licensed states, law firm or bail agency name, and licensing documentation for verified attorneys and bondsmen.</li>
        <li><strong>Location Information:</strong>
          <ul>
            <li><em>Precise Location:</em> Collected when initiating roadside assistance, emergency encounters, or searching for nearby verified practitioners.</li>
            <li><em>Background Location:</em> If explicitly authorized by you, background location is used exclusively during active emergency encounters or roadside stop events to track and relay your real-time position to your designated legal counsel or emergency contacts.</li>
          </ul>
        </li>
        <li><strong>Encounter Media & Audio Recordings:</strong> Audio recordings, video recordings, and incident logs captured when you activate GoVia encounter monitoring to record roadside events for your legal defense.</li>
        <li><strong>Communications & In-App Messages:</strong> Text chats, status notes, and call records between you and your preferred attorney or bail bondsman.</li>
        <li><strong>Payment & Billing Data:</strong> Payment details (credit card or debit card) processed securely through our third-party payment processor, Stripe. GoVia does not directly store complete credit card numbers on its servers.</li>
      </ul>

      <div class="highlight-box">
        <h4>📍 Location Data Usage Disclosure (Google Play Compliance)</h4>
        <p>GoVia accesses your device's location to determine your immediate physical position during roadside emergencies, calculate proximity to verified legal counsel, and broadcast incident coordinates to your designated emergency contacts. Background location is active solely while an incident monitoring session is active.</p>
      </div>

      <h2><span class="section-num">3</span> How We Use Your Information</h2>
      <p>We use the information we collect for the following essential purposes:</p>
      <ul>
        <li>To connect citizens with designated Preferred Attorneys and Bail Bondsmen during roadside stops or emergencies.</li>
        <li>To securely record, encrypt, and archive roadside incident media for legal counsel representation.</li>
        <li>To verify provider professional credentials, bar status, and state licensing.</li>
        <li>To process platform service charges, retainers, and subscription renewals via Stripe.</li>
        <li>To notify your designated emergency contacts when you trigger an emergency alert.</li>
        <li>To prevent fraudulent activity, unauthorized access, and ensure overall platform security.</li>
      </ul>

      <h2><span class="section-num">4</span> Data Sharing & Disclosure</h2>
      <p>We will not sell, rent, or trade your personal information to third parties. We share information only under these specific circumstances:</p>
      <ul>
        <li><strong>Your Designated Providers:</strong> Incident recordings, location, and account details are shared strictly with the specific Attorney or Bail Bondsman you have selected as your preferred provider.</li>
        <li><strong>Emergency Contacts:</strong> Alert notifications and GPS coordinates are sent to contacts you explicitly designate in your emergency protection network.</li>
        <li><strong>Authorized Service Providers:</strong> Trusted third-party vendors who provide infrastructure, cloud hosting (AWS / DigitalOcean), mapping services, real-time messaging, and payment processing (Stripe). These providers are bound by strict contractual data protection obligations.</li>
        <li><strong>Legal Compliance:</strong> We may disclose information if required by a valid court order, subpoena, or applicable state and federal law, or to protect the safety and rights of users.</li>
      </ul>

      <h2><span class="section-num">5</span> Data Security & Storage</h2>
      <p>We implement industry-standard technical and organizational security measures to protect your personal data:</p>
      <ul>
        <li><strong>Encryption in Transit:</strong> All communications between the GoVia mobile app and our servers use TLS 1.3 encryption (HTTPS / WSS).</li>
        <li><strong>Encryption at Rest:</strong> Encrypted databases and private media storage buckets ensure incident recordings remain strictly confidential.</li>
        <li><strong>Role-Based Access Controls:</strong> Strict access permissions ensure only authorized users can view your designated emergency information.</li>
      </ul>

      <h2><span class="section-num">6</span> Data Retention & Account Deletion</h2>
      <p>We retain your personal information for as long as your account is active or as necessary to fulfill the purposes outlined in this policy.</p>
      <div class="highlight-box">
        <h4>🗑️ Account & Data Deletion Request (Google Play Compliance)</h4>
        <p>You have the absolute right to delete your account and all associated personal data at any time. You can initiate account deletion directly in the GoVia mobile app under <strong>Profile &rarr; Account Settings &rarr; Delete Account</strong>, or by emailing us at <a href="mailto:support@govia.app" style="color:#1550A6;font-weight:600;">support@govia.app</a>. Upon request, all profile details and incident recordings will be permanently purged within 30 days, except where retention is mandated by law.</p>
      </div>

      <h2><span class="section-num">7</span> Children's Privacy</h2>
      <p>GoVia is not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If we discover that a user under 18 has registered or provided personal data, we will immediately take steps to terminate the account and delete the information.</p>

      <h2><span class="section-num">8</span> Changes to This Privacy Policy</h2>
      <p>We may update this Privacy Policy from time to time to reflect changes in our services or legal obligations. We will notify you of any material changes by posting the new Privacy Policy on this page and updating the "Effective Date" at the top.</p>

      <h2><span class="section-num">9</span> Contact Us</h2>
      <p>If you have any questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact our privacy compliance team:</p>

      <div class="contact-box">
        <p><strong>GoVia Inc. - Privacy & Legal Compliance</strong></p>
        <p>Email: <a href="mailto:privacy@govia.app">privacy@govia.app</a> or <a href="mailto:support@govia.app">support@govia.app</a></p>
        <p>Website: <a href="https://api.govia.app" target="_blank">https://api.govia.app</a></p>
      </div>
    </div>
  </div>

  <footer>
    &copy; 2026 GoVia Inc. All rights reserved. • <a href="/terms-of-service" style="color:#94A3B8;text-decoration:none;">Terms of Service</a>
  </footer>

</body>
</html>`;
};
