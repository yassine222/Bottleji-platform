import { Injectable } from '@nestjs/common';
import { NotificationsGateway } from './notifications.gateway';

export enum NotificationType {
  // User management
  USER_DELETED = 'user_deleted',
  USER_BANNED = 'user_banned',
  USER_UNBANNED = 'user_unbanned',
  ROLE_CHANGED = 'role_changed',
  
  // Drop management
  DROP_ACCEPTED = 'drop_accepted',
  DROP_COLLECTED = 'drop_collected',
  DROP_CANCELLED = 'drop_cancelled',
  DROP_EXPIRED = 'drop_expired',
  DROP_FLAGGED = 'drop_flagged',
  NEW_DROP_AVAILABLE = 'new_drop_available',
  
  // Support
  TICKET_RESPONSE = 'ticket_response',
  TICKET_STATUS_CHANGED = 'ticket_status_changed',
  
  // Applications
  APPLICATION_APPROVED = 'application_approved',
  APPLICATION_REJECTED = 'application_rejected',
  
  // Training
  NEW_TRAINING_CONTENT = 'new_training_content',
  TRAINING_COMPLETED = 'training_completed',
  
  // Rewards
  POINTS_EARNED = 'points_earned',
  POINTS_SPENT = 'points_spent',
  
  // System
  SYSTEM_MAINTENANCE = 'system_maintenance',
  ANNOUNCEMENT = 'announcement',
  
  // Connection
  CONNECTION_ESTABLISHED = 'connection_established',
  FORCE_LOGOUT = 'force_logout',
}

@Injectable()
export class NotificationsService {
  constructor(private notificationsGateway: NotificationsGateway) {}

  // User Management Notifications
  notifyUserDeleted(userId: string, deletedByAdminId: string) {
    console.log(`🔔 NotificationsService: Sending force logout for user ${userId}`);
    console.log(`🔔 NotificationsService: Deleted by admin ${deletedByAdminId}`);
    this.notificationsGateway.forceLogoutUser(userId, 'Your account has been deleted by an administrator');
    console.log(`🔔 NotificationsService: Force logout sent for user ${userId}`);
  }

