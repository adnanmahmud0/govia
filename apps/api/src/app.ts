import cors from 'cors';
import express, { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import { isOriginAllowed } from './app/logging/cors';
import globalErrorHandler from './app/middlewares/globalErrorHandler';
import { DocsRoutes } from './docs/docs.router';
import router, { V1Routes } from './routes';
import { Morgan } from './shared/morgen';

const app = express();

// Morgan HTTP request logging (piped to Winston)
app.use(Morgan.successHandler);
app.use(Morgan.errorHandler);

// CORS configuration supporting web dashboards, Flutter mobile app, and API clients
app.use(
  cors({
    origin: (origin, callback) => {
      if (isOriginAllowed(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    credentials: true,
  })
);

// Body parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// File retrieve
app.use(express.static('uploads'));
app.use('/uploads', express.static('uploads'));

// API Documentation (OpenAPI 3.0 & Swagger UI)
app.use('/api', DocsRoutes);
app.use('/api/v1', DocsRoutes);

// Versioned API Routes (/api/v1/* and /api/*)
app.use('/api', router);
app.use('/api/v1', V1Routes);

// Live server status screen (Matrix animation)
app.get('/', (_req: Request, res: Response) => {
  res.send(
    `<!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title>Govia API - Server Status</title>
      <style>
        body {
          margin: 0;
          padding: 0;
          overflow: hidden;
          background: #0d1117;
          font-family: monospace;
        }
        canvas {
          display: block;
        }
        .center-container {
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          text-align: center;
          color: #38ef7d;
          background: rgba(13, 17, 23, 0.85);
          padding: 30px 50px;
          border-radius: 16px;
          border: 1px solid rgba(56, 239, 125, 0.3);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
        }
        .server-message {
          font-size: 2.4rem;
          font-weight: bold;
          text-shadow: 0 0 10px #38ef7d, 0 0 20px #38ef7d;
        }
        .date-time {
          margin-top: 15px;
          font-size: 1.1rem;
          color: #a8b3cf;
        }
        .docs-link {
          margin-top: 20px;
          display: inline-block;
          padding: 10px 24px;
          background: #11998e;
          background: linear-gradient(to right, #38ef7d, #11998e);
          color: #0d1117;
          font-weight: 700;
          text-decoration: none;
          border-radius: 8px;
          transition: transform 0.2s ease;
        }
        .docs-link:hover {
          transform: scale(1.05);
        }
      </style>
    </head>
    <body>
      <canvas id="matrixCanvas"></canvas>
      <div class="center-container">
        <div class="server-message">🚀 Govia API is Live</div>
        <div class="date-time" id="dateTime"></div>
        <a class="docs-link" href="/api/v1/docs">📖 Explore Swagger API Docs</a>
      </div>

      <script>
        const canvas = document.getElementById("matrixCanvas");
        const ctx = canvas.getContext("2d");

        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        const letters = "GOVIA-0123456789-API-SERVICES-CONNECTED".split("");
        const fontSize = 16;
        const columns = Math.floor(canvas.width / fontSize);
        const drops = Array(columns).fill(1);

        function draw() {
          ctx.fillStyle = "rgba(13, 17, 23, 0.08)";
          ctx.fillRect(0, 0, canvas.width, canvas.height);

          ctx.fillStyle = "#11998e";
          ctx.font = fontSize + "px monospace";

          for (let i = 0; i < drops.length; i++) {
            const text = letters[Math.floor(Math.random() * letters.length)];
            ctx.fillText(text, i * fontSize, drops[i] * fontSize);
            drops[i]++;
            if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
              drops[i] = 0;
            }
          }
        }

        setInterval(draw, 35);

        function updateDateTime() {
          const now = new Date();
          document.getElementById("dateTime").textContent = now.toUTCString();
        }
        setInterval(updateDateTime, 1000);
        updateDateTime();

        window.addEventListener("resize", () => {
          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;
        });
      </script>
    </body>
    </html>`
  );
});

// Global error handler
app.use(globalErrorHandler);

// Handle 404 not found
app.use((req, res) => {
  res.status(StatusCodes.NOT_FOUND).json({
    success: false,
    message: 'Not found',
    errorMessages: [
      {
        path: req.originalUrl,
        message: "API DOESN'T EXIST",
      },
    ],
  });
});

export default app;
