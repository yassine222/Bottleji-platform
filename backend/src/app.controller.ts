import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getApiInfo() {
    return {
      message: 'Bottleji API Server',
      version: '1.0.0',
      status: 'running',
      environment: process.env.NODE_ENV || 'development',
      endpoints: {
        health: '/api',
        auth: '/api/auth',
        dropoffs: '/api/dropoffs',
        notifications: '/api/notifications',
        rewards: '/api/rewards',
        admin: '/api/admin',
        collectorApplications: '/api/collector-applications',
        supportTickets: '/api/support-tickets',
        training: '/api/training',
        earnings: '/api/earnings',
      },
      timestamp: new Date().toISOString(),
    };
  }
}
