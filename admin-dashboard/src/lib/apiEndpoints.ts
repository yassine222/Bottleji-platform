/**
 * Centralized API Endpoints Configuration
 * 
 * This file contains all API endpoints used in the admin dashboard.
 * Update the base URL here to switch between environments.
 */

// Base API URL - can be overridden by environment variables
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://192.168.1.14:3000/api';

/**
 * API Endpoints organized by category
 */
export const API_ENDPOINTS = {
  // Authentication & User Management
  AUTH: {
    LOGIN: '/auth/admin/login',
    PROFILE: '/auth/profile',
    CHANGE_PASSWORD: '/auth/change-password',
    VERIFY_TOKEN: '/auth/profile',
  },

  // Dashboard & Analytics
  DASHBOARD: {
    STATS: '/admin/dashboard',
    ANALYTICS: '/admin/dashboard',
    ANALYTICS_BY_DATE: '/admin/dashboard',
  },

  // User Management
  USERS: {
    GET_ALL: '/admin/users',
    GET_BY_ID: (userId: string) => `/admin/users/${userId}`,
    GET_ACTIVITIES: (userId: string) => `/admin/users/${userId}/activities`,
    UPDATE_ROLES: (userId: string) => `/admin/users/${userId}/roles`,
    BAN_USER: (userId: string) => `/admin/users/${userId}/ban`,
    UNBAN_USER: (userId: string) => `/admin/users/${userId}/unban`,
    RESET_WARNINGS: (userId: string) => `/admin/users/${userId}/reset-warnings`,
    DELETE_USER: (userId: string) => `/admin/users/${userId}`,
    RESTORE_USER: (userId: string) => `/admin/users/${userId}/restore`,
    GET_ADMIN_USERS: '/admin/users?limit=100',
    CREATE_ADMIN: '/admin/users',
  },

  // Drops Management
  DROPS: {
    // Basic drops endpoints
    GET_ALL: '/dropoffs',
    GET_BY_ID: (dropId: string) => `/dropoffs/${dropId}`,
    UPDATE: (dropId: string) => `/dropoffs/${dropId}`,
    DELETE: (dropId: string) => `/dropoffs/${dropId}`,
    GET_INTERACTIONS: (dropId: string) => `/admin/dropoffs/${dropId}/interactions`,
    
    // Drops management specific endpoints
    STATS: '/admin/drops-management/stats',
    LIST: '/admin/drops-management/list',
    REPORTED: '/admin/drops-management/reported',
    FLAGGED: '/admin/drops-management/flagged',
    COLLECTED: '/admin/drops-management/list?status=collected&limit=1000',
    STALE: '/admin/drops-management/stale?limit=1000',
    CENSORED: '/admin/drops?isCensored=true&limit=1000',
    
    // Analytics
    TIME_BASED_ANALYTICS: '/admin/drops-management/analytics/time-based',
    SUCCESS_RATE: '/admin/drops-management/analytics/success-rate',
    
    // Performance
    COLLECTOR_LEADERBOARD: '/admin/drops-management/performance/collector-leaderboard',
    HOUSEHOLD_RANKINGS: '/admin/drops-management/performance/household-rankings',
    
    // Actions
    ANALYZE_OLD: '/admin/drops-management/analyze-old',
    HIDE_OLD: '/admin/drops-management/hide-old',
    GET_DETAILS: (dropId: string) => `/admin/drops-management/details/${dropId}`,
    FLAG: (dropId: string) => `/admin/drops-management/flag/${dropId}`,
    UNFLAG: (dropId: string) => `/admin/drops-management/unflag/${dropId}`,
    CENSOR: (dropId: string) => `/admin/drops-management/censor/${dropId}`,
    DELETE_MANAGEMENT: (dropId: string) => `/admin/drops-management/delete/${dropId}`,
    
    // Reports
    REPORT_ACTION: (reportId: string, dropId: string) => `/api/admin/drops-management/reports/${reportId}/action/${dropId}`,
  },

  // Collector Applications
  APPLICATIONS: {
    GET_ALL: '/admin/collector-applications',
    GET_BY_ID: (applicationId: string) => `/admin/collector-applications/${applicationId}`,
    APPROVE: (applicationId: string) => `/admin/collector-applications/${applicationId}/approve`,
    REJECT: (applicationId: string) => `/admin/collector-applications/${applicationId}/reject`,
    REVERSE_APPROVAL: (applicationId: string) => `/admin/collector-applications/${applicationId}/reverse-approval`,
    GET_STATS: '/admin/collector-applications/stats',
  },

  // Support Tickets
  SUPPORT: {
    GET_ALL: '/support-tickets/admin/all',
    GET_BY_ID: (ticketId: string) => `/support-tickets/${ticketId}`,
    UPDATE_STATUS: (ticketId: string) => `/support-tickets/${ticketId}/status`,
    ASSIGN: (ticketId: string) => `/support-tickets/${ticketId}/assign`,
    ADD_MESSAGE: (ticketId: string) => `/support-tickets/${ticketId}/messages`,
    GET_STATS: '/support-tickets/admin/stats',
    ESCALATE: (ticketId: string) => `/support-tickets/${ticketId}/escalate`,
    RESOLVE: (ticketId: string) => `/admin/support-tickets/${ticketId}/resolve`,
    CLOSE: (ticketId: string) => `/admin/support-tickets/${ticketId}/close`,
  },

      // Training Content
      TRAINING: {
        GET_ALL: '/training',
        GET_BY_ID: (id: string) => `/training/${id}`,
        CREATE: '/training',
        UPDATE: (id: string) => `/training/${id}`,
        DELETE: (id: string) => `/training/${id}`,
        GET_BY_CATEGORY: (category: string) => `/training/category/${category}`,
        GET_FEATURED: '/training/featured',
        GET_CATEGORIES: '/training/categories',
        GET_STATS: '/training/stats',
        INCREMENT_VIEW: (id: string) => `/training/${id}/view`,
        TOGGLE_LIKE: (id: string) => `/training/${id}/like`,
      },

      // Reward Shop
      REWARDS: {
        GET_ALL: '/admin/rewards',
        GET_BY_ID: (id: string) => `/admin/rewards/${id}`,
        CREATE: '/admin/rewards',
        UPDATE: (id: string) => `/admin/rewards/${id}`,
        DELETE: (id: string) => `/admin/rewards/${id}`,
        GET_BY_CATEGORY: (category: string) => `/admin/rewards/category/${category}`,
        GET_BY_SUBCATEGORY: (subCategory: string) => `/admin/rewards/subcategory/${subCategory}`,
        GET_STATS: '/admin/rewards/stats',
        TOGGLE_ACTIVE: (id: string) => `/admin/rewards/${id}/toggle-active`,
        UPDATE_STOCK: (id: string) => `/admin/rewards/${id}/stock`,
        GET_REDEMPTIONS: '/admin/rewards/redemptions',
        GET_ALL_REDEMPTIONS: '/admin/rewards/redemptions',
        GET_REDEMPTION_BY_ID: (id: string) => `/admin/rewards/redemptions/${id}`,
    APPROVE_REDEMPTION: (id: string) => `/admin/rewards/redemptions/${id}/approve`,
    REJECT_REDEMPTION: (id: string) => `/admin/rewards/redemptions/${id}/reject`,
    DOWNLOAD_SHIPPING_LABEL: (id: string) => `/admin/shipping/label/${id}`,
        FULFILL_REDEMPTION: (id: string) => `/admin/rewards/redemptions/${id}/fulfill`,
      },
};

