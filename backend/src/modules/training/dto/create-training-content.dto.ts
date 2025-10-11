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
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}
