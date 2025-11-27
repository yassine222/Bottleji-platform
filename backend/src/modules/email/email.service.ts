import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService implements OnModuleInit {
  private transporter: nodemailer.Transporter;
  private isEmailServiceEnabled: boolean = false;
  private readonly logger = new Logger(EmailService.name);

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    await this.initializeEmailService();
  }

  private async initializeEmailService() {
    try {
      // Try ConfigService first, then fallback to process.env
      // Support both EMAIL_USER and MAIL_USER for flexibility
      const emailUser = this.configService.get<string>('EMAIL_USER') 
        || process.env.EMAIL_USER 
        || this.configService.get<string>('MAIL_USER')
        || process.env.MAIL_USER;
      
      // Support both EMAIL_PASS and MAIL_PASS for flexibility
      const emailPass = this.configService.get<string>('EMAIL_PASS') 
        || process.env.EMAIL_PASS
        || this.configService.get<string>('MAIL_PASS')
        || process.env.MAIL_PASS;

      // Debug logging
      this.logger.log(`🔍 Checking email configuration...`);
      this.logger.log(`   EMAIL_USER/MAIL_USER: ${emailUser ? '✅ Set' : '❌ Missing'}`);
      this.logger.log(`   EMAIL_PASS/MAIL_PASS: ${emailPass ? '✅ Set' : '❌ Missing'}`);

      if (!emailUser || !emailPass) {
        this.logger.warn('⚠️ Email service disabled: Missing email credentials');
        this.logger.warn('   Please add EMAIL_USER (or MAIL_USER) and EMAIL_PASS (or MAIL_PASS) to your environment variables');
        return;
      }

      this.transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        auth: {
          user: emailUser,
          pass: emailPass,
        },
        tls: {
          rejectUnauthorized: false
        }
      });

      // Test the connection
      await this.transporter.verify();
      this.isEmailServiceEnabled = true;
      this.logger.log('✅ Email service initialized successfully');
      this.logger.log(`   Sending emails from: ${emailUser}`);
      
    } catch (error) {
      this.logger.error('❌ Email service initialization failed:', error.message);
      this.logger.warn('📧 Email service will be disabled. OTP codes will be logged to console instead.');
      if (error.stack) {
        this.logger.debug(error.stack);
      }
      this.isEmailServiceEnabled = false;
    }
  }

  async sendOTPEmail(to: string, otp: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      this.logger.warn(`📧 Email service disabled - OTP would be sent to: ${to}, Code: ${otp}`);
      return;
    }

    try {
      const emailUser = this.configService.get<string>('EMAIL_USER') || process.env.EMAIL_USER;
      await this.transporter.sendMail({
        from: emailUser,
        to: to,
        subject: 'Bottleji - Email Verification Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #00695C;">Bottleji Email Verification</h2>
            <p>Your verification code is:</p>
            <h1 style="color: #00695C; font-size: 32px; text-align: center; padding: 20px; background: #f0f0f0; border-radius: 8px;">${otp}</h1>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
          </div>
        `
      });
      this.logger.log(`✅ OTP email sent successfully to: ${to}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send OTP email to ${to}:`, error.message);
      this.logger.warn(`📧 OTP code for manual verification: ${otp}`);
    }
  }

  async sendPasswordResetEmail(to: string, otp: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      this.logger.warn(`📧 Email service disabled - Password reset would be sent to: ${to}, Code: ${otp}`);
      return;
    }

    try {
      const emailUser = this.configService.get<string>('EMAIL_USER') || process.env.EMAIL_USER;
      await this.transporter.sendMail({
        from: emailUser,
        to: to,
        subject: 'Bottleji - Password Reset Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #00695C;">Bottleji Password Reset</h2>
            <p>Your password reset code is:</p>
            <h1 style="color: #00695C; font-size: 32px; text-align: center; padding: 20px; background: #f0f0f0; border-radius: 8px;">${otp}</h1>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request a password reset, please ignore this email.</p>
          </div>
        `
      });
      this.logger.log(`✅ Password reset email sent successfully to: ${to}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send password reset email to ${to}:`, error.message);
      this.logger.warn(`📧 Password reset code for manual verification: ${otp}`);
    }
  }

  async sendPhoneVerificationEmail(to: string, phoneNumber: string, verificationCode: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      this.logger.warn(`📧 Email service disabled - Phone verification would be sent to: ${to}, Phone: ${phoneNumber}, Code: ${verificationCode}`);
      return;
    }

    try {
      const emailUser = this.configService.get<string>('EMAIL_USER') || process.env.EMAIL_USER;
      await this.transporter.sendMail({
        from: emailUser,
        to: to,
        subject: 'Bottleji - Phone Verification Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #00695C;">Bottleji Phone Verification</h2>
            <p>Your phone verification code for ${phoneNumber} is:</p>
            <h1 style="color: #00695C; font-size: 32px; text-align: center; padding: 20px; background: #f0f0f0; border-radius: 8px;">${verificationCode}</h1>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
          </div>
        `
      });
      this.logger.log(`✅ Phone verification email sent successfully to: ${to}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send phone verification email to ${to}:`, error.message);
      this.logger.warn(`📧 Phone verification code for manual verification: ${verificationCode}`);
    }
  }

  async sendAdminInvitation(to: string, name: string, role: string, tempPassword: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      this.logger.warn(`📧 Email service disabled - Admin invitation would be sent to: ${to}, Name: ${name}, Role: ${role}`);
      return;
    }

    try {
      const emailUser = this.configService.get<string>('EMAIL_USER') || process.env.EMAIL_USER;
      await this.transporter.sendMail({
        from: emailUser,
        to: to,
        subject: 'Bottleji - Admin Account Invitation',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #00695C;">Bottleji Admin Invitation</h2>
            <p>Hello ${name},</p>
            <p>You have been invited to join the Bottleji admin team as a <strong>${role}</strong>.</p>
            <p>Your temporary login credentials:</p>
            <ul>
              <li><strong>Email:</strong> ${to}</li>
              <li><strong>Temporary Password:</strong> ${tempPassword}</li>
            </ul>
            <p>Please login to the admin dashboard and change your password immediately.</p>
            <p>If you have any questions, please contact the system administrator.</p>
          </div>
        `
      });
      this.logger.log(`✅ Admin invitation email sent successfully to: ${to}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send admin invitation email to ${to}:`, error.message);
      this.logger.warn(`📧 Admin invitation details - Email: ${to}, Name: ${name}, Role: ${role}`);
    }
  }
} 