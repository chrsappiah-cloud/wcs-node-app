import { Controller, Get, Module } from '@nestjs/common';

@Controller('health')
class HealthController {
  @Get()
  getHealth() {
    return { status: 'ok', service: 'dreamflow-api' };
  }
}

@Module({
  controllers: [HealthController]
})
export class HealthModule {}
