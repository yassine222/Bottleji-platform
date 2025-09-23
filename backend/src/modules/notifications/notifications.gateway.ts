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
      console.log('🔌 WebSocket connection attempt...');
      
      // Extract token from handshake auth
      const token = client.handshake.auth.token;
      console.log('Token provided:', !!token);
      
      if (!token) {
        console.log('No token provided for WebSocket connection');
        client.disconnect();
        return;
      }

      // Verify token and get user info
      const userId = await this.verifyToken(token);
      console.log('User ID from token:', userId);
      
      if (!userId) {
        console.log('Invalid token for WebSocket connection');
        client.disconnect();
        return;
      }

      // Store connected user
      this.connectedUsers.set(userId, client);
      
      // Join user to their personal room
      await client.join(`user:${userId}`);
      
      console.log(`✅ User ${userId} connected to notifications`);
      console.log(`📊 Total connected users: ${this.connectedUsers.size}`);
      
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

  // Send notification to specific user
  sendNotificationToUser(userId: string, notification: NotificationPayload) {
    const userSocket = this.connectedUsers.get(userId);
    if (userSocket) {
      console.log(`📤 Sending notification to user ${userId}: ${notification.type}`);
      userSocket.emit('notification', notification);
    } else {
      console.log(`❌ User ${userId} not connected, notification not sent`);
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