import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SupportTicketsController } from './support-tickets.controller';
import { SupportTicketsService } from './support-tickets.service';
import { SupportTicket, SupportTicketSchema } from './schemas/support-ticket.schema';
import { CollectionAttempt, CollectionAttemptSchema } from '../dropoffs/schemas/collection-attempt.schema';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { DropoffsModule } from '../dropoffs/dropoffs.module';
import { ChatModule } from '../chat/chat.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SupportTicket.name, schema: SupportTicketSchema },
      { name: CollectionAttempt.name, schema: CollectionAttemptSchema },
    ]),
    UsersModule,
    NotificationsModule,
    DropoffsModule,
    ChatModule,
  ],
  controllers: [SupportTicketsController],
  providers: [SupportTicketsService],
  exports: [SupportTicketsService],
})
export class SupportTicketsModule {}
