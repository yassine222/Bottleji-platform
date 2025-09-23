import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { UserRole } from '../schemas/user.schema';

export class SetupProfileDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  location?: {
    type: string;
    coordinates: number[];
  };

  @IsOptional()
  @IsString()
  profilePhoto?: string; // base64 or URL
} 