  notifyUserBanned(userId: string, reason: string, bannedByAdminId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.USER_BANNED,
      title: 'Account Locked',
      message: `Your account has been locked: ${reason}`,
      data: { reason, bannedByAdminId },
      userId,
      timestamp: new Date()
    });
  }

  notifyUserUnbanned(userId: string, unbannedByAdminId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.USER_UNBANNED,
      title: 'Account Unlocked',
      message: 'Your account has been unlocked. You can now use the app normally.',
      data: { unbannedByAdminId },
      userId,
      timestamp: new Date()
    });
  }

  notifyRoleChanged(userId: string, newRoles: string[], changedByAdminId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.ROLE_CHANGED,
      title: 'Role Updated',
      message: `Your role has been updated to: ${newRoles.join(', ')}`,
      data: { newRoles, changedByAdminId },
      userId,
      timestamp: new Date()
    });
  }

  // Drop Management Notifications
  notifyDropAccepted(dropId: string, userId: string, collectorId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.DROP_ACCEPTED,
      title: 'Drop Accepted',
      message: 'A collector has accepted your drop',
      data: { dropId, collectorId },
      userId,
      timestamp: new Date()
    });
  }

  notifyDropCollected(dropId: string, userId: string, collectorId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.DROP_COLLECTED,
      title: 'Drop Collected',
      message: 'Your drop has been successfully collected',
      data: { dropId, collectorId },
      userId,
      timestamp: new Date()
    });
  }

  notifyNewDropAvailable(collectorId: string, dropData: any) {
    this.notificationsGateway.sendNotificationToUser(collectorId, {
      type: NotificationType.NEW_DROP_AVAILABLE,
      title: 'New Drop Available',
      message: 'A new drop is available in your area',
      data: dropData,
      userId: collectorId,
      timestamp: new Date()
    });
  }

  // Support Notifications
  notifyTicketResponse(ticketId: string, userId: string, response: string, agentId: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.TICKET_RESPONSE,
      title: 'Support Response',
      message: 'You have received a response to your support ticket',
      data: { ticketId, response, agentId },
      userId,
      timestamp: new Date()
    });
  }

  // Application Notifications
  notifyApplicationApproved(userId: string, approvedByAdminId: string, applicationId?: string) {
    // Send single notification with application status update
    this.notificationsGateway.sendApplicationStatusUpdate(userId, 'approved', {
      applicationId: applicationId || userId, // Use actual application ID if provided
      approvedByAdminId,
      title: 'Application Approved',
      message: 'Congratulations! Your collector application has been approved.',
      timestamp: new Date().toISOString(),
    });
  }

  notifyApplicationRejected(userId: string, reason: string, rejectedByAdminId: string, applicationId?: string) {
    // Send single notification with application status update
    this.notificationsGateway.sendApplicationStatusUpdate(userId, 'rejected', {
      applicationId: applicationId || userId, // Use actual application ID if provided
      reason,
      rejectedByAdminId,
      title: 'Application Rejected',
      message: `Your collector application was rejected: ${reason}`,
      timestamp: new Date().toISOString(),
    });
  }

  notifyApplicationReversed(userId: string, reversedByAdminId: string, applicationId?: string) {
    // Send single notification with application status update
    this.notificationsGateway.sendApplicationStatusUpdate(userId, 'pending', {
      applicationId: applicationId || userId, // Use actual application ID if provided
      reversedByAdminId,
      title: 'Application Status Changed',
      message: 'Your collector application approval has been reversed and is now pending review.',
      timestamp: new Date().toISOString(),
    });
  }

  // System Notifications
  notifySystemMaintenance(message: string, scheduledTime?: Date) {
    this.notificationsGateway.sendNotificationToAll({
      type: NotificationType.SYSTEM_MAINTENANCE,
      title: 'System Maintenance',
      message,
      data: { scheduledTime },
      timestamp: new Date()
    });
  }

  notifyAnnouncement(title: string, message: string, targetRole?: string) {
    const notification = {
      type: NotificationType.ANNOUNCEMENT,
      title,
      message,
      timestamp: new Date()
    };

    if (targetRole) {
      this.notificationsGateway.sendNotificationToRole(targetRole, notification);
    } else {
      this.notificationsGateway.sendNotificationToAll(notification);
    }
  }

  // Training Notifications
  notifyNewTrainingContent(title: string, message: string, targetRole?: string) {
    const notification = {
      type: NotificationType.NEW_TRAINING_CONTENT,
      title,
      message,
      timestamp: new Date()
    };

    if (targetRole) {
      this.notificationsGateway.sendNotificationToRole(targetRole, notification);
    } else {
      this.notificationsGateway.sendNotificationToAll(notification);
    }
  }

  // Drop flagged notification to creator
  notifyDropFlagged(userId: string, dropId: string, totalCancellations: number, reason?: string, dropTitle?: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.DROP_FLAGGED,
      title: 'Drop Flagged',
      message: reason || 'Your drop was flagged due to multiple cancellations. It will be hidden from the map.',
      data: {
        dropId,
        totalCancellations,
        dropTitle,
        reason: reason || 'Cancelled by 3 different collectors',
      },
      userId,
      timestamp: new Date(),
    });
  }

  notifyTrainingCompleted(userId: string, trainingTitle: string) {
    this.notificationsGateway.sendNotificationToUser(userId, {
      type: NotificationType.TRAINING_COMPLETED,
      title: 'Training Completed',
      message: `You have completed the training: ${trainingTitle}`,
      data: { trainingTitle },
      userId,
      timestamp: new Date()
    });
  }

  // Utility methods
  isUserConnected(userId: string): boolean {
    return this.notificationsGateway.isUserConnected(userId);
  }

  getConnectedUsersCount(): number {
    return this.notificationsGateway.getConnectedUsersCount();
  }
} 