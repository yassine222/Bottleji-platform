import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { ConfigService } from '@nestjs/config';

interface ChatMessage {
  id: string;
  ticketId: string;
  message: string;
  senderId: string;
  senderType: 'user' | 'agent' | 'system';
  sentAt: Date;
  isInternal: boolean;
}

interface TypingIndicator {
  ticketId: string;
  userId: string;
  isTyping: boolean;
  senderType: 'user' | 'agent' | 'system';
}

interface PresenceIndicator {
  ticketId: string;
  userId: string;
  isPresent: boolean;
  senderType: 'user' | 'agent' | 'system';
}

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, Socket>();
  private userSockets = new Map<string, string>(); // userId -> socketId
  private typingUsers = new Map<string, Set<string>>(); // ticketId -> Set of userIds
  private presentUsers = new Map<string, Set<string>>(); // ticketId -> Set of userIds

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
    private configService: ConfigService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token;
      if (!token) {
        console.log('❌ No token provided for chat connection');
        client.disconnect();
        return;
      }

      const decoded = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      }) as any;
      const userId = decoded.sub || decoded.userId;

      if (!userId) {
        console.log('❌ No user ID in token for chat connection');
        client.disconnect();
        return;
      }

      // Store user connection
      this.connectedUsers.set(userId, client);
      this.userSockets.set(userId, client.id);

      console.log(`✅ User ${userId} connected to chat`);
      console.log(`📊 Total connected users: ${this.connectedUsers.size}`);

      // Send connection confirmation
      client.emit('chat_connected', {
        userId,
        timestamp: new Date(),
        message: 'Connected to real-time chat'
      });

    } catch (error) {
      console.error('❌ Chat connection error:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // Find and remove user from connected users
    for (const [userId, socket] of this.connectedUsers.entries()) {
      if (socket.id === client.id) {
        this.connectedUsers.delete(userId);
        this.userSockets.delete(userId);
        
        // Remove from typing and presence indicators
        for (const [ticketId, typingSet] of this.typingUsers.entries()) {
          typingSet.delete(userId);
          if (typingSet.size === 0) {
            this.typingUsers.delete(ticketId);
          }
        }
        
        for (const [ticketId, presentSet] of this.presentUsers.entries()) {
          presentSet.delete(userId);
          if (presentSet.size === 0) {
            this.presentUsers.delete(ticketId);
          }
        }
        
        console.log(`👋 User ${userId} disconnected from chat`);
        console.log(`📊 Total connected users: ${this.connectedUsers.size}`);
        break;
      }
    }
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { ticketId: string; message: string; senderType: 'user' | 'agent' | 'system' }
  ) {
    try {
      const userId = this.getUserIdFromSocket(client);
      if (!userId) return;

      const message: ChatMessage = {
        id: this.generateMessageId(),
        ticketId: data.ticketId,
        message: data.message,
        senderId: userId,
        senderType: data.senderType,
        sentAt: new Date(),
        isInternal: false,
      };

      console.log(`📨 Sending message: ${message.message} from ${message.senderType} ${userId} to ticket ${message.ticketId}`);

      // Broadcast message to all users connected to this ticket
      this.server.to(`ticket:${data.ticketId}`).emit('new_message', message);

      // Do not emit push notifications here to avoid duplicates.
      // Push notifications are handled centrally in SupportTicketsService after DB save.

      return { success: true, messageId: message.id };
    } catch (error) {
      console.error('❌ Error sending message:', error);
      client.emit('message_error', { error: 'Failed to send message' });
    }
  }

  @SubscribeMessage('join_ticket')
  async handleJoinTicket(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { ticketId: string; senderType: 'user' | 'agent' | 'system' }
  ) {
    try {
      const userId = this.getUserIdFromSocket(client);
      if (!userId) return;

      // Join the ticket room
      await client.join(`ticket:${data.ticketId}`);
      
      // Update presence indicator
      this.updatePresenceIndicator(data.ticketId, userId, true, data.senderType);

      console.log(`👤 User ${userId} joined ticket ${data.ticketId} as ${data.senderType}`);
      console.log(`👤 Room members count for ticket ${data.ticketId}:`, (await this.server.in(`ticket:${data.ticketId}`).fetchSockets()).length);

      // Notify others in the ticket
      client.to(`ticket:${data.ticketId}`).emit('user_joined', {
        ticketId: data.ticketId,
        userId,
        senderType: data.senderType,
        timestamp: new Date(),
      });

      return { success: true };
    } catch (error) {
      console.error('❌ Error joining ticket:', error);
    }
  }

  @SubscribeMessage('leave_ticket')
  async handleLeaveTicket(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { ticketId: string; senderType: 'user' | 'agent' | 'system' }
  ) {
    try {
      const userId = this.getUserIdFromSocket(client);
      if (!userId) return;

      // Leave the ticket room
      await client.leave(`ticket:${data.ticketId}`);
      
      // Update presence indicator
      this.updatePresenceIndicator(data.ticketId, userId, false, data.senderType);

      console.log(`👋 User ${userId} left ticket ${data.ticketId}`);

      // Notify others in the ticket
      client.to(`ticket:${data.ticketId}`).emit('user_left', {
        ticketId: data.ticketId,
        userId,
        senderType: data.senderType,
        timestamp: new Date(),
      });

      return { success: true };
    } catch (error) {
      console.error('❌ Error leaving ticket:', error);
    }
  }

  @SubscribeMessage('typing_start')
  async handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { ticketId: string; senderType: 'user' | 'agent' | 'system' }
  ) {
    try {
      const userId = this.getUserIdFromSocket(client);
      if (!userId) return;

      this.updateTypingIndicator(data.ticketId, userId, true, data.senderType);

      // Notify others in the ticket
      client.to(`ticket:${data.ticketId}`).emit('typing_indicator', {
        ticketId: data.ticketId,
        userId,
        isTyping: true,
        senderType: data.senderType,
        timestamp: new Date(),
      });

    } catch (error) {
      console.error('❌ Error handling typing start:', error);
    }
  }

  @SubscribeMessage('typing_stop')
  async handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { ticketId: string; senderType: 'user' | 'agent' | 'system' }
  ) {
    try {
      const userId = this.getUserIdFromSocket(client);
      if (!userId) return;

      this.updateTypingIndicator(data.ticketId, userId, false, data.senderType);

      // Notify others in the ticket
      client.to(`ticket:${data.ticketId}`).emit('typing_indicator', {
        ticketId: data.ticketId,
        userId,
        isTyping: false,
        senderType: data.senderType,
        timestamp: new Date(),
      });

    } catch (error) {
      console.error('❌ Error handling typing stop:', error);
    }
  }

  // Helper methods
  private getUserIdFromSocket(client: Socket): string | null {
    for (const [userId, socket] of this.connectedUsers.entries()) {
      if (socket.id === client.id) {
        return userId;
      }
    }
    return null;
  }

  private generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private updateTypingIndicator(ticketId: string, userId: string, isTyping: boolean, senderType: 'user' | 'agent' | 'system') {
    if (!this.typingUsers.has(ticketId)) {
      this.typingUsers.set(ticketId, new Set());
    }

    const typingSet = this.typingUsers.get(ticketId)!;
    
    if (isTyping) {
      typingSet.add(userId);
    } else {
      typingSet.delete(userId);
    }

    if (typingSet.size === 0) {
      this.typingUsers.delete(ticketId);
    }

    console.log(`⌨️ Typing indicator updated for ticket ${ticketId}: ${isTyping ? 'started' : 'stopped'} by ${senderType} ${userId}`);
  }

  private updatePresenceIndicator(ticketId: string, userId: string, isPresent: boolean, senderType: 'user' | 'agent' | 'system') {
    if (!this.presentUsers.has(ticketId)) {
      this.presentUsers.set(ticketId, new Set());
    }

    const presentSet = this.presentUsers.get(ticketId)!;
    
    if (isPresent) {
      presentSet.add(userId);
    } else {
      presentSet.delete(userId);
    }

    if (presentSet.size === 0) {
      this.presentUsers.delete(ticketId);
    }

    console.log(`👤 Presence indicator updated for ticket ${ticketId}: ${isPresent ? 'present' : 'absent'} ${senderType} ${userId}`);
  }

  private sendMessageNotification(message: ChatMessage) {
    // This will be implemented to send push notifications
    console.log(`🔔 Sending notification for message in ticket ${message.ticketId}`);
  }

  // Public methods for external services
  public async sendMessageToTicket(ticketId: string, message: ChatMessage) {
    const room = `ticket:${ticketId}`;
    const sockets = await this.server.in(room).fetchSockets();
    console.log(`📤 Sending message to room ${room}, ${sockets.length} connected clients`);
    console.log(`📤 Message:`, message);
    this.server.to(room).emit('new_message', message);
  }

  public isUserConnected(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  public getConnectedUsers(): string[] {
    return Array.from(this.connectedUsers.keys());
  }
}
