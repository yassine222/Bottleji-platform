import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SupportTicket, SupportTicketDocument, TicketStatus, TicketPriority, TicketCategory } from './schemas/support-ticket.schema';

@Injectable()
export class SupportTicketsService {
  constructor(
    @InjectModel(SupportTicket.name) private supportTicketModel: Model<SupportTicketDocument>,
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
        message: description,
        senderId: new Types.ObjectId(userId),
        senderType: 'user',
        sentAt: new Date(),
        isInternal: false,
      }],
    });

    return ticket.save();
  }

  async getTicketsByUser(userId: string): Promise<SupportTicket[]> {
    return this.supportTicketModel
      .find({ userId: new Types.ObjectId(userId), isDeleted: false })
      .populate('userId', 'name email phoneNumber')
      .populate('assignedTo', 'name email')
      .populate('relatedDropId', 'numberOfBottles numberOfCans bottleType notes location status createdAt')
      .populate('relatedCollectionId', 'status completedAt')
      .populate('relatedApplicationId', 'status submittedAt')
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
        .populate('userId', 'name email phoneNumber')
        .populate('assignedTo', 'name email')
        .populate('relatedDropId', 'numberOfBottles numberOfCans bottleType notes location status createdAt')
        .populate('relatedCollectionId', 'status completedAt')
        .populate('relatedApplicationId', 'status submittedAt')
        .sort({ priority: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.supportTicketModel.countDocuments(query),
    ]);

    return {
      tickets,
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
      .populate('userId', 'name email phoneNumber')
      .populate('assignedTo', 'name email')
      .populate('relatedDropId', 'numberOfBottles numberOfCans bottleType notes location status createdAt')
      .populate('relatedCollectionId', 'status completedAt')
      .populate('relatedApplicationId', 'status submittedAt')
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
      .populate('userId', 'name email phoneNumber')
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

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
      .populate('userId', 'name email phoneNumber')
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
      .populate('userId', 'name email phoneNumber')
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
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
      .populate('userId', 'name email phoneNumber')
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
      .populate('userId', 'name email phoneNumber')
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
      .populate('userId', 'name email phoneNumber')
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
      .populate('userId', 'name email phoneNumber')
      .exec();

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }
}
