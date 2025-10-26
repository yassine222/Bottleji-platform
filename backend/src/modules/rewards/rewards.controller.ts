import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { RewardsService, RewardItemFilters } from './rewards.service';
import { CreateRewardItemDto, UpdateRewardItemDto } from './dto/reward-item.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('admin/rewards')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class RewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  /**
   * Create a new reward item
   * POST /admin/rewards
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createRewardItemDto: CreateRewardItemDto) {
    const rewardItem = await this.rewardsService.create(createRewardItemDto);
    return {
      success: true,
      message: 'Reward item created successfully',
      data: rewardItem,
    };
  }

  /**
   * Get all reward items with optional filtering
   * GET /admin/rewards
   */
  @Get()
  async findAll(@Query() filters: RewardItemFilters) {
    const result = await this.rewardsService.findAll(filters);
    return {
      success: true,
      data: result,
    };
  }

  /**
   * Get reward item statistics
   * GET /admin/rewards/stats
   */
  @Get('stats')
  async getStats() {
    const stats = await this.rewardsService.getStats();
    return {
      success: true,
      data: stats,
    };
  }

  /**
   * Get reward items by category
   * GET /admin/rewards/category/:category
   */
  @Get('category/:category')
  async findByCategory(@Param('category') category: string) {
    const items = await this.rewardsService.findByCategory(category as any);
    return {
      success: true,
      data: items,
    };
  }

  /**
   * Get reward items by sub-category
   * GET /admin/rewards/subcategory/:subCategory
   */
  @Get('subcategory/:subCategory')
  async findBySubCategory(@Param('subCategory') subCategory: string) {
    const items = await this.rewardsService.findBySubCategory(subCategory);
    return {
      success: true,
      data: items,
    };
  }


  /**
   * Get all redemptions (admin)
   * GET /admin/rewards/redemptions
   */
  @Get('redemptions')
  async getAllRedemptions(
    @Query('status') status?: string,
    @Query('userId') userId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const filters = {
      status: status as any,
      userId,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 50,
    };
    
    const result = await this.rewardsService.getAllRedemptions(filters);
    return {
      success: true,
      data: result.redemptions,
      total: result.total,
    };
  }

  /**
   * Get redemption by ID (admin)
   * GET /admin/rewards/redemptions/:id
   */
  @Get('redemptions/:id')
  async getRedemptionById(@Param('id') id: string) {
    const redemption = await this.rewardsService.getRedemptionById(id);
    return {
      success: true,
      data: redemption,
    };
  }

  /**
   * Get a single reward item by ID
   * GET /admin/rewards/:id
   */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const rewardItem = await this.rewardsService.findOne(id);
    return {
      success: true,
      data: rewardItem,
    };
  }

  /**
   * Update a reward item
   * PUT /admin/rewards/:id
   */
  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateRewardItemDto: UpdateRewardItemDto) {
    const rewardItem = await this.rewardsService.update(id, updateRewardItemDto);
    return {
      success: true,
      message: 'Reward item updated successfully',
      data: rewardItem,
    };
  }

  /**
   * Toggle active status of a reward item
   * PATCH /admin/rewards/:id/toggle-active
   */
  @Patch(':id/toggle-active')
  async toggleActive(@Param('id') id: string) {
    const rewardItem = await this.rewardsService.toggleActive(id);
    return {
      success: true,
      message: `Reward item ${rewardItem.isActive ? 'activated' : 'deactivated'} successfully`,
      data: rewardItem,
    };
  }

  /**
   * Update stock of a reward item
   * PATCH /admin/rewards/:id/stock
   */
  @Patch(':id/stock')
  async updateStock(@Param('id') id: string, @Body() body: { stock: number }) {
    const rewardItem = await this.rewardsService.updateStock(id, body.stock);
    return {
      success: true,
      message: 'Stock updated successfully',
      data: rewardItem,
    };
  }

  /**
   * Delete a reward item
   * DELETE /admin/rewards/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string) {
    await this.rewardsService.remove(id);
    return {
      success: true,
      message: 'Reward item deleted successfully',
    };
  }


  /**
   * Approve redemption (admin)
   * PATCH /admin/rewards/redemptions/:id/approve
   */
  @Patch('redemptions/:id/approve')
  async approveRedemption(@Param('id') id: string) {
    const redemption = await this.rewardsService.approveRedemption(id);
    return {
      success: true,
      message: 'Redemption approved successfully',
      data: redemption,
    };
  }

  /**
   * Reject redemption (admin)
   * PATCH /admin/rewards/redemptions/:id/reject
   */
  @Patch('redemptions/:id/reject')
  async rejectRedemption(@Param('id') id: string, @Body() body: { reason: string }) {
    const redemption = await this.rewardsService.rejectRedemption(id, body.reason);
    return {
      success: true,
      message: 'Redemption rejected successfully',
      data: redemption,
    };
  }

  /**
   * Mark redemption as fulfilled (admin)
   * PATCH /admin/rewards/redemptions/:id/fulfill
   */
  @Patch('redemptions/:id/fulfill')
  async fulfillRedemption(@Param('id') id: string) {
    const redemption = await this.rewardsService.updateRedemptionStatus(id, {
      status: 'delivered' as any,
    });
    return {
      success: true,
      message: 'Redemption marked as fulfilled successfully',
      data: redemption,
    };
  }
}