/**
 * =====================================================================
 * AGARAM - Tamil Children's Educational Platform Backend API
 * Node.js + Express.js + MySQL REST API
 * =====================================================================
 */
const path = require('path');
const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');

const config = require('./src/config/env');
const corsOptions = require('./src/config/cors');
const { testConnection } = require('./src/config/db');
const apiV1Router = require('./src/routes');
const { notFoundHandler, globalErrorHandler } = require('./src/middleware/errorMiddleware');
const { successResponse } = require('./src/utils/apiResponse');
const logger = require('./src/utils/logger');

const app = express();

// Security Headers
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // Allows mobile apps & web admin to load uploaded media
}));

// CORS Configuration
app.use(cors(corsOptions));

// HTTP Request Logger
if (config.env !== 'test') {
  app.use(morgan('dev'));
}

// Body Parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static Media Serving for Uploaded Images, Audio, and Video files, plus default assets
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/assets', express.static(path.join(__dirname, '../frontend/assets')));
app.use('/assets', express.static(path.join(__dirname, '../assets')));

// ---------------------------------------------------------------------
// Health Check Endpoint
// ---------------------------------------------------------------------
app.get('/api/health', (req, res) => {
  return successResponse(res, 'AGARAM API is healthy', {
    service: 'agaram-backend',
    version: '1.0.0',
    uptime: `${Math.floor(process.uptime())}s`,
    timestamp: new Date().toISOString(),
  });
});

// Root friendly welcome endpoint
app.get('/', (req, res) => {
  return successResponse(res, 'Welcome to AGARAM Tamil Educational Platform API', {
    healthCheck: '/api/health',
    apiDocs: '/api/v1',
  });
});

// Privacy Policy Endpoint for Google OAuth & Play Store
app.get('/privacy-policy', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="ta">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy - எழுத்துக்கள் (Eluthukkal)</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #2B2D42; background: #FBF8F3; }
    h1 { color: #FF9F1C; }
    h2 { color: #2EC4B6; margin-top: 24px; }
    .card { background: white; padding: 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
  </style>
</head>
<body>
  <div class="card">
    <h1>Privacy Policy — எழுத்துக்கள் (Eluthukkal)</h1>
    <p><strong>Last updated:</strong> November 2026</p>
    <p>Welcome to <strong>எழுத்துக்கள் (Eluthukkal)</strong>, a kid-friendly educational application designed to learn the Tamil language.</p>
    
    <h2>1. Information We Collect</h2>
    <p>When you use Google Sign-In, we only collect your basic public profile information:</p>
    <ul>
      <li>Full Name (displayed as the child/learner's profile name)</li>
      <li>Email address (used as unique identifier for account synchronization)</li>
      <li>Profile photo (optional, used as your profile avatar)</li>
    </ul>

    <h2>2. How We Use Information</h2>
    <p>Your information is used strictly to authenticate you, synchronize learning stars, progress, and quizzes across your devices. We do not sell or share personal data with third-party advertisers.</p>

    <h2>3. Data Security & Retention</h2>
    <p>We use industry-standard encryption and security measures to protect your account information.</p>

    <h2>4. Contact Us</h2>
    <p>If you have any questions or privacy concerns, please contact our support team at: <strong>selvamalathi36@gmail.com</strong></p>
  </div>
</body>
</html>`);
});

// Terms of Service Endpoint
app.get('/terms', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="ta">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Terms of Service - எழுத்துக்கள் (Eluthukkal)</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #2B2D42; background: #FBF8F3; }
    h1 { color: #FF9F1C; }
    .card { background: white; padding: 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
  </style>
</head>
<body>
  <div class="card">
    <h1>Terms of Service — எழுத்துக்கள் (Eluthukkal)</h1>
    <p>By using the Eluthukkal educational platform, you agree to these terms. This app is designed for educational learning of the Tamil language.</p>
    <p>For questions, contact: <strong>selvamalathi36@gmail.com</strong></p>
  </div>
</body>
</html>`);
});

// ---------------------------------------------------------------------
// API Routes (Version 1: /api/v1)
// ---------------------------------------------------------------------
app.use(config.apiPrefix, apiV1Router);

// ---------------------------------------------------------------------
// Error Handling
// ---------------------------------------------------------------------
app.use(notFoundHandler);
app.use(globalErrorHandler);

// ---------------------------------------------------------------------
// Server Initialization
// ---------------------------------------------------------------------
const PORT = config.port;

async function startServer() {
  // Test MySQL connection
  await testConnection();

  const server = app.listen(PORT, () => {
    logger.info(`====================================================`);
    logger.info(`🌟 AGARAM Backend Server running on port ${PORT}`);
    logger.info(`🌐 Environment: ${config.env}`);
    logger.info(`🩺 Health check: http://localhost:${PORT}/api/health`);
    logger.info(`📚 API Base: http://localhost:${PORT}${config.apiPrefix}`);
    logger.info(`====================================================`);
  });

  // Graceful Shutdown
  const shutdown = () => {
    logger.info('🛑 Shutting down AGARAM server gracefully...');
    server.close(() => {
      logger.info('💤 Server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

  return server;
}

if (require.main === module) {
  startServer();
}

module.exports = { app, startServer };
