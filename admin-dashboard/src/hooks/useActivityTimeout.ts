'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';

interface UseActivityTimeoutOptions {
  timeoutMinutes?: number; // Total inactivity timeout (default: 30 minutes)
  warningMinutes?: number; // Show warning before this many minutes (default: 2 minutes)
  onLogout?: () => void;
}

export function useActivityTimeout({
  timeoutMinutes = 30,
  warningMinutes = 2,
  onLogout,
}: UseActivityTimeoutOptions = {}) {
  const router = useRouter();
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const warningTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const [showWarning, setShowWarning] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState(0);
  const lastActivityRef = useRef<number>(Date.now());

  // Calculate timeout in milliseconds
  const timeoutMs = timeoutMinutes * 60 * 1000;
  const warningMs = warningMinutes * 60 * 1000;

  // Reset timers on user activity
  const resetTimers = useCallback(() => {
    const now = Date.now();
    lastActivityRef.current = now;

    // Clear existing timers
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    if (warningTimeoutRef.current) {
      clearTimeout(warningTimeoutRef.current);
    }

    // Hide warning if user is active
    if (showWarning) {
      setShowWarning(false);
      setTimeRemaining(0);
    }

    // Set warning timer (show warning before logout)
    warningTimeoutRef.current = setTimeout(() => {
      setShowWarning(true);
      const remaining = warningMinutes * 60; // seconds
      setTimeRemaining(remaining);

      // Countdown in warning modal
      const countdownInterval = setInterval(() => {
        setTimeRemaining((prev) => {
          if (prev <= 1) {
            clearInterval(countdownInterval);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }, timeoutMs - warningMs);

    // Set logout timer
    timeoutRef.current = setTimeout(() => {
      handleLogout();
    }, timeoutMs);
  }, [timeoutMs, warningMs, warningMinutes, showWarning]);

  // Handle logout
  const handleLogout = useCallback(() => {
    // Clear timers
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    if (warningTimeoutRef.current) {
      clearTimeout(warningTimeoutRef.current);
    }

    // Clear session
    sessionStorage.removeItem('admin_token');
    localStorage.removeItem('admin_token');

    // Call custom logout handler if provided
    if (onLogout) {
      onLogout();
    } else {
      // Default: redirect to login
      router.push('/login');
    }
  }, [router, onLogout]);

  // Extend session (user clicked "Stay Logged In")
  const extendSession = useCallback(() => {
    resetTimers();
  }, [resetTimers]);

  // Track user activity
  useEffect(() => {
    const activityEvents = [
      'mousedown',
      'mousemove',
      'keypress',
      'scroll',
      'touchstart',
      'click',
    ];

    const handleActivity = () => {
      resetTimers();
    };

    // Add event listeners
    activityEvents.forEach((event) => {
      window.addEventListener(event, handleActivity, { passive: true });
    });

    // Initialize timers
    resetTimers();

    // Cleanup
    return () => {
      activityEvents.forEach((event) => {
        window.removeEventListener(event, handleActivity);
      });
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      if (warningTimeoutRef.current) {
        clearTimeout(warningTimeoutRef.current);
      }
    };
  }, [resetTimers]);

  return {
    showWarning,
    timeRemaining,
    extendSession,
    handleLogout,
  };
}