/**
 * Helper function to build full URL with base URL
 */
export const buildApiUrl = (endpoint: string, params?: Record<string, any>): string => {
  let url = `${API_BASE_URL}${endpoint}`;
  
  if (params) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        searchParams.append(key, value.toString());
      }
    });
    const queryString = searchParams.toString();
    if (queryString) {
      url += `?${queryString}`;
    }
  }
  
  return url;
};

/**
 * Helper function to get endpoint with parameters
 */
export const getEndpoint = (endpoint: string | ((...args: any[]) => string), ...args: any[]): string => {
  if (typeof endpoint === 'function') {
    return endpoint(...args);
  }
  return endpoint;
};

/**
 * API Configuration
 */
export const API_CONFIG = {
  BASE_URL: API_BASE_URL,
  TIMEOUT: 30000,
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000,
};

/**
 * Environment-specific configurations
 */
export const ENV_CONFIGS = {
  DEVELOPMENT: {
    BASE_URL: 'http://192.168.1.14:3000/api',
    TIMEOUT: 30000,
  },
  PRODUCTION: {
    BASE_URL: 'https://your-production-domain.com/api',
    TIMEOUT: 30000,
  },
  STAGING: {
    BASE_URL: 'https://your-staging-domain.com/api',
    TIMEOUT: 30000,
  },
};

export default API_ENDPOINTS;
