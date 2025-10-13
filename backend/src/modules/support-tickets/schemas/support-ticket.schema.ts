import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SupportTicketDocument = SupportTicket & Document;

export enum TicketStatus {
  OPEN = 'open',
  IN_PROGRESS = 'in_progress',
  ON_HOLD = 'on_hold',
  RESOLVED = 'resolved',
  CLOSED = 'closed',
}

export enum TicketPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent',
}

export enum TicketCategory {
  AUTHENTICATION = 'authentication',
  APP_TECHNICAL = 'app_technical',
  DROP_CREATION = 'drop_creation',
  COLLECTION_NAVIGATION = 'collection_navigation',
  COLLECTOR_APPLICATION = 'collector_application',
  PAYMENT_REWARDS = 'payment_rewards',
  STATISTICS_HISTORY = 'statistics_history',
  ROLE_SWITCHING = 'role_switching',
  COMMUNICATION = 'communication',
  GENERAL_SUPPORT = 'general_support',
}

@Schema({ timestamps: true })
export class SupportTicket {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  description: string;

  @Prop({ enum: TicketCategory, required: true })
  category: TicketCategory;

  @Prop({ enum: TicketPriority, default: TicketPriority.MEDIUM })
  priority: TicketPriority;

  @Prop({ enum: TicketStatus, default: TicketStatus.OPEN })
  status: TicketStatus;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  assignedTo: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  createdBy: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  lastUpdatedBy: Types.ObjectId;

  @Prop({ default: [] })
  tags: string[];

  @Prop({ default: [] })
  attachments: string[];

  @Prop({ default: [] })
  internalNotes: Array<{
    note: string;
    addedBy: Types.ObjectId;
    addedAt: Date;
  }>;

  @Prop({ default: [] })
  messages: Array<{
    message: string;
    senderId: Types.ObjectId;
    senderType: 'user' | 'agent' | 'system';
    sentAt: Date;
    isInternal: boolean;
  }>;

  @Prop({ default: null })
  resolvedAt: Date;

  @Prop({ default: null })
  closedAt: Date;

  @Prop({ default: null })
  dueDate: Date;

  @Prop({ default: null })
  estimatedResolutionTime: string;

  @Prop({ default: null })
  resolution: string;

  @Prop({ default: false })
  isEscalated: boolean;

  @Prop({ default: null })
  escalatedTo: Types.ObjectId;

  @Prop({ default: null })
  escalatedAt: Date;

  @Prop({ default: null })
  escalatedReason: string;

  @Prop({ default: false })
  isDeleted: boolean;

  @Prop({ default: null })
  deletedAt: Date;

  @Prop({ default: null })
  deletedBy: Types.ObjectId;

  // Context information for related objects
  @Prop({ default: null, type: Types.ObjectId, ref: 'Dropoff' })
  relatedDropId: Types.ObjectId;

  @Prop({ default: null, type: Types.ObjectId, ref: 'CollectionAttempt' })
  relatedCollectionId: Types.ObjectId;

  @Prop({ default: null, type: Types.ObjectId, ref: 'CollectorApplication' })
  relatedApplicationId: Types.ObjectId;

  @Prop({ default: null })
  relatedUserId: Types.ObjectId;

  // Additional context metadata
  @Prop({ type: Object, default: null })
  contextMetadata: any;

  // Location information if relevant
  @Prop({ 
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
      address: { type: String }
    },
    default: null 
  })
  location: {
    latitude: number;
    longitude: number;
    address: string;
  };
}

export const SupportTicketSchema = SchemaFactory.createForClass(SupportTicket);

// Add virtual id field to convert _id to id
SupportTicketSchema.virtual('id').get(function(this: any) {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized
SupportTicketSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc: any, ret: any) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    
    // Convert ObjectId fields to strings only if they're not populated
    if (ret.userId && typeof ret.userId === 'object' && !ret.userId.name && !ret.userId.email) {
      ret.userId = ret.userId.toString();
    }
    if (ret.assignedTo && typeof ret.assignedTo === 'object' && !ret.assignedTo.name) {
      ret.assignedTo = ret.assignedTo.toString();
    }
    if (ret.createdBy && typeof ret.createdBy === 'object') {
      ret.createdBy = ret.createdBy.toString();
    }
    if (ret.lastUpdatedBy && typeof ret.lastUpdatedBy === 'object') {
      ret.lastUpdatedBy = ret.lastUpdatedBy.toString();
    }
    if (ret.escalatedTo && typeof ret.escalatedTo === 'object') {
      ret.escalatedTo = ret.escalatedTo.toString();
    }
    if (ret.deletedBy && typeof ret.deletedBy === 'object') {
      ret.deletedBy = ret.deletedBy.toString();
    }
    
    // Handle related objects - keep populated objects as is, convert ObjectIds to strings
    if (ret.relatedDropId && typeof ret.relatedDropId === 'object' && !ret.relatedDropId.numberOfBottles && !ret.relatedDropId.status) {
      ret.relatedDropId = ret.relatedDropId.toString();
    }
    if (ret.relatedCollectionId && typeof ret.relatedCollectionId === 'object' && !ret.relatedCollectionId.status) {
      ret.relatedCollectionId = ret.relatedCollectionId.toString();
    }
    if (ret.relatedApplicationId && typeof ret.relatedApplicationId === 'object' && !ret.relatedApplicationId.status) {
      ret.relatedApplicationId = ret.relatedApplicationId.toString();
    }
    
    // Convert ObjectIds in arrays
    if (ret.internalNotes && Array.isArray(ret.internalNotes)) {
      ret.internalNotes = ret.internalNotes.map((note: any) => ({
        ...note,
        addedBy: note.addedBy && typeof note.addedBy === 'object' && note.addedBy.toString ? note.addedBy.toString() : note.addedBy
      }));
    }
    
    if (ret.messages && Array.isArray(ret.messages)) {
      ret.messages = ret.messages.map((message: any) => ({
        ...message,
        senderId: message.senderId && typeof message.senderId === 'object' && message.senderId.toString ? message.senderId.toString() : message.senderId
      }));
    }
    
    return ret;
  }
});
