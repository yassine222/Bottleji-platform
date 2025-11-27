import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EarningsSessionService } from './earnings-session.service';

@Controller('earnings')
@UseGuards(JwtAuthGuard)
export class EarningsController {
  constructor(private readonly earningsSessionService: EarningsSessionService) {}

  /**
   * Get today's session earnings
   * GET /earnings/today
   */
  @Get('today')
  async getTodayEarnings(@Request() req: any) {
    const userId = req.user.userId;
    const session = await this.earningsSessionService.getTodaySession(userId);
    
    return {
      sessionEarnings: session?.sessionEarnings || 0,
      collectionCount: session?.collectionCount || 0,
      isActive: session?.isActive || false,
      startTime: session?.startTime,
      lastCollectionTime: session?.lastCollectionTime,
    };
  }

  /**
   * Get active session (last collection within 3 hours)
   * GET /earnings/active
   */
  @Get('active')
  async getActiveSession(@Request() req: any) {
    const userId = req.user.userId;
    const session = await this.earningsSessionService.getActiveSession(userId);
    
    if (!session) {
      return {
        sessionEarnings: 0,
        collectionCount: 0,
        isActive: false,
      };
    }

    return {
      sessionEarnings: session.sessionEarnings,
      collectionCount: session.collectionCount,
      isActive: session.isActive,
      startTime: session.startTime,
      lastCollectionTime: session.lastCollectionTime,
    };
  }

  /**
   * Get earnings history
   * GET /earnings/history?page=1&limit=20
   */
  @Get('history')
  async getEarningsHistory(
    @Request() req: any,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '20',
  ) {
    const userId = req.user.userId;
    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;

    const result = await this.earningsSessionService.getEarningsHistory(userId, pageNum, limitNum);

    return {
      sessions: result.sessions.map(session => ({
        id: (session as any)._id?.toString() || session.id,
        date: session.date,
        sessionEarnings: session.sessionEarnings,
        collectionCount: session.collectionCount,
        startTime: session.startTime,
        lastCollectionTime: session.lastCollectionTime,
        isActive: session.isActive,
      })),
      total: result.total,
      page: pageNum,
      limit: limitNum,
    };
  }

  /**
   * Get total lifetime earnings
   * GET /earnings/total
   */
  @Get('total')
  async getTotalEarnings(@Request() req: any) {
    const userId = req.user.userId;
    const total = await this.earningsSessionService.getTotalEarnings(userId);
    
    return {
      totalEarnings: total,
    };
  }
}

