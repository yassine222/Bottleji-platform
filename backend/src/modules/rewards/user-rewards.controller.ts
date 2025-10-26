import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  HttpStatus,
  HttpCode,
  Request,
} from '@nestjs/common';
import { RewardsService } from './rewards.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../users/schemas/user.schema';
import { UserRole } from '../users/schemas/user.schema';

@Controller('rewards')
@UseGuards(JwtAuthGuard)
export class UserRewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  /**
   * Get user's reward stats
   * GET /rewards/stats/:userId
   */
  @Get('stats/:userId')
  async getUserRewardStats(@Param('userId') userId: string, @Request() req: any) {
    const user = req.user;
    // Verify the user is requesting their own stats or is an admin
    if (user._id.toString() !== userId && !user.roles.includes(UserRole.ADMIN) && !user.roles.includes(UserRole.SUPER_ADMIN)) {
      throw new Error('Unauthorized: Cannot access other user\'s reward stats');
    }

    const stats = await this.rewardsService.getUserRewardStats(userId);
    return {
      success: true,
      data: { stats },
    };
  }

  /**
   * Get available reward items for users
   * GET /rewards/items
   */
  @Get('items')
  async getAvailableRewards(
    @Request() req: any,
    @Query('category') category?: string,
    @Query('subCategory') subCategory?: string,
    @Query('isActive') isActive?: boolean,
  ) {
    const items = await this.rewardsService.findAvailableForUser({
      category,
      subCategory,
      isActive,
    });
    return {
      success: true,
      data: items,
    };
  }

  /**
   * Get user's redemption history
   * GET /rewards/redemptions
   */
  @Get('redemptions')
  async getUserRedemptions(@Request() req: any) {
    const user = req.user;
    const redemptions = await this.rewardsService.getUserRedemptions(user._id.toString());
    return {
      success: true,
      data: redemptions,
    };
  }
}
