import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SupportTicket, SupportTicketDocument, TicketStatus, TicketPriority, TicketCategory } from './schemas/support-ticket.schema';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { DropoffsService } from '../dropoffs/dropoffs.service';
import { ChatGateway } from '../chat/chat.gateway';

@Injectable()
export class SupportTicketsService {
  constructor(
    @InjectModel(SupportTicket.name) private supportTicketModel: Model<SupportTicketDocument>,
    private notificationsGateway: NotificationsGateway,
    private dropoffsService: DropoffsService,
    private chatGateway: ChatGateway,
  ) {}

  async createTicket(
    userId: string,
    title: string,
    description: string,
    category: TicketCategory,
    priority: TicketPriority = TicketPriority.MEDIUM,
    attachments: string[] = [],
    contextMetadata?: any,
    relatedDropId?: string,
    relatedCollectionId?: string,
    relatedApplicationId?: string,
    location?: { latitude: number; longitude: number; address: string },
  ): Promise<SupportTicket> {
    const ticket = new this.supportTicketModel({
      userId: new Types.ObjectId(userId),
      title,
      description,
      category,
      priority,
      attachments,
      createdBy: new Types.ObjectId(userId),
      lastUpdatedBy: new Types.ObjectId(userId),
      contextMetadata,
      relatedDropId: relatedDropId ? new Types.ObjectId(relatedDropId) : undefined,
      relatedCollectionId: relatedCollectionId ? new Types.ObjectId(relatedCollectionId) : undefined,
      relatedApplicationId: relatedApplicationId ? new Types.ObjectId(relatedApplicationId) : undefined,
      location,
      messages: [{
        message: this._generateContextualMessage(description, category, contextMetadata, relatedDropId, relatedCollectionId, relatedApplicationId),
        senderId: new Types.ObjectId(userId),
        senderType: 'user',
        sentAt: new Date(),
        isInternal: false,
      }],
    });

    const savedTicket = await ticket.save();

    // Send real-time notification for new ticket
    this.notificationsGateway.sendTicketUpdateToAdmins(
      (savedTicket._id as any).toString(),
      'new_ticket',
      {
        ticket: {
          id: (savedTicket._id as any).toString(),
          title: savedTicket.title,
          userId: savedTicket.userId.toString(),
        },
        ticketTitle: savedTicket.title,
      },
    );

    return savedTicket;
  }

  private _generateContextualMessage(
    description: string,
    category: TicketCategory,
    contextMetadata?: any,
    relatedDropId?: string,
    relatedCollectionId?: string,
    relatedApplicationId?: string,
  ): string {
    let contextualMessage = description;

    // Add simple context based on related objects
    if (relatedDropId) {
      contextualMessage += `\n\n📦 Related to Drop: ${relatedDropId.substring(0, 8)}...`;
    }

    if (relatedCollectionId) {
      contextualMessage += `\n\n🚛 Related to Collection: ${relatedCollectionId.substring(0, 8)}...`;
    }

    if (relatedApplicationId) {
      contextualMessage += `\n\n📋 Related to Application: ${relatedApplicationId.substring(0, 8)}...`;
    }

    return contextualMessage;
  }

  async getTicketsByUser(userId: string): Promise<SupportTicket[]> {
    return this.supportTicketModel
      .find({ userId: new Types.ObjectId(userId), isDeleted: false })
      .sort({ createdAt: -1 })
      .exec();
  }

