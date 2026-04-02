import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Module,
  Param,
  ParseIntPipe,
  Post,
  Query,
  BadRequestException,
  UseInterceptors,
  NestInterceptor,
  ExecutionContext,
  Injectable,
  CallHandler,
  Logger,
  OnModuleDestroy
} from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { Observable } from 'rxjs';
import { Queue } from 'bullmq';
import { ArrayMaxSize, ArrayNotEmpty, IsArray, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { PresenceService } from './presence/presence.service';
import { Roles } from '../common/auth/roles.decorator';
import { USER_ROLES } from '../common/auth/roles.constants';

class LocationPingDto {
  @IsString()
  userId!: string;

  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;

  @IsNumber()
  @Min(0)
  accuracy!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  speed?: number;
}

class BatchPresenceDto {
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(100)
  userIds!: string[];
}

function isFiniteCoordinate(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

@Injectable()
class PresenceInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const start = Date.now();
    return next.handle();
  }
}

@Controller('presence')
@UseInterceptors(PresenceInterceptor)
@ApiTags('presence')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Missing or invalid auth credentials.' })
@ApiForbiddenResponse({ description: 'Authenticated user lacks required role.' })
class PresenceController {
  constructor(private presenceService: PresenceService) {}

  @Post('location')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  async ingestLocation(@Body() dto: LocationPingDto) {
    if (!dto.userId || !isFiniteCoordinate(dto.lat) || !isFiniteCoordinate(dto.lng)) {
      throw new BadRequestException('userId, lat, and lng are required');
    }

    if (dto.accuracy !== undefined && (!isFiniteCoordinate(dto.accuracy) || dto.accuracy < 0)) {
      throw new BadRequestException('accuracy must be a finite non-negative number');
    }

    if (dto.speed !== undefined && (!isFiniteCoordinate(dto.speed) || dto.speed < 0)) {
      throw new BadRequestException('speed must be a finite non-negative number');
    }

    const event = await this.presenceService.ingestLocation(
      dto.userId,
      dto.lat,
      dto.lng,
      dto.accuracy || 0,
      dto.speed
    );

    return { accepted: true, event, timestamp: new Date().toISOString() };
  }

  @Get('user/:userId')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getPresence(@Param('userId') userId: string) {
    const presence = this.presenceService.getPresence(userId);
    if (!presence) {
      return { userId, lastLocation: null, isActive: false };
    }
    return presence;
  }

  @Get('user/:userId/history')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getLocationHistory(
    @Param('userId') userId: string,
    @Query('limit', new DefaultValuePipe(50), new ParseIntPipe()) limit: number
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('limit must be between 1 and 100');
    }
    const limitNumber = limit;
    const history = this.presenceService.getLocationHistory(userId, limitNumber);
    return { userId, history, count: history.length };
  }

  @Post('batch')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  async getBatchPresence(@Body() dto: BatchPresenceDto) {
    if (!Array.isArray(dto.userIds)) {
      throw new BadRequestException('userIds must be an array');
    }
    const presenceMap = this.presenceService.getBatchPresence(dto.userIds);
    return Object.fromEntries(presenceMap);
  }

  @Post('cleanup')
  @Roles(USER_ROLES.ADMIN)
  cleanupStalePresence(
    @Query('staleAfterMs', new DefaultValuePipe(300000), new ParseIntPipe()) staleMs: number
  ) {
    if (staleMs < 1000) {
      throw new BadRequestException('staleAfterMs must be at least 1000 ms');
    }
    const staleUserIds = this.presenceService.clearStalePresence(staleMs);
    return {
      cleared: staleUserIds.length,
      userIds: staleUserIds
    };
  }
}

@Module({
  controllers: [PresenceController],
  providers: [PresenceService],
  exports: [PresenceService]
})
export class PresenceModule implements OnModuleDestroy {
  private readonly logger = new Logger(PresenceModule.name);
  private geofenceQueue: Queue | null = null;
  private presenceQueue: Queue | null = null;

  constructor(private presenceService: PresenceService) {
    if (process.env.DISABLE_REDIS === 'true') {
      this.logger.warn('Redis disabled; presence queue publishing is skipped.');
      return;
    }

    const connection = {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10)
    };

    this.geofenceQueue = new Queue('geofence', { connection });
    this.presenceQueue = new Queue('presence', { connection });
    this.presenceService.setQueues(this.geofenceQueue, this.presenceQueue);
  }

  async onModuleDestroy() {
    await Promise.all([this.geofenceQueue?.close(), this.presenceQueue?.close()]);
  }
}
