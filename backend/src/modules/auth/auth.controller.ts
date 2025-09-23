import { Controller, Post, Body, Get, Put, UseGuards, Request, Param } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CreateUserDto } from './dto/create-user.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginDto } from './dto/login.dto';
import { SetupProfileDto } from './dto/setup-profile.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UpdateCollectorSubscriptionDto } from './dto/update-collector-subscription.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { VerifyPasswordResetDto } from './dto/verify-password-reset.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  async signup(@Body() createUserDto: CreateUserDto) {
    return this.authService.signup(createUserDto);
  }

  @Post('verify-otp')
  async verifyOTP(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOTP(verifyOtpDto);
  }

  @Post('resend-otp')
  async resendOTP(@Body() body: { email: string }) {
    return this.authService.resendOTP(body.email);
  }

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('admin/login')
  async adminLogin(@Body() loginDto: LoginDto) {
    return this.authService.adminLogin(loginDto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('setup-profile')
  async setupProfile(@Request() req, @Body() setupProfileDto: SetupProfileDto) {
    return this.authService.setupProfile(req.user.id, setupProfileDto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('update-profile')
  async updateProfile(@Request() req, @Body() updateProfileDto: SetupProfileDto) {
    return this.authService.updateProfile(req.user.id, updateProfileDto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('update-role')
  async updateRole(@Request() req, @Body() updateRoleDto: UpdateRoleDto) {
    return this.authService.updateRole(req.user.id, updateRoleDto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('update-collector-subscription')
  async updateCollectorSubscription(@Request() req, @Body() updateSubscriptionDto: UpdateCollectorSubscriptionDto) {
    return this.authService.updateCollectorSubscription(req.user.id, updateSubscriptionDto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('verify-phone')
  async verifyPhone(@Request() req, @Body() body: { phoneNumber: string; firebaseToken: string }) {
    return this.authService.verifyPhone(req.user.id, body.phoneNumber, body.firebaseToken);
  }

  @UseGuards(JwtAuthGuard)
  @Get('user/:userId')
  async getUserById(@Request() req, @Param('userId') userId: string) {
    return this.authService.getUserById(userId);
  }

  @Post('request-password-reset')
  async requestPasswordReset(@Body() requestPasswordResetDto: RequestPasswordResetDto) {
    return this.authService.requestPasswordReset(requestPasswordResetDto.email);
  }

  @Post('verify-password-reset')
  async verifyPasswordReset(@Body() verifyPasswordResetDto: VerifyPasswordResetDto) {
    return this.authService.verifyPasswordReset(verifyPasswordResetDto.email, verifyPasswordResetDto.otp);
  }

  @Post('reset-password')
  async resetPassword(@Body() body: { email: string; otp: string; newPassword: string }) {
    return this.authService.resetPassword(body.email, body.otp, body.newPassword);
  }

  @UseGuards(JwtAuthGuard)
  @Post('change-password')
  async changePassword(@Request() req, @Body() body: { currentPassword: string; newPassword: string }) {
    return this.authService.changePassword(req.user.id, body.currentPassword, body.newPassword);
  }

}
