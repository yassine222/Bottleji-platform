import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CollectorApplicationsController } from './collector-applications.controller';
import { CollectorApplicationsService } from './collector-applications.service';
import { CollectorApplication, CollectorApplicationSchema } from './schemas/collector-application.schema';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CollectorApplication.name, schema: CollectorApplicationSchema },
    ]),
    UsersModule,
    NotificationsModule,
  ],
  controllers: [CollectorApplicationsController],
  providers: [CollectorApplicationsService],
  exports: [CollectorApplicationsService],
})
export class CollectorApplicationsModule {} 