import { Injectable, UnauthorizedException, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { EmailService } from '../email/email.service';
import { CreateUserDto } from './dto/create-user.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginDto } from './dto/login.dto';
import { SetupProfileDto } from './dto/setup-profile.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UpdateCollectorSubscriptionDto } from './dto/update-collector-subscription.dto';
import { UserRole } from '../users/schemas/user.schema';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private emailService: EmailService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  private generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async signup(createUserDto: CreateUserDto) {
    const existingUser = await this.usersService.findByEmail(createUserDto.email);
    if (existingUser) {
      throw new BadRequestException('Email already exists');
    }

    const otp = this.generateOTP();
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15); // OTP expires in 15 minutes

    const user = await this.usersService.create({
      ...createUserDto,
      verificationOTP: otp,
      otpExpiresAt,
      isVerified: false,
      otpAttempts: 0,
    });

    // Send OTP via email
    await this.emailService.sendOTPEmail(user.email, otp);

    return {
      message: 'Please verify your email with the OTP sent',
      email: user.email,
      otp, // Remove this in production
    };
  }

  async verifyOTP(verifyOtpDto: VerifyOtpDto) {
    const user = await this.usersService.findByEmail(verifyOtpDto.email);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (user.isVerified) {
      throw new BadRequestException('User is already verified');
    }

    if (user.otpAttempts >= 3) {
      throw new BadRequestException('Too many OTP attempts. Please request a new OTP.');
    }

    if (user.otpExpiresAt && new Date() > user.otpExpiresAt) {
      throw new BadRequestException('OTP has expired. Please request a new OTP.');
    }

    if (user.verificationOTP !== verifyOtpDto.otp) {
      // Increment OTP attempts
      await this.usersService.update(user.id, {
        otpAttempts: user.otpAttempts + 1,
      });
      throw new BadRequestException('Invalid OTP');
    }

    // Mark user as verified and clear OTP
    await this.usersService.update(user.id, {
      isVerified: true,
      verificationOTP: undefined,
      otpExpiresAt: undefined,
      otpAttempts: 0,
    });

    // Generate JWT token
    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.roles[0] || 'household',
    });

    return {
      message: 'Email verified successfully',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        address: user.address,
        profilePhoto: user.profilePhoto,
        roles: user.roles,
        collectorSubscriptionType: user.collectorSubscriptionType,
        isProfileComplete: user.isProfileComplete,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    };
  }

  async resendOTP(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (user.isVerified) {
      throw new BadRequestException('User is already verified');
    }

    const otp = this.generateOTP();
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15);

    await this.usersService.update(user.id, {
      verificationOTP: otp,
      otpExpiresAt,
      otpAttempts: 0,
    });

    await this.emailService.sendOTPEmail(user.email, otp);

    return {
      message: 'OTP resent successfully',
      email: user.email,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isVerified) {
      throw new UnauthorizedException('Please verify your email first');
    }

    // Compare password using bcrypt
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if account lock has expired and auto-unlock
    if (user.isAccountLocked && user.accountLockedUntil) {
      const now = new Date();
      if (now >= user.accountLockedUntil) {
        // Lock has expired, auto-unlock the account
        await this.usersService.unlockAccount(user.id);
        console.log(`✅ Account ${user.id} auto-unlocked on login`);
        
        // Refresh user data after unlock
        const unlockedUser = await this.usersService.findByEmail(loginDto.email);
        if (unlockedUser) {
          Object.assign(user, unlockedUser);
        }
      }
    }

    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.roles[0] || 'household',
    });

    return {
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        address: user.address,
        profilePhoto: user.profilePhoto,
        roles: user.roles,
        collectorSubscriptionType: user.collectorSubscriptionType,
        isProfileComplete: user.isProfileComplete,
        isAccountLocked: user.isAccountLocked,
        accountLockedUntil: user.accountLockedUntil,
        warningCount: user.warningCount,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    };
  }

  async adminLogin(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isVerified) {
      throw new UnauthorizedException('Please verify your email first');
    }

    // Check if user has any admin role
    const hasAdminRole = user.roles.includes(UserRole.SUPER_ADMIN) || 
                        user.roles.includes(UserRole.ADMIN) || 
                        user.roles.includes(UserRole.MODERATOR) || 
                        user.roles.includes(UserRole.SUPPORT_AGENT);
    
    if (!hasAdminRole) {
      throw new ForbiddenException('Access denied. Admin privileges required.');
    }

    // Compare password using bcrypt
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.roles[0] || 'admin',
      roles: user.roles, // Add roles array for frontend
    });

    return {
      message: 'Admin login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        address: user.address,
        profilePhoto: user.profilePhoto,
        roles: user.roles,
        collectorSubscriptionType: user.collectorSubscriptionType,
        isProfileComplete: user.isProfileComplete,
        mustChangePassword: user.mustChangePassword,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    };
  }

  async setupProfile(userId: string, setupProfileDto: SetupProfileDto) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    const updatedUser = await this.usersService.update(userId, {
      name: setupProfileDto.name,
      phoneNumber: setupProfileDto.phoneNumber,
      address: setupProfileDto.address,
      profilePhoto: setupProfileDto.profilePhoto,
      isProfileComplete: true,
    });

    return {
      message: 'Profile setup completed successfully',
      user: updatedUser,
    };
  }

  async updateProfile(userId: string, updateProfileDto: SetupProfileDto) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Only update fields that are provided (not null/undefined)
    const updateData: any = {};
    
    if (updateProfileDto.name !== undefined) {
      updateData.name = updateProfileDto.name;
    }
    if (updateProfileDto.phoneNumber !== undefined) {
      updateData.phoneNumber = updateProfileDto.phoneNumber;
    }
    if (updateProfileDto.address !== undefined) {
      updateData.address = updateProfileDto.address;
    }
    if (updateProfileDto.profilePhoto !== undefined) {
      updateData.profilePhoto = updateProfileDto.profilePhoto;
    }

    const updatedUser = await this.usersService.update(userId, updateData);

    return {
      message: 'Profile updated successfully',
      user: updatedUser,
    };
  }

  async updateRole(userId: string, updateRoleDto: UpdateRoleDto) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Convert string roles to UserRole enum
    const roles = updateRoleDto.roles.map(role => role as UserRole);

    const updatedUser = await this.usersService.update(userId, {
      roles: roles,
    });

    return {
      message: 'Role updated successfully',
      user: updatedUser,
    };
  }

  async updateCollectorSubscription(userId: string, updateSubscriptionDto: UpdateCollectorSubscriptionDto) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    const updatedUser = await this.usersService.update(userId, {
      collectorSubscriptionType: updateSubscriptionDto.collectorSubscriptionType,
    });

    return {
      message: 'Collector subscription updated successfully',
      user: updatedUser,
    };
  }

  async getProfile(userId: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        address: user.address,
        profilePhoto: user.profilePhoto,
        roles: user.roles,
        collectorSubscriptionType: user.collectorSubscriptionType,
        isProfileComplete: user.isProfileComplete,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    };
  }

  async getUserById(userId: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      phoneNumber: user.phoneNumber,
      isPhoneVerified: user.isPhoneVerified,
      address: user.address,
      profilePhoto: user.profilePhoto,
      roles: user.roles,
      collectorSubscriptionType: user.collectorSubscriptionType,
      isProfileComplete: user.isProfileComplete,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  async verifyPhone(userId: string, phoneNumber: string, firebaseToken: string) {
    try {
      // In a real implementation, you would verify the Firebase token here
      // For now, we'll just update the user's phone number and mark it as verified
      // You can add Firebase Admin SDK verification later
      
      const user = await this.usersService.findOne(userId);
      if (!user) {
        throw new BadRequestException('User not found');
      }

      // Update user with verified phone number
      await this.usersService.update(userId, {
        phoneNumber: phoneNumber,
        isPhoneVerified: true,
        phoneVerificationId: firebaseToken, // Store the Firebase token for reference
      });

      return {
        message: 'Phone number verified successfully',
        phoneNumber: phoneNumber,
        isPhoneVerified: true,
      };
    } catch (error) {
      throw new BadRequestException('Failed to verify phone number');
    }
  }

  async requestPasswordReset(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Don't reveal if user exists or not for security
      return {
        message: 'If an account with this email exists, a password reset code has been sent.',
      };
    }

    const otp = this.generateOTP();
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15); // OTP expires in 15 minutes

    // Store password reset OTP
    await this.usersService.update(user.id, {
      resetPasswordOtp: otp,
      resetPasswordOtpExpiry: otpExpiresAt,
    });

    // Send password reset email
    await this.emailService.sendPasswordResetEmail(user.email, otp);

    return {
      message: 'If an account with this email exists, a password reset code has been sent.',
      otp, // Remove this in production
    };
  }

  async verifyPasswordReset(email: string, otp: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('Invalid email or OTP');
    }

    if (user.resetPasswordOtpExpiry && new Date() > user.resetPasswordOtpExpiry) {
      throw new BadRequestException('Password reset code has expired. Please request a new one.');
    }

    if (user.resetPasswordOtp !== otp) {
      throw new BadRequestException('Invalid OTP');
    }

    return {
      message: 'Password reset code verified successfully',
    };
  }

  async resetPassword(email: string, otp: string, newPassword: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('Invalid email or OTP');
    }

    if (user.resetPasswordOtpExpiry && new Date() > user.resetPasswordOtpExpiry) {
      throw new BadRequestException('Password reset code has expired. Please request a new one.');
    }

    if (user.resetPasswordOtp !== otp) {
      throw new BadRequestException('Invalid OTP');
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset fields
    await this.usersService.update(user.id, {
      password: hashedPassword,
      resetPasswordOtp: undefined,
      resetPasswordOtpExpiry: undefined,
    });

    return {
      message: 'Password reset successfully',
    };
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear mustChangePassword flag
    await this.usersService.update(userId, {
      password: hashedNewPassword,
      mustChangePassword: false,
    });

    return {
      message: 'Password changed successfully',
    };
  }

}
