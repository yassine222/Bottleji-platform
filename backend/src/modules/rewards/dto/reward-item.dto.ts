import { IsString, IsNotEmpty, IsNumber, IsOptional, IsBoolean, IsEnum, Min } from 'class-validator';
import { RewardCategory } from '../schemas/reward-item.schema';

export class CreateRewardItemDto {
  @IsString({ message: 'Name must be a string' })
  @IsNotEmpty({ message: 'Name is required' })
  name: string;

  @IsString({ message: 'Description must be a string' })
  @IsNotEmpty({ message: 'Description is required' })
  description: string;

  @IsEnum(RewardCategory, { message: 'Category must be either "collector" or "household"' })
  @IsNotEmpty()
  category: RewardCategory;

  @IsString()
  @IsNotEmpty()
  subCategory: string;

  @IsNumber()
  @Min(0)
  pointCost: number;

  @IsNumber()
  @Min(0)
  stock: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  isFootwear?: boolean;

  @IsOptional()
  @IsBoolean()
  isJacket?: boolean;

  @IsOptional()
  @IsBoolean()
  isBottoms?: boolean;
}

export class UpdateRewardItemDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(RewardCategory)
  category?: RewardCategory;

  @IsOptional()
  @IsString()
  subCategory?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  pointCost?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  isFootwear?: boolean;

  @IsOptional()
  @IsBoolean()
  isJacket?: boolean;

  @IsOptional()
  @IsBoolean()
  isBottoms?: boolean;
}
