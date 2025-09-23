import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../../users/users.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private usersService: UsersService,
  ) {
    const jwtSecret = configService.get<string>('JWT_SECRET');
    if (!jwtSecret) {
      throw new Error('JWT_SECRET is not defined');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: jwtSecret,
    });
  }

  async validate(payload: any) {
    const user = await this.usersService.findOne(payload.sub);
    
    // Check if user exists and is not soft-deleted
    if (!user || user.isDeleted) {
      throw new UnauthorizedException('User account has been deleted');
    }

    // Check if user session has been invalidated (for force logout)
    if (user.sessionInvalidatedAt && user.sessionInvalidatedAt > new Date(payload.iat * 1000)) {
      throw new UnauthorizedException('Session has been invalidated');
    }

    return user;
  }
} 