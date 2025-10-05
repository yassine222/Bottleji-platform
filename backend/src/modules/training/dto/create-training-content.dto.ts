import { IsString, IsOptional, IsEnum, IsBoolean, IsNumber, IsArray, Min } from 'class-validator';

export class CreateTrainingContentDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsEnum(['video', 'image', 'story'])
  type: string;

  @IsEnum([
    'getting_started', 
    'advanced_features', 
    'troubleshooting', 
    'best_practices', 
    'collector_application', 
    'payments', 
    'notifications'
  ])
  category: string;

  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @IsOptional()
  @IsString()
  thumbnailUrl?: string;

  @IsOptional()
  @IsString()
  content?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  duration?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}
