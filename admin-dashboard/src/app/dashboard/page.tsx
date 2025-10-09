'use client';

import { useState, useEffect, useRef } from 'react';
import { analyticsAPI } from '../../lib/api';
import Sidebar from '@/components/layout/Sidebar';
import Header from '@/components/layout/Header';
import AuthGuard from '@/components/auth/AuthGuard';
import {
  UsersIcon,
  CubeIcon,
  ClipboardDocumentListIcon,
  ChatBubbleLeftRightIcon,
} from '@heroicons/react/24/outline';
import { usersAPI } from '@/lib/api';
import { applicationsAPI } from '@/lib/api';
import { supportTicketsAPI, trainingAPI } from '@/lib/api';
import { CollectorApplication } from '@/types';
import { UserRole } from '@/types';

// Dashboard Content Component
function DashboardContent({ stats, loading, error }: any) {
  const statCards = [
    {
      name: 'Total Users',
      value: stats?.totalUsers || 0,
      icon: UsersIcon,
      color: 'bg-secondary',
      change: '+12%',
      changeType: 'positive',
    },
    {
      name: 'Total Drops',
      value: stats?.totalDrops || 0,
      icon: CubeIcon,
      color: 'bg-primary',
      change: '+8%',
      changeType: 'positive',
    },
    {
      name: 'Pending Applications',
      value: stats?.pendingApplications || 0,
      icon: ClipboardDocumentListIcon,
      color: 'bg-warning-color',
      change: '+3',
      changeType: 'neutral',
    },
    {
      name: 'Open Support Tickets',
      value: stats?.pendingTickets || 0,
      icon: ChatBubbleLeftRightIcon,
      color: 'bg-error-color',
      change: '-2',
      changeType: 'negative',
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="text-error-color text-lg font-medium mb-2">Error Loading Dashboard</div>
          <div className="text-text-secondary">{error}</div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <div
            key={stat.name}
            className="bg-white overflow-hidden shadow rounded-lg border border-gray-200"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <stat.icon className="h-6 w-6 text-text-secondary" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-text-secondary truncate">
                      {stat.name}
                    </dt>
                    <dd className="text-lg font-medium text-text-primary">
                      {stat.value.toLocaleString()}
                    </dd>
                  </dl>
                </div>
              </div>
              <div className="mt-2">
                <span
                  className={`inline-flex items-baseline px-2.5 py-0.5 rounded-full text-sm font-medium ${
                    stat.changeType === 'positive'
                      ? 'bg-success-color text-white'
                      : stat.changeType === 'negative'
                      ? 'bg-error-color text-white'
                      : 'bg-warning-color text-white'
                  }`}
                >
                  {stat.change}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="bg-white shadow rounded-lg border border-gray-200">
        <div className="px-4 py-5 sm:p-6">
          <div className="mt-5">
            {stats?.recentActivity && stats.recentActivity.length > 0 ? (
              <div className="flow-root">
                <ul className="-mb-8">
                  {stats.recentActivity.map((activity: any, activityIdx: number) => (
                    <li key={activity.id}>
                      <div className="relative pb-8">
                        {activityIdx !== stats.recentActivity.length - 1 ? (
                          <span
                            className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200"
                            aria-hidden="true"
                          />
                        ) : null}
                        <div className="relative flex space-x-3">
                          <div>
                            <span className="h-8 w-8 rounded-full bg-primary flex items-center justify-center ring-8 ring-white">
                              <span className="text-white text-sm font-medium">
                                {activity.type.charAt(0).toUpperCase()}
                              </span>
                            </span>
                          </div>
                          <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                            <div>
                              <p className="text-sm text-text-secondary">
                                {activity.description}
                              </p>
                            </div>
                            <div className="text-right text-sm whitespace-nowrap text-text-secondary">
                              <time dateTime={activity.timestamp}>
                                {new Date(activity.timestamp).toLocaleDateString()}
                              </time>
                            </div>
                          </div>
                        </div>
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            ) : (
              <p className="text-text-secondary">No recent activity</p>
            )}
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white shadow rounded-lg border border-gray-200">
        <div className="px-4 py-5 sm:p-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <button className="bg-secondary text-white px-4 py-2 rounded-md hover:bg-blue-600 transition-colors">
              Review Applications
            </button>
            <button className="bg-primary text-white px-4 py-2 rounded-md hover:bg-primary-dark transition-colors">
              Approve Drops
            </button>
            <button className="bg-primary-dark text-white px-4 py-2 rounded-md hover:bg-primary transition-colors">
              Respond to Tickets
            </button>
            <button className="bg-secondary text-white px-4 py-2 rounded-md hover:bg-blue-600 transition-colors">
              Add Training Content
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Other Content Components
function UsersContent() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [includeDeleted, setIncludeDeleted] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [showUserModal, setShowUserModal] = useState(false);
  const [showBanModal, setShowBanModal] = useState(false);
  const [banReason, setBanReason] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalUsers, setTotalUsers] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [userActivities, setUserActivities] = useState<any[]>([]);
  const [loadingActivities, setLoadingActivities] = useState(false);
  const [activeActivityTab, setActiveActivityTab] = useState('drops-created');
  const [activityFilter, setActivityFilter] = useState('all');
  const [activityDateFilter, setActivityDateFilter] = useState('all');

  // Load users from API
  const loadUsers = async (page = 1) => {
    try {
      setLoading(true);
      setError(null);
      const response = await usersAPI.getAllUsers(page, 20, includeDeleted);
      const { users, total, totalPages } = response.data;
      setUsers(users);
      setTotalUsers(total);
      setTotalPages(totalPages);
      setCurrentPage(page);
    } catch (err: any) {
      console.error('Error loading users:', err);
      setError(err.response?.data?.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  // Load user activities
  const loadUserActivities = async (userId: string) => {
    try {
      setLoadingActivities(true);
      const response = await usersAPI.getUserActivities(userId);
      setUserActivities(response.data.activities || []);
    } catch (err: any) {
      console.error('Error loading user activities:', err);
      setUserActivities([]);
    } finally {
      setLoadingActivities(false);
    }
  };



  // Filter activities by type
  const getFilteredActivities = () => {
    let filtered = userActivities;

    // Filter by activity type
    if (activeActivityTab === 'drops-created') {
      filtered = filtered.filter(activity => activity.type === 'drop_created');
    } else if (activeActivityTab === 'collection-history') {
      filtered = filtered.filter(activity => activity.type.startsWith('collector_'));
    }

    // Filter by interaction type (for collection history)
    if (activeActivityTab === 'collection-history' && activityFilter !== 'all') {
      filtered = filtered.filter(activity => activity.interactionType === activityFilter);
    }

    // Filter by date range
    if (activityDateFilter !== 'all') {
      const now = new Date();
      const filterDate = new Date();
      
      switch (activityDateFilter) {
        case 'today':
          filterDate.setHours(0, 0, 0, 0);
          filtered = filtered.filter(activity => new Date(activity.timestamp) >= filterDate);
          break;
        case 'week':
          filterDate.setDate(filterDate.getDate() - 7);
          filtered = filtered.filter(activity => new Date(activity.timestamp) >= filterDate);
          break;
        case 'month':
          filterDate.setMonth(filterDate.getMonth() - 1);
          filtered = filtered.filter(activity => new Date(activity.timestamp) >= filterDate);
          break;
        case 'year':
          filterDate.setFullYear(filterDate.getFullYear() - 1);
          filtered = filtered.filter(activity => new Date(activity.timestamp) >= filterDate);
          break;
      }
    }

    return filtered.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  };

  // Get activity counts for tabs
  const getActivityCounts = () => {
    const dropsCreated = userActivities.filter(activity => activity.type === 'drop_created').length;
    const collectionHistory = userActivities.filter(activity => activity.type.startsWith('collector_')).length;
    
    return { dropsCreated, collectionHistory };
  };

  useEffect(() => {
    loadUsers();
  }, [includeDeleted]); // Add includeDeleted to dependency array

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const isActive = !user.isAccountLocked || (user.accountLockedUntil && new Date(user.accountLockedUntil) <= new Date());
    const isLocked = user.isAccountLocked && (!user.accountLockedUntil || new Date(user.accountLockedUntil) > new Date());
    
    const matchesFilter = filterStatus === 'all' ||
                         (filterStatus === 'users' && !user.roles?.includes('collector')) ||
                         (filterStatus === 'collectors' && user.roles?.includes('collector')) ||
                         (filterStatus === 'active' && isActive) ||
                         (filterStatus === 'locked' && isLocked);
    
    return matchesSearch && matchesFilter;
  });

  const handleBanUser = (user: any) => {
    setSelectedUser(user);
    setShowBanModal(true);
  };

  const confirmBanUser = async () => {
    if (selectedUser && banReason.trim()) {
      try {
        await usersAPI.banUser(selectedUser.id, banReason);
        // Reload users to get updated data
        await loadUsers(currentPage);
        setShowBanModal(false);
        setBanReason('');
        setSelectedUser(null);
      } catch (err: any) {
        console.error('Error banning user:', err);
        setError(err.response?.data?.message || 'Failed to ban user');
      }
    }
  };

  const handleUnbanUser = async (user: any) => {
    try {
      await usersAPI.unbanUser(user.id);
      // Reload users to get updated data
      await loadUsers(currentPage);
    } catch (err: any) {
      console.error('Error unbanning user:', err);
      setError(err.response?.data?.message || 'Failed to unban user');
    }
  };

  const handleDeleteUser = async (user: any) => {
    const confirmed = window.confirm(
      `Are you sure you want to delete ${user.name}?\n\n` +
      `This will:\n` +
      `• Mark the user account as deleted\n` +
      `• Force logout any active sessions\n` +
      `• Keep all their data for analytics\n` +
      `• You can restore them later if needed\n\n` +
      `Click OK to proceed with deletion.`
    );
    
    if (confirmed) {
      try {
        await usersAPI.deleteUser(user.id);
        // Reload users to get updated data
        await loadUsers(currentPage);
      } catch (err: any) {
        console.error('Error deleting user:', err);
        setError(err.response?.data?.message || 'Failed to delete user');
      }
    }
  };

  const handleRestoreUser = async (user: any) => {
    const confirmed = window.confirm(
      `Are you sure you want to restore ${user.name}?\n\n` +
      `This will:\n` +
      `• Reactivate their account\n` +
      `• Allow them to log in again\n` +
      `• Clear any session invalidation\n\n` +
      `Click OK to proceed with restoration.`
    );
    
    if (confirmed) {
      try {
        await usersAPI.restoreUser(user.id);
        // Reload users to get updated data
        await loadUsers(currentPage);
      } catch (err: any) {
        console.error('Error restoring user:', err);
        setError(err.response?.data?.message || 'Failed to restore user');
      }
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusBadge = (user: any) => {
    // Check if user is deleted first
    if (user.isDeleted) {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
          Deleted
        </span>
      );
    }

    if (user.isAccountLocked) {
      // Check if it's a temporary lock (has accountLockedUntil date)
      if (user.accountLockedUntil) {
        const lockDate = new Date(user.accountLockedUntil);
        const now = new Date();
        
        if (lockDate > now) {
          // Still locked - temporary ban
          return (
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
              Locked
            </span>
          );
        } else {
          // Lock expired - should be active now
          return (
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
              Active
            </span>
          );
        }
      } else {
        // No end date - permanent lock
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            Locked
          </span>
        );
      }
    }
    
    // Not locked - show as active regardless of role
    return (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
        Active
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <p className="text-error-color mb-4">{error}</p>
          <button
            onClick={() => loadUsers()}
            className="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-4">
        <div className="bg-white overflow-hidden shadow rounded-lg border border-gray-200">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-bold">{totalUsers}</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-text-secondary truncate">Total Users</dt>
                  <dd className="text-lg font-medium text-text-primary">{totalUsers}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
        
        <div className="bg-white overflow-hidden shadow rounded-lg border border-gray-200">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-secondary rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-bold">
                    {users.filter(u => u.roles?.includes('collector')).length}
                  </span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-text-secondary truncate">Collectors</dt>
                  <dd className="text-lg font-medium text-text-primary">
                    {users.filter(u => u.roles?.includes('collector')).length}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
        
        <div className="bg-white overflow-hidden shadow rounded-lg border border-gray-200">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-success-color rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-bold">
                    {users.filter(u => !u.isAccountLocked || (u.accountLockedUntil && new Date(u.accountLockedUntil) <= new Date())).length}
                  </span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-text-secondary truncate">Active Users</dt>
                  <dd className="text-lg font-medium text-text-primary">
                    {users.filter(u => !u.isAccountLocked || (u.accountLockedUntil && new Date(u.accountLockedUntil) <= new Date())).length}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
        
        <div className="bg-white overflow-hidden shadow rounded-lg border border-gray-200">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-error-color rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-bold">
                    {users.filter(u => u.isAccountLocked && (!u.accountLockedUntil || new Date(u.accountLockedUntil) > new Date())).length}
                  </span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-text-secondary truncate">Locked Users</dt>
                  <dd className="text-lg font-medium text-text-primary">
                    {users.filter(u => u.isAccountLocked && (!u.accountLockedUntil || new Date(u.accountLockedUntil) > new Date())).length}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white shadow-lg rounded-xl border border-gray-100 overflow-hidden">
        <div className="px-6 py-5 border-b border-gray-100 bg-gradient-to-r from-gray-50 to-gray-100/50">
          <h3 className="text-lg font-semibold text-text-primary mb-4">Search & Filter Users</h3>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div>
              <label htmlFor="search" className="block text-sm font-medium text-text-primary mb-2 flex items-center">
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                Search Users
              </label>
              <div className="relative">
                <input
                  type="text"
                  id="search"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by name or email..."
                  className="w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-all duration-200"
                />
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </div>
              </div>
            </div>
            
            <div>
              <label htmlFor="filter" className="block text-sm font-medium text-text-primary mb-2 flex items-center">
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
                </svg>
                Filter by Status
              </label>
              <select
                id="filter"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-all duration-200 bg-white"
              >
                <option value="all">All Users</option>
                <option value="users">Household Users</option>
                <option value="collectors">Collectors</option>
                <option value="active">Active Users</option>
                <option value="locked">Locked Users</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-text-primary mb-2 flex items-center">
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4M12 4v16" />
                </svg>
                Show Deleted Users
              </label>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="includeDeleted"
                  checked={includeDeleted}
                  onChange={(e) => {
                    setIncludeDeleted(e.target.checked);
                    loadUsers(1); // Reload with new filter
                  }}
                  className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                />
                <label htmlFor="includeDeleted" className="ml-2 text-sm text-text-secondary">
                  Include deleted users
                </label>
              </div>
            </div>
            
            <div className="flex items-end">
              <button
                onClick={() => {
                  setSearchTerm('');
                  setFilterStatus('all');
                }}
                className="w-full inline-flex items-center justify-center px-4 py-2.5 bg-gray-100 text-text-primary border border-gray-300 rounded-lg hover:bg-gray-200 transition-all duration-200 font-medium"
              >
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Clear Filters
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white shadow-lg rounded-xl border border-gray-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100 bg-gradient-to-r from-primary/5 to-secondary/5">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-text-primary">User Management</h3>
            <div className="flex items-center space-x-2">
              <span className="text-sm text-text-secondary">
                {filteredUsers.length} of {totalUsers} users
              </span>
            </div>
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gradient-to-r from-gray-50 to-gray-100/50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span>User</span>
                  </div>
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span>Status</span>
                  </div>
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span>Role</span>
                  </div>
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    <span>Verification</span>
                  </div>
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span>Joined</span>
                  </div>
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-text-secondary uppercase tracking-wider">
                  <div className="flex items-center space-x-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4" />
                    </svg>
                    <span>Actions</span>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-50">
              {filteredUsers.map((user, index) => (
                <tr key={user.id} className={`hover:bg-gradient-to-r hover:from-primary/5 hover:to-secondary/5 transition-all duration-200 ${index % 2 === 0 ? 'bg-white' : 'bg-gray-50/30'}`}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-12 w-12 relative">
                        {user.profilePhoto ? (
                          <img
                            className="h-12 w-12 rounded-full object-cover ring-2 ring-white shadow-sm"
                            src={user.profilePhoto}
                            alt={user.name || 'User'}
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.style.display = 'none';
                              target.nextElementSibling?.classList.remove('hidden');
                            }}
                          />
                        ) : null}
                        <div className={`h-12 w-12 rounded-full bg-gradient-to-br from-primary to-primary-dark flex items-center justify-center shadow-sm ring-2 ring-white ${user.profilePhoto ? 'hidden' : ''}`}>
                          <span className="text-white text-sm font-semibold">
                            {user.name?.charAt(0)?.toUpperCase() || user.email?.charAt(0)?.toUpperCase() || 'U'}
                          </span>
                        </div>
                        {/* Online indicator */}
                        <div className="absolute -bottom-1 -right-1 h-4 w-4 bg-success-color rounded-full border-2 border-white shadow-sm"></div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-semibold text-text-primary">{user.name || 'No Name'}</div>
                        <div className="text-sm text-text-secondary flex items-center">
                          <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                          </svg>
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(user)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex flex-wrap gap-1">
                      {user.roles?.map((role: string, idx: number) => (
                        <span
                          key={idx}
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            role === 'admin' 
                              ? 'bg-red-100 text-red-800' 
                              : role === 'collector' 
                              ? 'bg-blue-100 text-blue-800' 
                              : 'bg-gray-100 text-gray-800'
                          }`}
                        >
                          {role}
                        </span>
                      )) || <span className="text-text-secondary text-sm">No roles</span>}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {user.isVerified ? (
                      <div className="flex items-center text-success-color">
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                        </svg>
                        <span className="text-sm font-medium">Verified</span>
                      </div>
                    ) : (
                      <div className="flex items-center text-warning-color">
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                        </svg>
                        <span className="text-sm font-medium">Not Verified</span>
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-text-secondary">
                    <div className="flex items-center">
                      <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      {formatDate(user.createdAt)}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => {
                          setSelectedUser(user);
                          setShowUserModal(true);
                          setActiveActivityTab('drops-created');
                          setActivityFilter('all');
                          setActivityDateFilter('all');
                          loadUserActivities(user.id);
                        }}
                        className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all duration-200 shadow-sm"
                      >
                        <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                        View
                      </button>
                      {user.isAccountLocked ? (
                        <button
                          onClick={() => handleUnbanUser(user)}
                          className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all duration-200 shadow-sm"
                        >
                          <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
                          </svg>
                          Unlock
                        </button>
                      ) : (
                        <button
                          onClick={() => handleBanUser(user)}
                          className="inline-flex items-center px-3 py-1.5 border border-orange-500 text-xs font-medium rounded-md text-orange-600 bg-orange-50 hover:bg-orange-500 hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 transition-all duration-200 shadow-sm"
                        >
                          <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                          </svg>
                          Lock
                        </button>
                      )}
                      {user.isDeleted ? (
                        <button
                          onClick={() => handleRestoreUser(user)}
                          className="inline-flex items-center px-3 py-1.5 border border-green-500 text-xs font-medium rounded-md text-green-600 bg-green-50 hover:bg-green-500 hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200 shadow-sm"
                        >
                          <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                          </svg>
                          Restore
                        </button>
                      ) : (
                        <button
                          onClick={() => handleDeleteUser(user)}
                          className="inline-flex items-center px-3 py-1.5 border border-red-500 text-xs font-medium rounded-md text-red-600 bg-red-50 hover:bg-red-500 hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-all duration-200 shadow-sm"
                        >
                          <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {filteredUsers.length === 0 && (
          <div className="text-center py-12">
            <div className="mx-auto h-12 w-12 text-gray-400">
              <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <h3 className="mt-2 text-sm font-medium text-text-primary">No users found</h3>
            <p className="mt-1 text-sm text-text-secondary">Try adjusting your search or filter criteria.</p>
          </div>
        )}

        {/* Enhanced Pagination */}
        {totalPages > 1 && (
          <div className="bg-gray-50 px-6 py-3 border-t border-gray-100">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 text-sm text-text-secondary">
                <span>Showing page {currentPage} of {totalPages}</span>
                <span className="text-gray-400">•</span>
                <span>{totalUsers} total users</span>
              </div>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => loadUsers(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="inline-flex items-center px-3 py-2 border border-gray-300 rounded-md text-sm font-medium text-text-secondary bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                  </svg>
                  Previous
                </button>
                <button
                  onClick={() => loadUsers(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className="inline-flex items-center px-3 py-2 border border-gray-300 rounded-md text-sm font-medium text-text-secondary bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  Next
                  <svg className="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* User Details Modal */}
      {showUserModal && selectedUser && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0 h-16 w-16">
                    {selectedUser.profilePhoto ? (
                      <img
                        className="h-16 w-16 rounded-full object-cover"
                        src={selectedUser.profilePhoto}
                        alt={selectedUser.name || 'User'}
                        onError={(e) => {
                          // Fallback to initials if image fails to load
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          target.nextElementSibling?.classList.remove('hidden');
                        }}
                      />
                    ) : null}
                    <div className={`h-16 w-16 rounded-full bg-primary flex items-center justify-center ${selectedUser.profilePhoto ? 'hidden' : ''}`}>
                      <span className="text-white text-xl font-medium">
                        {selectedUser.name?.charAt(0)?.toUpperCase() || selectedUser.email?.charAt(0)?.toUpperCase() || 'U'}
                      </span>
                    </div>
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-text-primary">{selectedUser.name || 'No Name'}</h3>
                    <p className="text-sm text-text-secondary">{selectedUser.email}</p>
                  </div>
                </div>
                <button
                  onClick={() => setShowUserModal(false)}
                  className="text-text-secondary hover:text-text-primary"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h4 className="font-medium text-text-primary mb-2">Personal Information</h4>
                  <div className="space-y-2 text-sm">
                    <div><span className="font-medium">Name:</span> {selectedUser.name || 'Not provided'}</div>
                    <div><span className="font-medium">Email:</span> {selectedUser.email}</div>
                    <div><span className="font-medium">Phone:</span> {selectedUser.phoneNumber || 'Not provided'}</div>
                    <div><span className="font-medium">Address:</span> {selectedUser.address || 'Not provided'}</div>
                  </div>
                </div>
                
                <div>
                  <h4 className="font-medium text-text-primary mb-2">Account Information</h4>
                  <div className="space-y-2 text-sm">
                    <div><span className="font-medium">Status:</span> {getStatusBadge(selectedUser)}</div>
                    <div><span className="font-medium">Roles:</span> {selectedUser.roles?.join(', ') || 'No roles'}</div>
                    <div><span className="font-medium">Verified:</span> {selectedUser.isVerified ? 'Yes' : 'No'}</div>
                    <div><span className="font-medium">Profile Complete:</span> {selectedUser.isProfileComplete ? 'Yes' : 'No'}</div>
                    <div><span className="font-medium">Joined:</span> {formatDate(selectedUser.createdAt)}</div>
                    <div><span className="font-medium">Last Updated:</span> {formatDate(selectedUser.updatedAt)}</div>
                    {selectedUser.isAccountLocked && selectedUser.accountLockedUntil && (
                      <div><span className="font-medium">Lock Expires:</span> {formatDate(selectedUser.accountLockedUntil)}</div>
                    )}
                  </div>
                </div>
                
                {selectedUser.collectorApplication && (
                  <div>
                    <h4 className="font-medium text-text-primary mb-2">Collector Application</h4>
                    <div className="space-y-2 text-sm">
                      <div><span className="font-medium">Status:</span> {selectedUser.collectorApplication.status}</div>
                      <div><span className="font-medium">Applied:</span> {formatDate(selectedUser.collectorApplication.appliedAt)}</div>
                      {selectedUser.collectorApplication.reviewedAt && (
                        <div><span className="font-medium">Reviewed:</span> {formatDate(selectedUser.collectorApplication.reviewedAt)}</div>
                      )}
                      {selectedUser.collectorApplication.rejectionReason && (
                        <div><span className="font-medium">Rejection Reason:</span> {selectedUser.collectorApplication.rejectionReason}</div>
                      )}
                    </div>
                  </div>
                )}
                
                {selectedUser.warnings && selectedUser.warnings.length > 0 && (
                  <div>
                    <h4 className="font-medium text-text-primary mb-2">Warnings</h4>
                    <div className="space-y-2 text-sm">
                      {selectedUser.warnings.map((warning: any, index: number) => (
                        <div key={index} className="text-error-color">
                          <div>{warning.reason}</div>
                          <div className="text-xs">{formatDate(warning.date)}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
              
                  {/* User Activities with Tabs */}
                  <div className="mt-8">
                    <div className="flex items-center justify-between mb-4">
                      <h4 className="font-medium text-text-primary">User Activities</h4>
                      <div className="flex items-center space-x-2">
                        {/* Date Filter */}
                        <select
                          value={activityDateFilter}
                          onChange={(e) => setActivityDateFilter(e.target.value)}
                          className="px-3 py-1 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                        >
                          <option value="all">All Time</option>
                          <option value="today">Today</option>
                          <option value="week">Last 7 Days</option>
                          <option value="month">Last 30 Days</option>
                          <option value="year">Last Year</option>
                        </select>
                        
                        {/* Interaction Type Filter (only for collection history) */}
                        {activeActivityTab === 'collection-history' && (
                          <select
                            value={activityFilter}
                            onChange={(e) => setActivityFilter(e.target.value)}
                            className="px-3 py-1 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                          >
                            <option value="all">All Interactions</option>
                            <option value="accepted">Accepted</option>
                            <option value="collected">Collected</option>
                            <option value="cancelled">Cancelled</option>
                            <option value="expired">Expired</option>
                          </select>
                        )}
                      </div>
                    </div>

                    {/* Activity Summary */}
                    {userActivities.length > 0 && (
                      <div className="bg-gray-50 rounded-lg p-4 mb-4">
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                          <div className="text-center">
                            <div className="text-lg font-semibold text-primary">
                              {userActivities.filter(a => a.type === 'drop_created').length}
                            </div>
                            <div className="text-xs text-text-secondary">Total Drops</div>
                          </div>
                          <div className="text-center">
                            <div className="text-lg font-semibold text-green-600">
                              {userActivities.filter(a => a.type === 'collector_collected').length}
                            </div>
                            <div className="text-xs text-text-secondary">Collected</div>
                          </div>
                          <div className="text-center">
                            <div className="text-lg font-semibold text-blue-600">
                              {userActivities.filter(a => a.type === 'collector_accepted').length}
                            </div>
                            <div className="text-xs text-text-secondary">Accepted</div>
                          </div>
                          <div className="text-center">
                            <div className="text-lg font-semibold text-red-600">
                              {userActivities.filter(a => a.type === 'collector_cancelled').length}
                            </div>
                            <div className="text-xs text-text-secondary">Cancelled</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Activity Tabs */}
                    <div className="border-b border-gray-200 mb-4">
                      <nav className="-mb-px flex space-x-8">
                        {(() => {
                          const counts = getActivityCounts();
                          return (
                            <>
                              <button
                                onClick={() => setActiveActivityTab('drops-created')}
                                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                                  activeActivityTab === 'drops-created'
                                    ? 'border-primary text-primary'
                                    : 'border-transparent text-text-secondary hover:text-text-primary hover:border-gray-300'
                                }`}
                              >
                                Drops Created ({counts.dropsCreated})
                              </button>
                              {selectedUser?.roles?.includes('collector') && (
                                <button
                                  onClick={() => setActiveActivityTab('collection-history')}
                                  className={`py-2 px-1 border-b-2 font-medium text-sm ${
                                    activeActivityTab === 'collection-history'
                                      ? 'border-primary text-primary'
                                      : 'border-transparent text-text-secondary hover:text-text-primary hover:border-gray-300'
                                  }`}
                                >
                                  Collection History ({counts.collectionHistory})
                                </button>
                              )}
                            </>
                          );
                        })()}
                      </nav>
                    </div>

                    {/* Activity Content */}
                    {loadingActivities ? (
                      <div className="flex items-center justify-center py-8">
                        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
                      </div>
                    ) : (() => {
                      const filteredActivities = getFilteredActivities();
                      return filteredActivities.length > 0 ? (
                        <div className="space-y-3">
                          {filteredActivities.map((activity) => (
                            <div key={activity.id} className="flex items-start space-x-3 p-3 bg-surface rounded-lg">
                              <div className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center">
                                {activity.type === 'drop_created' && (
                                  <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                                    </svg>
                                  </div>
                                )}
                                {activity.type === 'collector_accepted' && (
                                  <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                  </div>
                                )}
                                {activity.type === 'collector_collected' && (
                                  <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                    </svg>
                                  </div>
                                )}
                                {activity.type === 'collector_cancelled' && (
                                  <div className="w-8 h-8 bg-red-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                    </svg>
                                  </div>
                                )}
                                {activity.type === 'collector_expired' && (
                                  <div className="w-8 h-8 bg-orange-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                  </div>
                                )}
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center justify-between">
                                  <p className="text-sm font-medium text-text-primary">{activity.title}</p>
                                  <span className="text-xs text-text-secondary">{formatDate(activity.timestamp)}</span>
                                </div>
                                <p className="text-xs text-text-secondary mt-1">{activity.description}</p>
                                
                                {/* Additional details for drops */}
                                {activity.type === 'drop_created' && (
                                  <div className="mt-2 text-xs text-text-secondary">
                                    <div className="flex items-center space-x-4">
                                      <span>Bottles: {activity.numberOfBottles}</span>
                                      <span>Cans: {activity.numberOfCans}</span>
                                      <span>Type: {activity.bottleType}</span>
                                      <span className={`px-2 py-1 rounded-full text-xs ${
                                        activity.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                        activity.status === 'accepted' ? 'bg-blue-100 text-blue-800' :
                                        activity.status === 'collected' ? 'bg-green-100 text-green-800' :
                                        activity.status === 'cancelled' ? 'bg-red-100 text-red-800' :
                                        'bg-gray-100 text-gray-800'
                                      }`}>
                                        {activity.status}
                                      </span>
                                    </div>
                                    {activity.notes && (
                                      <p className="mt-1">Note: {activity.notes}</p>
                                    )}
                                  </div>
                                )}
                                
                                {/* Additional details for collector interactions */}
                                {activity.type.startsWith('collector_') && activity.cancellationReason && (
                                  <div className="mt-2 text-xs text-red-600">
                                    <p>Reason: {activity.cancellationReason}</p>
                                  </div>
                                )}
                                
                                {activity.notes && activity.type.startsWith('collector_') && (
                                  <div className="mt-2 text-xs text-text-secondary">
                                    <p>Note: {activity.notes}</p>
                                  </div>
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="text-center py-8">
                          <p className="text-text-secondary">
                            {activeActivityTab === 'drops-created' 
                              ? 'No drops created found for this user.' 
                              : 'No collection history found for this user.'}
                          </p>
                        </div>
                      );
                    })()}
                  </div>
              
              <div className="mt-6 flex justify-end space-x-3">
                <button
                  onClick={() => setShowUserModal(false)}
                  className="px-4 py-2 bg-surface text-text-primary border border-gray-300 rounded-md hover:bg-gray-100 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Ban User Modal */}
      {showBanModal && selectedUser && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 md:w-1/2 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-text-primary mb-4">Temporarily Lock User</h3>
              <p className="text-text-secondary mb-4">
                Are you sure you want to temporarily lock <strong>{selectedUser.name || selectedUser.email}</strong>? This will lock their account for 30 days.
              </p>
              
              <div className="mb-4">
                <label htmlFor="banReason" className="block text-sm font-medium text-text-primary mb-2">
                  Reason for Lock
                </label>
                <textarea
                  id="banReason"
                  value={banReason}
                  onChange={(e) => setBanReason(e.target.value)}
                  placeholder="Enter the reason for locking this user..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-primary focus:border-primary"
                  rows={3}
                />
              </div>
              
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowBanModal(false);
                    setBanReason('');
                    setSelectedUser(null);
                  }}
                  className="px-4 py-2 bg-surface text-text-primary border border-gray-300 rounded-md hover:bg-gray-100 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmBanUser}
                  disabled={!banReason.trim()}
                  className="px-4 py-2 bg-warning-color text-white rounded-md hover:bg-orange-600 transition-colors disabled:opacity-50"
                >
                  Lock User
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function DropsContent() {
  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-lg border border-gray-200">
        <div className="px-4 py-5 sm:p-6">
          <div className="bg-surface p-4 rounded-md">
            <p className="text-text-secondary">Drops management functionality will be implemented here.</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function ApplicationsContent() {
  const [applications, setApplications] = useState<CollectorApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
  });
  const [selectedApplication, setSelectedApplication] = useState<CollectorApplication | null>(null);
  const [showApplicationModal, setShowApplicationModal] = useState(false);
  const [selectedRejectionReason, setSelectedRejectionReason] = useState('');

  // Predefined rejection reasons
  const REJECTION_REASONS = [
    {
      id: 'incomplete_documents',
      label: 'Incomplete Documents',
      description: 'Missing or unclear identification documents'
    },
    {
      id: 'invalid_id',
      label: 'Invalid ID Card',
      description: 'ID card is expired, damaged, or not legible'
    },
    {
      id: 'poor_quality_photos',
      label: 'Poor Quality Photos',
      description: 'Photos are blurry, unclear, or don\'t meet requirements'
    },
    {
      id: 'mismatched_information',
      label: 'Information Mismatch',
      description: 'Information provided doesn\'t match ID documents'
    },
    {
      id: 'suspicious_activity',
      label: 'Suspicious Activity',
      description: 'Application flagged for suspicious activity or fraud'
    },
    {
      id: 'other',
      label: 'Other',
      description: 'Other reason not listed above'
    }
  ];

  useEffect(() => {
    loadApplications();
    loadStats();
  }, [currentPage, selectedStatus]);

  const loadApplications = async () => {
    try {
      setLoading(true);
      console.log('🔍 Loading applications with:', { currentPage, selectedStatus });
      const response = await applicationsAPI.getAllApplications(currentPage, 20, selectedStatus);
      console.log('🔍 API Response:', response);
      console.log('🔍 Applications:', response.data.applications);
      setApplications(response.data.applications || []);
      setTotalPages(response.data.pagination?.totalPages || 1);
    } catch (error) {
      console.error('Error loading applications:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      console.log('🔍 Loading application stats...');
      const response = await applicationsAPI.getApplicationStats();
      console.log('🔍 Stats Response:', response);
      console.log('🔍 Stats:', response.data.stats);
      setStats(response.data.stats || { total: 0, pending: 0, approved: 0, rejected: 0 });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const handleViewApplication = (application: CollectorApplication) => {
    setSelectedApplication(application);
    setShowApplicationModal(true);
    setSelectedRejectionReason('');
  };

  const handleApprove = async () => {
    if (!selectedApplication) return;
    
    try {
      await applicationsAPI.approveApplication(selectedApplication.id);
      setShowApplicationModal(false);
      setSelectedApplication(null);
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error approving application:', error);
    }
  };

  const handleReject = async () => {
    if (!selectedApplication || !selectedRejectionReason) return;
    
    try {
      const reason = REJECTION_REASONS.find(r => r.id === selectedRejectionReason);
      await applicationsAPI.rejectApplication(selectedApplication.id, reason?.label || selectedRejectionReason);
      setShowApplicationModal(false);
      setSelectedApplication(null);
      setSelectedRejectionReason('');
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error rejecting application:', error);
    }
  };

  const handleReverseApproval = async () => {
    if (!selectedApplication) return;
    
    try {
      await applicationsAPI.reverseApproval(selectedApplication.id);
      setShowApplicationModal(false);
      setSelectedApplication(null);
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error reversing application approval:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusClasses = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      approved: 'bg-green-100 text-green-800 border-green-200',
      rejected: 'bg-red-100 text-red-800 border-red-200',
    };
    
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full border ${statusClasses[status as keyof typeof statusClasses] || statusClasses.pending}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Collector Applications</h1>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-sm font-medium text-gray-500">Total Applications</div>
          <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-sm font-medium text-gray-500">Pending</div>
          <div className="text-2xl font-bold text-yellow-600">{stats.pending}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-sm font-medium text-gray-500">Approved</div>
          <div className="text-2xl font-bold text-green-600">{stats.approved}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-sm font-medium text-gray-500">Rejected</div>
          <div className="text-2xl font-bold text-red-600">{stats.rejected}</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow border">
        <div className="flex gap-4 items-center">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Status Filter</label>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>
        </div>
      </div>

      {/* Applications Table */}
      <div className="bg-white rounded-lg shadow border overflow-hidden">
        {loading ? (
          <div className="p-8 text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-gray-500">Loading applications...</p>
          </div>
        ) : applications.length === 0 ? (
          <div className="p-8 text-center">
            <p className="text-gray-500">No applications found</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Applicant
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Applied
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Reviewed
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {applications.map((application, index) => (
                  <tr key={`${application.id}-${index}`} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {typeof application.userId === 'object' && application.userId?.name 
                            ? application.userId.name 
                            : String(application.userId)}
                        </div>
                        <div className="text-sm text-gray-500">
                          {typeof application.userId === 'object' && application.userId?.email 
                            ? application.userId.email 
                            : `ID: ${application.id}`}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(application.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatDate(application.appliedAt)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {application.reviewedAt ? formatDate(application.reviewedAt) : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => handleViewApplication(application)}
                        className="text-blue-600 hover:text-blue-900 bg-blue-50 hover:bg-blue-100 px-3 py-1 rounded-md text-xs font-medium"
                      >
                        View Details
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center">
          <nav className="flex items-center space-x-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            <span className="px-3 py-2 text-sm text-gray-700">
              Page {currentPage} of {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </nav>
        </div>
      )}

      {/* Application Details Modal */}
      {showApplicationModal && selectedApplication && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-10 mx-auto p-5 border w-11/12 max-w-6xl shadow-lg rounded-md bg-white">
            <div className="mt-3">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-2xl font-bold text-gray-900">Application Review</h3>
                  <p className="text-gray-600">Review collector application details</p>
                </div>
                <button
                  onClick={() => setShowApplicationModal(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Left Column - User Information */}
                <div className="space-y-6">
                  {/* User Details */}
                  <div className="bg-gray-50 rounded-lg p-6">
                    <h4 className="text-lg font-semibold text-gray-900 mb-4">Applicant Information</h4>
                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="font-medium text-gray-700">Name:</span>
                        <span className="text-gray-900">
                          {typeof selectedApplication.userId === 'object' && selectedApplication.userId?.name 
                            ? selectedApplication.userId.name 
                            : 'Not provided'}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-medium text-gray-700">Email:</span>
                        <span className="text-gray-900">
                          {typeof selectedApplication.userId === 'object' && selectedApplication.userId?.email 
                            ? selectedApplication.userId.email 
                            : String(selectedApplication.userId)}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-medium text-gray-700">Application ID:</span>
                        <span className="text-gray-900">{selectedApplication.id}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-medium text-gray-700">Status:</span>
                        <span>{getStatusBadge(selectedApplication.status)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-medium text-gray-700">Applied:</span>
                        <span className="text-gray-900">{formatDate(selectedApplication.appliedAt)}</span>
                      </div>
                      {selectedApplication.reviewedAt && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Reviewed:</span>
                          <span className="text-gray-900">{formatDate(selectedApplication.reviewedAt)}</span>
                        </div>
                      )}
                      {selectedApplication.rejectionReason && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Rejection Reason:</span>
                          <span className="text-red-600">{selectedApplication.rejectionReason}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* ID Card Information */}
                  <div className="bg-blue-50 rounded-lg p-6">
                    <h4 className="text-lg font-semibold text-gray-900 mb-4">ID Card Information</h4>
                    <div className="space-y-3">
                      {selectedApplication.idCardType && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">ID Type:</span>
                          <span className="text-gray-900">{selectedApplication.idCardType}</span>
                        </div>
                      )}
                      {selectedApplication.idCardNumber && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">ID Number:</span>
                          <span className="text-gray-900">{selectedApplication.idCardNumber}</span>
                        </div>
                      )}
                      {selectedApplication.idCardIssuingAuthority && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Issuing Authority:</span>
                          <span className="text-gray-900">{selectedApplication.idCardIssuingAuthority}</span>
                        </div>
                      )}
                      {selectedApplication.idCardExpiryDate && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Expiry Date:</span>
                          <span className="text-gray-900">{formatDate(selectedApplication.idCardExpiryDate)}</span>
                        </div>
                      )}
                      {selectedApplication.passportIssueDate && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Passport Issue Date:</span>
                          <span className="text-gray-900">{formatDate(selectedApplication.passportIssueDate)}</span>
                        </div>
                      )}
                      {selectedApplication.passportExpiryDate && (
                        <div className="flex justify-between">
                          <span className="font-medium text-gray-700">Passport Expiry Date:</span>
                          <span className="text-gray-900">{formatDate(selectedApplication.passportExpiryDate)}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Review Actions */}
                  {selectedApplication.status === 'pending' && (
                    <div className="bg-blue-50 rounded-lg p-6">
                      <h4 className="text-lg font-semibold text-gray-900 mb-4">Review Actions</h4>
                      
                      {/* Rejection Reason Selection */}
                      <div className="mb-6">
                        <label className="block text-sm font-medium text-gray-700 mb-3">
                          Rejection Reason (Required for rejection)
                        </label>
                        <div className="space-y-3">
                          {REJECTION_REASONS.map((reason) => (
                            <label key={reason.id} className="flex items-start space-x-3 cursor-pointer">
                              <input
                                type="radio"
                                name="rejectionReason"
                                value={reason.id}
                                checked={selectedRejectionReason === reason.id}
                                onChange={(e) => setSelectedRejectionReason(e.target.value)}
                                className="mt-1 h-4 w-4 text-primary border-gray-300 focus:ring-primary"
                              />
                              <div className="flex-1">
                                <div className="text-sm font-medium text-gray-900">{reason.label}</div>
                                <div className="text-xs text-gray-500">{reason.description}</div>
                              </div>
                            </label>
                          ))}
                        </div>
                      </div>

                      {/* Action Buttons */}
                      <div className="flex gap-3">
                        <button
                          onClick={handleApprove}
                          className="flex-1 bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 transition-colors font-medium"
                        >
                          Approve Application
                        </button>
                        <button
                          onClick={handleReject}
                          disabled={!selectedRejectionReason}
                          className="flex-1 bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          Reject Application
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Approved Application Actions */}
                  {selectedApplication.status === 'approved' && (
                    <div className="bg-green-50 rounded-lg p-6">
                      <h4 className="text-lg font-semibold text-gray-900 mb-4">Application Approved</h4>
                      <div className="mb-4">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                            </svg>
                          </div>
                          <div className="ml-3">
                            <p className="text-sm text-green-700">
                              This application has been approved. You can reverse the approval if needed.
                            </p>
                          </div>
                        </div>
                      </div>
                      
                      {/* Reverse Approval Button */}
                      <div className="flex gap-3">
                        <button
                          onClick={handleReverseApproval}
                          className="flex-1 bg-orange-600 text-white px-4 py-2 rounded-md hover:bg-orange-700 transition-colors font-medium"
                        >
                          Reverse Approval
                        </button>
                      </div>
                    </div>
                  )}
                </div>

                {/* Right Column - Image Comparison */}
                <div className="space-y-6">
                  <h4 className="text-lg font-semibold text-gray-900">Identity Verification</h4>
                  
                  {selectedApplication.idCardType === 'Passport' ? (
                    // Passport Photos
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h5 className="text-md font-medium text-gray-900 mb-3">Passport Main Page</h5>
                      <div className="aspect-video bg-white rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden">
                        {selectedApplication.passportMainPagePhoto ? (
                          <img
                            src={selectedApplication.passportMainPagePhoto}
                            alt="Passport Main Page"
                            className="max-w-full max-h-full object-contain"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.style.display = 'none';
                              target.nextElementSibling?.classList.remove('hidden');
                            }}
                          />
                        ) : null}
                        <div className={`text-center ${selectedApplication.passportMainPagePhoto ? 'hidden' : ''}`}>
                          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          <p className="mt-2 text-sm text-gray-500">No passport main page photo available</p>
                        </div>
                      </div>
                    </div>
                  ) : (
                    // National ID Photos
                    <>
                      {/* ID Card Front Photo */}
                      <div className="bg-gray-50 rounded-lg p-4">
                        <h5 className="text-md font-medium text-gray-900 mb-3">ID Card Front</h5>
                        <div className="aspect-video bg-white rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden">
                          {selectedApplication.idCardPhoto ? (
                            <img
                              src={selectedApplication.idCardPhoto}
                              alt="ID Card Front"
                              className="max-w-full max-h-full object-contain"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.style.display = 'none';
                                target.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : null}
                          <div className={`text-center ${selectedApplication.idCardPhoto ? 'hidden' : ''}`}>
                            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <p className="mt-2 text-sm text-gray-500">No ID card front photo available</p>
                          </div>
                        </div>
                      </div>

                      {/* ID Card Back Photo */}
                      <div className="bg-gray-50 rounded-lg p-4">
                        <h5 className="text-md font-medium text-gray-900 mb-3">ID Card Back</h5>
                        <div className="aspect-video bg-white rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden">
                          {selectedApplication.idCardBackPhoto ? (
                            <img
                              src={selectedApplication.idCardBackPhoto}
                              alt="ID Card Back"
                              className="max-w-full max-h-full object-contain"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.style.display = 'none';
                                target.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : null}
                          <div className={`text-center ${selectedApplication.idCardBackPhoto ? 'hidden' : ''}`}>
                            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <p className="mt-2 text-sm text-gray-500">No ID card back photo available</p>
                          </div>
                        </div>
                      </div>
                    </>
                  )}

                  {/* Selfie with ID Photo */}
                  <div className="bg-gray-50 rounded-lg p-4">
                    <h5 className="text-md font-medium text-gray-900 mb-3">Selfie with ID</h5>
                    <div className="aspect-video bg-white rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden">
                      {selectedApplication.selfieWithIdPhoto ? (
                        <img
                          src={selectedApplication.selfieWithIdPhoto}
                          alt="Selfie with ID"
                          className="max-w-full max-h-full object-contain"
                          onError={(e) => {
                            const target = e.target as HTMLImageElement;
                            target.style.display = 'none';
                            target.nextElementSibling?.classList.remove('hidden');
                          }}
                        />
                      ) : null}
                      <div className={`text-center ${selectedApplication.selfieWithIdPhoto ? 'hidden' : ''}`}>
                        <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <p className="mt-2 text-sm text-gray-500">No selfie photo available</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div className="mt-8 flex justify-end">
                <button
                  onClick={() => setShowApplicationModal(false)}
                  className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function TrainingContent() {
  const [trainingContent, setTrainingContent] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [selectedType, setSelectedType] = useState<string>('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingContent, setEditingContent] = useState<any>(null);
  const [stats, setStats] = useState<any>(null);

  const contentTypes = [
    { value: 'video', label: 'Video', icon: '🎥' },
    { value: 'image', label: 'Image', icon: '🖼️' },
    { value: 'story', label: 'Story', icon: '📖' },
  ];

  const categories = [
    { value: 'getting_started', label: 'Getting Started', icon: '🚀' },
    { value: 'advanced_features', label: 'Advanced Features', icon: '⚡' },
    { value: 'troubleshooting', label: 'Troubleshooting', icon: '🔧' },
    { value: 'best_practices', label: 'Best Practices', icon: '💡' },
    { value: 'collector_application', label: 'Collector Application', icon: '📋' },
    { value: 'payments', label: 'Payments', icon: '💳' },
    { value: 'notifications', label: 'Notifications', icon: '🔔' },
  ];

  const loadTrainingContent = async () => {
    try {
      setLoading(true);
      const response = await trainingAPI.getAllContent();
      setTrainingContent(response.data.content || []);
    } catch (err: any) {
      console.error('Error loading training content:', err);
      setError('Failed to load training content');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await trainingAPI.getStats();
      setStats(response.data);
    } catch (err: any) {
      console.error('Error loading training stats:', err);
    }
  };

  useEffect(() => {
    loadTrainingContent();
    loadStats();
  }, []);

  const handleCreate = () => {
    setEditingContent(null);
    setShowCreateModal(true);
  };

  const handleEdit = (content: any) => {
    setEditingContent(content);
    setShowCreateModal(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this training content?')) {
      try {
        await trainingAPI.deleteContent(id);
        await loadTrainingContent();
      } catch (err: any) {
        console.error('Error deleting training content:', err);
        setError('Failed to delete training content');
      }
    }
  };

  const handleSave = () => {
    setShowCreateModal(false);
    setEditingContent(null);
    loadTrainingContent();
  };

  const handleCloseModal = () => {
    setShowCreateModal(false);
    setEditingContent(null);
  };

  const filteredContent = trainingContent.filter(content => {
    const matchesCategory = !selectedCategory || content.category === selectedCategory;
    const matchesType = !selectedType || content.type === selectedType;
    return matchesCategory && matchesType;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-900">Training Content</h2>
        <button
          onClick={handleCreate}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          + Create Content
        </button>
      </div>

      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total Content</h3>
            <p className="text-2xl font-bold text-gray-900">{stats.totalContent || 0}</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Videos</h3>
            <p className="text-2xl font-bold text-gray-900">{stats.videoCount || 0}</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Images</h3>
            <p className="text-2xl font-bold text-gray-900">{stats.imageCount || 0}</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Stories</h3>
            <p className="text-2xl font-bold text-gray-900">{stats.storyCount || 0}</p>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex space-x-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Filter by Category
          </label>
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Categories</option>
            {categories.map(category => (
              <option key={category.value} value={category.value}>
                {category.icon} {category.label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Filter by Type
          </label>
          <select
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Types</option>
            {contentTypes.map(type => (
              <option key={type.value} value={type.value}>
                {type.icon} {type.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <p className="text-red-600">{error}</p>
        </div>
      )}

      {/* Content List */}
      {filteredContent.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <p>No training content found.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredContent.map((content) => (
            <div key={content._id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-lg">
                      {contentTypes.find(t => t.value === content.type)?.icon || '📄'}
                    </span>
                    <h3 className="text-lg font-semibold text-gray-900">{content.title}</h3>
                    {content.isFeatured && (
                      <span className="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                        ⭐ Featured
                      </span>
                    )}
                    {!content.isActive && (
                      <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded-full">
                        Inactive
                      </span>
                    )}
                  </div>
                  
                  <p className="text-gray-600 mb-3">{content.description}</p>
                  
                  <div className="flex items-center gap-4 text-sm text-gray-500">
                    <span>
                      {categories.find(c => c.value === content.category)?.icon} 
                      {categories.find(c => c.value === content.category)?.label}
                    </span>
                    {content.duration && (
                      <span>⏱️ {Math.floor(content.duration / 60)}:{(content.duration % 60).toString().padStart(2, '0')}</span>
                    )}
                    <span>📅 {new Date(content.createdAt).toLocaleDateString()}</span>
                  </div>

                  {/* Media Display */}
                  {content.type === 'video' && content.mediaUrl && (
                    <div className="mt-4">
                      <div className="relative w-full max-w-md">
                        {content.thumbnailUrl ? (
                          <img
                            src={content.thumbnailUrl}
                            alt={content.title}
                            className="w-full h-48 object-cover rounded-lg"
                          />
                        ) : (
                          <div className="bg-gray-200 h-48 rounded-lg flex items-center justify-center">
                            <div className="text-center">
                              <svg className="w-12 h-12 text-gray-400 mx-auto mb-2" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M8 5v14l11-7z"/>
                              </svg>
                              <p className="text-gray-500">Video Content</p>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {content.type === 'image' && content.mediaUrl && (
                    <div className="mt-4">
                      <img
                        src={content.mediaUrl}
                        alt={content.title}
                        className="w-full max-w-md h-48 object-cover rounded-lg"
                      />
                    </div>
                  )}
                </div>

                <div className="flex space-x-2 ml-4">
                  <button
                    onClick={() => handleEdit(content)}
                    className="px-3 py-1 text-sm bg-blue-100 text-blue-700 rounded hover:bg-blue-200"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(content._id)}
                    className="px-3 py-1 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      {showCreateModal && (
        <TrainingContentModal
          content={editingContent}
          onClose={handleCloseModal}
          onSave={handleSave}
        />
      )}
    </div>
  );
}

// Training Content Modal Component
function TrainingContentModal({ content, onClose, onSave }: {
  content?: any;
  onClose: () => void;
  onSave: () => void;
}) {
  const [formData, setFormData] = useState(() => {
    const safeString = (value: any) => (value && typeof value === 'string') ? value : '';
    const safeNumber = (value: any) => (value && typeof value === 'number') ? value : 0;
    const safeBoolean = (value: any) => (value && typeof value === 'boolean') ? value : false;
    
    return {
      title: safeString(content?.title),
      description: safeString(content?.description),
      type: safeString(content?.type) || 'video',
      category: safeString(content?.category) || 'getting_started',
      mediaUrl: safeString(content?.mediaUrl),
      thumbnailUrl: safeString(content?.thumbnailUrl),
      content: safeString(content?.content),
      duration: safeNumber(content?.duration),
      order: safeNumber(content?.order),
      isActive: safeBoolean(content?.isActive ?? true),
      isFeatured: safeBoolean(content?.isFeatured),
      tags: Array.isArray(content?.tags) ? content.tags : [],
    };
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const contentTypes = [
    { value: 'video', label: 'Video', icon: '🎥' },
    { value: 'image', label: 'Image', icon: '🖼️' },
    { value: 'story', label: 'Story', icon: '📖' },
  ];

  const categories = [
    { value: 'getting_started', label: 'Getting Started', icon: '🚀' },
    { value: 'advanced_features', label: 'Advanced Features', icon: '⚡' },
    { value: 'troubleshooting', label: 'Troubleshooting', icon: '🔧' },
    { value: 'best_practices', label: 'Best Practices', icon: '💡' },
    { value: 'collector_application', label: 'Collector Application', icon: '📋' },
    { value: 'payments', label: 'Payments', icon: '💳' },
    { value: 'notifications', label: 'Notifications', icon: '🔔' },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (content) {
        await trainingAPI.updateContent(content._id, formData);
      } else {
        await trainingAPI.createContent(formData);
      }
      onSave();
    } catch (err: any) {
      console.error('Error saving training content:', err);
      setError(err.response?.data?.message || 'Failed to save training content');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
        <div className="mt-3">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium text-gray-900">
              {content ? 'Edit Training Content' : 'Create Training Content'}
            </h3>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
              <p className="text-red-600">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Title *
              </label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={3}
                required
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Type *
                </label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  {contentTypes.map(type => (
                    <option key={type.value} value={type.value}>
                      {type.icon} {type.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category *
                </label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  {categories.map(category => (
                    <option key={category.value} value={category.value}>
                      {category.icon} {category.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Media URL
              </label>
              <input
                type="url"
                value={formData.mediaUrl}
                onChange={(e) => setFormData({ ...formData, mediaUrl: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="https://example.com/video.mp4"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Thumbnail URL
              </label>
              <input
                type="url"
                value={formData.thumbnailUrl}
                onChange={(e) => setFormData({ ...formData, thumbnailUrl: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="https://example.com/thumbnail.jpg"
              />
            </div>

            {formData.type === 'story' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Content
                </label>
                <textarea
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={5}
                  placeholder="Enter story content here..."
                />
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Duration (seconds)
                </label>
                <input
                  type="number"
                  value={formData.duration}
                  onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) || 0 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  min="0"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Display Order
                </label>
                <input
                  type="number"
                  value={formData.order}
                  onChange={(e) => setFormData({ ...formData, order: parseInt(e.target.value) || 0 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  min="0"
                />
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={formData.isActive}
                  onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <span className="ml-2 text-sm text-gray-700">Active</span>
              </label>

              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={formData.isFeatured}
                  onChange={(e) => setFormData({ ...formData, isFeatured: e.target.checked })}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <span className="ml-2 text-sm text-gray-700">Featured</span>
              </label>
            </div>

            <div className="flex justify-end space-x-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {loading ? 'Saving...' : (content ? 'Update' : 'Create')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

function SupportContent() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [showTicketModal, setShowTicketModal] = useState(false);
  const [newMessage, setNewMessage] = useState('');
  const [sendingMessage, setSendingMessage] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [stats, setStats] = useState<any>(null);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [showNotifications, setShowNotifications] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [userTyping, setUserTyping] = useState(false);
  const [userPresent, setUserPresent] = useState(false);
  const [typingTimeout, setTypingTimeout] = useState<NodeJS.Timeout | null>(null);
  const [socket, setSocket] = useState<any>(null);
  const conversationRef = useRef<HTMLDivElement>(null);

  // Function to scroll conversation to bottom
  const scrollToBottom = () => {
    if (conversationRef.current) {
      conversationRef.current.scrollTop = conversationRef.current.scrollHeight;
    }
  };

  const fetchTickets = async () => {
    try {
      console.log('🔍 Starting to fetch support tickets...');
      setLoading(true);
      setError(null);
      
      console.log('🔍 Calling supportTicketsAPI.getAllTickets with params:', {
        page: 1,
        limit: 50,
        status: selectedStatus,
        category: selectedCategory
      });
      
      const response = await supportTicketsAPI.getAllTickets(1, 50, selectedStatus, selectedCategory);
      
      console.log('✅ Support tickets API response:', response);
      console.log('✅ Response data:', response.data);
      console.log('✅ Tickets array:', response.data.tickets);
      console.log('✅ Tickets count:', response.data.tickets?.length || 0);
      
      setTickets(response.data.tickets || []);
      
      console.log('✅ Tickets state updated with:', response.data.tickets?.length || 0, 'tickets');
    } catch (err: any) {
      console.error('❌ Error fetching support tickets:', err);
      console.error('❌ Error response:', err.response);
      console.error('❌ Error data:', err.response?.data);
      setError(err.response?.data?.message || 'Failed to fetch support tickets');
    } finally {
      setLoading(false);
      console.log('🔍 fetchTickets completed, loading set to false');
    }
  };

  const fetchStats = async () => {
    try {
      const response = await supportTicketsAPI.getTicketStats();
      setStats(response.data);
    } catch (err: any) {
      console.error('Error loading support ticket stats:', err);
    }
  };

  useEffect(() => {
    console.log('🔍 useEffect triggered - fetching tickets');
    fetchTickets();
    fetchStats();
  }, [selectedStatus, selectedCategory]);

  // Real-time Socket.IO connection for support tickets with retry logic
  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (!token) {
      console.log('❌ No admin token found for WebSocket connection');
      return;
    }

    let retryCount = 0;
    const maxRetries = 5;
    let retryTimeout: NodeJS.Timeout;

    const connectWebSocket = () => {
      console.log(`🔌 Admin Dashboard: Attempting WebSocket connection (attempt ${retryCount + 1}/${maxRetries})`);
      console.log('🔌 Connecting to: http://localhost:3000/chat');
      console.log('🔌 Token length:', token.length);

      // Import Socket.IO client dynamically
      import('socket.io-client').then(({ io }) => {
        console.log('🔌 Socket.IO client loaded, creating connection...');
        const newSocket = io('http://localhost:3000/chat', {
          auth: { token },
          transports: ['websocket'],
          timeout: 10000,
          forceNew: true,
          reconnection: true,
          reconnectionAttempts: 3,
          reconnectionDelay: 1000,
          reconnectionDelayMax: 5000
        });
        
        console.log('🔌 Socket created, setting up event listeners...');

        newSocket.on('connect', () => {
          console.log('🔌 ✅ Admin Dashboard: Connected to chat Socket.IO');
          console.log('🔌 Socket ID:', newSocket.id);
          console.log('🔌 Socket connected:', newSocket.connected);
          console.log('🔌 Socket auth:', newSocket.auth);
          retryCount = 0; // Reset retry count on successful connection
          setSocket(newSocket);
        });

        newSocket.on('connect_error', (error) => {
          console.error('❌ Admin Dashboard: WebSocket connection error:', error);
          console.error('❌ Error details:', error.message);
          setSocket(null);
          
          // Retry connection with exponential backoff
          if (retryCount < maxRetries) {
            retryCount++;
            const delay = Math.min(1000 * Math.pow(2, retryCount), 10000); // Max 10 seconds
            console.log(`🔄 Admin Dashboard: Retrying connection in ${delay}ms (attempt ${retryCount}/${maxRetries})`);
            retryTimeout = setTimeout(connectWebSocket, delay);
          } else {
            console.error('❌ Admin Dashboard: Max retry attempts reached, giving up');
          }
        });

        newSocket.on('disconnect', (reason) => {
          console.log('🔌 Admin Dashboard: WebSocket disconnected:', reason);
          setSocket(null);
          
          // Auto-reconnect on disconnect (unless it's a manual disconnect)
          if (reason !== 'io client disconnect') {
            console.log('🔄 Admin Dashboard: Auto-reconnecting after disconnect...');
            setTimeout(connectWebSocket, 2000);
          }
        });

        newSocket.on('reconnect', (attemptNumber) => {
          console.log(`🔌 ✅ Admin Dashboard: Reconnected after ${attemptNumber} attempts`);
          setSocket(newSocket);
        });

        newSocket.on('reconnect_error', (error) => {
          console.error('❌ Admin Dashboard: Reconnection error:', error);
        });

        newSocket.on('reconnect_failed', () => {
          console.error('❌ Admin Dashboard: Reconnection failed, will retry manually');
          setSocket(null);
        });

        return () => {
          if (retryTimeout) {
            clearTimeout(retryTimeout);
          }
          newSocket.disconnect();
        };
      }).catch((error) => {
        console.error('❌ Admin Dashboard: Failed to load Socket.IO client:', error);
        setSocket(null);
        
        // Retry loading Socket.IO client
        if (retryCount < maxRetries) {
          retryCount++;
          const delay = Math.min(1000 * Math.pow(2, retryCount), 10000);
          console.log(`🔄 Admin Dashboard: Retrying Socket.IO client load in ${delay}ms`);
          retryTimeout = setTimeout(connectWebSocket, delay);
        }
      });
    };

    // Start initial connection
    connectWebSocket();

    return () => {
      if (retryTimeout) {
        clearTimeout(retryTimeout);
      }
    };
  }, []); // Empty dependency array to run only once

  // Handle ticket-specific events when selectedTicket changes
  useEffect(() => {
    if (!socket || !selectedTicket) return;

    // Handle new messages from chat
    const handleNewMessage = (data: any) => {
      console.log('📨 ===== ADMIN DASHBOARD: NEW MESSAGE RECEIVED =====');
      console.log('📨 Message data:', data);
      const currentTicketId = selectedTicket?._id || selectedTicket?.id;
      console.log('📨 Current selected ticket ID:', currentTicketId);
      console.log('📨 Message ticket ID:', data.ticketId);
      
      if (selectedTicket && currentTicketId === data.ticketId) {
        console.log('📨 ✅ Message matches current ticket, updating conversation');
        
        const newMessage = {
          message: data.message,
          senderId: data.senderId,
          senderType: data.senderType,
          sentAt: data.sentAt,
          isInternal: data.isInternal,
        };
        
        setSelectedTicket((prev: any) => {
          console.log('📨 Current messages count:', prev.messages?.length || 0);
          console.log('📨 Current messages:', prev.messages);
          
          // Check if message already exists to prevent duplicates
          const messageExists = prev.messages?.some((msg: any) => 
            msg.message === newMessage.message && 
            msg.sentAt === newMessage.sentAt
          );
          
          if (messageExists) {
            console.log('📨 ⚠️ Message already exists, skipping duplicate');
            return prev;
          }
          
          console.log('📨 ✅ Adding new message to conversation');
          const updatedTicket = {
            ...prev,
            messages: [...(prev.messages || []), newMessage]
          };
          console.log('📨 New messages count:', updatedTicket.messages.length);
          console.log('📨 New messages:', updatedTicket.messages);
          return updatedTicket;
        });
        
        // Auto-scroll to bottom when receiving new message
        setTimeout(() => {
          scrollToBottom();
          console.log('📨 Auto-scrolled to bottom');
        }, 100);
      } else {
        console.log('📨 ❌ Message does not match current ticket');
      }
    };

    // Handle typing indicators
    const handleTypingIndicator = (data: any) => {
      console.log('📝 Received typing indicator:', data);
      if (selectedTicket && selectedTicket.id === data.ticketId) {
        if (data.senderType === 'user') {
          setUserTyping(data.isTyping);
        }
      }
    };

    // Handle presence indicators
    const handlePresenceIndicator = (data: any) => {
      console.log('👤 Received presence indicator:', data);
      if (selectedTicket && selectedTicket.id === data.ticketId) {
        if (data.senderType === 'user') {
          setUserPresent(data.isPresent);
        }
      }
    };

    // Add the event listeners
    socket.on('new_message', handleNewMessage);
    socket.on('typing_indicator', handleTypingIndicator);
    socket.on('user_joined', handlePresenceIndicator);
    socket.on('user_left', handlePresenceIndicator);
    
    // Add catch-all listener for debugging
    socket.onAny((event: string, data: any) => {
      console.log('🔍 Admin Dashboard: Received ANY event:', event);
      console.log('🔍 Admin Dashboard: Event data:', data);
    });

    // Cleanup function
    return () => {
      console.log('🧹 Admin Dashboard: Cleaning up WebSocket event listeners');
      socket.off('new_message', handleNewMessage);
      socket.off('typing_indicator', handleTypingIndicator);
      socket.off('user_joined', handlePresenceIndicator);
      socket.off('user_left', handlePresenceIndicator);
    };
  }, [socket, selectedTicket]);

  // Cleanup socket on unmount
  useEffect(() => {
    return () => {
      if (socket) {
        socket.disconnect();
      }
    };
  }, [socket]);

  // Auto-dismiss notifications after 5 seconds
  useEffect(() => {
    if (notifications.length > 0) {
      const timer = setTimeout(() => {
        setNotifications(prev => prev.slice(1));
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [notifications]);

  const handleViewTicket = (ticket: any) => {
    setSelectedTicket(ticket);
    setShowTicketModal(true);
    
    // Ensure WebSocket connection is established first
    const ensureConnectionAndJoin = async () => {
      // If no socket or not connected, try to establish connection
      if (!socket || !socket.connected) {
        console.log('🔌 Admin Dashboard: No active socket connection, establishing connection...');
        
        const token = localStorage.getItem('admin_token');
        if (!token) {
          console.error('❌ Admin Dashboard: No admin token found');
          return;
        }

        try {
          // Import Socket.IO client dynamically
          const { io } = await import('socket.io-client');
          const newSocket = io('http://localhost:3000/chat', {
            auth: { token },
            transports: ['websocket'],
            timeout: 10000,
            forceNew: true,
            reconnection: true,
            reconnectionAttempts: 3,
            reconnectionDelay: 1000,
            reconnectionDelayMax: 5000
          });

          // Wait for connection
          await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
              reject(new Error('Connection timeout'));
            }, 10000);

            newSocket.on('connect', () => {
              clearTimeout(timeout);
              console.log('🔌 ✅ Admin Dashboard: Connected to chat Socket.IO');
              setSocket(newSocket);
              resolve(true);
            });

            newSocket.on('connect_error', (error) => {
              clearTimeout(timeout);
              console.error('❌ Admin Dashboard: WebSocket connection error:', error);
              reject(error);
            });
          });
        } catch (error) {
          console.error('❌ Admin Dashboard: Failed to establish WebSocket connection:', error);
          return;
        }
      }

      // Now join the ticket room
      if (socket && socket.connected) {
        const ticketId = ticket._id || ticket.id;
        console.log('👤 Admin Dashboard: Joining ticket room:', ticketId);
        console.log('👤 Admin Dashboard: Socket state:', socket.connected);
        console.log('👤 Admin Dashboard: Socket ID:', socket.id);
        
        socket.emit('join_ticket', {
          ticketId: ticketId,
          senderType: 'agent'
        });
        
        // Send presence indicator
        socket.emit('presence_indicator', {
          ticketId: ticketId,
          isPresent: true,
          senderType: 'agent'
        });
        
        console.log('👤 Admin Dashboard: Successfully joined ticket room and sent presence indicator for ticket:', ticketId);
      }
    };

    // Execute connection and room joining
    ensureConnectionAndJoin();

    // Auto-scroll to bottom when opening ticket
    setTimeout(() => {
      scrollToBottom();
    }, 100);
  };

  const handleCloseModal = () => {
    // Leave ticket room and send presence indicator
    if (selectedTicket && socket && socket.connected) {
      const ticketId = selectedTicket._id || selectedTicket.id;
      console.log('👋 Admin Dashboard: Leaving ticket room:', ticketId);
      
      socket.emit('leave_ticket', {
        ticketId: ticketId,
        senderType: 'agent'
      });
      
      // Send presence indicator that admin left
      socket.emit('presence_indicator', {
        ticketId: ticketId,
        isPresent: false,
        senderType: 'agent'
      });
      
      console.log('👋 Admin Dashboard: Successfully left ticket room and sent presence indicator');
    }
    
    setShowTicketModal(false);
    setSelectedTicket(null);
    setNewMessage('');
    setUserTyping(false);
    setUserPresent(false);
    setIsTyping(false);
    if (typingTimeout) {
      clearTimeout(typingTimeout);
      setTypingTimeout(null);
    }
  };

  const handleUpdateStatus = async (ticketId: string, newStatus: string) => {
    try {
      setUpdatingStatus(true);
      await supportTicketsAPI.updateTicketStatus(ticketId, newStatus);
      
      // Update the ticket in the local state
      setTickets(prevTickets => 
        prevTickets.map(ticket => 
          (ticket._id || ticket.id) === ticketId ? { ...ticket, status: newStatus } : ticket
        )
      );
      
      // Update selected ticket if it's the same
      if (selectedTicket && (selectedTicket._id || selectedTicket.id) === ticketId) {
        setSelectedTicket((prev: any) => ({ ...prev, status: newStatus }));
      }
      
      // Refresh tickets to get updated data
      await fetchTickets();
      
    } catch (err: any) {
      console.error('Error updating ticket status:', err);
      setError('Failed to update ticket status');
    } finally {
      setUpdatingStatus(false);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || !selectedTicket) return;
    
    const ticketId = selectedTicket._id || selectedTicket.id;
    if (!ticketId) {
      console.error('❌ No ticket ID available');
      setError('Invalid ticket ID');
      return;
    }
    
    try {
      setSendingMessage(true);
      console.log('📤 Sending message to ticket:', ticketId);
      console.log('📤 Message content:', newMessage.trim());
      
      // Send message via API to save to database (this will also trigger real-time updates)
      const response = await supportTicketsAPI.addMessage(ticketId, newMessage.trim());
      
      console.log('✅ Message sent successfully:', response);
      
      // Clear the message input
      setNewMessage('');
      
      // Stop typing indicator
      setIsTyping(false);
      if (typingTimeout) {
        clearTimeout(typingTimeout);
        setTypingTimeout(null);
      }

      // The message will be added via WebSocket notification automatically
    } catch (err: any) {
      console.error('❌ Error sending message:', err);
      console.error('❌ Error response:', err.response);
      console.error('❌ Error data:', err.response?.data);
      setError('Failed to send message');
    } finally {
      setSendingMessage(false);
    }
  };

  const handleTyping = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNewMessage(e.target.value);
    
    // Send typing start indicator
    if (!isTyping && socket && selectedTicket) {
      setIsTyping(true);
      socket.emit('typing_start', {
        ticketId: selectedTicket.id,
        senderType: 'agent'
      });
    }
    
    // Clear existing timeout
    if (typingTimeout) {
      clearTimeout(typingTimeout);
    }
    
    // Set new timeout to stop typing indicator
    const timeout = setTimeout(() => {
      setIsTyping(false);
      // Send stop typing indicator
      if (socket && selectedTicket) {
        socket.emit('typing_stop', {
          ticketId: selectedTicket.id,
          senderType: 'agent'
        });
      }
    }, 1000);
    
    setTypingTimeout(timeout);
  };

  // Debug logging
  console.log('🔍 Support Content Render - Current State:', {
    loading,
    error,
    ticketsCount: tickets.length,
    tickets: tickets,
    selectedStatus,
    selectedCategory
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open':
        return 'bg-yellow-100 text-yellow-800';
      case 'in_progress':
        return 'bg-blue-100 text-blue-800';
      case 'resolved':
        return 'bg-green-100 text-green-800';
      case 'closed':
        return 'bg-gray-100 text-gray-800';
      case 'on_hold':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'authentication':
        return '🔐';
      case 'app_technical':
        return '📱';
      case 'drop_creation':
      case 'drop_issue':
        return '🏠';
      case 'collection_navigation':
      case 'collection_issue':
        return '🚚';
      case 'collector_application':
      case 'application_issue':
        return '👤';
      case 'payment_rewards':
        return '💰';
      case 'statistics_history':
        return '📊';
      case 'general_support':
        return '❓';
      default:
        return '📋';
    }
  };

  const getCategoryDisplayName = (category: string) => {
    switch (category) {
      case 'authentication':
        return '🔐 Authentication';
      case 'app_technical':
        return '📱 App Technical';
      case 'drop_creation':
        return '🏠 Drop Creation';
      case 'drop_issue':
        return '🏠 Drop Issue';
      case 'collection_navigation':
        return '🚚 Collection & Navigation';
      case 'collection_issue':
        return '🚚 Collection Issue';
      case 'collector_application':
        return '👤 Collector Application';
      case 'application_issue':
        return '👤 Application Issue';
      case 'payment_rewards':
        return '💰 Payment & Rewards';
      case 'statistics_history':
        return '📊 Statistics & History';
      case 'role_switching':
        return '🔄 Role Switching';
      case 'communication':
        return '💬 Communication';
      case 'general_support':
        return '❓ General Support';
      default:
        return category;
    }
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error</h3>
              <div className="mt-2 text-sm text-red-700">
                <p>{error}</p>
              </div>
              <div className="mt-4">
                <button
                  onClick={fetchTickets}
                  className="bg-red-100 px-3 py-2 rounded-md text-sm font-medium text-red-800 hover:bg-red-200"
                >
                  Try Again
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="space-y-6">
        {/* Debug Info */}
        <div className="bg-gray-100 p-4 rounded-md">
          <h3 className="font-semibold">Debug Info:</h3>
          <p>Loading: {loading ? 'Yes' : 'No'}</p>
          <p>Error: {error || 'None'}</p>
          <p>Tickets Count: {tickets.length}</p>
          <p>Selected Status: {selectedStatus || 'All'}</p>
          <p>Selected Category: {selectedCategory || 'All'}</p>
        </div>
        
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold text-gray-900">Support Tickets</h1>
            {notifications.length > 0 && (
              <div className="relative">
                <button
                  onClick={() => setShowNotifications(!showNotifications)}
                  className="relative p-2 text-gray-600 hover:text-gray-900"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-5 5v-5zM4.828 7l2.586 2.586a2 2 0 002.828 0L12 7H4.828z" />
                  </svg>
                  <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    {notifications.length}
                  </span>
                </button>
                {showNotifications && (
                  <div className="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border z-50">
                    <div className="p-3 border-b">
                      <h3 className="font-semibold">Notifications</h3>
                    </div>
                    <div className="max-h-64 overflow-y-auto">
                      {notifications.map(notification => (
                        <div key={notification.id} className="p-3 border-b hover:bg-gray-50">
                          <p className="text-sm">{notification.message}</p>
                          <p className="text-xs text-gray-500">{notification.timestamp.toLocaleTimeString()}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
          <div className="flex space-x-4">
            <button
              onClick={() => {
                fetchTickets();
                fetchStats();
              }}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 text-sm"
            >
              Refresh
            </button>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Statuses</option>
              <option value="open">Open</option>
              <option value="in_progress">In Progress</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
              <option value="on_hold">On Hold</option>
            </select>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Categories</option>
              <option value="authentication">Authentication</option>
              <option value="app_technical">App Technical</option>
              <option value="drop_creation">Drop Creation</option>
              <option value="collection_navigation">Collection & Navigation</option>
              <option value="collector_application">Collector Application</option>
              <option value="payment_rewards">Payment & Rewards</option>
              <option value="statistics_history">Statistics & History</option>
              <option value="role_switching">Role Switching</option>
              <option value="communication">Communication</option>
              <option value="general_support">General Support</option>
            </select>
          </div>
        </div>

        {/* Stats */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-white p-4 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500">Total Tickets</h3>
              <p className="text-2xl font-bold text-gray-900">{stats.totalTickets || 0}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500">Open</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.openTickets || 0}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500">In Progress</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.inProgressTickets || 0}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500">Resolved</h3>
              <p className="text-2xl font-bold text-green-600">{stats.resolvedTickets || 0}</p>
            </div>
          </div>
        )}

        {tickets.length === 0 ? (
          <div className="text-center py-12">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No support tickets</h3>
            <p className="mt-1 text-sm text-gray-500">No support tickets found matching your criteria.</p>
          </div>
        ) : (
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {tickets.map((ticket) => (
                <li key={ticket._id || ticket.id}>
                  <div className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3">
                          <h3 className="text-lg font-medium text-gray-900 truncate">
                            {ticket.title}
                          </h3>
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(ticket.status)}`}>
                            {ticket.status.replace('_', ' ')}
                          </span>
                        </div>
                        <div className="mt-1 flex items-center space-x-4 text-sm text-gray-500">
                          <span>{getCategoryDisplayName(ticket.category)}</span>
                          <span>•</span>
                          <span>Priority: {ticket.priority}</span>
                          <span>•</span>
                          <span>Created: {new Date(ticket.createdAt).toLocaleDateString()}</span>
                        </div>
                        <div className="mt-2">
                          <p className="text-sm text-gray-600 line-clamp-2">{ticket.description}</p>
                        </div>
                      </div>
                      <div className="flex-shrink-0">
                        <button 
                          onClick={() => handleViewTicket(ticket)}
                          className="text-blue-600 hover:text-blue-900 text-sm font-medium"
                        >
                          View Details
                        </button>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {/* Ticket Details Modal */}
      {showTicketModal && selectedTicket && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              {/* Modal Header */}
              <div className="flex items-center justify-between pb-4 border-b">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-gray-900">
                    Support Ticket Details
                  </h3>
                </div>
                <button
                  onClick={handleCloseModal}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Modal Content */}
              <div className="mt-4 space-y-6">
                {/* Ticket Header Card */}
                <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 shadow-lg text-white">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                        </svg>
                        <h2 className="text-2xl font-bold">{selectedTicket.title}</h2>
                      </div>
                      <p className="text-blue-100 text-sm">
                        Created {new Date(selectedTicket.createdAt).toLocaleString('en-US', { 
                          month: 'short', 
                          day: 'numeric', 
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </p>
                    </div>
                    
                    {/* Status Badge */}
                    <div className="flex-shrink-0">
                      <span className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-bold shadow-lg ${
                        selectedTicket.status === 'open' ? 'bg-yellow-400 text-yellow-900' :
                        selectedTicket.status === 'in_progress' ? 'bg-blue-400 text-blue-900' :
                        selectedTicket.status === 'resolved' ? 'bg-green-400 text-green-900' :
                        selectedTicket.status === 'closed' ? 'bg-gray-400 text-gray-900' :
                        'bg-white text-gray-900'
                      }`}>
                        {selectedTicket.status.replace('_', ' ').toUpperCase()}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Quick Info Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Priority Card */}
                  <div className="bg-white rounded-lg border-2 border-gray-200 p-4 shadow-sm hover:shadow-md transition-shadow">
                    <div className="flex items-center space-x-3">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                        selectedTicket.priority === 'high' ? 'bg-red-100' :
                        selectedTicket.priority === 'medium' ? 'bg-yellow-100' :
                        'bg-green-100'
                      }`}>
                        <svg className={`w-5 h-5 ${
                          selectedTicket.priority === 'high' ? 'text-red-600' :
                          selectedTicket.priority === 'medium' ? 'text-yellow-600' :
                          'text-green-600'
                        }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-1.964-1.333-2.732 0L3.268 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 font-medium">Priority</p>
                        <p className={`text-lg font-bold capitalize ${
                          selectedTicket.priority === 'high' ? 'text-red-600' :
                          selectedTicket.priority === 'medium' ? 'text-yellow-600' :
                          'text-green-600'
                        }`}>
                          {selectedTicket.priority}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Category Card */}
                  <div className="bg-white rounded-lg border-2 border-gray-200 p-4 shadow-sm hover:shadow-md transition-shadow">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                        <span className="text-xl">{getCategoryIcon(selectedTicket.category)}</span>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 font-medium">Category</p>
                        <p className="text-sm font-bold text-gray-900">
                          {getCategoryDisplayName(selectedTicket.category)}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Created Date Card */}
                  <div className="bg-white rounded-lg border-2 border-gray-200 p-4 shadow-sm hover:shadow-md transition-shadow">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                        <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 font-medium">Created</p>
                        <p className="text-sm font-bold text-gray-900">
                          {new Date(selectedTicket.createdAt).toLocaleDateString('en-US', { 
                            month: 'short', 
                            day: 'numeric'
                          })}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Status Action Buttons */}
                <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
                  <p className="text-xs font-medium text-gray-500 mb-3">QUICK ACTIONS</p>
                  <div className="flex flex-wrap gap-2">
                    {selectedTicket.status !== 'resolved' && selectedTicket.status !== 'closed' && (
                      <button
                        onClick={() => handleUpdateStatus(selectedTicket._id || selectedTicket.id, 'resolved')}
                        disabled={updatingStatus}
                        className="px-4 py-2 text-sm font-medium bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors shadow-sm"
                      >
                        ✓ Mark Resolved
                      </button>
                    )}
                    {selectedTicket.status !== 'closed' && (
                      <button
                        onClick={() => handleUpdateStatus(selectedTicket._id || selectedTicket.id, 'closed')}
                        disabled={updatingStatus}
                        className="px-4 py-2 text-sm font-medium bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors shadow-sm"
                      >
                        🔒 Close Ticket
                      </button>
                    )}
                    {(selectedTicket.status === 'resolved' || selectedTicket.status === 'closed') && (
                      <button
                        onClick={() => handleUpdateStatus(selectedTicket._id || selectedTicket.id, 'open')}
                        disabled={updatingStatus}
                        className="px-4 py-2 text-sm font-medium bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors shadow-sm"
                      >
                        🔄 Reopen Ticket
                      </button>
                    )}
                  </div>
                </div>

                {/* Description Card */}
                <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
                  <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                    <h3 className="text-sm font-semibold text-gray-700 flex items-center space-x-2">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                      <span>Issue Description</span>
                    </h3>
                  </div>
                  <div className="p-4">
                    <p className="text-sm text-gray-700 whitespace-pre-wrap leading-relaxed">{selectedTicket.description}</p>
                  </div>
                </div>

                {/* User Information - Modern Design */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">User Information</label>
                  <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl border-2 border-gray-200 overflow-hidden shadow-sm">
                    <div className="p-6">
                      <div className="flex items-start space-x-4">
                        {/* Profile Photo */}
                        <div className="flex-shrink-0">
                          {selectedTicket.userId?.profilePhoto ? (
                            <img
                              src={selectedTicket.userId.profilePhoto}
                              alt={selectedTicket.userId.name || 'User'}
                              className="w-20 h-20 rounded-full object-cover border-4 border-white shadow-lg"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%236b7280"/><text x="50" y="50" fill="white" text-anchor="middle" dy=".3em" font-size="40" font-weight="bold">' + (selectedTicket.userId?.name?.[0]?.toUpperCase() || 'U') + '</text></svg>';
                              }}
                            />
                          ) : (
                            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center border-4 border-white shadow-lg">
                              <span className="text-3xl font-bold text-white">
                                {selectedTicket.userId?.name?.[0]?.toUpperCase() || 'U'}
                              </span>
                            </div>
                          )}
                        </div>

                        {/* User Details */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div>
                              <h4 className="text-lg font-bold text-gray-900">
                                {selectedTicket.userId?.name || 'Unknown User'}
                              </h4>
                              <p className="text-sm text-gray-600 mt-0.5">
                                {selectedTicket.userId?.email || 'No email'}
                              </p>
                            </div>
                            
                            {/* Verification Badges */}
                            <div className="flex flex-col items-end space-y-1">
                              {selectedTicket.userId?.isVerified && (
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                                  <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                                  </svg>
                                  Verified
                                </span>
                              )}
                              {selectedTicket.userId?.isPhoneVerified && (
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">
                                  <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                    <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" />
                                  </svg>
                                  Phone Verified
                                </span>
                              )}
                            </div>
                          </div>

                          {/* Contact Info */}
                          <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div className="bg-white rounded-lg p-3 shadow-sm border border-gray-200">
                              <div className="flex items-center space-x-2">
                                <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                                </svg>
                                <div>
                                  <p className="text-xs text-gray-500">Phone</p>
                                  <p className="text-sm font-medium text-gray-900">
                                    {selectedTicket.userId?.phoneNumber || 'Not provided'}
                                  </p>
                                </div>
                              </div>
                            </div>

                            <div className="bg-white rounded-lg p-3 shadow-sm border border-gray-200">
                              <div className="flex items-center space-x-2">
                                <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                </svg>
                                <div>
                                  <p className="text-xs text-gray-500">Role</p>
                                  <div className="flex flex-wrap gap-1 mt-0.5">
                                    {selectedTicket.userId?.roles?.map((role: string, index: number) => (
                                      <span 
                                        key={index}
                                        className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                                          role === 'collector' ? 'bg-purple-100 text-purple-800' :
                                          role === 'household' ? 'bg-blue-100 text-blue-800' :
                                          role === 'admin' ? 'bg-red-100 text-red-800' :
                                          'bg-gray-100 text-gray-800'
                                        }`}
                                      >
                                        {role.charAt(0).toUpperCase() + role.slice(1)}
                                      </span>
                                    )) || (
                                      <span className="text-sm font-medium text-gray-900">Household</span>
                                    )}
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>

                          {/* Collector Status */}
                          {selectedTicket.userId?.collectorApplicationStatus && (
                            <div className="mt-3 bg-white rounded-lg p-3 shadow-sm border border-gray-200">
                              <div className="flex items-center justify-between">
                                <span className="text-xs text-gray-500">Collector Application</span>
                                <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                  selectedTicket.userId.collectorApplicationStatus === 'approved' ? 'bg-green-100 text-green-800' :
                                  selectedTicket.userId.collectorApplicationStatus === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                  selectedTicket.userId.collectorApplicationStatus === 'rejected' ? 'bg-red-100 text-red-800' :
                                  'bg-gray-100 text-gray-800'
                                }`}>
                                  {selectedTicket.userId.collectorApplicationStatus.charAt(0).toUpperCase() + selectedTicket.userId.collectorApplicationStatus.slice(1)}
                                </span>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Related Objects Context */}
                {(selectedTicket.relatedDropId || selectedTicket.relatedCollectionId || selectedTicket.relatedApplicationId) && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Related Context</label>
                    <div className="mt-1 space-y-3">
                      {selectedTicket.relatedDropId && (
                        <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl border-2 border-blue-200 overflow-hidden shadow-md">
                          {/* Header */}
                          <div className="bg-white/80 backdrop-blur-sm px-6 py-4 border-b border-blue-200">
                            <div className="flex items-center space-x-3">
                              <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
                                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                </svg>
                              </div>
                              <div>
                                <h3 className="text-lg font-bold text-blue-900">Related Drop Details</h3>
                                <p className="text-xs text-blue-600">
                                  {selectedTicket.relatedDropId.createdAt ? (
                                    `Created ${new Date(selectedTicket.relatedDropId.createdAt).toLocaleDateString('en-US', { 
                                      month: 'short', 
                                      day: 'numeric', 
                                      year: 'numeric' 
                                    })}`
                                  ) : (
                                    'Drop Information'
                                  )}
                                </p>
                              </div>
                            </div>
                          </div>

                          <div className="p-6">
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                              {/* Left Column: Drop Image and Info */}
                              <div className="space-y-4">
                                {/* Drop Image - Large and Prominent */}
                                {selectedTicket.relatedDropId.imageUrl ? (
                                  <div className="relative group">
                                    <img
                                      src={selectedTicket.relatedDropId.imageUrl}
                                      alt="Drop"
                                      className="w-full h-64 object-cover rounded-lg shadow-lg border-2 border-white"
                                      onError={(e) => {
                                        const target = e.target as HTMLImageElement;
                                        target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300"><rect fill="%23e5e7eb" width="400" height="300"/><text x="50%" y="50%" fill="%236b7280" text-anchor="middle" font-size="20">Image Failed to Load</text></svg>';
                                      }}
                                    />
                                    {/* Hover overlay for full view */}
                                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-all duration-200 rounded-lg flex items-center justify-center">
                                      <a
                                        href={selectedTicket.relatedDropId.imageUrl}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 bg-white/90 px-3 py-2 rounded-lg text-sm font-medium text-blue-600 hover:bg-white"
                                      >
                                        View Full Size
                                      </a>
                                    </div>
                                  </div>
                                ) : (
                                  <div className="w-full h-64 bg-gradient-to-br from-blue-100 to-blue-200 rounded-lg flex items-center justify-center border-2 border-white shadow-lg">
                                    <div className="text-center">
                                      <svg className="w-16 h-16 text-blue-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                      </svg>
                                      <p className="text-sm text-blue-500 font-medium">No Image Available</p>
                                    </div>
                                  </div>
                                )}

                                {/* Drop Stats Cards */}
                                <div className="grid grid-cols-2 gap-3">
                                  <div className="bg-white rounded-lg p-4 shadow-sm border border-blue-100">
                                    <div className="flex items-center space-x-2">
                                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                                        <span className="text-lg">🍾</span>
                                      </div>
                                      <div>
                                        <p className="text-2xl font-bold text-blue-900">{selectedTicket.relatedDropId.numberOfBottles || 0}</p>
                                        <p className="text-xs text-gray-600">Bottles</p>
                                      </div>
                                    </div>
                                  </div>
                                  
                                  <div className="bg-white rounded-lg p-4 shadow-sm border border-blue-100">
                                    <div className="flex items-center space-x-2">
                                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                                        <span className="text-lg">🥫</span>
                                      </div>
                                      <div>
                                        <p className="text-2xl font-bold text-blue-900">{selectedTicket.relatedDropId.numberOfCans || 0}</p>
                                        <p className="text-xs text-gray-600">Cans</p>
                                      </div>
                                    </div>
                                  </div>
                                </div>

                                {/* Type and Status */}
                                <div className="bg-white rounded-lg p-4 shadow-sm border border-blue-100 space-y-3">
                                  <div className="flex items-center justify-between">
                                    <span className="text-sm font-medium text-gray-700">Bottle Type</span>
                                    <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium capitalize">
                                      {selectedTicket.relatedDropId.bottleType || 'N/A'}
                                    </span>
                                  </div>
                                  <div className="flex items-center justify-between">
                                    <span className="text-sm font-medium text-gray-700">Status</span>
                                    <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                                      selectedTicket.relatedDropId.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                      selectedTicket.relatedDropId.status === 'accepted' ? 'bg-blue-100 text-blue-800' :
                                      selectedTicket.relatedDropId.status === 'collected' ? 'bg-green-100 text-green-800' :
                                      selectedTicket.relatedDropId.status === 'cancelled' ? 'bg-red-100 text-red-800' :
                                      'bg-gray-100 text-gray-800'
                                    }`}>
                                      {selectedTicket.relatedDropId.status || 'N/A'}
                                    </span>
                                  </div>
                                </div>

                                {/* Notes */}
                                {selectedTicket.relatedDropId.notes && (
                                  <div className="bg-white rounded-lg p-4 shadow-sm border border-blue-100">
                                    <div className="flex items-start space-x-2">
                                      <svg className="w-5 h-5 text-blue-500 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                                      </svg>
                                      <div className="flex-1">
                                        <p className="text-xs font-medium text-gray-700 mb-1">Notes</p>
                                        <p className="text-sm text-gray-600">{selectedTicket.relatedDropId.notes}</p>
                                      </div>
                                    </div>
                                  </div>
                                )}
                              </div>

                              {/* Right Column: Map */}
                              <div className="space-y-4">
                                {/* Location Map */}
                                {selectedTicket.relatedDropId.location && (() => {
                                  const location = selectedTicket.relatedDropId.location;
                                  const lat = location.coordinates?.[1] || location.latitude;
                                  const lng = location.coordinates?.[0] || location.longitude;
                                  
                                  if (!lat || !lng) return null;
                                  
                                  return (
                                    <div className="bg-white rounded-lg shadow-sm border border-blue-100 overflow-hidden">
                                      <div className="h-80 bg-gray-100 rounded-t-lg overflow-hidden">
                                        <iframe
                                          width="100%"
                                          height="100%"
                                          style={{ border: 0 }}
                                          loading="lazy"
                                          src={`https://www.google.com/maps/embed/v1/place?key=AIzaSyBFw0Qbyq9zTFTd-tUY6dZWTgaQzuU17R8&q=${lat},${lng}&zoom=15`}
                                        ></iframe>
                                      </div>
                                      <div className="p-4 bg-white">
                                        <div className="flex items-start space-x-2">
                                          <svg className="w-5 h-5 text-blue-500 mt-0.5" fill="currentColor" viewBox="0 0 24 24">
                                            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                                          </svg>
                                          <div className="flex-1">
                                            <p className="text-sm font-medium text-gray-900">
                                              {location.address || 'Drop Location'}
                                            </p>
                                            <p className="text-xs text-gray-500 mt-1">
                                              {lat.toFixed(6)}, {lng.toFixed(6)}
                                            </p>
                                            <a 
                                              href={`https://www.google.com/maps?q=${lat},${lng}`}
                                              target="_blank"
                                              rel="noopener noreferrer"
                                              className="text-xs text-blue-600 hover:text-blue-800 mt-2 inline-flex items-center space-x-1"
                                            >
                                              <span>Open in Google Maps</span>
                                              <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                              </svg>
                                            </a>
                                          </div>
                                        </div>
                                      </div>
                                    </div>
                                  );
                                })()}
                              </div>
                            </div>
                          </div>

                          {/* Drop Interaction Timeline - Only show for Drop Issues, NOT Collection Issues */}
                          {!selectedTicket.relatedCollectionId && selectedTicket.relatedDropId && (() => {
                            console.log('🔍 Drop Timeline Debug:');
                            console.log('  - relatedDropId:', selectedTicket.relatedDropId);
                            console.log('  - interactions:', selectedTicket.relatedDropId.interactions);
                            console.log('  - interactions length:', selectedTicket.relatedDropId.interactions?.length);
                            return (
                            <div className="mt-4 pt-4 border-t border-blue-200">
                              <h4 className="font-medium text-blue-900 mb-3">Drop Collection Timeline - Complete History</h4>
                              <div className="relative">
                                {/* Timeline line */}
                                <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-blue-200"></div>
                                
                                <div className="space-y-4 max-h-96 overflow-y-auto">
                                  {/* Drop Created Event - Always first */}
                                  <div className="relative flex items-start space-x-4">
                                    <div className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium border-2 bg-blue-100 text-blue-800 border-blue-200">
                                      🏠
                                    </div>
                                    <div className="flex-1 min-w-0 bg-white rounded-lg border border-gray-200 p-3 shadow-sm">
                                      <div className="flex items-center justify-between">
                                        <h5 className="text-sm font-medium text-gray-900">Drop Created</h5>
                                        <span className="text-xs text-gray-500">
                                          {new Date(selectedTicket.relatedDropId.createdAt).toLocaleString()}
                                        </span>
                                      </div>
                                      <div className="mt-1 text-sm text-gray-600">
                                        <p><strong>Items:</strong> {selectedTicket.relatedDropId.numberOfBottles} bottles, {selectedTicket.relatedDropId.numberOfCans} cans</p>
                                        <p><strong>Type:</strong> {selectedTicket.relatedDropId.bottleType}</p>
                                        {selectedTicket.relatedDropId.notes && (
                                          <p><strong>Notes:</strong> {selectedTicket.relatedDropId.notes}</p>
                                        )}
                                      </div>
                                    </div>
                                  </div>
                                  
                                  {/* Collector Interactions */}
                                  {selectedTicket.relatedDropId.interactions?.map((interaction: any, index: number) => {
                                    const getInteractionIcon = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return '✓';
                                        case 'COLLECTED':
                                          return '📦';
                                        case 'CANCELLED':
                                          return '✗';
                                        case 'EXPIRED':
                                          return '⏰';
                                        default:
                                          return '•';
                                      }
                                    };

                                    const getInteractionColor = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return 'bg-green-100 text-green-800 border-green-200';
                                        case 'COLLECTED':
                                          return 'bg-blue-100 text-blue-800 border-blue-200';
                                        case 'CANCELLED':
                                          return 'bg-red-100 text-red-800 border-red-200';
                                        case 'EXPIRED':
                                          return 'bg-orange-100 text-orange-800 border-orange-200';
                                        default:
                                          return 'bg-gray-100 text-gray-800 border-gray-200';
                                      }
                                    };

                                    const getInteractionTitle = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return 'Collector Accepted Drop';
                                        case 'COLLECTED':
                                          return 'Drop Collected Successfully';
                                        case 'CANCELLED':
                                          return 'Collector Cancelled';
                                        case 'EXPIRED':
                                          return 'Acceptance Expired';
                                        default:
                                          return type.charAt(0).toUpperCase() + type.slice(1);
                                      }
                                    };

                                    return (
                                      <div key={interaction.id || index} className="relative flex items-start space-x-4">
                                        {/* Timeline dot */}
                                        <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium border-2 ${getInteractionColor(interaction.type)}`}>
                                          {getInteractionIcon(interaction.type)}
                                        </div>
                                        
                                        {/* Content */}
                                        <div className="flex-1 min-w-0 bg-white rounded-lg border border-gray-200 p-3">
                                          <div className="flex items-center justify-between">
                                            <h5 className="text-sm font-medium text-gray-900">
                                              {getInteractionTitle(interaction.type)}
                                            </h5>
                                            <span className="text-xs text-gray-500">
                                              {new Date(interaction.timestamp).toLocaleString()}
                                            </span>
                                          </div>
                                          
                                          <div className="mt-1 text-sm text-gray-600">
                                            <p><strong>Collector:</strong> {interaction.collectorName || 'Unknown Collector'}</p>
                                            {interaction.cancellationReason && (
                                              <p><strong>Reason:</strong> {interaction.cancellationReason}</p>
                                            )}
                                            {interaction.numberOfItems && (
                                              <p><strong>Items:</strong> {interaction.numberOfItems} ({interaction.bottleType})</p>
                                            )}
                                            {interaction.location && (
                                              <p><strong>Location:</strong> {interaction.location.coordinates?.[0]?.toFixed(4)}, {interaction.location.coordinates?.[1]?.toFixed(4)}</p>
                                            )}
                                          </div>
                                          
                                          {interaction.notes && (
                                            <div className="mt-2 p-2 bg-gray-50 rounded text-xs text-gray-700">
                                              <strong>Notes:</strong> {interaction.notes}
                                            </div>
                                          )}
                                        </div>
                                      </div>
                                    );
                                  })}
                                  
                                  {/* Show message when no collector interactions yet */}
                                  {(!selectedTicket.relatedDropId.interactions || selectedTicket.relatedDropId.interactions.length === 0) && (
                                    <div className="relative flex items-start space-x-4">
                                      <div className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium border-2 bg-gray-100 text-gray-600 border-gray-300">
                                        ⏳
                                      </div>
                                      <div className="flex-1 min-w-0 bg-gray-50 rounded-lg border border-dashed border-gray-300 p-3">
                                        <p className="text-sm text-gray-600 text-center">
                                          No collector interactions yet. Waiting for collectors to accept this drop.
                                        </p>
                                      </div>
                                    </div>
                                  )}
                                </div>
                              </div>
                            </div>
                            );
                          })()}
                          
                        </div>
                      )}
                      
                      {/* Collection Issue - Show only the interaction timeline, no separate drop card */}
                      {selectedTicket.relatedCollectionId && (
                        <div className="p-4 bg-green-50 rounded-lg border border-green-200">

                          {/* Collection Interaction Timeline - Grouped by Pairs */}
                          {selectedTicket.relatedCollectionId.interactions && selectedTicket.relatedCollectionId.interactions.length > 0 && (
                            <div className="mt-4 pt-4 border-t border-green-200">
                              <h4 className="font-medium text-green-900 mb-3">Collection Interaction Timeline (Paired)</h4>
                              
                              <div className="space-y-4 max-h-96 overflow-y-auto">
                                {(() => {
                                  // Group interactions into pairs (ACCEPTED + FINAL_STATE)
                                  const interactions = selectedTicket.relatedCollectionId.interactions;
                                  console.log('🔍 Total interactions:', interactions.length);
                                  console.log('🔍 All interactions:', interactions.map((i: any) => ({ type: i.type, time: i.timestamp })));
                                  
                                  const pairs: any[] = [];
                                  const acceptedInteractions = interactions.filter((i: any) => i.type.toUpperCase() === 'ACCEPTED');
                                  const usedFinalInteractions = new Set();
                                  
                                  console.log('🔍 ACCEPTED interactions:', acceptedInteractions.length);
                                  
                                  // Sort interactions by timestamp
                                  const sortedInteractions = [...interactions].sort((a: any, b: any) => 
                                    new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
                                  );
                                  
                                  acceptedInteractions.forEach((accepted: any) => {
                                    // Find the next interaction after this ACCEPTED (CANCELLED, EXPIRED, or COLLECTED)
                                    const acceptedTime = new Date(accepted.timestamp).getTime();
                                    const finalInteraction = sortedInteractions.find((i: any) => {
                                      const type = i.type.toUpperCase();
                                      return (type === 'CANCELLED' || type === 'EXPIRED' || type === 'COLLECTED') &&
                                        new Date(i.timestamp).getTime() > acceptedTime &&
                                        !usedFinalInteractions.has(i.id);
                                    });
                                    
                                    if (finalInteraction) {
                                      usedFinalInteractions.add(finalInteraction.id);
                                    }
                                    
                                    pairs.push({
                                      accepted,
                                      final: finalInteraction || null
                                    });
                                  });
                                  
                                  console.log('🔍 Created pairs:', pairs.length);
                                  console.log('🔍 Pairs:', pairs.map((p: any) => ({ 
                                    accepted: p.accepted.type, 
                                    final: p.final?.type || 'none' 
                                  })));
                                  
                                  if (pairs.length === 0) {
                                    return (
                                      <div className="text-center py-4 text-gray-500">
                                        <p>No interaction pairs found.</p>
                                        <p className="text-xs mt-2">Total interactions: {interactions.length}</p>
                                        <p className="text-xs">ACCEPTED: {acceptedInteractions.length}</p>
                                      </div>
                                    );
                                  }
                                  
                                  return pairs.map((pair: any, pairIndex: number) => {
                                    const getInteractionIcon = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return '✓';
                                        case 'COLLECTED':
                                          return '📦';
                                        case 'CANCELLED':
                                          return '✗';
                                        case 'EXPIRED':
                                          return '⏰';
                                        default:
                                          return '•';
                                      }
                                    };

                                    const getInteractionColor = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return 'bg-green-100 text-green-800 border-green-200';
                                        case 'COLLECTED':
                                          return 'bg-blue-100 text-blue-800 border-blue-200';
                                        case 'CANCELLED':
                                          return 'bg-red-100 text-red-800 border-red-200';
                                        case 'EXPIRED':
                                          return 'bg-orange-100 text-orange-800 border-orange-200';
                                        default:
                                          return 'bg-gray-100 text-gray-800 border-gray-200';
                                      }
                                    };

                                    const getInteractionTitle = (type: string) => {
                                      switch (type.toUpperCase()) {
                                        case 'ACCEPTED':
                                          return 'Collection Accepted';
                                        case 'COLLECTED':
                                          return 'Successfully Collected';
                                        case 'CANCELLED':
                                          return 'Collection Cancelled';
                                        case 'EXPIRED':
                                          return 'Collection Expired';
                                        default:
                                          return type.charAt(0).toUpperCase() + type.slice(1);
                                      }
                                    };

                                    return (
                                      <div key={pair.accepted.id || pairIndex} className="bg-white rounded-lg border-2 border-green-300 p-4 shadow-sm">
                                        {/* Pair Header */}
                                        <div className="flex items-center justify-between mb-3">
                                          <h5 className="text-sm font-semibold text-green-900">
                                            Interaction Pair #{pairIndex + 1}
                                          </h5>
                                          <span className="text-xs text-gray-500">
                                            {new Date(pair.accepted.timestamp).toLocaleDateString()}
                                          </span>
                                        </div>
                                        
                                        {/* ACCEPTED Interaction */}
                                        <div className={`rounded-lg border-2 ${getInteractionColor(pair.accepted.type)} p-3 mb-2`}>
                                          <div className="flex items-start space-x-3">
                                            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white flex items-center justify-center text-lg font-bold border-2 border-green-500">
                                              {getInteractionIcon(pair.accepted.type)}
                                            </div>
                                            <div className="flex-1">
                                              <div className="flex items-center justify-between">
                                                <h6 className="text-sm font-medium text-gray-900">
                                                  {getInteractionTitle(pair.accepted.type)}
                                                </h6>
                                                <span className="text-xs text-gray-600">
                                                  {new Date(pair.accepted.timestamp).toLocaleTimeString()}
                                                </span>
                                              </div>
                                              <div className="mt-1 text-xs text-gray-700">
                                                <p><strong>Collector:</strong> {pair.accepted.collectorName || 'Unknown'}</p>
                                                {pair.accepted.notes && (
                                                  <p className="mt-1"><strong>Notes:</strong> {pair.accepted.notes}</p>
                                                )}
                                              </div>
                                            </div>
                                          </div>
                                        </div>
                                        
                                        {/* Connection Arrow */}
                                        <div className="flex justify-center my-2">
                                          <div className="flex flex-col items-center">
                                            <div className="w-0.5 h-4 bg-green-400"></div>
                                            <svg className="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                                              <path fillRule="evenodd" d="M10 3a1 1 0 011 1v10.586l2.293-2.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 14.586V4a1 1 0 011-1z" clipRule="evenodd" />
                                            </svg>
                                          </div>
                                        </div>
                                        
                                        {/* FINAL Interaction (CANCELLED/EXPIRED/COLLECTED) */}
                                        {pair.final ? (
                                          <div className={`rounded-lg border-2 ${getInteractionColor(pair.final.type)} p-3`}>
                                            <div className="flex items-start space-x-3">
                                              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white flex items-center justify-center text-lg font-bold border-2 border-current">
                                                {getInteractionIcon(pair.final.type)}
                                              </div>
                                              <div className="flex-1">
                                                <div className="flex items-center justify-between">
                                                  <h6 className="text-sm font-medium text-gray-900">
                                                    {getInteractionTitle(pair.final.type)}
                                                  </h6>
                                                  <span className="text-xs text-gray-600">
                                                    {new Date(pair.final.timestamp).toLocaleTimeString()}
                                                  </span>
                                                </div>
                                                <div className="mt-1 text-xs text-gray-700">
                                                  {pair.final.collectorName && (
                                                    <p><strong>Collector:</strong> {pair.final.collectorName}</p>
                                                  )}
                                                  {pair.final.cancellationReason && (
                                                    <p><strong>Reason:</strong> {pair.final.cancellationReason}</p>
                                                  )}
                                                  {pair.final.notes && (
                                                    <p className="mt-1"><strong>Notes:</strong> {pair.final.notes}</p>
                                                  )}
                                                </div>
                                              </div>
                                            </div>
                                          </div>
                                        ) : (
                                          <div className="rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-3 text-center">
                                            <p className="text-xs text-gray-500">Still pending final action...</p>
                                          </div>
                                        )}
                                      </div>
                                    );
                                  });
                                })()}
                              </div>
                            </div>
                          )}
                          
                          {/* Show message when no interactions are found for collection */}
                          {(!selectedTicket.relatedCollectionId.interactions || selectedTicket.relatedCollectionId.interactions.length === 0) && (
                            <div className="mt-4 pt-4 border-t border-green-200">
                              <h4 className="font-medium text-green-900 mb-3">Collection Interaction Timeline</h4>
                              <div className="text-center py-4 text-gray-500">
                                <p>No interaction history found for this drop.</p>
                              </div>
                            </div>
                          )}
                        </div>
                      )}
                      
                      {selectedTicket.relatedApplicationId && (
                        <div className="p-4 bg-purple-50 rounded-lg border border-purple-200">
                          <div className="flex items-center space-x-2 mb-3">
                            <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                            <span className="font-semibold text-purple-900">Collector Application</span>
                          </div>
                          
                          {typeof selectedTicket.relatedApplicationId === 'string' ? (
                            // Application ID is a string (ObjectId) - not populated
                            <div className="space-y-3">
                              <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-md">
                                <div className="flex items-center space-x-2">
                                  <svg className="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                                  </svg>
                                  <span className="text-sm font-medium text-yellow-800">Application Not Loaded</span>
                                </div>
                                <p className="text-xs text-yellow-700 mt-1">
                                  Application ID: <span className="font-mono">{selectedTicket.relatedApplicationId}</span>
                                </p>
                                <p className="text-xs text-yellow-600 mt-2">
                                  The application details are not available in this ticket. Please check the Applications tab for full details.
                                </p>
                              </div>
                            </div>
                          ) : (
                            // Application is populated object
                            <div className="space-y-3">
                              {/* Application Information */}
                              <div className="space-y-2 text-sm text-purple-800">
                                <div className="flex justify-between">
                                  <span className="font-medium">Status:</span>
                                  <span className={`px-2 py-1 rounded-full text-xs ${
                                    selectedTicket.relatedApplicationId.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                    selectedTicket.relatedApplicationId.status === 'approved' ? 'bg-green-100 text-green-800' :
                                    selectedTicket.relatedApplicationId.status === 'rejected' ? 'bg-red-100 text-red-800' :
                                    'bg-gray-100 text-gray-800'
                                  }`}>
                                    {selectedTicket.relatedApplicationId.status || 'N/A'}
                                  </span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="font-medium">Applied:</span>
                                  <span>{selectedTicket.relatedApplicationId.appliedAt ? new Date(selectedTicket.relatedApplicationId.appliedAt).toLocaleDateString() : 'N/A'}</span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="font-medium">Reviewed:</span>
                                  <span>{selectedTicket.relatedApplicationId.reviewedAt ? new Date(selectedTicket.relatedApplicationId.reviewedAt).toLocaleDateString() : 'Not reviewed'}</span>
                                </div>
                                {selectedTicket.relatedApplicationId.rejectionReason && (
                                  <div className="mt-2 p-2 bg-red-100 rounded">
                                    <span className="font-medium">Rejection Reason:</span>
                                    <p className="text-xs mt-1">{selectedTicket.relatedApplicationId.rejectionReason}</p>
                                  </div>
                                )}
                              </div>
                            </div>
                          )}

                          {/* Step-by-Step Resolution Guide */}
                          <div className="mt-4 pt-4 border-t border-purple-200">
                            <h4 className="font-medium text-purple-900 mb-3">How to Resolve This Application Issue</h4>
                            <div className="space-y-2 text-sm text-purple-800">
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">1</span>
                                <div>
                                  <p className="font-medium">Navigate to Applications Tab</p>
                                  <p className="text-xs text-purple-600">Go to the main dashboard and click on the "Applications" tab to access the dedicated application review interface.</p>
                                </div>
                              </div>
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">2</span>
                                <div>
                                  <p className="font-medium">Find This Application</p>
                                  <p className="text-xs text-purple-600">Search for this user's application using their name ({selectedTicket.userId?.name || 'N/A'}) or email ({selectedTicket.userId?.email || 'N/A'}).</p>
                                </div>
                              </div>
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">3</span>
                                <div>
                                  <p className="font-medium">Review Application Details</p>
                                  <p className="text-xs text-purple-600">Check the ID card photo, selfie with ID, and all submitted documents for authenticity and clarity.</p>
                                </div>
                              </div>
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">4</span>
                                <div>
                                  <p className="font-medium">Make Decision</p>
                                  <p className="text-xs text-purple-600">Approve or reject the application with appropriate notes explaining your decision.</p>
                                </div>
                              </div>
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">5</span>
                                <div>
                                  <p className="font-medium">Update Status</p>
                                  <p className="text-xs text-purple-600">The application status will be automatically updated and the user will be notified of the decision.</p>
                                </div>
                              </div>
                              <div className="flex items-start space-x-2">
                                <span className="flex-shrink-0 w-6 h-6 bg-purple-100 text-purple-800 rounded-full flex items-center justify-center text-xs font-medium">6</span>
                                <div>
                                  <p className="font-medium">Resolve Support Ticket</p>
                                  <p className="text-xs text-purple-600">Return to this support ticket and update its status to "Resolved" with a summary of the action taken.</p>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                )}



                {/* Timestamps */}
                <div>
                  <label className="block text-sm font-medium text-gray-700">Timestamps</label>
                  <div className="mt-1 grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="text-gray-500">Created:</span>
                      <span className="ml-2 text-gray-900">
                        {new Date(selectedTicket.createdAt).toLocaleString()}
                      </span>
                    </div>
                    <div>
                      <span className="text-gray-500">Updated:</span>
                      <span className="ml-2 text-gray-900">
                        {new Date(selectedTicket.updatedAt).toLocaleString()}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Attachments */}
                {selectedTicket.attachments && selectedTicket.attachments.length > 0 && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Attachments</label>
                    <div className="mt-1 space-y-2">
                      {selectedTicket.attachments.map((attachment: any, index: number) => (
                        <div key={index} className="flex items-center space-x-2">
                          <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                          </svg>
                          <span className="text-sm text-gray-900">{attachment.filename}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Conversation History */}
                <div className="border-t pt-4">
                  <div className="flex justify-between items-center mb-3">
                    <label className="block text-sm font-medium text-gray-700">
                      Conversation History ({selectedTicket.messages?.length || 0} messages)
                    </label>
                    <div className="flex items-center space-x-2">
                      <div className={`w-2 h-2 rounded-full ${socket ? 'bg-green-500' : 'bg-red-500'}`}></div>
                      <span className="text-xs text-gray-500">
                        {socket ? 'Connected' : 'Connecting...'}
                      </span>
                    </div>
                  </div>
                  <div ref={conversationRef} className="space-y-4 max-h-96 overflow-y-auto">
                    {selectedTicket.messages && selectedTicket.messages.length > 0 ? (
                      selectedTicket.messages.map((message: any, index: number) => (
                        <div
                          key={index}
                          className={`flex ${message.senderType === 'user' ? 'justify-start' : 'justify-end'}`}
                        >
                          <div
                            className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                              message.senderType === 'user'
                                ? 'bg-gray-100 text-gray-900'
                                : message.senderType === 'agent'
                                ? 'bg-blue-500 text-white'
                                : 'bg-yellow-100 text-yellow-900'
                            }`}
                          >
                            <div className="text-sm">{message.message}</div>
                            <div className={`text-xs mt-1 ${
                              message.senderType === 'user' ? 'text-gray-500' : 'text-blue-100'
                            }`}>
                              {message.senderType === 'user' ? 'User' : 
                               message.senderType === 'agent' ? 'Support Agent' : 'System'} • {' '}
                              {new Date(message.sentAt).toLocaleString()}
                            </div>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="text-center py-8 text-gray-500">
                        <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                        </svg>
                        <p className="mt-2">No conversation yet</p>
                        <p className="text-sm">Start the conversation by sending a response</p>
                      </div>
                    )}
                  </div>
                  
                  {/* Status Banners */}
                  {selectedTicket.status === 'resolved' && (
                    <div className="mt-4 bg-green-50 border-l-4 border-green-400 p-4 rounded-r-lg">
                      <div className="flex items-start">
                        <svg className="w-5 h-5 text-green-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                        <div className="ml-3 flex-1">
                          <p className="text-sm font-medium text-green-800">
                            ✅ This ticket is marked as resolved.
                          </p>
                          <p className="text-xs text-green-700 mt-1">
                            You can still reply. If the user responds, the ticket will automatically reopen.
                          </p>
                        </div>
                      </div>
                    </div>
                  )}
                  
                  {selectedTicket.status === 'closed' && (
                    <div className="mt-4 bg-gray-50 border-l-4 border-gray-400 p-4 rounded-r-lg">
                      <div className="flex items-start">
                        <svg className="w-5 h-5 text-gray-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                        </svg>
                        <div className="ml-3 flex-1">
                          <p className="text-sm font-medium text-gray-800">
                            🔒 This ticket is closed.
                          </p>
                          <p className="text-xs text-gray-600 mt-1">
                            Chat is disabled. Click "Reopen Ticket" above to continue the conversation.
                          </p>
                        </div>
                      </div>
                    </div>
                  )}
                  
                  {/* Admin Response Input */}
                  <div className="mt-4 border-t pt-4">
                    <label className="block text-sm font-medium text-gray-700 mb-2">Send Response</label>
                    <textarea
                      value={newMessage}
                      onChange={handleTyping}
                      className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 ${
                        selectedTicket.status === 'closed' 
                          ? 'border-gray-200 bg-gray-100 cursor-not-allowed text-gray-400' 
                          : 'border-gray-300 focus:ring-blue-500'
                      }`}
                      rows={3}
                      placeholder={
                        selectedTicket.status === 'closed' 
                          ? 'Chat is disabled for closed tickets...' 
                          : 'Type your response here...'
                      }
                      disabled={sendingMessage || selectedTicket.status === 'closed'}
                    />
                    
                    {/* Typing and Presence Indicators */}
                    <div className="mt-2 text-sm text-gray-500">
                      {userPresent && (
                        <div className="flex items-center space-x-1">
                          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                          <span>User is online</span>
                        </div>
                      )}
                      {userTyping && (
                        <div className="flex items-center space-x-1">
                          <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                          <span>User is typing...</span>
                        </div>
                      )}
                    </div>
                    <div className="mt-3 flex justify-end space-x-3">
                      <button
                        onClick={handleCloseModal}
                        className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                      >
                        Cancel
                      </button>
                      <button 
                        onClick={handleSendMessage}
                        disabled={!newMessage.trim() || sendingMessage || selectedTicket.status === 'closed'}
                        className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {sendingMessage ? 'Sending...' : selectedTicket.status === 'closed' ? 'Chat Disabled' : 'Send Response'}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function SettingsContent() {
  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-lg border border-gray-200">
        <div className="px-4 py-5 sm:p-6">
          <div className="bg-surface p-4 rounded-md">
            <p className="text-text-secondary">Settings functionality will be implemented here.</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function AdminManagementContent() {
  const [adminUsers, setAdminUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [showRoleModal, setShowRoleModal] = useState(false);
  const [newRoles, setNewRoles] = useState<UserRole[]>([]);
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [newAdminData, setNewAdminData] = useState({
    email: '',
    name: '',
    role: 'admin' as UserRole,
  });
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    const fetchAdminUsers = async () => {
      try {
        setLoading(true);
        const response = await usersAPI.getAdminUsers();
        
        // Filter for admin users only
        const allUsers = response.data.users || [];
        console.log('All users from API:', allUsers);
        
        const adminUsers = allUsers.filter((user: any) => 
          user.roles && user.roles.some((role: string) => 
            ['super_admin', 'admin', 'moderator', 'support_agent'].includes(role)
          )
        );
        
        console.log('Filtered admin users:', adminUsers);
        setAdminUsers(adminUsers);
      } catch (error: any) {
        setError('Failed to fetch admin users');
        console.error('Error fetching admin users:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAdminUsers();
  }, []);

  const handleUpdateRoles = async () => {
    if (!selectedUser) return;

    try {
      await usersAPI.updateUserRoles(selectedUser.id, newRoles);
      // Refresh the list
      const response = await usersAPI.getAdminUsers();
      const allUsers = response.data.users || [];
      const adminUsers = allUsers.filter((user: any) => 
        user.roles && user.roles.some((role: string) => 
          ['super_admin', 'admin', 'moderator', 'support_agent'].includes(role)
        )
      );
      setAdminUsers(adminUsers);
      setShowRoleModal(false);
      setSelectedUser(null);
      setNewRoles([]);
    } catch (error: any) {
      setError('Failed to update user roles');
      console.error('Error updating roles:', error);
    }
  };

  const handleAddNewAdmin = async () => {
    try {
      // Create admin user using signup endpoint
      const response = await usersAPI.createAdminUser(newAdminData);
      
      // If signup requires email verification, show success message
      if (response.data?.message?.includes('verify your email')) {
        setSuccessMessage(`Admin user created successfully! Email verification required. OTP: ${response.data.otp}`);
      } else {
        setSuccessMessage('Admin user created successfully!');
      }
      
      // Refresh the admin users list
      const usersResponse = await usersAPI.getAdminUsers();
      const allUsers = usersResponse.data.users || [];
      const adminUsers = allUsers.filter((user: any) => 
        user.roles && user.roles.some((role: string) => 
          ['super_admin', 'admin', 'moderator', 'support_agent'].includes(role)
        )
      );
      setAdminUsers(adminUsers);
      
      // Reset form and close modal
      setNewAdminData({ email: '', name: '', role: 'admin' });
      setShowAddAdminModal(false);
    } catch (error: any) {
      setError('Failed to create admin user');
      console.error('Error creating admin user:', error);
    }
  };

  const getRoleBadgeColor = (role: UserRole) => {
    switch (role) {
      case 'super_admin':
        return 'bg-red-100 text-red-800';
      case 'admin':
        return 'bg-blue-100 text-blue-800';
      case 'moderator':
        return 'bg-green-100 text-green-800';
      case 'support_agent':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getRoleDisplayName = (role: UserRole) => {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'support_agent':
        return 'Support Agent';
      default:
        return role;
    }
  };

  const openRoleModal = (user: any) => {
    setSelectedUser(user);
    setNewRoles([...user.roles]);
    setShowRoleModal(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-md p-4">
        <div className="flex">
          <div className="ml-3">
            <h3 className="text-sm font-medium text-red-800">Error</h3>
            <div className="mt-2 text-sm text-red-700">{error}</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="border-b border-gray-200 pb-4">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Admin Management</h1>
            <p className="mt-2 text-sm text-gray-600">
              Manage admin users, moderators, and support agents. Only visible to Super Admins.
            </p>
          </div>
          <button
            onClick={() => setShowAddAdminModal(true)}
            className="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark transition-colors duration-200"
          >
            Add New Admin
          </button>
        </div>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="bg-green-50 border border-green-200 rounded-md p-4 mb-4">
          <div className="flex">
            <div className="ml-3">
              <h3 className="text-sm font-medium text-green-800">Success</h3>
              <div className="mt-2 text-sm text-green-700">{successMessage}</div>
              <button
                onClick={() => setSuccessMessage(null)}
                className="mt-2 text-sm text-green-600 hover:text-green-500"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="text-2xl font-bold text-gray-900">
            {adminUsers.filter(u => u.roles.includes('super_admin')).length}
          </div>
          <div className="text-sm text-gray-600">Super Admins</div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="text-2xl font-bold text-gray-900">
            {adminUsers.filter(u => u.roles.includes('admin')).length}
          </div>
          <div className="text-sm text-gray-600">Admins</div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="text-2xl font-bold text-gray-900">
            {adminUsers.filter(u => u.roles.includes('moderator')).length}
          </div>
          <div className="text-sm text-gray-600">Moderators</div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <div className="text-2xl font-bold text-gray-900">
            {adminUsers.filter(u => u.roles.includes('support_agent')).length}
          </div>
          <div className="text-sm text-gray-600">Support Agents</div>
        </div>
      </div>

      {/* Admin Users Table */}
      <div className="bg-white shadow rounded-lg">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900">Admin Users</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  User
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Roles
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Joined
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {adminUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10">
                        <div className="h-10 w-10 rounded-full bg-primary flex items-center justify-center">
                          <span className="text-white font-semibold text-sm">
                            {user.name?.charAt(0).toUpperCase() || user.email?.charAt(0).toUpperCase()}
                          </span>
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {user.name || user.email?.split('@')[0] || 'Unknown User'}
                        </div>
                        <div className="text-sm text-gray-500">
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex flex-wrap gap-1">
                      {user.roles.map((role: string) => (
                        <span
                          key={role}
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getRoleBadgeColor(role as UserRole)}`}
                        >
                          {getRoleDisplayName(role as UserRole)}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      user.isVerified 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {user.isVerified ? 'Verified' : 'Unverified'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(user.createdAt).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button
                      onClick={() => openRoleModal(user)}
                      className="text-primary hover:text-primary-dark"
                    >
                      Manage Roles
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Role Management Modal */}
      {showRoleModal && selectedUser && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Manage Roles for {selectedUser.name || selectedUser.email?.split('@')[0]}
              </h3>
              
              <div className="space-y-3">
                {(['admin', 'moderator', 'support_agent'] as UserRole[]).map((role) => (
                  <label key={role} className="flex items-center">
                    <input
                      type="checkbox"
                      checked={newRoles.includes(role)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setNewRoles([...newRoles, role]);
                        } else {
                          setNewRoles(newRoles.filter(r => r !== role));
                        }
                      }}
                      className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700">
                      {getRoleDisplayName(role)}
                    </span>
                  </label>
                ))}
              </div>

              <div className="mt-6 flex justify-end space-x-3">
                <button
                  onClick={() => setShowRoleModal(false)}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                >
                  Cancel
                </button>
                <button
                  onClick={handleUpdateRoles}
                  className="px-4 py-2 text-sm font-medium text-white bg-primary border border-transparent rounded-md hover:bg-primary-dark"
                >
                  Update Roles
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add New Admin Modal */}
      {showAddAdminModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Add New Admin User
              </h3>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Full Name
                  </label>
                  <input
                    type="text"
                    value={newAdminData.name}
                    onChange={(e) => setNewAdminData({ ...newAdminData, name: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="Enter full name"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email Address
                  </label>
                  <input
                    type="email"
                    value={newAdminData.email}
                    onChange={(e) => setNewAdminData({ ...newAdminData, email: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="Enter email address"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Admin Role
                  </label>
                  <select
                    value={newAdminData.role}
                    onChange={(e) => setNewAdminData({ ...newAdminData, role: e.target.value as UserRole })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                  >
                    <option value="admin">Admin</option>
                    <option value="moderator">Moderator</option>
                    <option value="support_agent">Support Agent</option>
                  </select>
                </div>

                <div className="bg-blue-50 border border-blue-200 rounded-md p-3">
                  <p className="text-sm text-blue-800">
                    <strong>Note:</strong> An invitation email will be sent to the user with instructions to set up their account and password.
                  </p>
                </div>
              </div>

              <div className="mt-6 flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowAddAdminModal(false);
                    setNewAdminData({ email: '', name: '', role: 'admin' });
                  }}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                >
                  Cancel
                </button>
                <button
                  onClick={handleAddNewAdmin}
                  className="px-4 py-2 text-sm font-medium text-white bg-primary border border-transparent rounded-md hover:bg-primary-dark"
                >
                  Send Invitation
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Main Dashboard Component
export default function DashboardPage() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [userRoles, setUserRoles] = useState<string[]>([]);

  useEffect(() => {
    const fetchUserProfile = async () => {
      try {
        const token = localStorage.getItem('admin_token');
        if (token) {
          // Try to decode JWT token to get user roles
          try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            // Handle both 'roles' array and single 'role'
            const roles = payload.roles || (payload.role ? [payload.role] : []);
            setUserRoles(roles);
            console.log('User roles from JWT:', roles);
          } catch (jwtError) {
            console.log('Could not decode JWT token for roles');
          }
        }
      } catch (error) {
        console.error('Error fetching user profile:', error);
      }
    };

    const fetchStats = async () => {
      try {
        setLoading(true);
        setError(null);
        
        console.log('🔍 Starting to fetch dashboard stats...');
        const response = await analyticsAPI.getAnalytics();
        console.log('📊 Raw API response:', response);
        console.log('📊 Response type:', typeof response);
        console.log('📊 Response keys:', Object.keys(response));
        
        // The API returns { success: true, stats: { ... } }
        const dashboardStats = response.data.stats || response.data;
        console.log('📊 Dashboard stats:', dashboardStats);
        console.log('📊 Stats keys:', Object.keys(dashboardStats));
        console.log('📊 Total users:', dashboardStats.totalUsers);
        console.log('📊 Total drops:', dashboardStats.totalDrops);
        console.log('📊 Recent activity:', dashboardStats.recentActivity);
        
        setStats(dashboardStats);
      } catch (error: any) {
        console.error('❌ Failed to fetch dashboard stats:', error);
        console.error('❌ Error response:', error.response?.data);
        console.error('❌ Error status:', error.response?.status);
        setError(error.message);
        
        // Mock data for demo
        setStats({
          totalUsers: 1250,
          totalDrops: 3420,
          totalApplications: 89,
          totalTickets: 45,
          pendingApplications: 12,
          pendingTickets: 8,
          recentActivity: [
            {
              id: '1',
              type: 'user_registration',
              description: 'New user registered: John Doe',
              timestamp: new Date().toISOString(),
              userName: 'John Doe',
            },
            {
              id: '2',
              type: 'drop_created',
              description: 'New drop created by Jane Smith',
              timestamp: new Date(Date.now() - 3600000).toISOString(),
              userName: 'Jane Smith',
            },
          ],
        });
      } finally {
        setLoading(false);
      }
    };

    fetchUserProfile();
    fetchStats();
  }, []);

  const handleTabChange = (tabId: string) => {
    setActiveTab(tabId);
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <DashboardContent stats={stats} loading={loading} error={error} />;
      case 'users':
        return <UsersContent />;
      case 'drops':
        return <DropsContent />;
      case 'applications':
        return <ApplicationsContent />;
      case 'training':
        return <TrainingContent />;
      case 'support':
        return <SupportContent />;
      case 'settings':
        return <SettingsContent />;
      case 'admin-management':
        return <AdminManagementContent />;
      default:
        return <DashboardContent stats={stats} loading={loading} error={error} />;
    }
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-surface">
        <Sidebar activeTab={activeTab} onTabChange={handleTabChange} userRoles={userRoles} />
        <div className="pl-56">
          <Header />
          <main className="pt-24 pb-8">
            <div className="mx-auto max-w-7xl px-6 lg:px-8">
              <div className="fade-in">
                {renderContent()}
              </div>
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
} 