import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Module,
  Param,
  Post
} from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { IsIn, IsNumber, IsString, MaxLength, Min } from 'class-validator';
import { CirclesService, Circle, Geofence } from './circles/circles.service';
import { Roles } from '../common/auth/roles.decorator';
import { USER_ROLES } from '../common/auth/roles.constants';

class CreateCircleDto {
  @IsString()
  @MaxLength(80)
  name!: string;

  @IsIn(['family', 'care', 'team'])
  type!: 'family' | 'care' | 'team';

  @IsString()
  userId!: string;
}

class AddMemberDto {
  @IsString()
  userId!: string;
}

class AddGeofenceDto {
  @IsString()
  @MaxLength(80)
  name!: string;

  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;

  @IsNumber()
  @Min(1)
  radiusMeters!: number;
}

@Controller('circles')
@ApiTags('circles')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Missing or invalid auth credentials.' })
@ApiForbiddenResponse({ description: 'Authenticated user lacks required role.' })
class CirclesController {
  constructor(private circlesService: CirclesService) {}

  @Post()
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  create(@Body() dto: CreateCircleDto) {
    if (!dto.name || !dto.type || !dto.userId) {
      throw new BadRequestException('name, type, and userId are required');
    }
    const circle = this.circlesService.create(dto.name, dto.type, dto.userId);
    return circle;
  }

  @Get('user/:userId')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getUserCircles(@Param('userId') userId: string) {
    return this.circlesService.getByUserId(userId);
  }

  @Get(':id')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getById(@Param('id') id: string) {
    const circle = this.circlesService.getById(id);
    if (!circle) {
      throw new BadRequestException(`Circle ${id} not found`);
    }
    return circle;
  }

  @Post(':id/members')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  addMember(@Param('id') circleId: string, @Body() dto: AddMemberDto) {
    const circle = this.circlesService.addMember(circleId, dto.userId);
    if (!circle) {
      throw new BadRequestException(`Circle ${circleId} not found`);
    }
    return circle;
  }

  @Delete(':id/members/:userId')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  removeMember(@Param('id') circleId: string, @Param('userId') userId: string) {
    const circle = this.circlesService.removeMember(circleId, userId);
    if (!circle) {
      throw new BadRequestException(`Circle ${circleId} not found`);
    }
    return circle;
  }

  @Post(':id/geofences')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  addGeofence(@Param('id') circleId: string, @Body() dto: AddGeofenceDto) {
    if (!dto.name || dto.lat === undefined || dto.lng === undefined || !dto.radiusMeters) {
      throw new BadRequestException('name, lat, lng, and radiusMeters are required');
    }
    const geofence: Geofence = {
      id: `geofence-${randomUUID()}`,
      ...dto
    };
    const circle = this.circlesService.addGeofence(circleId, geofence);
    if (!circle) {
      throw new BadRequestException(`Circle ${circleId} not found`);
    }
    return circle;
  }

  @Delete(':id/geofences/:geofenceId')
  @Roles(USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  removeGeofence(@Param('id') circleId: string, @Param('geofenceId') geofenceId: string) {
    const circle = this.circlesService.removeGeofence(circleId, geofenceId);
    if (!circle) {
      throw new BadRequestException(`Circle ${circleId} not found`);
    }
    return circle;
  }

  @Get(':id/member-count')
  @Roles(USER_ROLES.VIEWER, USER_ROLES.OPERATOR, USER_ROLES.ADMIN)
  getMemberCount(@Param('id') circleId: string) {
    const count = this.circlesService.getCircleMemberCount(circleId);
    return { circleId, memberCount: count };
  }
}

@Module({
  controllers: [CirclesController],
  providers: [CirclesService],
  exports: [CirclesService]
})
export class CirclesModule {}
