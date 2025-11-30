import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards, Inject, forwardRef } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WsJwtGuard } from '../auth/guards/ws-jwt.guard';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { NotificationsService } from './notifications.service';
import { FCMService } from './fcm.service';
import { NotificationType, NotificationPriority } from './schemas/notification.schema';
import { DropoffsService } from '../dropoffs/dropoffs.service';

export interface NotificationPayload {
  type: string;
  title: string;
  message: string;
  data?: any;
  userId?: string;
  timestamp: Date;
}

@WebSocketGateway({
  cors: {
    origin: ["http://localhost:3001", "http://172.20.10.12:3001", "http://172.20.10.12:3000", "http://192.168.1.14:3001", "http://192.168.1.14:3000"],
    credentials: true
  },
  namespace: '/notifications'
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, Socket>();

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
    private fcmService: FCMService,
    @Inject(forwardRef(() => DropoffsService))
    private dropoffsService: DropoffsService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      // Extract token from handshake auth
      const token = client.handshake.auth.token;
      
      if (!token) {
        client.disconnect();
        return;
      }

      // Verify token and get user info
      const userId = await this.verifyToken(token);
      console.log('🔍 WebSocket connection - User ID from token:', userId);
      
      if (!userId) {
        client.disconnect();
        return;
      }

      // Normalize userId to string to ensure consistent storage
      const normalizedUserId = String(userId);
      
      // Store connected user with normalized ID
      this.connectedUsers.set(normalizedUserId, client);
      
      // Join user to their personal room
      await client.join(`user:${normalizedUserId}`);
      
      console.log(`✅ User ${normalizedUserId} connected (original: ${userId})`);
      console.log(`📊 Total connected users: ${this.connectedUsers.size}`);
      
      // Add event listener to catch all events for debugging
      (client as any).onAny((eventName: string, ...args: any[]) => {
        console.log(`🔍 ===== INCOMING WEBSOCKET EVENT =====`);
        console.log(`🔍 Event name: ${eventName}`);
        console.log(`🔍 Client ID: ${client.id}`);
        console.log(`🔍 User ID: ${normalizedUserId}`);
        console.log(`🔍 Args:`, JSON.stringify(args, null, 2));
        console.log(`🔍 ====================================`);
      });
      
      // Removed welcome notification - no longer needed for testing

    } catch (error) {
      console.error('❌ Connection error:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // Remove user from connected users
    for (const [userId, socket] of this.connectedUsers.entries()) {
      if (socket === client) {
        this.connectedUsers.delete(userId);
        console.log(`User ${userId} disconnected from notifications`);
        break;
      }
    }
  }

  @SubscribeMessage('ping')
  handlePing(@ConnectedSocket() client: Socket) {
    client.emit('pong', { timestamp: new Date() });
  }

  @SubscribeMessage('test_notification')
  handleTestNotification(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
    // Find the user ID by looking through the connected users map
    let userId: string | null = null;
    for (const [uid, socket] of this.connectedUsers.entries()) {
      if (socket.id === client.id) {
        userId = uid;
        break;
      }
    }
    
    if (userId) {
      this.sendNotificationToUser(userId, {
        type: 'test',
        title: 'Test Notification',
        message: 'This is a test notification',
        data: { test: true },
        userId,
        timestamp: new Date(),
      });
    }
  }

  @SubscribeMessage('typing_indicator')
  handleTypingIndicator(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
    // Find the user ID by looking through the connected users map
    let userId: string | null = null;
    for (const [uid, socket] of this.connectedUsers.entries()) {
      if (socket.id === client.id) {
        userId = uid;
        break;
      }
    }
    
    if (userId && data.ticketId && data.senderType) {
      // Forward typing indicator to the other party
      if (data.senderType === 'user') {
        // User is typing, notify admins
        this.server.emit('admin_typing_indicator', {
          ticketId: data.ticketId,
          isTyping: data.isTyping,
          senderType: 'user',
          timestamp: new Date(),
        });
      } else if (data.senderType === 'agent') {
        // Admin is typing, notify the user
        // We need to get the user ID from the ticket
        // For now, we'll broadcast to all admins
        this.server.emit('admin_typing_indicator', {
          ticketId: data.ticketId,
          isTyping: data.isTyping,
          senderType: 'agent',
          timestamp: new Date(),
        });
      }
    }
  }

  @SubscribeMessage('presence_indicator')
  handlePresenceIndicator(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
    // Find the user ID by looking through the connected users map
    let userId: string | null = null;
    for (const [uid, socket] of this.connectedUsers.entries()) {
      if (socket.id === client.id) {
        userId = uid;
        break;
      }
    }
    
    if (userId && data.ticketId && data.senderType) {
      // Forward presence indicator to the other party
      if (data.senderType === 'user') {
        // User presence change, notify admins
        this.server.emit('admin_presence_indicator', {
          ticketId: data.ticketId,
          isPresent: data.isPresent,
          senderType: 'user',
          timestamp: new Date(),
        });
      } else if (data.senderType === 'agent') {
        // Admin presence change, notify the user
        this.server.emit('admin_presence_indicator', {
          ticketId: data.ticketId,
          isPresent: data.isPresent,
          senderType: 'agent',
          timestamp: new Date(),
        });
      }
    }
  }

  /**
   * Handle collector location updates
   * Collectors send their location via WebSocket, which is then broadcasted to household users
   */
  @SubscribeMessage('collector_location_update')
  async handleCollectorLocationUpdate(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
    try {
      console.log('📨 ===== COLLECTOR LOCATION UPDATE HANDLER CALLED =====');
      console.log('📨 WebSocket event received: collector_location_update');
      console.log('📦 Event data:', JSON.stringify(data, null, 2));
      console.log('🔌 Client ID:', client.id);
      console.log('👥 Connected users count:', this.connectedUsers.size);
      
      // Find the user ID (collector) by looking through the connected users map
      let collectorId: string | null = null;
      for (const [uid, socket] of this.connectedUsers.entries()) {
        if (socket.id === client.id) {
          collectorId = uid;
          break;
        }
      }

      if (!collectorId) {
        console.error('❌ Collector location update: User not found in connected users');
        console.error('🔍 Available connected users:', Array.from(this.connectedUsers.keys()));
        client.emit('error', { message: 'User not authenticated' });
        return;
      }

      console.log(`✅ Found collector ID: ${collectorId}`);

      // Validate required fields
      if (!data.attemptId) {
        console.error('❌ Collector location update: Missing attemptId');
        client.emit('error', { message: 'Missing attemptId' });
        return;
      }

      if (data.latitude === undefined || data.longitude === undefined) {
        console.error('❌ Collector location update: Missing latitude or longitude');
        client.emit('error', { message: 'Missing latitude or longitude' });
        return;
      }

      console.log(`📍 Collector ${collectorId} location update for attempt ${data.attemptId}:`, {
        latitude: data.latitude,
        longitude: data.longitude,
        accuracy: data.accuracy,
        speed: data.speed,
        heading: data.heading,
      });

      // Update location via dropoffs service (this will also broadcast to household)
      console.log('🔄 Calling dropoffsService.updateCollectorLocation...');
      const result = await this.dropoffsService.updateCollectorLocation(data.attemptId, {
        latitude: data.latitude,
        longitude: data.longitude,
        accuracy: data.accuracy,
        speed: data.speed,
        heading: data.heading,
      });

      console.log('✅ updateCollectorLocation returned:', result ? 'Success' : 'Failed');

      // Send confirmation to collector
      client.emit('collector_location_update_confirmed', {
        attemptId: data.attemptId,
        timestamp: new Date(),
      });

      console.log(`✅ Collector location update processed for attempt ${data.attemptId}`);
    } catch (error: any) {
      console.error('❌ Error handling collector location update:', error);
      console.error('❌ Error stack:', error.stack);
      client.emit('error', {
        message: error.message || 'Failed to update location',
        code: error.status || 500,
      });
    }
  }

  /**
   * Handle subscription to collector location updates (for household users)
   * This is optional - location updates are automatically sent to the drop owner
   */
  @SubscribeMessage('subscribe_to_collector_location')
  handleSubscribeToCollectorLocation(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
    try {
      // Find the user ID by looking through the connected users map
      let userId: string | null = null;
      for (const [uid, socket] of this.connectedUsers.entries()) {
        if (socket.id === client.id) {
          userId = uid;
          break;
        }
      }

      if (!userId) {
        console.error('❌ Subscribe to collector location: User not found');
        client.emit('error', { message: 'User not authenticated' });
        return;
      }

      if (!data.dropoffId) {
        console.error('❌ Subscribe to collector location: Missing dropoffId');
        client.emit('error', { message: 'Missing dropoffId' });
        return;
      }

      // Join room for this drop (optional - location is already sent to user room)
      client.join(`drop:${data.dropoffId}`);
      console.log(`✅ User ${userId} subscribed to collector location for drop ${data.dropoffId}`);

      client.emit('subscribed_to_collector_location', {
        dropoffId: data.dropoffId,
        timestamp: new Date(),
      });
    } catch (error: any) {
      console.error('❌ Error subscribing to collector location:', error);
      client.emit('error', {
        message: error.message || 'Failed to subscribe',
      });
    }
  }

  // Send notification to specific user
  async sendNotificationToUser(userId: string, notification: NotificationPayload) {
    // Normalize userId to string to ensure consistent matching
    const normalizedUserId = String(userId);
    
    console.log(`📤 ===== SENDING NOTIFICATION =====`);
    console.log(`📤 User ID: ${normalizedUserId} (original: ${userId})`);
    console.log(`📤 Notification type: ${notification.type}`);
    console.log(`📤 Notification title: ${notification.title}`);
    console.log(`📤 Connected users: ${Array.from(this.connectedUsers.keys()).join(', ')}`);
    
    // Try to find user socket - check both normalized and original format
    let userSocket = this.connectedUsers.get(normalizedUserId);
    if (!userSocket) {
      // Try original format in case it's stored differently
      userSocket = this.connectedUsers.get(userId);
    }
    
    if (userSocket) {
      console.log(`✅ User ${normalizedUserId} is connected, sending via WebSocket`);
      userSocket.emit('notification', notification);
      console.log(`✅ WebSocket notification sent to user ${normalizedUserId}`);
    } else {
      console.log(`⚠️ User ${normalizedUserId} is NOT connected to WebSocket`);
      console.log(`⚠️ FCM is not configured/available - notification will be saved to database only`);
      console.log(`⚠️ User will receive notification when they reconnect to WebSocket`);
      // Note: Since FCM is not available, we only save to database
      // The user will receive the notification when they reconnect via WebSocket
      // or when they fetch notifications from the API
    }

    // Save notification to database
    try {
      // Map notification type to database enum
      const dbType = this.mapNotificationTypeToEnum(notification.type);
      if (dbType) {
        await this.notificationsService.create({
          userId: normalizedUserId,
          type: dbType,
          title: notification.title,
          message: notification.message,
          priority: this.getPriorityForType(notification.type),
          data: notification.data || {},
        });
        console.log(`💾 Notification saved to database: ${notification.type} for user ${normalizedUserId}`);
      } else {
        console.warn(`⚠️ Notification type ${notification.type} not mapped to database enum, skipping save`);
      }
    } catch (error) {
      console.error(`❌ Error saving notification to database: ${error}`);
      // Don't fail the WebSocket send if database save fails
    }
    console.log(`📤 =================================`);
  }

  // Map notification type string to NotificationType enum
  private mapNotificationTypeToEnum(type: string): NotificationType | null {
    const typeMap: { [key: string]: NotificationType } = {
      'drop_accepted': NotificationType.DROP_ACCEPTED,
      'drop_collected': NotificationType.DROP_COLLECTED,
      'drop_collected_with_rewards': NotificationType.DROP_COLLECTED_WITH_REWARDS,
      'drop_collected_with_tier_upgrade': NotificationType.DROP_COLLECTED_WITH_TIER_UPGRADE,
      'drop_cancelled': NotificationType.DROP_CANCELLED,
      'drop_expired': NotificationType.DROP_EXPIRED,
      'drop_near_expiring': NotificationType.DROP_NEAR_EXPIRING,
      'drop_censored': NotificationType.DROP_CENSORED,
      'ticket_message': NotificationType.TICKET_MESSAGE,
      'account_locked': NotificationType.ACCOUNT_LOCKED,
      'account_unlocked': NotificationType.ACCOUNT_UNLOCKED,
      'application_approved': NotificationType.APPLICATION_APPROVED,
      'application_rejected': NotificationType.APPLICATION_REJECTED,
      'application_reversed': NotificationType.APPLICATION_REVERSED,
      'test': NotificationType.TEST,
    };
    return typeMap[type] || null;
  }

  // Get priority for notification type
  private getPriorityForType(type: string): NotificationPriority {
    const highPriorityTypes = [
      'account_locked',
      'drop_censored',
      'application_rejected',
    ];
    const urgentPriorityTypes = [
      'account_locked',
    ];
    
    if (urgentPriorityTypes.includes(type)) {
      return NotificationPriority.URGENT;
    } else if (highPriorityTypes.includes(type)) {
      return NotificationPriority.HIGH;
    } else {
      return NotificationPriority.MEDIUM;
    }
  }

  sendApplicationStatusUpdate(userId: string, status: string, data: any) {
    const userSocket = this.connectedUsers.get(userId);
    if (userSocket) {
      console.log(`📤 Sending application status update to user ${userId}: ${status}`);
      userSocket.emit(`application_${status}`, data);
    } else {
      console.log(`❌ User ${userId} not connected, application status update not sent`);
    }
  }

  // Send notification to all connected users
  sendNotificationToAll(notification: NotificationPayload) {
    this.server.emit('notification', notification);
    console.log('Broadcast notification sent:', notification.type);
  }

  // Send notification to users with specific roles
  sendNotificationToRole(role: string, notification: NotificationPayload) {
    this.server.to(`role:${role}`).emit('notification', notification);
    console.log(`Role notification sent to ${role}:`, notification.type);
  }

  // Force logout user (for admin actions)
  forceLogoutUser(userId: string, reason: string) {
    console.log(`🚪 NotificationsGateway: Force logout requested for user ${userId}`);
    console.log(`🚪 NotificationsGateway: Reason: ${reason}`);
    
    const userSocket = this.connectedUsers.get(userId);
    console.log(`🚪 NotificationsGateway: User socket found: ${userSocket ? 'Yes' : 'No'}`);
    
    if (userSocket) {
      console.log(`🚪 NotificationsGateway: Sending force_logout event to user ${userId}`);
      userSocket.emit('force_logout', {
        reason,
        timestamp: new Date()
      });
      console.log(`🚪 NotificationsGateway: Force logout event sent to user ${userId}`);
      
      userSocket.disconnect();
      this.connectedUsers.delete(userId);
      console.log(`🚪 NotificationsGateway: User ${userId} force logged out: ${reason}`);
    } else {
      console.log(`🚪 NotificationsGateway: User ${userId} not connected to WebSocket`);
    }
  }

  // Get connected users count
  getConnectedUsersCount(): number {
    return this.connectedUsers.size;
  }

  // Check if user is connected
  isUserConnected(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  // Send ticket message update to user
  async sendTicketMessageUpdate(userId: string, ticketId: string, message: any) {
    console.log(`📤 ===== SEND TICKET MESSAGE UPDATE =====`);
    console.log(`📤 Target User ID: ${userId}`);
    console.log(`📤 Ticket ID: ${ticketId}`);
    console.log(`📤 Message:`, message);
    console.log(`📤 Connected users:`, Array.from(this.connectedUsers.keys()));
    console.log(`📤 User ${userId} connected:`, this.connectedUsers.has(userId));
    console.log(`📤 Sender type: ${message.senderType}`);
    
    const notification = {
      type: 'ticket_message',
      title: 'New Support Message',
      message: 'You have a new message on your support ticket',
      data: {
        ticketId,
        message,
      },
      userId,
      timestamp: new Date(),
    };
    
    console.log(`📤 Notification payload:`, notification);
    
    await this.sendNotificationToUser(userId, notification);
    console.log(`📤 ======================================`);
  }

  // Send typing indicator to user
  sendTypingIndicator(userId: string, ticketId: string, isTyping: boolean, senderType: 'user' | 'agent') {
    const userSocket = this.connectedUsers.get(userId);
    if (userSocket) {
      console.log(`📝 Sending typing indicator to user ${userId} for ticket ${ticketId}: ${isTyping}`);
      userSocket.emit('typing_indicator', {
        ticketId,
        isTyping,
        senderType,
        timestamp: new Date(),
      });
    }
  }

  // Send presence indicator to user
  sendPresenceIndicator(userId: string, ticketId: string, isPresent: boolean, senderType: 'user' | 'agent') {
    const userSocket = this.connectedUsers.get(userId);
    if (userSocket) {
      console.log(`👤 Sending presence indicator to user ${userId} for ticket ${ticketId}: ${isPresent}`);
      userSocket.emit('presence_indicator', {
        ticketId,
        isPresent,
        senderType,
        timestamp: new Date(),
      });
    }
  }

  // Broadcast ticket update to all admins
  sendTicketUpdateToAdmins(ticketId: string, updateType: string, data: any) {
    console.log(`📤 Broadcasting ticket update to admins: ${updateType} for ticket ${ticketId}`);
    this.server.emit('admin_ticket_update', {
      type: updateType,
      ticketId,
      data,
      timestamp: new Date(),
    });
  }

  private async verifyToken(token: string): Promise<string | null> {
    try {
      const decoded = this.jwtService.verify(token);
      const userId = decoded.sub?.toString() || decoded.sub; // Ensure it's a string
      const user = await this.usersService.findOne(userId);

      if (!user) {
        console.log('User not found for WebSocket token');
        return null;
      }

      // Ensure we return a string
      return userId?.toString() || null;
    } catch (error) {
      console.error('Error verifying WebSocket token:', error);
      return null;
    }
  }
} 