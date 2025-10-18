import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { RewardsService } from './rewards.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('rewards')
@UseGuards(JwtAuthGuard)
export class RewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  /**
   * Get collector's reward stats
   * GET /rewards/stats/:collectorId
   */
  @Get('stats/:collectorId')
  async getCollectorStats(@Param('collectorId') collectorId: string) {
    const stats = await this.rewardsService.getCollectorStats(collectorId);
    return { success: true, stats };
  }

  /**
   * Get all tiers information
   * GET /rewards/tiers
   */
  @Get('tiers')
  async getAllTiers() {
    const tiers = this.rewardsService.getAllTiers();
    return { success: true, tiers };
  }

  /**
   * Award points for drop collection (called internally)
   * POST /rewards/award/:collectorId
   */
  @Post('award/:collectorId')
  async awardPoints(
    @Param('collectorId') collectorId: string,
    @Body() body: { dropId: string }
  ) {
    const result = await this.rewardsService.awardPointsForCollection(
      collectorId,
      body.dropId
    );
    return { success: true, ...result };
  }

  /**
   * Spend points (for reward shop)
   * POST /rewards/spend/:collectorId
   */
  @Post('spend/:collectorId')
  async spendPoints(
    @Param('collectorId') collectorId: string,
    @Body() body: { points: number; reason: string }
  ) {
    const result = await this.rewardsService.spendPoints(
      collectorId,
      body.points,
      body.reason
    );
    return { success: true, ...result };
  }
}
