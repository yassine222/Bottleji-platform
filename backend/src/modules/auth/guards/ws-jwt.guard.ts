import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { UsersService } from '../../users/users.service';

@Injectable()
export class WsJwtGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const client: Socket = context.switchToWs().getClient();
      const token = client.handshake.auth.token;

      if (!token) {
        throw new WsException('Authentication token not found');
      }

      // Verify JWT token
      const payload = this.jwtService.verify(token);
      const userId = payload.sub;

      if (!userId) {
        throw new WsException('Invalid token payload');
      }

      // Get user from database
      const user = await this.usersService.findOne(userId);
      
      if (!user || user.isDeleted) {
        throw new WsException('User not found or deleted');
      }

      // Check if session has been invalidated
      if (user.sessionInvalidatedAt && user.sessionInvalidatedAt > new Date(payload.iat * 1000)) {
        throw new WsException('Session has been invalidated');
      }

      // Attach user to socket for later use
      client.data.user = user;
      
      return true;
    } catch (error) {
      throw new WsException('Invalid authentication token');
    }
  }
} 