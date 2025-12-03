import { IsString, IsNotEmpty } from 'class-validator';

export class PhoneSignupDto {
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  firebaseToken: string;
}

