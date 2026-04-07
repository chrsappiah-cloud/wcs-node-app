/*
 * GeoWCS NestJS API - Bootstrap
 * 
 * Copyright © 2026 World Class Scholars. All rights reserved.
 * Developed under the leadership of Dr. Christopher Appiah-Thompson
 * 
 * Enterprise-grade real-time safety platform backend.
 */

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import * as fs from 'fs';
import { AppModule } from './app.module';
import * as helmet from 'helmet';
import rateLimit from 'express-rate-limit';

const expressRuntime = require('express') as {
  json: (options: { limit: string }) => unknown;
  urlencoded: (options: { extended: boolean; limit: string }) => unknown;
};

type SecurityHeaderResponse = {
  setHeader: (name: string, value: string) => void;
};

const LOG_FILE_PATH = 'logs/app.log';
function logToFile(message: string) {
  fs.mkdirSync('logs', { recursive: true });
  fs.appendFileSync(LOG_FILE_PATH, message + '\n');
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');
  // Patch logger to also write to file
  const origLog = logger.log.bind(logger);
  logger.log = (msg) => {
    origLog(msg);
    logToFile(`[LOG] ${msg}`);
  };
  const origError = logger.error.bind(logger);
  logger.error = (msg, trace) => {
    origError(msg, trace);
    logToFile(`[ERROR] ${msg}${trace ? ' ' + trace : ''}`);
  };
  const bodyLimit = process.env.API_BODY_LIMIT || '8mb';
  const isProduction = process.env.NODE_ENV === 'production';

  // Body size limits
  app.use(expressRuntime.json({ limit: bodyLimit }));
  app.use(expressRuntime.urlencoded({ extended: false, limit: bodyLimit }));

  // Helmet security headers with enhanced CSP
  app.use(helmet.default({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'", process.env.CORS_ORIGIN || '*'],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    hsts: {
      maxAge: isProduction ? 31536000 : 3600, // 1 year in production
      includeSubDomains: true,
      preload: isProduction,
    },
    referrerPolicy: { policy: 'no-referrer' },
  }));

  // Rate limiting
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req: any) => !isProduction, // Skip rate limiting in development
  });
  app.use('/v1/', limiter);

  // Additional security headers
  app.use((_req: unknown, res: SecurityHeaderResponse, next: () => void) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', isProduction ? 'max-age=31536000; includeSubDomains; preload' : 'max-age=3600');
    res.setHeader('X-DNS-Prefetch-Control', 'off');
    res.setHeader('X-Permitted-Cross-Domain-Policies', 'none');
    next();
  });

  // CORS with restricted origins
  const corsOrigins = process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',').map(origin => origin.trim())
    : isProduction 
      ? [] // Deny all in production if not explicitly configured
      : [/^http:\/\/localhost:\d+$/, /^http:\/\/127\.0\.0\.1:\d+$/]; // Allow localhost in dev

  app.enableCors({
    origin: corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    maxAge: 3600,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true
      },
      skipMissingProperties: false,
      skipNullProperties: false,
    })
  );

  app.setGlobalPrefix('v1');

  const port = parseInt(process.env.PORT || '3000', 10);
  await app.listen(port, () => {
    logger.log(`🚀 Server running on port ${port}`);
    logger.log(`📋 Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.log(`🔒 CORS Origins: ${Array.isArray(corsOrigins) ? corsOrigins.join(', ') : 'dynamic'}`);
  });
}

bootstrap().catch(err => {
  logToFile('❌ Bootstrap error: ' + err);
  console.error('❌ Bootstrap error:', err);
  process.exit(1);
});
