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
import { UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WsJwtGuard } from '../auth/guards/ws-jwt.guard';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';

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
    origin: ["http://localhost:3001", "http://172.20.10.12:3001", "http://172.20.10.12:3000"],
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

      // Store connected user
      this.connectedUsers.set(userId, client);
      
      // Join user to their personal room
      await client.join(`user:${userId}`);
      
      console.log(`✅ User ${userId} connected`);
      
      // Send welcome notification
      this.sendNotificationToUser(userId, {
        type: 'connection',
        title: 'Connected',
        message: 'You are now connected to real-time notifications',
        timestamp: new Date()
      });

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

  // Send notification to specific user
  sendNotificationToUser(userId: string, notification: NotificationPayload) {
    const userSocket = this.connectedUsers.get(userId);
    if (userSocket) {
      userSocket.emit('notification', notification);
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
  sendTicketMessageUpdate(userId: string, ticketId: string, message: any) {
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
    
    this.sendNotificationToUser(userId, notification);
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
      const userId = decoded.sub;
      const user = await this.usersService.findOne(userId);

      if (!user) {
        console.log('User not found for WebSocket token');
        return null;
      }

      return userId;
    } catch (error) {
      console.error('Error verifying WebSocket token:', error);
      return null;
    }
  }
} 