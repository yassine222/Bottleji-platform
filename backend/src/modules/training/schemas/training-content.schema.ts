import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TrainingContentDocument = TrainingContent & Document;

@Schema({ timestamps: true })
export class TrainingContent {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  description: string;

  @Prop({ 
    type: String, 
    enum: ['video', 'image', 'story'], 
    required: true 
  })
  type: string;

  @Prop({ 
    type: String, 
    enum: [
      'getting_started', 
      'advanced_features', 
      'troubleshooting', 
      'best_practices', 
      'collector_application', 
      'payments', 
      'notifications'
    ], 
    required: true 
  })
  category: string;

  @Prop()
  mediaUrl?: string; // For video/image URLs

  @Prop()
  thumbnailUrl?: string; // For video thumbnails

  @Prop()
  content?: string; // For text content or story content

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ required: true })
  createdBy: string; // User ID who created this content

  @Prop({ default: 0 })
  viewCount: number; // Number of views
}

export const TrainingContentSchema = SchemaFactory.createForClass(TrainingContent);
