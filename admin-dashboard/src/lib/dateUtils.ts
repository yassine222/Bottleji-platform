/**
 * Centralized date formatting utilities for the admin dashboard
 * Ensures consistent timezone handling across all components
 */

/**
 * Formats a date string to a consistent format with timezone conversion
 * @param dateString - ISO date string from the backend
 * @param options - Intl.DateTimeFormatOptions for customization
 * @returns Formatted date string in local timezone
 */
export function formatDate(
  dateString: string, 
  options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }
): string {
  try {
    const date = new Date(dateString);
    
    // Validate the date
    if (isNaN(date.getTime())) {
      console.warn(`Invalid date string: ${dateString}`);
      return 'Invalid Date';
    }
    
    return date.toLocaleDateString('en-US', options);
  } catch (error) {
    console.error(`Error formatting date: ${dateString}`, error);
    return 'Invalid Date';
  }
}

/**
 * Formats a date string to show only the date (no time)
 * @param dateString - ISO date string from the backend
 * @returns Formatted date string in local timezone
 */
export function formatDateOnly(dateString: string): string {
  return formatDate(dateString, {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

/**
 * Formats a date string to show date and time
 * @param dateString - ISO date string from the backend
 * @returns Formatted date and time string in local timezone
 */
export function formatDateTime(dateString: string): string {
  return formatDate(dateString, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Formats a date string to show relative time (e.g., "2 hours ago")
 * @param dateString - ISO date string from the backend
 * @returns Relative time string
 */
export function formatRelativeTime(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
    
    if (diffInSeconds < 60) {
      return 'Just now';
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60);
      return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600);
      return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    } else if (diffInSeconds < 2592000) {
      const days = Math.floor(diffInSeconds / 86400);
      return `${days} day${days > 1 ? 's' : ''} ago`;
    } else {
      return formatDateOnly(dateString);
    }
  } catch (error) {
    console.error(`Error formatting relative time: ${dateString}`, error);
    return 'Invalid Date';
  }
}

/**
 * Gets the current date in ISO format for comparisons
 * @returns Current date as ISO string
 */
export function getCurrentISODate(): string {
  return new Date().toISOString();
}

/**
 * Checks if a date is today
 * @param dateString - ISO date string from the backend
 * @returns True if the date is today
 */
export function isToday(dateString: string): boolean {
  try {
    const date = new Date(dateString);
    const today = new Date();
    
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear();
  } catch (error) {
    console.error(`Error checking if date is today: ${dateString}`, error);
    return false;
  }
}

/**
 * Checks if a date is within the last N days
 * @param dateString - ISO date string from the backend
 * @param days - Number of days to check
 * @returns True if the date is within the last N days
 */
export function isWithinLastDays(dateString: string, days: number): boolean {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffInDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));
    
    return diffInDays <= days;
  } catch (error) {
    console.error(`Error checking if date is within last ${days} days: ${dateString}`, error);
    return false;
  }
}