  async getAllTickets(
    status?: TicketStatus,
    priority?: TicketPriority,
    category?: TicketCategory,
    assignedTo?: string,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ tickets: SupportTicket[]; total: number; page: number; totalPages: number }> {
    const query: any = { isDeleted: false };

    if (status) query.status = status;
    if (priority) query.priority = priority;
    if (category) query.category = category;
    if (assignedTo) query.assignedTo = new Types.ObjectId(assignedTo);

    const skip = (page - 1) * limit;

    const [tickets, total] = await Promise.all([
      this.supportTicketModel
        .find(query)
        .populate('userId', '_id name email phoneNumber')
        .populate('assignedTo', 'name email')
        .populate('relatedDropId', 'numberOfBottles numberOfCans bottleType notes location status createdAt')
        // Don't populate relatedCollectionId - it's an interaction ID, not a collection entity
        // We'll manually create an object for it and add interactions later
        .populate('relatedApplicationId', 'status appliedAt reviewedAt rejectionReason idCardPhoto selfieWithIdPhoto')
        .sort({ priority: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.supportTicketModel.countDocuments(query),
    ]);

    // Fetch interaction timelines for tickets with related drops or collections
    const ticketsWithTimelines = await Promise.all(
      tickets.map(async (ticket) => {
        if (ticket.relatedDropId) {
          try {
            console.log('🔍 Support Tickets: Processing ticket with relatedDropId:', ticket.relatedDropId);
            
            // Get the ObjectId string from the populated object or direct ObjectId
            const dropoffId = typeof ticket.relatedDropId === 'object' && ticket.relatedDropId._id 
              ? ticket.relatedDropId._id.toString()
              : ticket.relatedDropId.toString();
            
            console.log('🔍 Support Tickets: Extracted dropoffId:', dropoffId);
            
            const timeline = await this.dropoffsService.getDropInteractionTimeline(dropoffId);
            console.log('🔍 Support Tickets: Fetched timeline with', timeline.length, 'interactions');
            
            // Add timeline to the related drop object
            if (ticket.relatedDropId && typeof ticket.relatedDropId === 'object') {
              (ticket.relatedDropId as any).interactions = timeline;
              console.log('🔍 Support Tickets: Added interactions to relatedDropId object');
            }
          } catch (error) {
            console.error(`❌ Support Tickets: Error fetching timeline for drop ${ticket.relatedDropId}:`, error);
          }
        }
        
        if (ticket.relatedCollectionId) {
          try {
            console.log('🔍 Support Tickets: Processing ticket with relatedCollectionId:', ticket.relatedCollectionId);
            console.log('🔍 Support Tickets: Ticket also has relatedDropId:', ticket.relatedDropId);
            
            // Get the ObjectId string - relatedCollectionId is not populated, so it's just an ObjectId
            const collectionId = ticket.relatedCollectionId.toString();
            console.log('🔍 Support Tickets: Extracted collectionId:', collectionId);
            
            // Create an object for relatedCollectionId so we can add interactions to it
            const collectionObject = {
              _id: ticket.relatedCollectionId,
              interactions: [] as any[]
            };
            
            // If we have relatedDropId, use it directly to fetch interactions
            // This is more reliable than using the collection ID (which is actually an interaction ID)
            if (ticket.relatedDropId) {
              const dropoffId = typeof ticket.relatedDropId === 'object' && (ticket.relatedDropId as any)._id 
                ? (ticket.relatedDropId as any)._id.toString()
                : (ticket.relatedDropId as any).toString();
              
              const dropInteractions = await this.dropoffsService.getDropInteractionTimeline(dropoffId);
              console.log('🔍 Support Tickets: Fetched drop timeline with', dropInteractions.length, 'interactions for collection issue');
              
              collectionObject.interactions = dropInteractions;
              console.log('🔍 Support Tickets: Added drop interactions to collection object');
            } else {
              // Fallback: Try to fetch interactions by collection ID (interaction ID)
              const collectionInteractions = await this.dropoffsService.getCollectionInteractionTimeline(collectionId);
              console.log('🔍 Support Tickets: Fetched collection timeline with', collectionInteractions.length, 'interactions');
              
              collectionObject.interactions = collectionInteractions;
              console.log('🔍 Support Tickets: Added interactions to collection object');
            }
            
            // Replace the ObjectId with our custom object
            (ticket as any).relatedCollectionId = collectionObject;
            console.log('🔍 Support Tickets: Replaced relatedCollectionId with object containing interactions');
          } catch (error) {
            console.error(`❌ Support Tickets: Error fetching timeline for collection ${ticket.relatedCollectionId}:`, error);
          }
        }
        
        if (!ticket.relatedDropId && !ticket.relatedCollectionId) {
          console.log('🔍 Support Tickets: Ticket has no relatedDropId or relatedCollectionId');
        }
        
        return ticket;
      })
    );

    return {
      tickets: ticketsWithTimelines,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getTicketById(ticketId: string, userId?: string): Promise<SupportTicket> {
    const query: any = { _id: new Types.ObjectId(ticketId), isDeleted: false };
    
    // If userId is provided, ensure the user can only see their own tickets
    if (userId) {
      query.userId = new Types.ObjectId(userId);
    }

    const ticket = await this.supportTicketModel
      .findOne(query)
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async updateTicketStatus(
    ticketId: string,
    status: TicketStatus,
    updatedBy: string,
    resolution?: string,
  ): Promise<SupportTicket> {
    const updateData: any = {
      status,
      lastUpdatedBy: new Types.ObjectId(updatedBy),
    };

    if (status === TicketStatus.RESOLVED) {
      updateData.resolvedAt = new Date();
      if (resolution) updateData.resolution = resolution;
    } else if (status === TicketStatus.CLOSED) {
      updateData.closedAt = new Date();
    }

    const ticket = await this.supportTicketModel
      .findByIdAndUpdate(
        new Types.ObjectId(ticketId),
        updateData,
        { new: true }
      )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    // Send real-time notification for status update
    this.notificationsGateway.sendTicketUpdateToAdmins(
      ticketId,
      'status_update',
      {
        ticket: {
          id: (ticket._id as any).toString(),
          title: ticket.title,
          userId: ticket.userId.toString(),
        },
        newStatus: status,
        updatedBy,
      },
    );

    return ticket;
  }

  async assignTicket(ticketId: string, assignedTo: string, assignedBy: string): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel
      .findByIdAndUpdate(
        new Types.ObjectId(ticketId),
        {
          assignedTo: new Types.ObjectId(assignedTo),
          lastUpdatedBy: new Types.ObjectId(assignedBy),
          status: TicketStatus.IN_PROGRESS,
        },
        { new: true }
      )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async addMessage(
    ticketId: string,
    message: string,
    senderId: string,
    senderType: 'user' | 'agent' | 'system',
    isInternal: boolean = false,
  ): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel
      .findByIdAndUpdate(
        new Types.ObjectId(ticketId),
        {
          $push: {
            messages: {
              message,
              senderId: new Types.ObjectId(senderId),
              senderType,
              sentAt: new Date(),
              isInternal,
            },
          },
          lastUpdatedBy: new Types.ObjectId(senderId),
        },
        { new: true }
      )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    // Create the message object
    const newMessage = {
      message,
      senderId: new Types.ObjectId(senderId),
      senderType,
      sentAt: new Date(),
      isInternal,
    };

    // Add message to ticket in database
    ticket.messages.push(newMessage);
    ticket.markModified('updatedAt');
    ticket.set('updatedAt', new Date());
    await ticket.save();

    console.log(`📨 Message saved to database: ${message} from ${senderType} ${senderId} to ticket ${ticketId}`);

    // Send real-time message via chat gateway
    const chatMessage = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      ticketId,
      message,
      senderId,
      senderType,
      sentAt: newMessage.sentAt,
      isInternal,
    };

    console.log(`📨 Sending real-time message via chat gateway: ${message} from ${senderType} ${senderId} to ticket ${ticketId}`);
    console.log(`📨 Chat message object:`, chatMessage);
    
    // Send message through chat gateway for real-time delivery
    await this.chatGateway.sendMessageToTicket(ticketId, chatMessage);

    // Send push notification if agent sent message
    if (senderType === 'agent') {
      console.log('🔔 Sending push notification to user for agent message');
      this.notificationsGateway.sendTicketMessageUpdate(
        ticket.userId.toString(),
        ticketId,
        {
          message,
          senderId,
          senderType,
          sentAt: newMessage.sentAt,
          isInternal,
        },
      );
    }

    return ticket;
  }

  async addInternalNote(ticketId: string, note: string, addedBy: string): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel
      .findByIdAndUpdate(
        new Types.ObjectId(ticketId),
        {
          $push: {
            internalNotes: {
              note,
              addedBy: new Types.ObjectId(addedBy),
              addedAt: new Date(),
            },
          },
          lastUpdatedBy: new Types.ObjectId(addedBy),
        },
        { new: true }
      )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async escalateTicket(
    ticketId: string,
    escalatedTo: string,
    escalatedBy: string,
    reason: string,
  ): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel
      .findByIdAndUpdate(
        new Types.ObjectId(ticketId),
        {
          isEscalated: true,
          escalatedTo: new Types.ObjectId(escalatedTo),
          escalatedAt: new Date(),
          escalatedReason: reason,
          lastUpdatedBy: new Types.ObjectId(escalatedBy),
        },
        { new: true }
      )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async getTicketStats(): Promise<{
    total: number;
    open: number;
    inProgress: number;
    resolved: number;
    closed: number;
    byPriority: Record<TicketPriority, number>;
    byCategory: Record<TicketCategory, number>;
  }> {
    const [
      total,
      open,
      inProgress,
      resolved,
      closed,
      priorityStats,
      categoryStats,
    ] = await Promise.all([
      this.supportTicketModel.countDocuments({ isDeleted: false }),
      this.supportTicketModel.countDocuments({ status: TicketStatus.OPEN, isDeleted: false }),
      this.supportTicketModel.countDocuments({ status: TicketStatus.IN_PROGRESS, isDeleted: false }),
      this.supportTicketModel.countDocuments({ status: TicketStatus.RESOLVED, isDeleted: false }),
      this.supportTicketModel.countDocuments({ status: TicketStatus.CLOSED, isDeleted: false }),
      this.supportTicketModel.aggregate([
        { $match: { isDeleted: false } },
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]),
      this.supportTicketModel.aggregate([
        { $match: { isDeleted: false } },
        { $group: { _id: '$category', count: { $sum: 1 } } },
      ]),
    ]);

    const byPriority = priorityStats.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {} as Record<TicketPriority, number>);

    const byCategory = categoryStats.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {} as Record<TicketCategory, number>);

    return {
      total,
      open,
      inProgress,
      resolved,
      closed,
      byPriority,
      byCategory,
    };
  }

  async deleteTicket(ticketId: string, deletedBy: string): Promise<void> {
    const ticket = await this.supportTicketModel.findByIdAndUpdate(
      new Types.ObjectId(ticketId),
      {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: new Types.ObjectId(deletedBy),
      }
    );

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }
  }

  async resolveTicket(ticketId: string, resolution: string, resolvedBy: string): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel.findByIdAndUpdate(
      new Types.ObjectId(ticketId),
      {
        status: TicketStatus.RESOLVED,
        resolution,
        resolvedAt: new Date(),
        lastUpdatedBy: new Types.ObjectId(resolvedBy),
      },
      { new: true }
    )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async closeTicket(ticketId: string, closedBy: string): Promise<SupportTicket> {
    const ticket = await this.supportTicketModel.findByIdAndUpdate(
      new Types.ObjectId(ticketId),
      {
        status: TicketStatus.CLOSED,
        closedAt: new Date(),
        lastUpdatedBy: new Types.ObjectId(closedBy),
      },
      { new: true }
    )
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }
}
