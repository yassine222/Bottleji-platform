/**
 * Centralized configuration for API and WebSocket URLs
 * 
 * Environment variables:
 * - NEXT_PUBLIC_API_URL: Base API URL (defaults to production)
 * - NEXT_PUBLIC_WS_URL: WebSocket URL (defaults to production)
 */

// API Base URL
export const API_BASE_URL = 
  process.env.NEXT_PUBLIC_API_URL || 
  'https://bottleji-api.onrender.com/api';

// WebSocket URL (remove /api suffix if present, add /chat)
export const getWebSocketUrl = (): string => {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://bottleji-api.onrender.com';
  // Remove /api if present
  const baseUrl = apiUrl.replace(/\/api$/, '');
  // Convert http to ws, https to wss
  const wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
  const wsBaseUrl = baseUrl.replace(/^https?:\/\//, '');
  return `${wsProtocol}://${wsBaseUrl}/chat`;
};

// Export WebSocket URL as constant
export const WS_URL = getWebSocketUrl();

