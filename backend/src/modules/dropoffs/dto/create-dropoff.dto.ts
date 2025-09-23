import { IsString, IsNumber, IsEnum, IsBoolean, IsObject, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { BottleType } from '../schemas/dropoff.schema';

export class LocationDto {
  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;
}

export class CreateDropoffDto {
  @IsString()
  userId: string;

  @IsString()
  imageUrl: string;

  @IsNumber()
  @IsOptional()
  numberOfBottles?: number;

  @IsNumber()
  @IsOptional()
  numberOfCans?: number;

  @IsEnum(BottleType)
  bottleType: BottleType;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsBoolean()
  leaveOutside: boolean;

  @IsObject()
  @ValidateNested()
  @Type(() => LocationDto)
  location: LocationDto;
} 