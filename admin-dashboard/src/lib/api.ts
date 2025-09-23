import axios from 'axios';

// API Configuration
const API_BASE_URL = 'http://localhost:3000/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // Increased timeout to 30 seconds
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    // Try localStorage first, then sessionStorage as fallback
    let token = localStorage.getItem('admin_token');
    if (!token) {
      token = sessionStorage.getItem('admin_token');
      if (token) {
        // If found in sessionStorage, copy to localStorage
        localStorage.setItem('admin_token', token);
      }
    }
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    console.log('🚀 API Request:', config.method?.toUpperCase(), config.url, config.data || config.params);
    return config;
  },
  (error) => {
    console.error('❌ API Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for logging and error handling
api.interceptors.response.use(
  (response) => {
    console.log('✅ API Response:', response.status, response.config.url, response.data);
    return response;
  },
  (error) => {
    // Enhanced error logging
    if (error.code === 'ECONNABORTED') {
      console.error('❌ API Timeout Error: Request timed out after', error.config?.timeout, 'ms');
    } else if (error.code === 'ERR_NETWORK') {
      console.error('❌ API Network Error: Unable to connect to server');
    } else if (error.response?.status !== 403 && error.response?.status !== 401) {
      console.error('❌ API Response Error:', error.response?.status, error.response?.data);
    }
    
    // Log the full error for debugging
    console.error('❌ Full Error Details:', {
      message: error.message,
      code: error.code,
      status: error.response?.status,
      data: error.response?.data,
      config: {
        url: error.config?.url,
        method: error.config?.method,
        timeout: error.config?.timeout,
      }
    });
    
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (email: string, password: string) =>
    api.post('/auth/admin/login', { email, password }),
  
  verifyToken: () =>
    api.get('/auth/profile'),
  
  getProfile: () =>
    api.get('/auth/profile'),
  
  changePassword: (currentPassword: string, newPassword: string) =>
    api.post('/auth/change-password', { currentPassword, newPassword }),
};

// Dashboard API
export const dashboardAPI = {
  getStats: () =>
    api.get('/admin/dashboard'),
  
  getRecentActivity: () =>
    api.get('/admin/dashboard'),
};

// Users API
export const usersAPI = {
  getAllUsers: (page = 1, limit = 20, includeDeleted = false) =>
    api.get('/admin/users', { params: { page, limit, includeDeleted } }),
  
  getUserById: (userId: string, includeDeleted = false) =>
    api.get(`/admin/users/${userId}`, { params: { includeDeleted } }),
  
  getUserActivities: (userId: string) =>
    api.get(`/admin/users/${userId}/activities`),
  
  updateUserRoles: (userId: string, roles: string[]) =>
    api.put(`/admin/users/${userId}/roles`, { roles }),
  
  banUser: (userId: string, reason: string) =>
    api.put(`/admin/users/${userId}/ban`, { reason }),
  
  unbanUser: (userId: string) =>
    api.put(`/admin/users/${userId}/unban`),
  
  deleteUser: (userId: string) =>
    api.delete(`/admin/users/${userId}`),
  
  restoreUser: (userId: string) =>
    api.put(`/admin/users/${userId}/restore`),

  // Admin management endpoints (Super Admin only)
  getAdminUsers: () =>
    api.get('/admin/users?limit=100'), // Use existing users endpoint with high limit
  
  createAdminUser: (adminData: { email: string; name: string; role: string }) =>
    api.post('/admin/users', { 
      email: adminData.email, 
      name: adminData.name, 
      password: 'temp123456', 
      roles: [adminData.role] 
    }),
};

// Drops API
export const dropsAPI = {
  getAllDrops: (page = 1, limit = 20, status?: string) =>
    api.get('/admin/drops', { params: { page, limit, status } }),
  
  getDropById: (dropId: string) =>
    api.get(`/admin/drops/${dropId}`),
  
  updateDrop: (dropId: string, updateData: any) =>
    api.put(`/admin/drops/${dropId}`, updateData),
  
  deleteDrop: (dropId: string) =>
    api.delete(`/admin/drops/${dropId}`),
};

// Applications API
export const applicationsAPI = {
  getAllApplications: (page = 1, limit = 20, status?: string) =>
    api.get('/admin/collector-applications', { params: { page, limit, status } }),
  getApplicationById: (applicationId: string) =>
    api.get(`/admin/collector-applications/${applicationId}`),
  approveApplication: (applicationId: string) =>
    api.put(`/admin/collector-applications/${applicationId}/approve`),
  rejectApplication: (applicationId: string, rejectionReason: string) =>
    api.put(`/admin/collector-applications/${applicationId}/reject`, { rejectionReason }),
  reverseApproval: (applicationId: string) =>
    api.put(`/admin/collector-applications/${applicationId}/reverse-approval`),
  getApplicationStats: () =>
    api.get('/admin/collector-applications/stats'),
};

// Support Tickets API
export const supportTicketsAPI = {
  getAllTickets: (page = 1, limit = 20, status?: string, category?: string) =>
    api.get('/admin/support-tickets', { params: { page, limit, status, category } }),
  
  getTicketById: (ticketId: string) =>
    api.get(`/admin/support-tickets/${ticketId}`),
  
  updateTicketStatus: (ticketId: string, status: string) =>
    api.put(`/admin/support-tickets/${ticketId}/status`, { status }),
  
  assignTicket: (ticketId: string, assignedTo: string) =>
    api.put(`/admin/support-tickets/${ticketId}/assign`, { assignedTo }),
  
  addMessage: (ticketId: string, message: string, isInternal = false) =>
    api.post(`/admin/support-tickets/${ticketId}/messages`, { message, isInternal }),
  
  getTicketStats: () =>
    api.get('/admin/support-tickets/stats'),
  
  escalateTicket: (ticketId: string, escalatedTo: string, reason: string) =>
    api.put(`/admin/support-tickets/${ticketId}/escalate`, { escalatedTo, reason }),
  
  resolveTicket: (ticketId: string, resolution: string) =>
    api.put(`/admin/support-tickets/${ticketId}/resolve`, { resolution }),
  
  closeTicket: (ticketId: string) =>
    api.put(`/admin/support-tickets/${ticketId}/close`),
};

// Analytics API - Use dashboard stats instead
export const analyticsAPI = {
  getAnalytics: () =>
    api.get('/admin/dashboard'),
  
  getAnalyticsByDateRange: (startDate: string, endDate: string) =>
    api.get('/admin/dashboard', { params: { startDate, endDate } }),
};

export default api; 