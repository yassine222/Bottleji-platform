import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { SupportTicketsService } from './support-tickets.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../admin/guards/admin.guard';
import { TicketStatus, TicketPriority, TicketCategory } from './schemas/support-ticket.schema';

@Controller('support-tickets')
export class SupportTicketsController {
  constructor(private readonly supportTicketsService: SupportTicketsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createTicket(
    @Request() req,
    @Body() body: {
      title: string;
      description: string;
      category: TicketCategory;
      priority?: TicketPriority;
      attachments?: string[];
      contextMetadata?: any;
      relatedDropId?: string;
      relatedCollectionId?: string;
      relatedApplicationId?: string;
      location?: { latitude: number; longitude: number; address: string };
    },
  ) {
    const { 
      title, 
      description, 
      category, 
      priority, 
      attachments,
      contextMetadata,
      relatedDropId,
      relatedCollectionId,
      relatedApplicationId,
      location
    } = body;
    return this.supportTicketsService.createTicket(
      req.user.id,
      title,
      description,
      category,
      priority,
      attachments,
      contextMetadata,
      relatedDropId,
      relatedCollectionId,
      relatedApplicationId,
      location,
    );
  }

  @Get('my-tickets')
  @UseGuards(JwtAuthGuard)
  async getMyTickets(@Request() req) {
    return this.supportTicketsService.getTicketsByUser(req.user.id);
  }

  @Get('admin/all')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getAllTickets(
    @Query('status') status?: TicketStatus,
    @Query('priority') priority?: TicketPriority,
    @Query('category') category?: TicketCategory,
    @Query('assignedTo') assignedTo?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    
    return this.supportTicketsService.getAllTickets(
      status,
      priority,
      category,
      assignedTo,
      pageNum,
      limitNum,
    );
  }

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getTicketStats() {
    return this.supportTicketsService.getTicketStats();
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getTicketById(@Param('id') id: string, @Request() req) {
    // Check if user is admin/support agent
    const isAdmin = req.user.roles.some((role: string) => 
      ['super_admin', 'admin', 'moderator', 'support_agent'].includes(role)
    );
    
    return this.supportTicketsService.getTicketById(id, isAdmin ? undefined : req.user.id);
  }

  @Put(':id/status')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async updateTicketStatus(
    @Param('id') id: string,
    @Request() req,
    @Body() body: { status: TicketStatus; resolution?: string },
  ) {
    const { status, resolution } = body;
    return this.supportTicketsService.updateTicketStatus(id, status, req.user.id, resolution);
  }

  @Put(':id/assign')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async assignTicket(
    @Param('id') id: string,
    @Request() req,
    @Body() body: { assignedTo: string },
  ) {
    const { assignedTo } = body;
    return this.supportTicketsService.assignTicket(id, assignedTo, req.user.id);
  }

  @Post(':id/messages')
  @UseGuards(JwtAuthGuard)
  async addMessage(
    @Param('id') id: string,
    @Request() req,
    @Body() body: { message: string; isInternal?: boolean },
  ) {
    const { message, isInternal = false } = body;
    
    // Check if user is admin/support agent
    const isAdmin = req.user.roles.some((role: string) => 
      ['super_admin', 'admin', 'moderator', 'support_agent'].includes(role)
    );
    
    const senderType = isAdmin ? 'agent' : 'user';
    
    return this.supportTicketsService.addMessage(
      id,
      message,
      req.user.id,
      senderType,
      isInternal,
    );
  }

  @Post(':id/internal-notes')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async addInternalNote(
    @Param('id') id: string,
    @Request() req,
    @Body() body: { note: string },
  ) {
    const { note } = body;
    return this.supportTicketsService.addInternalNote(id, note, req.user.id);
  }

  @Post(':id/escalate')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async escalateTicket(
    @Param('id') id: string,
    @Request() req,
    @Body() body: { escalatedTo: string; reason: string },
  ) {
    const { escalatedTo, reason } = body;
    return this.supportTicketsService.escalateTicket(id, escalatedTo, req.user.id, reason);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteTicket(@Param('id') id: string, @Request() req) {
    await this.supportTicketsService.deleteTicket(id, req.user.id);
  }
}
