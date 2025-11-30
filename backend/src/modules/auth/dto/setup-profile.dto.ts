import { IsString, IsOptional, IsNotEmpty } from 'class-validator';

export class SetupProfileDto {
  @IsString()
  @IsNotEmpty()
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
