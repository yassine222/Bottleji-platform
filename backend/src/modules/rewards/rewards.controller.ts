import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { RewardsService } from './rewards.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('rewards')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  /**
   * Get user's reward stats (works for both collectors and households)
   * GET /rewards/stats/:userId
   */
  @Get('stats/:userId')
  @Roles(UserRole.COLLECTOR, UserRole.HOUSEHOLD, UserRole.ADMIN, UserRole.SUPER_ADMIN)
  async getUserStats(@Param('userId') userId: string) {
    const stats = await this.rewardsService.getCollectorStats(userId);
    return { success: true, stats };
  }

  /**
   * Get all tiers information
   * GET /rewards/tiers
   */
  @Get('tiers')
  @Roles(UserRole.COLLECTOR, UserRole.HOUSEHOLD, UserRole.ADMIN, UserRole.SUPER_ADMIN)
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
   * POST /rewards/spend/:userId
   */
  @Post('spend/:userId')
  @Roles(UserRole.COLLECTOR, UserRole.HOUSEHOLD, UserRole.ADMIN, UserRole.SUPER_ADMIN)
  async spendPoints(
    @Param('userId') userId: string,
    @Body() body: { points: number; reason: string }
  ) {
    const result = await this.rewardsService.spendPoints(
      userId,
      body.points,
      body.reason
    );
    return result;
  }
}
