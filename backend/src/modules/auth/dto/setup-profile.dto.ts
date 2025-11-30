import { IsString, IsOptional, IsNotEmpty } from 'class-validator';

export class SetupProfileDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsOptional()
  profilePhoto?: string;
}
