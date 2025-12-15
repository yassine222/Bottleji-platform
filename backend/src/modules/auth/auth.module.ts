import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { DeviceCapabilitiesController } from './device-capabilities.controller';
import { UsersModule } from '../users/users.module';
import { EmailModule } from '../email/email.module';
import { TemporarySignup, TemporarySignupSchema } from './schemas/temporary-signup.schema';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    UsersModule,
    EmailModule,
    MongooseModule.forFeature([
      { name: TemporarySignup.name, schema: TemporarySignupSchema },
    ]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: configService.get<string>('JWT_EXPIRES_IN') || '7d' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController, DeviceCapabilitiesController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
