import { IsString, IsOptional } from 'class-validator';

export class SetupProfileDto {
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsOptional()
  profilePhoto?: string;
}
