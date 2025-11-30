import { Controller, Get, Post, Body, Patch, Param, Delete, Query, Put } from '@nestjs/common';
import { DropoffsService } from './dropoffs.service';
import { CreateDropoffDto } from './dto/create-dropoff.dto';
import { CreateInteractionDto, GetCollectorStatsDto, GetCollectorHistoryDto } from './dto/collector-interaction.dto';
import { BadRequestException } from '@nestjs/common';

@Controller('dropoffs')
export class DropoffsController {
  constructor(private readonly dropoffsService: DropoffsService) {}

  @Post()
  create(@Body() createDropoffDto: CreateDropoffDto) {
    return this.dropoffsService.create(createDropoffDto);
  }

  @Get()
  findAll() {
    return this.dropoffsService.findAll();
  }

  @Get('available')
  findAvailableForCollectors(@Query('excludeCollectorId') excludeCollectorId?: string) {
    return this.dropoffsService.findAvailableForCollectors(excludeCollectorId);
  }

  @Get('collector/:collectorId/accepted')
  findAcceptedByCollector(@Param('collectorId') collectorId: string) {
    return this.dropoffsService.findAcceptedByCollector(collectorId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.dropoffsService.findOne(id);
  }

  @Get('user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.dropoffsService.findByUser(userId);
  }

  @Get('status/:status')
  findByStatus(@Param('status') status: string) {
    return this.dropoffsService.findByStatus(status);
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.dropoffsService.updateStatus(id, status);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateDropoffDto: any) {
    return this.dropoffsService.update(id, updateDropoffDto);
  }

  @Patch(':id/collector')
  assignCollector(@Param('id') id: string, @Body('collectorId') collectorId: string) {
    return this.dropoffsService.assignCollector(id, collectorId);
  }

  @Patch(':id/confirm-collection')
  confirmCollection(@Param('id') id: string) {
    return this.dropoffsService.confirmCollection(id);
  }

  @Patch(':id/cancel-accepted')
  async cancelAcceptedDrop(
    @Param('id') id: string,
    @Body() body: { reason?: string; cancelledByCollectorId?: string }
  ) {
    return this.dropoffsService.cancelAcceptedDrop(id, body.reason, body.cancelledByCollectorId);
  }

  @Post('cleanup-expired')
  cleanupExpiredAcceptedDrops() {
    console.log('🎯 Cleanup endpoint called!');
    return this.dropoffsService.cleanupExpiredAcceptedDrops();
  }

  @Get('test')
  test() {
    console.log('🧪 Test endpoint called!');
    return { message: 'Test endpoint working', timestamp: new Date().toISOString() };
  }

  @Get('debug/dropoff/:id/interactions')
  debugDropoffInteractions(@Param('id') id: string) {
    return this.dropoffsService.debugDropoffInteractions(id);
  }

  @Get('debug/collector/:id/interactions')
  debugCollectorInteractions(@Param('id') id: string) {
    return this.dropoffsService.debugCollectorInteractions(id);
  }

  @Get('verify/collector-data')
  verifyNoCollectorDataInDropoffs() {
    return this.dropoffsService.verifyNoCollectorDataInDropoffs();
  }

  @Get('debug/all-drops')
  debugAllDrops() {
    return this.dropoffsService.debugAllDrops();
  }

  @Post('migrate/user-warning-fields')
  async migrateUserWarningFields() {
    try {
      await this.dropoffsService.migrateUserWarningFields();
      return { message: 'User warning fields migration completed successfully' };
    } catch (error) {
      throw new BadRequestException('Migration failed: ' + error.message);
    }
  }

  @Post('cleanup/duplicate-expired')
  async cleanupDuplicateExpired() {
    console.log('🧹 Cleaning up duplicate EXPIRED interactions...');
    return this.dropoffsService.cleanupDuplicateExpired();
  }

  @Post('drop-expired-constraint')
  async dropExpiredConstraint() {
    console.log('🗑️ Dropping unique constraint for EXPIRED interactions...');
    return this.dropoffsService.dropExpiredConstraint();
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.dropoffsService.remove(id);
  }

  // Collector Interaction Tracking Endpoints
  @Post('interactions')
  createInteraction(@Body() createInteractionDto: CreateInteractionDto) {
    return this.dropoffsService.createInteraction(createInteractionDto);
  }

  @Get('collector/:collectorId/stats')
  getCollectorStats(
    @Param('collectorId') collectorId: string,
    @Query('timeRange') timeRange?: string
  ) {
    return this.dropoffsService.getCollectorStats(collectorId, timeRange);
  }

  @Get('collector/:collectorId/history')
  getCollectorHistory(
    @Param('collectorId') collectorId: string,
    @Query('status') status?: string,
    @Query('timeRange') timeRange?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.dropoffsService.getCollectorHistory(collectorId, status, timeRange, pageNum, limitNum);
  }

  @Get('user/:userId/drop-stats')
  getUserDropStats(
    @Param('userId') userId: string,
    @Query('timeRange') timeRange?: string
  ) {
    return this.dropoffsService.getUserDropStats(userId, timeRange);
  }

  @Get(':dropoffId/interaction-timeline')
  getDropInteractionTimeline(@Param('dropoffId') dropoffId: string) {
    return this.dropoffsService.getDropInteractionTimeline(dropoffId);
  }

  // =============================================================================
  // NEW COLLECTION ATTEMPT ENDPOINTS
  // =============================================================================

  @Post(':dropoffId/attempts')
  createCollectionAttempt(
    @Param('dropoffId') dropoffId: string,
    @Body() body: { collectorId: string }
  ) {
    return this.dropoffsService.createCollectionAttempt(dropoffId, body.collectorId);
  }

  @Patch(':dropoffId/attempts/:attemptId/complete')
  completeCollectionAttempt(
    @Param('attemptId') attemptId: string,
    @Body() body: { 
      outcome: 'expired' | 'cancelled' | 'collected',
      reason?: string,
      notes?: string,
      location?: { lat: number, lng: number }
    }
  ) {
    return this.dropoffsService.completeCollectionAttempt(
      attemptId, 
      body.outcome, 
      { reason: body.reason, notes: body.notes, location: body.location }
    );
  }

  @Patch(':dropoffId/attempts/:attemptId/location')
  updateCollectorLocation(
    @Param('attemptId') attemptId: string,
    @Body() body: {
      latitude: number;
      longitude: number;
      accuracy?: number;
      speed?: number;
      heading?: number;
    }
  ) {
    return this.dropoffsService.updateCollectorLocation(attemptId, body);
  }

  @Get(':dropoffId/attempts/:attemptId/location')
  getCollectorLocation(@Param('attemptId') attemptId: string) {
    return this.dropoffsService.getCollectorLocation(attemptId);
  }

  @Get('collector/:collectorId/attempts')
  getCollectorAttempts(
    @Param('collectorId') collectorId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number
  ) {
    return this.dropoffsService.getCollectorAttempts(
      collectorId, 
      page ? parseInt(page.toString()) : 1, 
      limit ? parseInt(limit.toString()) : 20
    );
  }

  @Get(':dropoffId/attempts')
  getDropoffAttempts(@Param('dropoffId') dropoffId: string) {
    return this.dropoffsService.getDropoffAttempts(dropoffId);
  }

  @Get('collector/:collectorId/attempts/stats')
  getCollectionAttemptStats(@Param('collectorId') collectorId: string) {
    return this.dropoffsService.getCollectionAttemptStats(collectorId);
  }

  // Report drop endpoint
  @Post(':dropId/report')
  async reportDrop(
    @Param('dropId') dropId: string,
    @Body() body: { collectorId: string; reason: string; details?: string },
  ) {
    const report = await this.dropoffsService.reportDrop(
      dropId,
      body.collectorId,
      body.reason,
      body.details,
    );
    return { success: true, report };
  }

  // Get reports for a drop
  @Get(':dropId/reports')
  async getDropReports(@Param('dropId') dropId: string) {
    const reports = await this.dropoffsService.getDropReports(dropId);
    return { success: true, reports };
  }
} 