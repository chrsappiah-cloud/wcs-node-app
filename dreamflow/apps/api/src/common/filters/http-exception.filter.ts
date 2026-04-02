import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger
} from '@nestjs/common';

type RequestWithId = { requestId?: string };
type ResponseLike = { status(code: number): { json(body: unknown): void } };

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const req = ctx.getRequest<RequestWithId>();
    const res = ctx.getResponse<ResponseLike>();

    const status =
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;

    const raw =
      exception instanceof HttpException ? exception.getResponse() : 'Internal server error';

    const base: Record<string, unknown> =
      typeof raw === 'object' && raw !== null
        ? { ...(raw as Record<string, unknown>) }
        : { message: raw };

    base.requestId = req.requestId;

    if (status >= 500) {
      this.logger.error(
        exception instanceof Error ? exception.message : String(exception),
        exception instanceof Error ? exception.stack : undefined
      );
    }

    res.status(status).json(base);
  }
}
