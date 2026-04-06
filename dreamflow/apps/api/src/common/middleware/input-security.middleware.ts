import { Injectable, NestMiddleware } from '@nestjs/common';

type RequestLike = {
  method?: string;
  originalUrl?: string;
  url?: string;
  headers?: Record<string, unknown>;
  body?: unknown;
  requestId?: string;
};

type ResponseLike = {
  status: (code: number) => ResponseLike;
  json: (body: unknown) => void;
};

@Injectable()
export class InputSecurityMiddleware implements NestMiddleware {
  private readonly maxContentLengthBytes = parseInt(
    process.env.API_MAX_CONTENT_LENGTH_BYTES || `${8 * 1024 * 1024}`,
    10
  );

  private isMutationMethod(method: string): boolean {
    return method === 'POST' || method === 'PUT' || method === 'PATCH';
  }

  private hasUnsafeKey(value: unknown, depth = 0): boolean {
    if (depth > 20) return true;
    if (!value || typeof value !== 'object') return false;

    if (Array.isArray(value)) {
      return value.some(item => this.hasUnsafeKey(item, depth + 1));
    }

    const obj = value as Record<string, unknown>;
    for (const key of Object.keys(obj)) {
      if (key === '__proto__' || key === 'constructor' || key === 'prototype') {
        return true;
      }
      if (this.hasUnsafeKey(obj[key], depth + 1)) {
        return true;
      }
    }

    return false;
  }

  use(req: RequestLike, res: ResponseLike, next: () => void) {
    const method = (req.method || 'GET').toUpperCase();
    if (!this.isMutationMethod(method)) {
      next();
      return;
    }

    const contentLengthHeader = req.headers?.['content-length'];
    const contentLength =
      typeof contentLengthHeader === 'string' ? parseInt(contentLengthHeader, 10) : 0;

    const requestBodyLooksPresent =
      (Number.isFinite(contentLength) && contentLength > 0) ||
      (typeof req.body === 'object' && req.body !== null);

    const contentType = req.headers?.['content-type'];
    const contentTypeValue = typeof contentType === 'string' ? contentType.toLowerCase() : '';
    if (requestBodyLooksPresent && !contentTypeValue.includes('application/json')) {
      res.status(415).json({
        message: 'Only application/json payloads are supported',
        requestId: req.requestId
      });
      return;
    }

    if (Number.isFinite(contentLength) && contentLength > this.maxContentLengthBytes) {
      res.status(413).json({
        message: 'Payload too large',
        requestId: req.requestId
      });
      return;
    }

    if (this.hasUnsafeKey(req.body)) {
      res.status(400).json({
        message: 'Payload contains unsafe object keys',
        requestId: req.requestId
      });
      return;
    }

    next();
  }
}
