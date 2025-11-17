export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  address?: string;
  profilePhoto?: string;
  roles: string[];
  collectorSubscriptionType?: string;
  isProfileComplete: boolean;
  isAccountLocked?: boolean;
  warningCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface Drop {
  id: string;
  userId: string;
  imageUrl: string;
  numberOfBottles: number;
  numberOfCans: number;
  bottleType: string;
  notes?: string;
  leaveOutside: boolean;
  status: 'pending' | 'accepted' | 'collected' | 'cancelled' | 'expired';
  location: {
    latitude: number;
    longitude: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface CollectorApplication {
  id: string;
  userId: string | { id: string; name: string; email: string; }; // Updated to handle populated user
  status: 'pending' | 'approved' | 'rejected';
  idCardPhoto: string;
  selfieWithIdPhoto: string;
  idCardNumber?: string;
  idCardType?: string;
  idCardExpiryDate?: string;
  idCardIssuingAuthority?: string;
  idCardBackPhoto?: string;
  passportIssueDate?: string;
  passportExpiryDate?: string;
  passportMainPagePhoto?: string;
  rejectionReason?: string;
  appliedAt: string;
  reviewedAt?: string;
  reviewedBy?: string;
  reviewNotes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface TrainingContent {
  id: string;
  title: string;
  content: string;
  category: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface SupportTicket {
  id: string;
  userId: string;
  subject: string;
  message: string;
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  priority: 'low' | 'medium' | 'high';
  responses: SupportResponse[];
  createdAt: string;
  updatedAt: string;
}

export interface SupportResponse {
  id: string;
  ticketId: string;
  responderId: string;
  responderName: string;
  response: string;
  createdAt: string;
}

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'moderator';
  permissions: string[];
  createdAt: string;
  updatedAt: string;
}

export interface DashboardStats {
  totalUsers: number;
  totalDrops: number;
  totalApplications: number;
  totalTickets: number;
  pendingApplications: number;
  pendingTickets: number;
  recentActivity: ActivityItem[];
  bottleTypeDistribution?: Record<string, number>;
  co2SavingsTimeSeries?: { date: string; co2: number }[];
}

export interface ActivityItem {
  id: string;
  type: 'user_registration' | 'drop_created' | 'application_submitted' | 'ticket_created';
  description: string;
  timestamp: string;
  userId?: string;
  userName?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export type UserRole = 'super_admin' | 'admin' | 'moderator' | 'support_agent' | 'collector' | 'household'; 