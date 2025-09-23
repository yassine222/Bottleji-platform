import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { User, UserSchema } from '../users/schemas/user.schema';
import { CollectorApplication, CollectorApplicationSchema } from '../collector-applications/schemas/collector-application.schema';
import { Dropoff, DropoffSchema } from '../dropoffs/schemas/dropoff.schema';
import { CollectorApplicationsModule } from '../collector-applications/collector-applications.module';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { EmailModule } from '../email/email.module';
import { SupportTicketsModule } from '../support-tickets/support-tickets.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: CollectorApplication.name, schema: CollectorApplicationSchema },
      { name: Dropoff.name, schema: DropoffSchema },
    ]),
    CollectorApplicationsModule,
    UsersModule,
    NotificationsModule,
    EmailModule,
    SupportTicketsModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AdminGuard],
  exports: [AdminService, AdminGuard],
})
export class AdminModule {} 