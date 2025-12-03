import { IsString, IsNotEmpty } from 'class-validator';

export class PhoneLoginDto {
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  firebaseToken: string;
}

