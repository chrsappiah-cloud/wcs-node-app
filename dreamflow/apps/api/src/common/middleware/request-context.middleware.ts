import { randomUUID } from 'node:crypto';
import { Injectable, Logger, NestMiddleware } from '@nestjs/common';

type RequestLike = {
  method?: string;
  originalUrl?: string;
  url?: string;
  headers?: Record<string, unknown>;
  requestId?: string;
};

type ResponseLike = {
  statusCode?: number;
  setHeader: (name: string, value: string) => void;
  on: (event: 'finish', listener: () => void) => void;
};

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  private readonly logger = new Logger('RequestLogger');

  use(req: RequestLike, res: ResponseLike, next: () => void) {
    const requestIdHeader = req.headers?.['x-request-id'];
    const requestId = typeof requestIdHeader === 'string' ? requestIdHeader : randomUUID();
    req.requestId = requestId;
    res.setHeader('X-Request-Id', requestId);

    const startedAt = Date.now();
    res.on('finish', () => {
      const durationMs = Date.now() - startedAt;
      this.logger.log(
        JSON.stringify({
          requestId,
          method: req.method ?? 'UNKNOWN',
          path: req.originalUrl ?? req.url ?? 'UNKNOWN',
          statusCode: res.statusCode ?? 0,
          durationMs
        })
      );
    });

    next();
  }
}