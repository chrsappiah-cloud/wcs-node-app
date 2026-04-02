import { MiddlewareConsumer, Module, NestModule, RequestMethod } from '@nestjs/common';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { HealthModule } from './modules/health.module';
import { CirclesModule } from './modules/circles.module';
import { PresenceModule } from './modules/presence.module';
import { AlertsModule } from './modules/alerts.module';
import { AuthModule } from './modules/auth/auth.module';
import { RequestContextMiddleware } from './common/middleware/request-context.middleware';
import { AuthMiddleware } from './common/middleware/auth.middleware';
import { RolesGuard } from './common/auth/roles.guard';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

@Module({
  providers: [
    { provide: APP_FILTER, useClass: HttpExceptionFilter },
    {
      provide: APP_GUARD,
      useClass: RolesGuard
    }
  ],
  imports: [
    ThrottlerModule.forRoot({
      throttlers: [{ ttl: 60000, limit: 120 }]
    }),
    HealthModule,
    CirclesModule,
    PresenceModule,
    AlertsModule,
    AuthModule
  ]
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestContextMiddleware).forRoutes({ path: '*', method: RequestMethod.ALL });
    consumer.apply(AuthMiddleware).forRoutes({ path: '*', method: RequestMethod.ALL });
  }
}
