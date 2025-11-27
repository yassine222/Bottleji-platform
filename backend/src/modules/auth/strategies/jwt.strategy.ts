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
    // Validate payload structure
    if (!payload || !payload.sub) {
      throw new UnauthorizedException('Invalid token payload');
    }

    try {
      const user = await this.usersService.findOne(payload.sub);
      
      // Check if user exists
      if (!user) {
        throw new UnauthorizedException('User account not found');
      }

      // Note: We don't check for soft-deleted or permanently disabled accounts here
      // The session should remain valid until the user acknowledges the popup
      // Session invalidation will happen after user acknowledges the account deleted/disabled dialog
      // This allows the popup to show first without causing immediate 401 errors
      // - Soft-deleted users (isDeleted = true) will see account deleted card
      // - Permanently disabled users (isAccountLocked = true && accountLockedUntil = null) will see account disabled dialog

      // Check if user session has been invalidated (for force logout)
      // This happens AFTER user acknowledges the popup
      if (user.sessionInvalidatedAt && payload.iat) {
        const sessionInvalidatedTime = new Date(user.sessionInvalidatedAt).getTime();
        const tokenIssuedTime = payload.iat * 1000;
        if (sessionInvalidatedTime > tokenIssuedTime) {
          throw new UnauthorizedException('Session has been invalidated');
        }
      }

      return user;
    } catch (error) {
      // Re-throw UnauthorizedException as-is
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      // Wrap other errors
      throw new UnauthorizedException('Token validation failed');
    }
  }
} 