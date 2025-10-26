import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Request,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { CreateNotificationDto, UpdateNotificationDto, NotificationFiltersDto } from './dto/notification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';
// Using @Request() decorator instead of @GetUser()

@Controller('notifications')
@UseGuards(JwtAuthGuard, RolesGuard)
@UsePipes(new ValidationPipe({ transform: true }))
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * Get user's notifications
   * GET /notifications
   */
  @Get()
  async getUserNotifications(
    @Request() req: any,
    @Query() filters: NotificationFiltersDto,
  ) {
    const result = await this.notificationsService.getUserNotifications(req.user._id.toString(), filters);
    return {
      success: true,
      data: result.notifications,
      total: result.total,
      unreadCount: result.unreadCount,
    };
  }

  /**
   * Mark notification as read
   * PATCH /notifications/:id/read
   */
  @Patch(':id/read')
  @HttpCode(HttpStatus.OK)
  async markAsRead(
    @Param('id') notificationId: string,
    @Request() req: any,
  ) {
    const notification = await this.notificationsService.markAsRead(notificationId, req.user._id.toString());
    return {
      success: true,
      message: 'Notification marked as read',
      data: notification,
    };
  }

  /**
   * Mark all notifications as read
   * PATCH /notifications/read-all
   */
  @Patch('read-all')
  @HttpCode(HttpStatus.OK)
  async markAllAsRead(@Request() req: any) {
    const result = await this.notificationsService.markAllAsRead(req.user._id.toString());
    return {
      success: true,
      message: 'All notifications marked as read',
      data: result,
    };
  }

  /**
   * Delete notification
   * DELETE /notifications/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async deleteNotification(
    @Param('id') notificationId: string,
    @Request() req: any,
  ) {
    await this.notificationsService.delete(notificationId, req.user._id.toString());
    return {
      success: true,
      message: 'Notification deleted successfully',
    };
  }

  /**
   * Create notification (admin only)
   * POST /notifications
   */
  @Post()
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @HttpCode(HttpStatus.CREATED)
  async createNotification(@Body() createNotificationDto: CreateNotificationDto) {
    const notification = await this.notificationsService.create(createNotificationDto);
    return {
      success: true,
      message: 'Notification created successfully',
      data: notification,
    };
  }
}
