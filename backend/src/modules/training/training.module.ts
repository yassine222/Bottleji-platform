import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TrainingService } from './training.service';
import { TrainingController } from './training.controller';
import { TrainingContent, TrainingContentSchema } from './schemas/training-content.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TrainingContent.name, schema: TrainingContentSchema },
    ]),
  ],
  controllers: [TrainingController],
  providers: [TrainingService],
  exports: [TrainingService],
})
export class TrainingModule {}
