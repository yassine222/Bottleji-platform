import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { EmailModule } from './modules/email/email.module';

import { DropoffsModule } from './modules/dropoffs/dropoffs.module';
import { AdminModule } from './modules/admin/admin.module';
import { CollectorApplicationsModule } from './modules/collector-applications/collector-applications.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { SupportTicketsModule } from './modules/support-tickets/support-tickets.module';
import { TrainingModule } from './modules/training/training.module';
import { ChatModule } from './modules/chat/chat.module';
import { RewardsModule } from './modules/rewards/rewards.module';
import { ShippingModule } from './modules/shipping/shipping.module';
import { EarningsModule } from './modules/earnings/earnings.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: require('./config/validation.schema').validationSchema,
    }),
    ScheduleModule.forRoot(),
    MongooseModule.forRoot(process.env.MONGODB_URI || 'mongodb://localhost:27017/eco_collect'),
    AuthModule,
    UsersModule,
    EmailModule,
    DropoffsModule,
    AdminModule,
    CollectorApplicationsModule,
    NotificationsModule,
    SupportTicketsModule,
    TrainingModule,
    ChatModule,
    RewardsModule,
    ShippingModule,
    EarningsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
