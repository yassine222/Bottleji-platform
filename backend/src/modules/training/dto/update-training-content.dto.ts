import { PartialType } from '@nestjs/mapped-types';
import { CreateTrainingContentDto } from './create-training-content.dto';

export class UpdateTrainingContentDto extends PartialType(CreateTrainingContentDto) {}
