import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { DropsManagementController } from './drops-management.controller';
import { AdminService } from './admin.service';
import { DropsManagementService } from './drops-management.service';
import { AdminGuard } from './guards/admin.guard';
import { User, UserSchema } from '../users/schemas/user.schema';
import { CollectorApplication, CollectorApplicationSchema } from '../collector-applications/schemas/collector-application.schema';
import { Dropoff, DropoffSchema } from '../dropoffs/schemas/dropoff.schema';
import { CollectorInteraction, CollectorInteractionSchema } from '../dropoffs/schemas/collector-interaction.schema';
import { CollectionAttempt, CollectionAttemptSchema } from '../dropoffs/schemas/collection-attempt.schema';
import { DropReport, DropReportSchema } from '../dropoffs/schemas/drop-report.schema';
import { SupportTicket, SupportTicketSchema } from '../support-tickets/schemas/support-ticket.schema';
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
      { name: CollectorInteraction.name, schema: CollectorInteractionSchema },
      { name: CollectionAttempt.name, schema: CollectionAttemptSchema },
      { name: DropReport.name, schema: DropReportSchema },
      { name: SupportTicket.name, schema: SupportTicketSchema },
    ]),
    CollectorApplicationsModule,
    UsersModule,
    NotificationsModule,
    EmailModule,
    SupportTicketsModule,
  ],
  controllers: [AdminController, DropsManagementController],
  providers: [AdminService, DropsManagementService, AdminGuard],
  exports: [AdminService, DropsManagementService, AdminGuard],
})
export class AdminModule {} 