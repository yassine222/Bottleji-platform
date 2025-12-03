import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<User>,
  ) {}

  async create(createUserDto: CreateUserDto & Partial<User>): Promise<User> {
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
    const createdUser = new this.userModel({
      ...createUserDto,
      password: hashedPassword,
    });
    return createdUser.save();
  }

  async findAll(): Promise<User[]> {
    return this.userModel.find().exec();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel.findById(id).exec();
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userModel.findOne({ email }).exec();
  }

  /**
   * Normalize phone number by removing spaces, dashes, and keeping only digits and +
   * Examples: "+1 234 567 8900" -> "+12345678900", "123-456-7890" -> "1234567890"
   */
  private normalizePhoneNumber(phoneNumber: string): string {
    if (!phoneNumber) return phoneNumber;
    // Trim whitespace
    const trimmed = phoneNumber.trim();
    // Keep + at the start if present, then keep only digits
    const hasPlus = trimmed.startsWith('+');
    const digitsOnly = trimmed.replace(/[^\d]/g, '');
    return hasPlus ? `+${digitsOnly}` : digitsOnly;
  }

  async findByPhone(phoneNumber: string): Promise<User | null> {
    if (!phoneNumber) return null;
    
    const normalized = this.normalizePhoneNumber(phoneNumber);
    
    // First try exact match with normalized phone
    let user = await this.userModel.findOne({ phoneNumber: normalized }).exec();
    
    // If not found, try with original (in case stored differently)
    if (!user && phoneNumber !== normalized) {
      user = await this.userModel.findOne({ phoneNumber: phoneNumber }).exec();
    }
    
    // If still not found, try searching by digits only (ignore + and formatting)
    if (!user) {
      const digitsOnly = normalized.replace(/[^\d]/g, '');
      // Search for phone numbers that match when we remove all non-digits
      const allUsers = await this.userModel.find({ phoneNumber: { $exists: true, $ne: null } }).exec();
      user = allUsers.find(u => {
        if (!u.phoneNumber) return false;
        const userDigits = u.phoneNumber.replace(/[^\d]/g, '');
        return userDigits === digitsOnly;
      }) || null;
    }
    
    return user;
  }

  async findByVerificationToken(token: string): Promise<User | null> {
    return this.userModel.findOne({ verificationToken: token }).exec();
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    console.log('🔍 UsersService: Updating user with ID:', id);
    console.log('🔍 UsersService: Update data:', updateData);
    
    const user = await this.userModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .exec();
      
    if (!user) {
      console.error('❌ UsersService: User not found with ID:', id);
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    
    console.log('🔍 UsersService: User updated successfully:', user.email);
    console.log('🔍 UsersService: Updated collectorApplicationStatus:', user.collectorApplicationStatus);
    console.log('🔍 UsersService: Updated collectorApplicationId:', user.collectorApplicationId);
    
    return user;
  }

  async remove(id: string): Promise<User> {
    const user = await this.userModel.findByIdAndDelete(id).exec();
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async unlockAccount(userId: string): Promise<User> {
    console.log(`🔓 Unlocking account for user: ${userId}`);
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      {
        isAccountLocked: false,
        accountLockedUntil: null,
      },
      { new: true }
    ).exec();
    
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
    
    console.log(`✅ Account unlocked for user: ${userId}`);
    return user;
  }

  async invalidateSession(userId: string): Promise<void> {
    console.log(`🔒 Invalidating session for user: ${userId}`);
    await this.userModel.findByIdAndUpdate(
      userId,
      {
        sessionInvalidatedAt: new Date(),
      }
    ).exec();
    console.log(`✅ Session invalidated for user: ${userId}`);
  }
} 