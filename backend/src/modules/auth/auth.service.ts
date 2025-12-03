import { Injectable, UnauthorizedException, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { UsersService } from '../users/users.service';
import { EmailService } from '../email/email.service';
import { CreateUserDto } from './dto/create-user.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginDto } from './dto/login.dto';
import { SetupProfileDto } from './dto/setup-profile.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UpdateCollectorSubscriptionDto } from './dto/update-collector-subscription.dto';
import { UserRole } from '../users/schemas/user.schema';
import { TemporarySignup, TemporarySignupDocument } from './schemas/temporary-signup.schema';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private emailService: EmailService,
    private jwtService: JwtService,
    private configService: ConfigService,
    @InjectModel(TemporarySignup.name) private temporarySignupModel: Model<TemporarySignupDocument>,
  ) {}

  private generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async signup(createUserDto: CreateUserDto) {
    // Check if user already exists and is verified
    const existingUser = await this.usersService.findByEmail(createUserDto.email);
    if (existingUser) {
      // Explicitly check if account is verified
      if (existingUser.isVerified) {
        throw new BadRequestException('Email already exists and is verified');
      } else {
        // This shouldn't happen with new flow, but handle legacy unverified accounts
        throw new BadRequestException('An account with this email exists but is not verified. Please verify your email or contact support.');
      }
    }

    // Check if there's already a temporary signup for this email
    const existingTempSignup = await this.temporarySignupModel.findOne({ email: createUserDto.email }).exec();
    
    const otp = this.generateOTP();
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15); // OTP expires in 15 minutes

    // Hash the password before storing
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    if (existingTempSignup) {
      // Update existing temporary signup with new OTP
      existingTempSignup.verificationOTP = otp;
      existingTempSignup.otpExpiresAt = otpExpiresAt;
      existingTempSignup.password = hashedPassword;
      existingTempSignup.otpAttempts = 0;
      await existingTempSignup.save();
    } else {
      // Create new temporary signup (account not created yet)
      await this.temporarySignupModel.create({
        email: createUserDto.email,
        password: hashedPassword,
        verificationOTP: otp,
        otpExpiresAt,
        otpAttempts: 0,
      });
    }

    // Send OTP via email
    await this.emailService.sendOTPEmail(createUserDto.email, otp);

    return {
      message: 'Please verify your email with the OTP sent',
      email: createUserDto.email,
      otp, // Remove this in production
    };
  }

  async verifyOTP(verifyOtpDto: VerifyOtpDto) {
    // First check if user already exists and is verified (shouldn't happen, but safety check)
    const existingUser = await this.usersService.findByEmail(verifyOtpDto.email);
    if (existingUser && existingUser.isVerified) {
      throw new BadRequestException('This email is already verified. Please login instead.');
    }

    // Find temporary signup (account not created yet)
    const tempSignup = await this.temporarySignupModel.findOne({ email: verifyOtpDto.email }).exec();
    if (!tempSignup) {
      throw new BadRequestException('No signup found for this email. Please sign up first.');
    }

    // Check if OTP has expired
    if (new Date() > tempSignup.otpExpiresAt) {
      throw new BadRequestException('OTP has expired. Please request a new OTP.');
    }

    // Check OTP attempts
    if (tempSignup.otpAttempts >= 3) {
      throw new BadRequestException('Too many OTP attempts. Please request a new OTP.');
    }

    // Verify OTP
    if (tempSignup.verificationOTP !== verifyOtpDto.otp) {
      // Increment OTP attempts
      tempSignup.otpAttempts += 1;
      await tempSignup.save();
      throw new BadRequestException('Invalid OTP');
    }

    // OTP is valid - NOW create the actual user account
    const user = await this.usersService.create({
      email: tempSignup.email,
      password: tempSignup.password, // Already hashed
      isVerified: true, // Account is verified since OTP was correct
    });

    // Delete temporary signup after successful account creation
    await this.temporarySignupModel.findByIdAndDelete(tempSignup._id).exec();

    // Generate JWT token
    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.roles[0] || 'household',
    });

    return {
      message: 'Email verified successfully. Account created.',
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
    // Check if user already exists and is verified
    const existingUser = await this.usersService.findByEmail(email);
    if (existingUser && existingUser.isVerified) {
      throw new BadRequestException('User already exists and is verified. Please login instead.');
    }

    // Find temporary signup
    const tempSignup = await this.temporarySignupModel.findOne({ email }).exec();
    if (!tempSignup) {
      throw new BadRequestException('No signup found for this email. Please sign up first.');
    }

    const otp = this.generateOTP();
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15);

    // Update temporary signup with new OTP
    tempSignup.verificationOTP = otp;
    tempSignup.otpExpiresAt = otpExpiresAt;
    tempSignup.otpAttempts = 0;
    await tempSignup.save();

    await this.emailService.sendOTPEmail(email, otp);

    return {
      message: 'OTP resent successfully',
      email: email,
      otp, // Remove this in production
    };
  }

  async login(loginDto: LoginDto) {
    console.log(`🔐 Login attempt for email: ${loginDto.email}`);
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      console.log(`❌ Login failed: User not found for email: ${loginDto.email}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    console.log(`✅ User found: ${user.id}, verified: ${user.isVerified}, deleted: ${user.isDeleted}`);

    // Check if account is soft-deleted
    if (user.isDeleted) {
      console.log(`❌ Login failed: Account is soft-deleted for user: ${user.id}`);
      throw new UnauthorizedException('Your account has been deleted by an administrator. Please contact support: support@bottleji.com');
    }

    if (!user.isVerified) {
      console.log(`❌ Login failed: Account not verified for user: ${user.id}`);
      throw new UnauthorizedException('Please verify your email first');
    }

    // Check if this is a phone-registered user trying to login with email/password
    // Phone-registered users must always use phone + OTP login, even if they added an email later
    if (user.registeredWithPhone) {
      console.log(`❌ Login failed: Phone-registered user trying to login with email/password: ${user.id}`);
      throw new UnauthorizedException('This account was created with phone number. Please use phone number login with OTP verification instead.');
    }

    // Compare password using bcrypt
    console.log(`🔐 Comparing password for user: ${user.id}`);
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) {
      console.log(`❌ Login failed: Invalid password for user: ${user.id}`);
      throw new UnauthorizedException('Invalid credentials');
    }
    console.log(`✅ Password valid for user: ${user.id}`);

    // Check if account is permanently disabled (isAccountLocked = true and accountLockedUntil = null)
    if (user.isAccountLocked && user.accountLockedUntil === null) {
      throw new UnauthorizedException('Your account has been permanently disabled due to repeated violations of Bottleji\'s community guidelines. Please contact support: support@bottleji.com');
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
      } else {
        // Account is still locked (temporary lock)
        // Allow login but user will see lock card in app
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

    // Normalize phone number if provided
    const normalizedPhone = setupProfileDto.phoneNumber 
      ? this.normalizePhoneNumber(setupProfileDto.phoneNumber)
      : null;
    
    // Normalize existing user phone for comparison
    const normalizedUserPhone = user.phoneNumber 
      ? this.normalizePhoneNumber(user.phoneNumber)
      : null;

    // For phone sign-in users: phone is already verified, skip verification check
    // For email sign-in users: phone must be verified
    const isPhoneSignInUser = user.email?.startsWith('phone_') && user.email?.endsWith('@bottleji.temp');
    
    if (!isPhoneSignInUser) {
      // Email/password user - phone must be verified
      if (!user.isPhoneVerified || normalizedUserPhone !== normalizedPhone) {
        throw new BadRequestException('Phone number must be verified before completing profile setup');
      }
    } else {
      // Phone sign-in user - phone is already verified, just ensure it matches (normalized)
      if (normalizedUserPhone !== normalizedPhone) {
        throw new BadRequestException('Phone number mismatch');
      }
    }

    const updateData: any = {
      name: setupProfileDto.name,
      phoneNumber: normalizedPhone || setupProfileDto.phoneNumber, // Store normalized phone
      address: setupProfileDto.address,
      isProfileComplete: true,
    };

    // Allow email to be added/updated if:
    // 1. User signed in with phone (has temp email) OR
    // 2. User doesn't have an email yet
    if (setupProfileDto.email) {
      const canUpdateEmail = isPhoneSignInUser || !user.email || user.email === '';
      
      if (canUpdateEmail) {
        // Check if email is already taken by another user
        const existingUserWithEmail = await this.usersService.findByEmail(setupProfileDto.email);
        if (existingUserWithEmail && existingUserWithEmail.id !== userId) {
          throw new BadRequestException('Email already registered to another account');
        }
        updateData.email = setupProfileDto.email;
      } else {
        // Email/password user trying to change email - not allowed
        throw new BadRequestException('Email cannot be changed for email/password accounts');
      }
    }

    if (setupProfileDto.profilePhoto) {
      updateData.profilePhoto = setupProfileDto.profilePhoto;
    }

    const updatedUser = await this.usersService.update(userId, updateData);

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
      // Normalize phone number before storing
      updateData.phoneNumber = this.normalizePhoneNumber(updateProfileDto.phoneNumber);
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

    // Debug: Log reward history from database
    console.log('📊 getProfile - User ID:', userId);
    console.log('📊 getProfile - Reward history from DB:', JSON.stringify(user.rewardHistory, null, 2));
    console.log('📊 getProfile - Reward history type:', typeof user.rewardHistory);
    console.log('📊 getProfile - Reward history is array:', Array.isArray(user.rewardHistory));
    console.log('📊 getProfile - Reward history length:', user.rewardHistory?.length || 0);

    const profileData = {
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
        isAccountLocked: user.isAccountLocked,
        accountLockedUntil: user.accountLockedUntil,
        warningCount: user.warningCount,
        rewardHistory: user.rewardHistory || [],
        totalEarnings: user.totalEarnings || 0,
        earningsHistory: user.earningsHistory || [],
      },
    };

    // Debug: Log what we're sending
    console.log('📊 getProfile - Sending reward history:', JSON.stringify(profileData.user.rewardHistory, null, 2));
    console.log('📊 getProfile - Reward history in response type:', typeof profileData.user.rewardHistory);
    console.log('📊 getProfile - Reward history in response is array:', Array.isArray(profileData.user.rewardHistory));
    console.log('📊 getProfile - Reward history in response length:', profileData.user.rewardHistory?.length || 0);
    
    // Debug earnings data
    console.log('📊 getProfile - Total earnings:', profileData.user.totalEarnings);
    console.log('📊 getProfile - Earnings history:', JSON.stringify(profileData.user.earningsHistory, null, 2));
    console.log('📊 getProfile - Earnings history length:', profileData.user.earningsHistory?.length || 0);

    return profileData;
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

  async sendPhoneOTP(userId: string, phoneNumber: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Generate OTP (hardcoded for now until Trello implementation)
    const otp = '123456'; // Hardcoded OTP for testing
    const otpExpiresAt = new Date();
    otpExpiresAt.setMinutes(otpExpiresAt.getMinutes() + 15); // OTP expires in 15 minutes

    // Store OTP in user record
    await this.usersService.update(userId, {
      phoneNumber: phoneNumber,
      phoneVerificationOtp: otp,
      phoneOtpExpiresAt: otpExpiresAt,
      phoneOtpAttempts: 0,
      isPhoneVerified: false, // Reset verification status when sending new OTP
    });

    // TODO: Send OTP via SMS service (Trello implementation)
    // For now, just return the OTP in the response (remove in production)
    console.log(`📱 Phone OTP for ${phoneNumber}: ${otp}`);

    return {
      message: 'Phone OTP sent successfully',
      phoneNumber: phoneNumber,
      otp: otp, // Remove this in production - only for testing with hardcoded OTP
    };
  }

  async verifyPhoneOTP(userId: string, phoneNumber: string, otp: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Check if phone number matches
    if (user.phoneNumber !== phoneNumber) {
      throw new BadRequestException('Phone number does not match');
    }

    // Check if OTP has expired
    if (!user.phoneOtpExpiresAt || new Date() > user.phoneOtpExpiresAt) {
      throw new BadRequestException('Phone OTP has expired. Please request a new OTP.');
    }

    // Check OTP attempts
    if (user.phoneOtpAttempts >= 3) {
      throw new BadRequestException('Too many OTP attempts. Please request a new OTP.');
    }

    // Verify OTP (hardcoded for now)
    if (user.phoneVerificationOtp !== otp) {
      // Increment OTP attempts
      await this.usersService.update(userId, {
        phoneOtpAttempts: (user.phoneOtpAttempts || 0) + 1,
      });
      throw new BadRequestException('Invalid phone OTP');
    }

    // OTP is valid - mark phone as verified
    await this.usersService.update(userId, {
      isPhoneVerified: true,
      phoneVerificationOtp: undefined, // Clear OTP after successful verification
      phoneOtpExpiresAt: undefined,
      phoneOtpAttempts: 0,
    });

    return {
      message: 'Phone number verified successfully',
      phoneNumber: phoneNumber,
      isPhoneVerified: true,
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

  /**
   * Normalize phone number by removing spaces, dashes, and keeping only digits and +
   */
  private normalizePhoneNumber(phoneNumber: string): string {
    if (!phoneNumber) return phoneNumber;
    // Keep + at the start if present, then keep only digits
    const hasPlus = phoneNumber.trim().startsWith('+');
    const digitsOnly = phoneNumber.replace(/[^\d]/g, '');
    return hasPlus ? `+${digitsOnly}` : digitsOnly;
  }

  async phoneSignup(phoneNumber: string, firebaseToken: string) {
    // Normalize phone number before checking/creating
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);
    
    // Check if user already exists with this phone number (normalized)
    const existingUser = await this.usersService.findByPhone(normalizedPhone);
    if (existingUser) {
      throw new BadRequestException('Phone number already registered. Please login instead.');
    }

    // TODO: Verify Firebase token with Firebase Admin SDK
    // For now, we trust the token from the client

    // Generate a random password (user won't use it - they login with phone)
    // This is required by the user schema but user can't login with email/password
    const randomPassword = Math.random().toString(36).slice(-12) + Math.random().toString(36).slice(-12) + '!@#';
    
    // Create new user with phone number (no email, random password)
    // Store normalized phone number for consistency
    const user = await this.usersService.create({
      email: `phone_${normalizedPhone.replace(/[^0-9]/g, '')}@bottleji.temp`, // Temporary email placeholder
      password: randomPassword, // Random password - user can't login with email/password
      phoneNumber: normalizedPhone, // Store normalized phone number
      isPhoneVerified: true, // Phone is verified via Firebase OTP
      phoneVerificationId: firebaseToken,
      isVerified: true, // Phone verification counts as verification
      registeredWithPhone: true, // Mark that user registered with phone - they must always use phone login
      // User can add real email in profile setup, but cannot use email/password login
    });

    // Generate JWT token
    const token = this.jwtService.sign({
      sub: user.id,
      phoneNumber: user.phoneNumber,
      role: user.roles[0] || 'household',
    });

    return {
      message: 'Phone number verified successfully. Account created.',
      token,
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        name: user.name,
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

  async phoneLogin(phoneNumber: string, firebaseToken: string) {
    // Normalize phone number before searching
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);
    
    // Find user by phone number (normalized)
    const user = await this.usersService.findByPhone(normalizedPhone);
    if (!user) {
      throw new UnauthorizedException('Phone number not registered. Please sign up first.');
    }

    // Check if account is soft-deleted
    if (user.isDeleted) {
      throw new UnauthorizedException('Your account has been deleted by an administrator. Please contact support: support@bottleji.com');
    }

    // TODO: Verify Firebase token with Firebase Admin SDK
    // For now, we trust the token from the client

    // Update phone verification status and token
    await this.usersService.update(user.id, {
      isPhoneVerified: true,
      phoneVerificationId: firebaseToken,
    });

    // Check if account is permanently disabled
    if (user.isAccountLocked && user.accountLockedUntil === null) {
      throw new UnauthorizedException('Your account has been permanently disabled due to repeated violations of Bottleji\'s community guidelines. Please contact support: support@bottleji.com');
    }

    // Check if account lock has expired and auto-unlock
    if (user.isAccountLocked && user.accountLockedUntil) {
      const now = new Date();
      if (now >= user.accountLockedUntil) {
        await this.usersService.unlockAccount(user.id);
        const unlockedUser = await this.usersService.findByPhone(normalizedPhone);
        if (unlockedUser) {
          Object.assign(user, unlockedUser);
        }
      }
    }

    // Generate JWT token
    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.roles[0] || 'household',
    });

    return {
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
        name: user.name,
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

  async requestPasswordReset(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Don't reveal if user exists or not for security
      return {
        message: 'If an account with this email exists, a password reset code has been sent.',
      };
    }

    // Block password reset for phone-registered users
    // They must always use phone + OTP login
    if (user.registeredWithPhone) {
      throw new BadRequestException('This account was created with phone number. Password reset is not available. Please use phone number login with OTP verification instead.');
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

    // Block password reset for phone-registered users
    // They must always use phone + OTP login
    if (user.registeredWithPhone) {
      throw new BadRequestException('This account was created with phone number. Password reset is not available. Please use phone number login with OTP verification instead.');
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

    // Block password reset for phone-registered users
    // They must always use phone + OTP login
    if (user.registeredWithPhone) {
      throw new BadRequestException('This account was created with phone number. Password reset is not available. Please use phone number login with OTP verification instead.');
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

  async saveFCMToken(userId: string, fcmToken: string) {
    await this.usersService.update(userId, {
      fcmToken: fcmToken,
    });

    return {
      message: 'FCM token saved successfully',
    };
  }

  async invalidateSession(userId: string) {
    await this.usersService.invalidateSession(userId);
    return {
      message: 'Session invalidated successfully',
    };
  }

}
