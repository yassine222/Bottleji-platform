import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CollectorApplication, CollectorApplicationStatus } from './schemas/collector-application.schema';
import { UsersService } from '../users/users.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class CollectorApplicationsService {
  constructor(
    @InjectModel(CollectorApplication.name)
    private collectorApplicationModel: Model<CollectorApplication>,
    private usersService: UsersService,
    private notificationsService: NotificationsService,
  ) {}

  async createApplication(userId: string, applicationData: {
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
  }): Promise<CollectorApplication> {
    console.log('🔍 CollectorApplicationsService: Creating application for user:', userId);
    console.log('🔍 CollectorApplicationsService: Application data:', applicationData);
    
    // Check if user already has an application
    const existingApplication = await this.getApplicationByUserId(userId);
    if (existingApplication) {
      console.log('🔍 CollectorApplicationsService: Found existing application:', existingApplication.status);
      if (existingApplication.status === CollectorApplicationStatus.PENDING) {
        throw new Error('You already have a pending application. Please wait for it to be reviewed.');
      } else if (existingApplication.status === CollectorApplicationStatus.APPROVED) {
        throw new Error('You are already an approved collector.');
      }
      // If rejected, allow them to apply again
      console.log('🔍 CollectorApplicationsService: Allowing re-application after rejection');
    }

    const application = new this.collectorApplicationModel({
      userId: new Types.ObjectId(userId),
      idCardPhoto: applicationData.idCardPhoto,
      selfieWithIdPhoto: applicationData.selfieWithIdPhoto,
      idCardNumber: applicationData.idCardNumber,
      idCardType: applicationData.idCardType,
      idCardExpiryDate: applicationData.idCardExpiryDate ? new Date(applicationData.idCardExpiryDate) : undefined,
      idCardIssuingAuthority: applicationData.idCardIssuingAuthority,
      passportIssueDate: applicationData.passportIssueDate ? new Date(applicationData.passportIssueDate) : undefined,
      passportExpiryDate: applicationData.passportExpiryDate ? new Date(applicationData.passportExpiryDate) : undefined,
      passportMainPagePhoto: applicationData.passportMainPagePhoto,
      idCardBackPhoto: applicationData.idCardBackPhoto,
      status: CollectorApplicationStatus.PENDING,
      appliedAt: new Date(),
    });

    console.log('🔍 CollectorApplicationsService: Saving application...');
    const savedApplication = await application.save();
    console.log('🔍 CollectorApplicationsService: Application saved with ID:', savedApplication._id);

    // Update user's application status in user collection
    console.log('🔍 CollectorApplicationsService: Updating user with application status...');
    try {
      const updatedUser = await this.usersService.update(userId, {
        collectorApplicationStatus: CollectorApplicationStatus.PENDING,
        collectorApplicationId: (savedApplication._id as any).toString(),
        collectorApplicationAppliedAt: savedApplication.appliedAt,
        collectorApplicationRejectionReason: undefined,
      });
      console.log('🔍 CollectorApplicationsService: User updated successfully:', updatedUser.email);
      console.log('🔍 CollectorApplicationsService: User collectorApplicationStatus:', updatedUser.collectorApplicationStatus);
      console.log('🔍 CollectorApplicationsService: User collectorApplicationId:', updatedUser.collectorApplicationId);
    } catch (error) {
      console.error('❌ CollectorApplicationsService: Error updating user:', error);
      throw error;
    }

    return savedApplication;
  }

  async getApplicationByUserId(userId: string): Promise<CollectorApplication | null> {
    return await this.collectorApplicationModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 }) // Get the most recent application
      .exec();
  }

  async getApplicationById(applicationId: string): Promise<CollectorApplication | null> {
    return await this.collectorApplicationModel
      .findById(applicationId)
      .populate('userId', 'email name')
      .populate('reviewedBy', 'email name')
      .exec();
  }

  async getAllApplications(status?: CollectorApplicationStatus): Promise<CollectorApplication[]> {
    const filter = status ? { status } : {};
    return await this.collectorApplicationModel
      .find(filter)
      .populate('userId', 'email name')
      .populate('reviewedBy', 'email name')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getPendingApplications(): Promise<CollectorApplication[]> {
    return await this.collectorApplicationModel
      .find({ status: CollectorApplicationStatus.PENDING })
      .populate('userId', 'email name')
      .sort({ createdAt: -1 })
      .exec();
  }

  async approveApplication(applicationId: string, adminId: string, notes?: string): Promise<CollectorApplication> {
    const application = await this.collectorApplicationModel.findById(applicationId);
    if (!application) {
      throw new Error('Application not found');
    }

    application.status = CollectorApplicationStatus.APPROVED;
    application.reviewedAt = new Date();
    application.reviewedBy = new Types.ObjectId(adminId);
    application.reviewNotes = notes;

    return await application.save();
  }

  async rejectApplication(applicationId: string, adminId: string, rejectionReason: string, notes?: string): Promise<CollectorApplication> {
    const application = await this.collectorApplicationModel.findById(applicationId);
    if (!application) {
      throw new Error('Application not found');
    }

    application.status = CollectorApplicationStatus.REJECTED;
    application.rejectionReason = rejectionReason;
    application.reviewedAt = new Date();
    application.reviewedBy = new Types.ObjectId(adminId);
    application.reviewNotes = notes;

    return await application.save();
  }

  async reverseApproval(applicationId: string, adminId: string, notes?: string): Promise<CollectorApplication> {
    const application = await this.collectorApplicationModel.findById(applicationId);
    if (!application) {
      throw new Error('Application not found');
    }

    if (application.status !== CollectorApplicationStatus.APPROVED) {
      throw new Error('Can only reverse approved applications');
    }

    application.status = CollectorApplicationStatus.PENDING;
    application.rejectionReason = undefined; // Clear any previous rejection reason
    application.reviewedAt = new Date();
    application.reviewedBy = new Types.ObjectId(adminId);
    application.reviewNotes = notes;

    return await application.save();
  }

  async updateApplication(
    applicationId: string,
    userId: string,
    applicationData: {
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
  ): Promise<CollectorApplication> {
    const application = await this.collectorApplicationModel.findById(applicationId);
    if (!application) {
      throw new Error('Application not found');
    }

    // Verify the application belongs to the user
    if (application.userId.toString() !== userId) {
      throw new Error('Unauthorized: Application does not belong to user');
    }

    // Only allow updates for rejected applications
    if (application.status !== CollectorApplicationStatus.REJECTED) {
      throw new Error('Only rejected applications can be updated');
    }

    // Update application fields
    application.idCardPhoto = applicationData.idCardPhoto;
    application.selfieWithIdPhoto = applicationData.selfieWithIdPhoto;
    application.idCardNumber = applicationData.idCardNumber;
    application.idCardType = applicationData.idCardType;
    application.idCardExpiryDate = applicationData.idCardExpiryDate ? new Date(applicationData.idCardExpiryDate) : undefined;
    application.idCardIssuingAuthority = applicationData.idCardIssuingAuthority;
    application.passportIssueDate = applicationData.passportIssueDate ? new Date(applicationData.passportIssueDate) : undefined;
    application.passportExpiryDate = applicationData.passportExpiryDate ? new Date(applicationData.passportExpiryDate) : undefined;
    application.passportMainPagePhoto = applicationData.passportMainPagePhoto;
    application.idCardBackPhoto = applicationData.idCardBackPhoto;

    // Reset status to pending and clear rejection reason
    application.status = CollectorApplicationStatus.PENDING;
    application.rejectionReason = undefined;
    application.reviewedAt = undefined;
    application.reviewedBy = undefined;
    application.reviewNotes = undefined;

    // Update applied date to current time
    application.appliedAt = new Date();

    const savedApplication = await application.save();

    // Update user's application status in user collection
    await this.usersService.update(userId, {
      collectorApplicationStatus: CollectorApplicationStatus.PENDING,
      collectorApplicationId: applicationId,
      collectorApplicationAppliedAt: savedApplication.appliedAt,
      collectorApplicationRejectionReason: undefined, // Clear rejection reason
    });

    // Send notification to user about application update
    this.notificationsService.notifyApplicationReversed(userId, 'system', applicationId);

    return savedApplication;
  }

  async getApplicationStats(): Promise<{
    total: number;
    pending: number;
    approved: number;
    rejected: number;
  }> {
    const [total, pending, approved, rejected] = await Promise.all([
      this.collectorApplicationModel.countDocuments(),
      this.collectorApplicationModel.countDocuments({ status: CollectorApplicationStatus.PENDING }),
      this.collectorApplicationModel.countDocuments({ status: CollectorApplicationStatus.APPROVED }),
      this.collectorApplicationModel.countDocuments({ status: CollectorApplicationStatus.REJECTED }),
    ]);

    return { total, pending, approved, rejected };
  }
} 