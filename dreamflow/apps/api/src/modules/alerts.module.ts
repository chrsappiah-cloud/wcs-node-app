import {
  Body,
  Controller,
  Delete,
  DefaultValuePipe,
  Get,
  Module,
  Param,
  ParseIntPipe,
  Post,
  Query,
  BadRequestException,
  Logger,
  OnModuleDestroy
} from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { Queue } from 'bullmq';
import { IsIn, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';
import { AlertsService } from './alerts/alerts.service';
import { Roles } from '../common/auth/roles.decorator';
import { USER_ROLES } from '../common/auth/roles.constants';

class SosDto {
  @IsString()
  userId!: string;

  @IsString()
  circleId!: string;

  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;
}

class CreateAlertDto {
  @IsString()
  circleId!: string;

  @IsString()
  userId!: string;

  @IsIn(['arrival', 'departure', 'sos', 'low_battery', 'device_offline', 'inactivity'])
  type!: 'arrival' | 'departure' | 'sos' | 'low_battery' | 'device_offline' | 'inactivity';

  @IsString()
  @MaxLength(500)
  message!: string;

  @IsOptional()
  @IsString()
  geofenceId?: string;
}

function isFiniteCoordinate(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

@Controller('alerts')
@ApiTags('alerts')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Missing or invalid auth credentials.' })
@ApiForbiddenResponse({ description: 'Authenticated user lacks required role.' })
class AlertsController {
  constructor(private alertsService: AlertsService) {}

  @Post('sos')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  async triggerSos(@Body() dto: SosDto) {
    if (!dto.userId || !dto.circleId) {
      throw new BadRequestException('userId and circleId are required');
    }

    if (!isFiniteCoordinate(dto.lat) || !isFiniteCoordinate(dto.lng)) {
      throw new BadRequestException('lat and lng must be finite numbers');
    }
    
    const alert = await this.alertsService.createAlert(
      dto.circleId,
      dto.userId,
      'sos',
      `SOS triggered at (${dto.lat}, ${dto.lng})`,
      undefined
    );

    return { accepted: true, type: 'sos', alert };
  }

  @Post()
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  async create(@Body() dto: CreateAlertDto) {
    const alert = await this.alertsService.createAlert(
      dto.circleId,
      dto.userId,
      dto.type,
      dto.message,
      dto.geofenceId
    );

    return alert;
  }

  @Get(':id')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getAlert(@Param('id') id: string) {
    const alert = this.alertsService.getAlert(id);
    if (!alert) {
      throw new BadRequestException(`Alert ${id} not found`);
    }
    return alert;
  }

  @Get('circle/:circleId')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getCircleAlerts(
    @Param('circleId') circleId: string,
    @Query('limit', new DefaultValuePipe(50), new ParseIntPipe()) limit: number
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('limit must be between 1 and 100');
    }
    const limitNumber = limit;
    const alerts = this.alertsService.getCircleAlerts(circleId, limitNumber);
    return { circleId, alerts, count: alerts.length };
  }

  @Get('user/:userId')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getUserAlerts(
    @Param('userId') userId: string,
    @Query('limit', new DefaultValuePipe(50), new ParseIntPipe()) limit: number
  ) {
    if (limit < 1 || limit > 100) {
      throw new BadRequestException('limit must be between 1 and 100');
    }
    const limitNumber = limit;
    const alerts = this.alertsService.getUserAlerts(userId, limitNumber);
    return { userId, alerts, count: alerts.length };
  }

  @Post(':id/acknowledge')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  acknowledgeAlert(@Param('id') id: string) {
    const alert = this.alertsService.acknowledgeAlert(id);
    if (!alert) {
      throw new BadRequestException(`Alert ${id} not found`);
    }
    return alert;
  }

  @Post(':id/resolve')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  resolveAlert(@Param('id') id: string) {
    const alert = this.alertsService.resolveAlert(id);
    if (!alert) {
      throw new BadRequestException(`Alert ${id} not found`);
    }
    return alert;
  }

  @Get('circle/:circleId/unresolved')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getUnresolvedAlerts(@Param('circleId') circleId: string) {
    const alerts = this.alertsService.getUnresolvedAlerts(circleId);
    return { circleId, unresolved: alerts, count: alerts.length };
  }

  @Get('circle/:circleId/recent')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getRecentAlerts(
    @Param('circleId') circleId: string,
    @Query('minutes', new DefaultValuePipe(60), new ParseIntPipe()) minutes: number
  ) {
    if (minutes < 1 || minutes > 1440) {
      throw new BadRequestException('minutes must be between 1 and 1440');
    }
    const minutesNumber = minutes;
    const alerts = this.alertsService.getRecentAlerts(circleId, minutesNumber);
    return { circleId, recent: alerts, count: alerts.length, minutes: minutesNumber };
  }
}

@Module({
  controllers: [AlertsController],
  providers: [AlertsService],
  exports: [AlertsService]
})
export class AlertsModule implements OnModuleDestroy {
  private readonly logger = new Logger(AlertsModule.name);
  private notificationQueue: Queue | null = null;

  constructor(private alertsService: AlertsService) {
    if (process.env.DISABLE_REDIS === 'true') {
      this.logger.warn('Redis disabled; alert notification queue publishing is skipped.');
      return;
    }

    const connection = {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10)
    };

    this.notificationQueue = new Queue('notification', { connection });
    this.alertsService.setNotificationQueue(this.notificationQueue);
  }

  async onModuleDestroy() {
    await this.notificationQueue?.close();
  }
}
