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

  async findByPhone(phoneNumber: string): Promise<User | null> {
    return this.userModel.findOne({ phoneNumber: phoneNumber }).exec();
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
} 