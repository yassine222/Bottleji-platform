import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersService } from './users.service';
import { User, UserSchema } from './schemas/user.schema';
import { DeviceCapabilities, DeviceCapabilitiesSchema } from './schemas/device-capabilities.schema';
import { DeviceCapabilitiesService } from './device-capabilities.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: DeviceCapabilities.name, schema: DeviceCapabilitiesSchema },
    ]),
  ],
  providers: [UsersService, DeviceCapabilitiesService],
  exports: [UsersService, DeviceCapabilitiesService],
})
export class UsersModule {} 