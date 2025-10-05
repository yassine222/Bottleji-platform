import { Controller, Get, Put, Delete, Param, Body, UseGuards, Request, Query, Post } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from './guards/admin.guard';
import { AdminService } from './admin.service';
import { CollectorApplicationsService } from '../collector-applications/collector-applications.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SupportTicketsService } from '../support-tickets/support-tickets.service';
import { TicketStatus, TicketPriority, TicketCategory } from '../support-tickets/schemas/support-ticket.schema';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly collectorApplicationsService: CollectorApplicationsService,
    private readonly notificationsService: NotificationsService,
    private readonly supportTicketsService: SupportTicketsService,
  ) {}

  @Get('dashboard')
  async getDashboardStats() {
    const stats = await this.adminService.getDashboardStats();
    return { success: true, stats };
  }

  @Get('admin-users')
  async getAdminUsers(@Request() req) {
    // Check if the current user is a super admin
    const currentUser = req.user;
    if (!currentUser.roles?.includes('super_admin')) {
      throw new Error('Access denied. Super admin privileges required.');
    }
    
    const adminUsers = await this.adminService.getAdminUsers();
    return { success: true, data: adminUsers };
  }

  @Post('create-admin')
  async createAdminUser(@Request() req, @Body() createAdminDto: { email: string; name: string; role: string }) {
    // Check if the current user is a super admin
    const currentUser = req.user;
    if (!currentUser.roles?.includes('super_admin')) {
      throw new Error('Access denied. Super admin privileges required.');
    }
    
    const newAdmin = await this.adminService.createAdminUser(createAdminDto);
    return { success: true, user: newAdmin };
  }

  @Post('test-create')
  async testCreate() {
    return { success: true, message: 'Test endpoint working' };
  }

  @Get('users')
  async getAllUsers(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('includeDeleted') includeDeleted = 'false',
  ) {
    const users = await this.adminService.getAllUsers(
      Number(page), 
      Number(limit), 
      includeDeleted === 'true'
    );
    return { success: true, ...users };
  }

  @Post('users')
  async createUser(@Request() req, @Body() createUserDto: { email: string; name: string; password: string; roles: string[] }) {
    // Check if the current user is a super admin
    const currentUser = req.user;
    if (!currentUser.roles?.includes('super_admin')) {
      throw new Error('Access denied. Super admin privileges required.');
    }
    
    const newUser = await this.adminService.createAdminUser({
      email: createUserDto.email,
      name: createUserDto.name,
      role: createUserDto.roles[0]
    });
    return { success: true, user: newUser };
  }

  @Get('users/:id')
  async getUserById(
    @Param('id') userId: string,
    @Query('includeDeleted') includeDeleted = 'false',
  ) {
    const user = await this.adminService.getUserById(userId, includeDeleted === 'true');
    return { success: true, user };
  }

  @Get('users/:id/activities')
  async getUserActivities(@Param('id') userId: string) {
    const activities = await this.adminService.getUserActivities(userId);
    return { success: true, activities };
  }

  @Put('users/:id/roles')
  async updateUserRoles(
    @Param('id') userId: string,
    @Body() data: { roles: string[] },
  ) {
    const user = await this.adminService.updateUserRole(userId, data.roles);
    return { success: true, user };
  }

  @Put('users/:id/ban')
  async banUser(
    @Param('id') userId: string,
    @Body() data: { reason: string },
  ) {
    const user = await this.adminService.banUser(userId, data.reason);
    return { success: true, user };
  }

  @Put('users/:id/unban')
  async unbanUser(@Param('id') userId: string) {
    const user = await this.adminService.unbanUser(userId);
    return { success: true, user };
  }

  @Put('/users/:id/restore')
  async restoreUser(@Param('id') userId: string, @Request() req) {
    const adminId = req.user.id;
    return await this.adminService.restoreUser(userId, adminId);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') userId: string, @Request() req) {
    await this.adminService.deleteUser(userId, req.user.id);
    return { success: true, message: 'User deleted successfully' };
  }

  @Get('drops')
  async getAllDrops(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('status') status?: string,
  ) {
    const drops = await this.adminService.getAllDrops(Number(page), Number(limit), status);
    return { success: true, ...drops };
  }

  @Get('drops/:id')
  async getDropById(@Param('id') dropId: string) {
    const drop = await this.adminService.getDropById(dropId);
    return { success: true, drop };
  }

  @Put('drops/:id')
  async updateDrop(
    @Param('id') dropId: string,
    @Body() updateData: any,
  ) {
    const drop = await this.adminService.updateDrop(dropId, updateData);
    return { success: true, drop };
  }

  @Delete('drops/:id')
  async deleteDrop(@Param('id') dropId: string) {
    await this.adminService.deleteDrop(dropId);
    return { success: true, message: 'Drop deleted successfully' };
  }

  // Collector Applications Management
  @Get('/collector-applications')
  async getAllCollectorApplications(
    @Query('status') status?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return await this.adminService.getAllCollectorApplications(status, page, limit);
  }

  @Get('/collector-applications/stats')
  async getCollectorApplicationStats() {
    return await this.adminService.getCollectorApplicationStats();
  }

  @Get('/collector-applications/:id')
  async getCollectorApplication(@Param('id') applicationId: string) {
    return await this.adminService.getCollectorApplication(applicationId);
  }

  @Put('/collector-applications/:id/approve')
  async approveCollectorApplication(
    @Param('id') applicationId: string,
    @Body() body: { notes?: string } = {},
    @Request() req,
  ) {
    console.log('🔍 approveCollectorApplication called with applicationId:', applicationId);
    
    if (!applicationId || applicationId === 'undefined') {
      throw new Error('Invalid application ID provided');
    }
    
    const adminId = req.user.id;
    return await this.adminService.approveCollectorApplication(applicationId, adminId, body?.notes);
  }

  @Put('/collector-applications/:id/reject')
  async rejectCollectorApplication(
    @Param('id') applicationId: string,
    @Body() body: { rejectionReason: string; notes?: string },
    @Request() req,
  ) {
    console.log('🔍 rejectCollectorApplication called with applicationId:', applicationId);
    
    if (!applicationId || applicationId === 'undefined') {
      throw new Error('Invalid application ID provided');
    }
    
    const adminId = req.user.id;
    return await this.adminService.rejectCollectorApplication(
      applicationId,
      adminId,
      body.rejectionReason,
      body?.notes,
    );
  }

  @Put('/collector-applications/:id/reverse-approval')
  async reverseCollectorApplicationApproval(
    @Param('id') applicationId: string,
    @Body() body: { notes?: string } = {},
    @Request() req,
  ) {
    console.log('🔍 reverseCollectorApplicationApproval called with applicationId:', applicationId);
    
    if (!applicationId || applicationId === 'undefined') {
      throw new Error('Invalid application ID provided');
    }
    
    const adminId = req.user.id;
    return await this.adminService.reverseCollectorApplicationApproval(applicationId, adminId, body?.notes);
  }

  // Support Tickets Admin Routes
  @Get('support-tickets')
  async getAllSupportTickets(
    @Query('status') status?: TicketStatus,
    @Query('priority') priority?: TicketPriority,
    @Query('category') category?: TicketCategory,
    @Query('assignedTo') assignedTo?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    
    const result = await this.supportTicketsService.getAllTickets(
      status,
      priority,
      category,
      assignedTo,
      pageNum,
      limitNum,
    );
    
    return { success: true, ...result };
  }

  @Get('support-tickets/:id')
  async getSupportTicketById(@Param('id') ticketId: string) {
    const ticket = await this.supportTicketsService.getTicketById(ticketId);
    return { success: true, ticket };
  }

  @Get('support-tickets/stats')
  async getSupportTicketStats() {
    const stats = await this.supportTicketsService.getTicketStats();
    return { success: true, stats };
  }

  @Put('support-tickets/:id/status')
  async updateSupportTicketStatus(
    @Param('id') ticketId: string,
    @Body() body: { status: TicketStatus },
    @Request() req,
  ) {
    const adminId = req.user.id;
    const ticket = await this.supportTicketsService.updateTicketStatus(ticketId, body.status, adminId);
    return { success: true, ticket };
  }

  @Put('support-tickets/:id/assign')
  async assignSupportTicket(
    @Param('id') ticketId: string,
    @Body() body: { assignedTo: string },
    @Request() req,
  ) {
    const adminId = req.user.id;
    const ticket = await this.supportTicketsService.assignTicket(ticketId, body.assignedTo, adminId);
    return { success: true, ticket };
  }

  @Post('support-tickets/:id/messages')
  async addSupportTicketMessage(
    @Param('id') ticketId: string,
    @Body() body: { message: string; isInternal?: boolean },
    @Request() req,
  ) {
    const adminId = req.user.id;
    const ticket = await this.supportTicketsService.addMessage(
      ticketId,
      body.message,
      adminId,
      'agent',
      body.isInternal || false,
    );
    return { success: true, ticket };
  }

  @Put('support-tickets/:id/resolve')
  async resolveSupportTicket(
    @Param('id') ticketId: string,
    @Body() body: { resolution: string },
    @Request() req,
  ) {
    const adminId = req.user.id;
    const ticket = await this.supportTicketsService.resolveTicket(ticketId, body.resolution, adminId);
    return { success: true, ticket };
  }

  @Put('support-tickets/:id/close')
  async closeSupportTicket(
    @Param('id') ticketId: string,
    @Request() req,
  ) {
    const adminId = req.user.id;
    const ticket = await this.supportTicketsService.closeTicket(ticketId, adminId);
    return { success: true, ticket };
  }

  @Get('dropoffs/:id/interactions')
  async getDropInteractions(
    @Param('id') dropId: string,
    @Query('excludeUserId') excludeUserId?: string,
  ) {
    const result = await this.adminService.getDropInteractions(dropId, excludeUserId);
    return result;
  }
} 