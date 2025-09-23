import { Controller, Post, Get, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { CollectorApplicationsService } from './collector-applications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('collector-applications')
@UseGuards(JwtAuthGuard)
export class CollectorApplicationsController {
  constructor(
    private readonly collectorApplicationsService: CollectorApplicationsService,
  ) {}

  @Post()
  async createApplication(
    @Request() req,
    @Body() applicationData: {
      idCardPhoto: string;
      selfieWithIdPhoto: string;
      idCardNumber?: string;
      idCardType?: string;
      idCardExpiryDate?: string;
      idCardIssuingAuthority?: string;
      passportIssueDate?: string;
      passportExpiryDate?: string;
      passportMainPagePhoto?: string;
      idCardBackPhoto?: string;
    },
  ) {
    console.log('🔍 CollectorApplicationsController: Creating application for user:', req.user.id);
    console.log('🔍 CollectorApplicationsController: Application data received:', applicationData);
    
    const userId = req.user.id;
    const application = await this.collectorApplicationsService.createApplication(
      userId,
      applicationData,
    );
    
    console.log('🔍 CollectorApplicationsController: Application created successfully:', application._id);
    console.log('🔍 CollectorApplicationsController: Returning response with application');
    
    return { success: true, application };
  }

  @Get('my-application')
  async getMyApplication(@Request() req) {
    const userId = req.user.id;
    const application = await this.collectorApplicationsService.getApplicationByUserId(userId);
    return { success: true, application };
  }

  @Put(':id')
  async updateApplication(
    @Param('id') applicationId: string,
    @Request() req,
    @Body() applicationData: {
      idCardPhoto: string;
      selfieWithIdPhoto: string;
      idCardNumber?: string;
      idCardType?: string;
      idCardExpiryDate?: string;
      idCardIssuingAuthority?: string;
      passportIssueDate?: string;
      passportExpiryDate?: string;
      passportMainPagePhoto?: string;
      idCardBackPhoto?: string;
    },
  ) {
    const userId = req.user.id;
    const application = await this.collectorApplicationsService.updateApplication(
      applicationId,
      userId,
      applicationData,
    );
    return { success: true, application };
  }
} 