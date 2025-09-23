import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter;
  private isEmailServiceEnabled: boolean = false;

  constructor(private configService: ConfigService) {
    this.initializeEmailService();
  }

  private async initializeEmailService() {
    try {
      const emailUser = this.configService.get<string>('EMAIL_USER');
      const emailPass = this.configService.get<string>('EMAIL_PASS');

      if (!emailUser || !emailPass) {
        console.log('⚠️ Email service disabled: Missing EMAIL_USER or EMAIL_PASS environment variables');
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
      console.log('✅ Email service initialized successfully');
      
    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      console.log('📧 Email service will be disabled. OTP codes will be logged to console instead.');
      this.isEmailServiceEnabled = false;
    }
  }

  async sendOTPEmail(to: string, otp: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      console.log('📧 Email service disabled - OTP would be sent to:', to, 'Code:', otp);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.configService.get<string>('EMAIL_USER'),
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
      console.log('✅ OTP email sent successfully to:', to);
    } catch (error) {
      console.error('❌ Failed to send OTP email:', error.message);
      console.log('📧 OTP code for manual verification:', otp);
    }
  }

  async sendPasswordResetEmail(to: string, otp: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      console.log('📧 Email service disabled - Password reset would be sent to:', to, 'Code:', otp);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.configService.get<string>('EMAIL_USER'),
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
      console.log('✅ Password reset email sent successfully to:', to);
    } catch (error) {
      console.error('❌ Failed to send password reset email:', error.message);
      console.log('📧 Password reset code for manual verification:', otp);
    }
  }

  async sendPhoneVerificationEmail(to: string, phoneNumber: string, verificationCode: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      console.log('📧 Email service disabled - Phone verification would be sent to:', to, 'Phone:', phoneNumber, 'Code:', verificationCode);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.configService.get<string>('EMAIL_USER'),
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
      console.log('✅ Phone verification email sent successfully to:', to);
    } catch (error) {
      console.error('❌ Failed to send phone verification email:', error.message);
      console.log('📧 Phone verification code for manual verification:', verificationCode);
    }
  }

  async sendAdminInvitation(to: string, name: string, role: string, tempPassword: string): Promise<void> {
    if (!this.isEmailServiceEnabled) {
      console.log('📧 Email service disabled - Admin invitation would be sent to:', to, 'Name:', name, 'Role:', role, 'Temp Password:', tempPassword);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.configService.get<string>('EMAIL_USER'),
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
      console.log('✅ Admin invitation email sent successfully to:', to);
    } catch (error) {
      console.error('❌ Failed to send admin invitation email:', error.message);
      console.log('📧 Admin invitation details for manual verification:', { to, name, role, tempPassword });
    }
  }
} 