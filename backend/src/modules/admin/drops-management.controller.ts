import { Controller, Get, Put, Post, Body, UseGuards, Query, Param } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from './guards/admin.guard';
import { DropsManagementService } from './drops-management.service';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Controller('admin/drops-management')
@UseGuards(JwtAuthGuard, AdminGuard)
export class DropsManagementController {
  constructor(
    private readonly dropsManagementService: DropsManagementService,
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  /**
   * Get drops overview statistics
   * GET /admin/drops/stats
   */
  @Get('stats')
  async getDropsStats() {
    const stats = await this.dropsManagementService.getDropsStats();
    return { success: true, stats };
  }

  /**
   * Get drops list with advanced filters
   * GET /admin/drops/list
   */
  @Get('list')
  async getDropsList(
    @Query('status') status?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('userId') userId?: string,
    @Query('isSuspicious') isSuspicious?: string,
    @Query('isOld') isOld?: string,
    @Query('hasAttempts') hasAttempts?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const filters = {
      status,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      userId,
      isSuspicious: isSuspicious === 'true',
      isOld: isOld === 'true',
      hasAttempts: hasAttempts === 'true',
      search,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    };

    const result = await this.dropsManagementService.getDropsList(filters);
    return { success: true, ...result };
  }

  /**
   * Analyze old drops (>3 days, not collected)
   * GET /admin/drops/analyze-old
   */
  @Get('analyze-old')
  async analyzeOldDrops() {
    const oldDrops = await this.dropsManagementService.analyzeOldDrops();
    return {
      success: true,
      count: oldDrops.length,
      drops: oldDrops,
    };
  }

  /**
   * Hide old drops and send notifications
   * POST /admin/drops/hide-old
   */
  @Post('hide-old')
  async hideOldDrops(@Body('dropIds') dropIds: string[]) {
    const result = await this.dropsManagementService.hideOldDrops(dropIds);

    // Send notifications to affected users
    for (const userId of result.userIds) {
      this.notificationsGateway.sendNotificationToUser(userId, {
        type: 'drop_removed',
        title: 'Drop Removed',
        message: 'Your drop has been removed as it was older than 3 days and not collected.',
        data: {},
        timestamp: new Date(),
      });
    }

    return {
      success: true,
      hiddenCount: result.hiddenCount,
      notificationsSent: result.userIds.length,
    };
  }

  /**
   * Get flagged/suspicious drops
   * GET /admin/drops/flagged
   */
  @Get('flagged')
  async getFlaggedDrops() {
    const flaggedDrops = await this.dropsManagementService.getFlaggedDrops();
    return {
      success: true,
      count: flaggedDrops.length,
      drops: flaggedDrops,
    };
  }

  /**
   * Get detailed drop information
   * GET /admin/drops-management/details/:id
   */
  @Get('details/:id')
  async getDropDetails(@Param('id') dropId: string) {
    const details = await this.dropsManagementService.getDropDetails(dropId);
    return { success: true, ...details };
  }

  /**
   * Flag drop as suspicious
   * PUT /admin/drops-management/flag/:id
   */
  @Put('flag/:id')
  async flagDrop(@Param('id') dropId: string, @Body('reason') reason: string) {
    const drop = await this.dropsManagementService.flagDrop(dropId, reason);
    return { success: true, drop };
  }

  /**
   * Remove flag from drop
   * PUT /admin/drops-management/unflag/:id
   */
  @Put('unflag/:id')
  async unflagDrop(@Param('id') dropId: string) {
    const drop = await this.dropsManagementService.unflagDrop(dropId);
    return { success: true, drop };
  }

  /**
   * Delete drop permanently
   * DELETE /admin/drops-management/delete/:id
   */
  @Put('delete/:id')
  async deleteDrop(@Param('id') dropId: string) {
    const drop = await this.dropsManagementService.deleteDrop(dropId);
    
    // Notify the user
    if (drop && drop.userId) {
      this.notificationsGateway.sendNotificationToUser(drop.userId, {
        type: 'drop_deleted',
        title: 'Drop Deleted',
        message: 'Your drop has been deleted by an administrator.',
        data: { dropId: drop.id },
        timestamp: new Date(),
      });
    }
    
    return { success: true, drop };
  }

  /**
   * Get drop success rate analytics
   * GET /admin/drops/analytics/success-rate
   */
  @Get('analytics/success-rate')
  async getDropSuccessRate(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const stats = await this.dropsManagementService.getDropSuccessRate(
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
    return { success: true, stats };
  }

  /**
   * Get average collection time
   * GET /admin/drops/analytics/avg-collection-time
   */
  @Get('analytics/avg-collection-time')
  async getAverageCollectionTime(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const stats = await this.dropsManagementService.getAverageCollectionTime(
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
    return { success: true, stats };
  }

  /**
   * Get popular locations
   * GET /admin/drops/analytics/popular-locations
   */
  @Get('analytics/popular-locations')
  async getPopularLocations(@Query('limit') limit?: string) {
    const locations = await this.dropsManagementService.getPopularLocations(
      limit ? parseInt(limit) : 10,
    );
    return { success: true, locations };
  }

  /**
   * Get peak times analysis
   * GET /admin/drops/analytics/peak-times
   */
  @Get('analytics/peak-times')
  async getPeakTimes() {
    const stats = await this.dropsManagementService.getPeakTimes();
    return { success: true, stats };
  }

  /**
   * Get collector leaderboard
   * GET /admin/drops/performance/collector-leaderboard
   */
  @Get('performance/collector-leaderboard')
  async getCollectorLeaderboard(
    @Query('limit') limit?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const leaderboard = await this.dropsManagementService.getCollectorLeaderboard(
      limit ? parseInt(limit) : 10,
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
    return { success: true, leaderboard };
  }

  /**
   * Get household rankings
   * GET /admin/drops/performance/household-rankings
   */
  @Get('performance/household-rankings')
  async getHouseholdRankings(
    @Query('limit') limit?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const rankings = await this.dropsManagementService.getHouseholdRankings(
      limit ? parseInt(limit) : 10,
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
    return { success: true, rankings };
  }

  /**
   * Get time-based analytics
   * GET /admin/drops/analytics/time-based
   */
  @Get('analytics/time-based')
  async getTimeBasedAnalytics() {
    const stats = await this.dropsManagementService.getTimeBasedAnalytics();
    return { success: true, stats };
  }
}

