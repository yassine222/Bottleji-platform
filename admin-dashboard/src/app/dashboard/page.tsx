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
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  UserGroupIcon,
  TicketIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationCircleIcon,
  FunnelIcon,
  MagnifyingGlassIcon,
  SparklesIcon,
} from '@heroicons/react/24/outline';
import { usersAPI } from '@/lib/api';
import { applicationsAPI } from '@/lib/api';
import { supportTicketsAPI, trainingAPI } from '@/lib/api';
import { CollectorApplication } from '@/types';
import { UserRole } from '@/types';
import {
  UsersGrowthChart,
  DropsActivityChart,
  CollectorInteractionsChart,
  DropStatusPieChart,
  BottleTypeDistribution,
  TicketsByCategory,
  ApplicationsStatus,
} from '@/components/dashboard/DashboardCharts';
import FileUpload from '@/components/training/FileUpload';
import VideoPlayer from '@/components/training/VideoPlayer';
import VideoModal from '@/components/training/VideoModal';

// Dashboard Content Component
function DashboardContent({ stats, loading, error }: any) {
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

  const mainStatCards = [
    {
      name: 'Total Users',
      value: stats?.totalUsers || 0,
      icon: UsersIcon,
      color: 'from-blue-500 to-blue-600',
      textColor: 'text-blue-600',
      bgColor: 'bg-blue-50',
      trend: { value: stats?.usersLast7Days || 0, label: 'Last 7 days' },
    },
    {
      name: 'Total Drops',
      value: stats?.totalDrops || 0,
      icon: CubeIcon,
      color: 'from-green-500 to-green-600',
      textColor: 'text-green-600',
      bgColor: 'bg-green-50',
      trend: { value: stats?.dropsLast7Days || 0, label: 'Last 7 days' },
    },
    {
      name: 'Active Collectors',
      value: stats?.activeCollectors || 0,
      icon: UserGroupIcon,
      color: 'from-purple-500 to-purple-600',
      textColor: 'text-purple-600',
      bgColor: 'bg-purple-50',
      trend: { value: stats?.pendingApplications || 0, label: 'Pending' },
    },
    {
      name: 'Open Tickets',
      value: stats?.pendingTickets || 0,
      icon: ChatBubbleLeftRightIcon,
      color: 'from-orange-500 to-orange-600',
      textColor: 'text-orange-600',
      bgColor: 'bg-orange-50',
      trend: { value: stats?.totalTickets || 0, label: 'Total' },
    },
  ];

  return (
    <div className="space-y-6">
      {/* Main Stats Cards - Enhanced */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {mainStatCards.map((stat) => (
          <div
            key={stat.name}
            className="bg-white overflow-hidden shadow-sm rounded-xl border border-gray-200 hover:shadow-md transition-shadow"
          >
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className={`p-3 rounded-lg ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.textColor}`} />
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-gray-900">
                    {stat.value.toLocaleString()}
                  </p>
                  <p className="text-sm font-medium text-gray-500 mt-1">
                    {stat.name}
                  </p>
                </div>
              </div>
              <div className="mt-4 flex items-center justify-between">
                <div className="flex items-center text-sm text-gray-600">
                  <ArrowTrendingUpIcon className="h-4 w-4 mr-1" />
                  <span className="font-medium">{stat.trend.value}</span>
                  <span className="ml-1 text-gray-500">{stat.trend.label}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Secondary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
          <div className="text-sm text-gray-600">Drops (Last 30 Days)</div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{stats?.dropsLast30Days || 0}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
          <div className="text-sm text-gray-600">New Users (Last 30 Days)</div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{stats?.usersLast30Days || 0}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
          <div className="text-sm text-gray-600">Total Applications</div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{stats?.totalApplications || 0}</div>
        </div>
      </div>

      {/* Charts Section - Time Series */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {stats?.usersTimeSeries && stats.usersTimeSeries.length > 0 && (
          <UsersGrowthChart data={stats.usersTimeSeries} />
        )}
        {stats?.dropsTimeSeries && stats.dropsTimeSeries.length > 0 && (
          <DropsActivityChart data={stats.dropsTimeSeries} />
        )}
      </div>

      {/* Collector Interactions Chart - Full Width */}
      {stats?.interactionsTimeSeries && stats.interactionsTimeSeries.length > 0 && (
        <CollectorInteractionsChart data={stats.interactionsTimeSeries} />
      )}

      {/* Charts Section - Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {stats?.dropsByStatus && Object.keys(stats.dropsByStatus).length > 0 && (
          <DropStatusPieChart data={stats.dropsByStatus} />
        )}
        {stats?.bottleTypeDistribution && Object.keys(stats.bottleTypeDistribution).length > 0 && (
          <BottleTypeDistribution data={stats.bottleTypeDistribution} />
        )}
      </div>

      {/* Charts Section - Applications & Tickets */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {stats?.applicationsByStatus && Object.keys(stats.applicationsByStatus).length > 0 && (
          <ApplicationsStatus data={stats.applicationsByStatus} />
        )}
        {stats?.ticketsByCategory && Object.keys(stats.ticketsByCategory).length > 0 && (
          <TicketsByCategory data={stats.ticketsByCategory} />
        )}
      </div>

      {/* Recent Activity */}
      <div className="bg-white shadow-sm rounded-lg border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Recent Activity</h3>
        </div>
        <div className="px-6 py-4">
          {stats?.recentActivity && stats.recentActivity.length > 0 ? (
            <div className="flow-root">
              <ul className="-mb-8">
                {stats.recentActivity.slice(0, 10).map((activity: any, activityIdx: number) => (
                  <li key={activity.id}>
                    <div className="relative pb-8">
                      {activityIdx !== Math.min(stats.recentActivity.length, 10) - 1 ? (
                        <span
                          className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200"
                          aria-hidden="true"
                        />
                      ) : null}
                      <div className="relative flex space-x-3">
                        <div>
                          <span className={`h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white ${
                            activity.type === 'user_registration' ? 'bg-blue-500' : 
                            activity.type === 'drop_created' ? 'bg-green-500' : 'bg-purple-500'
                          }`}>
                            <span className="text-white text-sm font-medium">
                              {activity.type === 'user_registration' ? 'U' : 
                               activity.type === 'drop_created' ? 'D' : 'A'}
                            </span>
                          </span>
                        </div>
                        <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                          <div>
                            <p className="text-sm text-gray-700">
                              {activity.description}
                            </p>
                          </div>
                          <div className="text-right text-sm whitespace-nowrap text-gray-500">
                            <time dateTime={activity.timestamp}>
                              {new Date(activity.timestamp).toLocaleDateString('en-US', {
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
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
            <p className="text-gray-500 text-center py-4">No recent activity</p>
          )}
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
  const [videoModalOpen, setVideoModalOpen] = useState(false);
  const [selectedVideo, setSelectedVideo] = useState<{ url: string; thumbnail?: string; title: string } | null>(null);

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

  const handlePlayVideo = (videoUrl: string, thumbnailUrl: string | undefined, title: string) => {
    setSelectedVideo({ url: videoUrl, thumbnail: thumbnailUrl, title });
    setVideoModalOpen(true);
  };

  const handleCloseVideoModal = () => {
    setVideoModalOpen(false);
    setSelectedVideo(null);
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

      {/* Stats - Enhanced */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gradient-to-br from-blue-500 to-blue-600 p-5 rounded-xl shadow-md hover:shadow-lg transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-medium text-blue-100">Total Content</h3>
                <p className="text-3xl font-bold text-white mt-1">{stats.totalContent || 0}</p>
              </div>
              <div className="bg-white bg-opacity-20 rounded-lg p-3">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </div>
            </div>
          </div>
          
          <div className="bg-gradient-to-br from-purple-500 to-purple-600 p-5 rounded-xl shadow-md hover:shadow-lg transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-medium text-purple-100">Videos</h3>
                <p className="text-3xl font-bold text-white mt-1">{stats.videoCount || 0}</p>
              </div>
              <div className="bg-white bg-opacity-20 rounded-lg p-3">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
          </div>
          
          <div className="bg-gradient-to-br from-green-500 to-green-600 p-5 rounded-xl shadow-md hover:shadow-lg transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-medium text-green-100">Images</h3>
                <p className="text-3xl font-bold text-white mt-1">{stats.imageCount || 0}</p>
              </div>
              <div className="bg-white bg-opacity-20 rounded-lg p-3">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
          </div>
          
          <div className="bg-gradient-to-br from-orange-500 to-orange-600 p-5 rounded-xl shadow-md hover:shadow-lg transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-medium text-orange-100">Stories</h3>
                <p className="text-3xl font-bold text-white mt-1">{stats.storyCount || 0}</p>
              </div>
              <div className="bg-white bg-opacity-20 rounded-lg p-3">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filters - Modern Design */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200">
        <div className="flex flex-wrap gap-4 items-center">
          <div className="flex items-center space-x-2">
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
            </svg>
            <span className="text-sm font-medium text-gray-700">Filters:</span>
          </div>
          
          <div className="flex-1 flex flex-wrap gap-3">
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-4 py-2 bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            >
              <option value="">📚 All Categories</option>
              {categories.map(category => (
                <option key={category.value} value={category.value}>
                  {category.icon} {category.label}
                </option>
              ))}
            </select>

            <select
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value)}
              className="px-4 py-2 bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            >
              <option value="">📁 All Types</option>
              {contentTypes.map(type => (
                <option key={type.value} value={type.value}>
                  {type.icon} {type.label}
                </option>
              ))}
            </select>
          </div>
          
          <div className="text-sm text-gray-500">
            {filteredContent.length} {filteredContent.length === 1 ? 'item' : 'items'}
          </div>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <p className="text-red-600">{error}</p>
        </div>
      )}

      {/* Content Grid - Modern Cards */}
      {filteredContent.length === 0 ? (
        <div className="text-center py-16 bg-gray-50 rounded-xl border-2 border-dashed border-gray-300">
          <svg className="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p className="text-gray-500 text-lg">No training content found.</p>
          <p className="text-gray-400 text-sm mt-2">Create your first content to get started!</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredContent.map((content) => (
            <div key={content._id} className="bg-white border border-gray-200 rounded-xl overflow-hidden hover:shadow-lg transition-all duration-300 inline-block w-auto max-w-full">
              {/* Card Header */}
              <div className="p-4 border-b border-gray-100">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-2xl">
                        {contentTypes.find(t => t.value === content.type)?.icon || '📄'}
                      </span>
                      <h3 className="text-lg font-bold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-1">
                        {content.title}
                      </h3>
                    </div>
                    
                    <p className="text-sm text-gray-600 line-clamp-1 leading-relaxed">{content.description}</p>
                  </div>
                  
                  {/* Action Buttons */}
                  <div className="flex gap-2 ml-3">
                    <button
                      onClick={() => handleEdit(content)}
                      className="p-1.5 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                      title="Edit"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button
                      onClick={() => handleDelete(content._id)}
                      className="p-1.5 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                      title="Delete"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
                
                {/* Badges */}
                <div className="flex flex-wrap gap-2 mt-3">
                  <span className="px-3 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full">
                    {categories.find(c => c.value === content.category)?.icon} 
                    {categories.find(c => c.value === content.category)?.label}
                  </span>
                </div>
              </div>

              {/* Card Body - Media */}
              <div className="p-3 bg-gray-50">
                {content.type === 'video' && content.mediaUrl && (
                  <div className="relative group/video cursor-pointer" onClick={() => handlePlayVideo(content.mediaUrl, content.thumbnailUrl, content.title)}>
                    <div className="relative w-96 h-56 bg-black rounded-lg overflow-hidden">
                      {content.thumbnailUrl ? (
                        <img
                          src={content.thumbnailUrl}
                          alt={content.title}
                          className="w-full h-full object-cover"
                          crossOrigin="anonymous"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-800 to-gray-900">
                          <svg className="w-20 h-20 text-gray-600" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M8 5v14l11-7z"/>
                          </svg>
                        </div>
                      )}
                      
                      {/* Play Button Overlay */}
                      <div className="absolute inset-0 flex items-center justify-center bg-black bg-opacity-0 group-hover/video:bg-opacity-30 transition-all">
                        <div className="transform scale-100 group-hover/video:scale-110 transition-transform">
                          <div className="bg-blue-600 rounded-full p-4 shadow-2xl">
                            <svg className="w-8 h-8 text-white ml-1" fill="currentColor" viewBox="0 0 24 24">
                              <path d="M8 5v14l11-7z"/>
                            </svg>
                          </div>
                        </div>
                      </div>
                      
                      {/* Duration Badge */}
                      {content.duration && (
                        <div className="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                          {Math.floor(content.duration / 60)}:{(content.duration % 60).toString().padStart(2, '0')}
                        </div>
                      )}
                    </div>
                    <p className="text-xs text-gray-600 mt-2 text-center">Click to play video</p>
                  </div>
                )}

                {content.type === 'image' && content.mediaUrl && (
                  <div className="relative group/image w-96">
                    <img
                      src={content.mediaUrl}
                      alt={content.title}
                      className="w-full h-56 object-cover rounded-lg shadow-md"
                      crossOrigin="anonymous"
                    />
                    <div className="absolute inset-0 bg-black bg-opacity-0 group-hover/image:bg-opacity-10 transition-all rounded-lg flex items-center justify-center">
                      <svg className="w-12 h-12 text-white opacity-0 group-hover/image:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                      </svg>
                    </div>
                  </div>
                )}
                
                {content.type === 'story' && (
                  <div className="bg-white p-3 rounded-lg border border-gray-200 w-96 max-w-full">
                    <div className="flex items-center text-gray-500 mb-2">
                      <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                      <span className="text-xs font-medium">Story Content</span>
                    </div>
                    <p className="text-sm text-gray-600 line-clamp-3 leading-relaxed">{content.content}</p>
                  </div>
                )}
              </div>
              
              {/* Card Footer */}
              <div className="px-4 py-2 bg-white border-t border-gray-100">
                <div className="flex items-center justify-between text-xs">
                  <span className="flex items-center text-gray-500">
                    <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    {new Date(content.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </span>
                  <span className="flex items-center text-blue-600 font-semibold">
                    <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                    {content.viewCount || 0} {(content.viewCount || 0) === 1 ? 'view' : 'views'}
                  </span>
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

      {/* Video Modal */}
      {videoModalOpen && selectedVideo && (
        <VideoModal
          isOpen={videoModalOpen}
          onClose={handleCloseVideoModal}
          videoUrl={selectedVideo.url}
          thumbnailUrl={selectedVideo.thumbnail}
          title={selectedVideo.title}
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
    
    return {
      title: safeString(content?.title),
      description: safeString(content?.description),
      type: safeString(content?.type) || 'video',
      category: safeString(content?.category) || 'getting_started',
      mediaUrl: safeString(content?.mediaUrl),
      thumbnailUrl: safeString(content?.thumbnailUrl),
      content: safeString(content?.content),
      tags: Array.isArray(content?.tags) ? content.tags : [],
    };
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [uploadingMedia, setUploadingMedia] = useState(false);
  const [uploadingThumbnail, setUploadingThumbnail] = useState(false);
  const [tagInput, setTagInput] = useState('');

  const availableTags = [
    { value: 'household', label: 'Household Users', icon: '🏠', color: 'bg-blue-100 text-blue-700' },
    { value: 'collector', label: 'Collectors', icon: '🚛', color: 'bg-green-100 text-green-700' },
  ];

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
      console.log('📤 Submitting training content:', formData);
      console.log('   mediaUrl:', formData.mediaUrl);
      console.log('   thumbnailUrl:', formData.thumbnailUrl);
      
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

            {/* Media Upload */}
            {formData.type !== 'story' && (
              <FileUpload
                type={formData.type === 'video' ? 'video' : 'image'}
                label={formData.type === 'video' ? 'Video File' : 'Image File'}
                accept={formData.type === 'video' ? 'video/mp4,video/webm' : 'image/png,image/jpeg,image/jpg,image/gif'}
                currentUrl={formData.mediaUrl}
                onUploadComplete={(url) => {
                  console.log('🔄 Media upload complete callback:', url);
                  setFormData(prev => ({ ...prev, mediaUrl: url }));
                }}
                onUploadingChange={setUploadingMedia}
                disabled={loading}
              />
            )}

            {/* Thumbnail Upload */}
            {formData.type === 'video' && (
              <FileUpload
                type="thumbnail"
                label="Video Thumbnail"
                accept="image/png,image/jpeg,image/jpg"
                currentUrl={formData.thumbnailUrl}
                onUploadComplete={(url) => {
                  console.log('🔄 Thumbnail upload complete callback:', url);
                  setFormData(prev => {
                    const updated = { ...prev, thumbnailUrl: url };
                    console.log('✅ Updated formData with thumbnail:', updated);
                    return updated;
                  });
                }}
                onUploadingChange={setUploadingThumbnail}
                disabled={loading}
              />
            )}

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

            {/* Tags Section */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Target Audience (Select who can see this content)
              </label>
              <div className="flex flex-wrap gap-2">
                {availableTags.map((tag) => {
                  const isSelected = formData.tags.includes(tag.value);
                  return (
                    <button
                      key={tag.value}
                      type="button"
                      onClick={() => {
                        setFormData(prev => ({
                          ...prev,
                          tags: isSelected
                            ? prev.tags.filter((t: string) => t !== tag.value)
                            : [...prev.tags, tag.value]
                        }));
                      }}
                      className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                        isSelected
                          ? tag.color + ' border-2 border-current'
                          : 'bg-gray-100 text-gray-600 hover:bg-gray-200 border-2 border-transparent'
                      }`}
                    >
                      {tag.icon} {tag.label}
                      {isSelected && (
                        <span className="ml-1">✓</span>
                      )}
                    </button>
                  );
                })}
              </div>
              {formData.tags.length === 0 && (
                <p className="text-xs text-orange-600 mt-2">
                  ⚠️ Select at least one audience to make this content visible
                </p>
              )}
              {formData.tags.length > 0 && (
                <p className="text-xs text-green-600 mt-2">
                  ✓ This content will be visible to: {formData.tags.map((t: string) => 
                    availableTags.find(at => at.value === t)?.label
                  ).join(', ')}
                </p>
              )}
            </div>

            <div className="flex justify-end space-x-3 pt-6">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={(() => {
                  const isDisabled = 
                    loading || 
                    uploadingMedia || 
                    uploadingThumbnail || 
                    !formData.title || 
                    !formData.description ||
                    formData.tags.length === 0 ||
                    (formData.type !== 'story' && !formData.mediaUrl) ||
                    (formData.type === 'video' && !formData.thumbnailUrl);
                  
                  console.log('🔍 Create button validation:', {
                    loading,
                    uploadingMedia,
                    uploadingThumbnail,
                    hasTitle: !!formData.title,
                    hasDescription: !!formData.description,
                    hasTags: formData.tags.length > 0,
                    tags: formData.tags,
                    type: formData.type,
                    hasMediaUrl: !!formData.mediaUrl,
                    hasThumbnailUrl: !!formData.thumbnailUrl,
                    isDisabled
                  });
                  
                  return isDisabled;
                })()}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {uploadingMedia || uploadingThumbnail
                  ? 'Uploading...'
                  : loading
                  ? 'Saving...'
                  : (content ? 'Update' : 'Create')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// Modern SupportContent component to replace the old one in dashboard/page.tsx
// This goes from line 2718 to line 4688

function SupportContent() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [stats, setStats] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedTicket, setSelectedTicket] = useState<any | null>(null);

  const fetchStats = async () => {
    try {
      const response = await supportTicketsAPI.getTicketStats();
      setStats(response.data);
    } catch (err) {
      console.error('Error fetching ticket stats:', err);
    }
  };

  const fetchTickets = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await supportTicketsAPI.getAllTickets(1, 100, selectedStatus, selectedCategory);
      setTickets(response.data.tickets || []);
      
      await fetchStats();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch support tickets');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();
  }, [selectedStatus, selectedCategory]);

  const handleMessageSent = async () => {
    if (selectedTicket) {
      try {
        const response = await supportTicketsAPI.getTicketById(selectedTicket.id || selectedTicket._id);
        setSelectedTicket(response.data);
        fetchTickets();
      } catch (err) {
        console.error('Error refreshing ticket:', err);
      }
    }
  };

  const handleStatusChange = async () => {
    setSelectedTicket(null);
    fetchTickets();
  };

  // Filter tickets by search query
  const filteredTickets = tickets.filter(ticket => 
    ticket.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ticket.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ticket.userId.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open':
        return 'bg-yellow-100 text-yellow-800 border border-yellow-300';
      case 'in_progress':
        return 'bg-blue-100 text-blue-800 border border-blue-300';
      case 'resolved':
        return 'bg-green-100 text-green-800 border border-green-300';
      case 'closed':
        return 'bg-gray-100 text-gray-800 border border-gray-300';
      case 'on_hold':
        return 'bg-orange-100 text-orange-800 border border-orange-300';
      default:
        return 'bg-gray-100 text-gray-800 border border-gray-300';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'bg-red-100 text-red-800 border border-red-300';
      case 'high':
        return 'bg-orange-100 text-orange-800 border border-orange-300';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border border-yellow-300';
      case 'low':
        return 'bg-green-100 text-green-800 border border-green-300';
      default:
        return 'bg-gray-100 text-gray-800 border border-gray-300';
    }
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'urgent':
      case 'high':
        return '🔥 ';
      case 'medium':
        return '⚡ ';
      case 'low':
        return '💬 ';
      default:
        return '';
    }
  };

  const getCategoryDisplayName = (category: string) => {
    const categoryMap: { [key: string]: string } = {
      authentication: '🔐 Authentication',
      app_technical: '📱 App Technical',
      drop_creation: '🏠 Drop Creation',
      collection_navigation: '🚚 Collection & Navigation',
      collector_application: '👤 Collector Application',
      payment_rewards: '💰 Payment & Rewards',
      statistics_history: '📊 Statistics & History',
      role_switching: '🔄 Role Switching',
      communication: '📞 Communication',
      general_support: '🛠️ General Support',
    };
    return categoryMap[category] || category;
  };

  const TicketDetailModal = ({ ticket, onClose }: { ticket: any; onClose: () => void }) => {
    const [newMessage, setNewMessage] = useState('');
    const [sending, setSending] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [updatingStatus, setUpdatingStatus] = useState(false);

    const handleSendMessage = async () => {
      if (!newMessage.trim()) return;

      try {
        setSending(true);
        setError(null);
        
        await supportTicketsAPI.addMessage(ticket.id || ticket._id, newMessage, false);
        
        setNewMessage('');
        handleMessageSent();
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to send message');
      } finally {
        setSending(false);
      }
    };

    const handleStatusUpdate = async (newStatus: string) => {
      try {
        setUpdatingStatus(true);
        await supportTicketsAPI.updateTicketStatus(ticket.id || ticket._id, newStatus);
        handleStatusChange();
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to update status');
      } finally {
        setUpdatingStatus(false);
      }
    };

    return (
      <div className="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4" onClick={onClose}>
        <div className="relative w-full max-w-5xl bg-white rounded-2xl shadow-2xl" onClick={(e) => e.stopPropagation()}>
          {/* Header */}
          <div className="relative px-8 py-6 border-b border-gray-200 bg-gradient-to-r from-blue-50 to-indigo-50">
            <button
              onClick={onClose}
              className="absolute top-6 right-6 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <div className="pr-12">
              <div className="flex items-center gap-3 mb-3">
                <TicketIcon className="h-6 w-6 text-blue-600" />
                <h3 className="text-2xl font-bold text-gray-900">{ticket.title}</h3>
              </div>
              <div className="flex items-center gap-4">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(ticket.status)}`}>
                  {ticket.status.replace('_', ' ').toUpperCase()}
                </span>
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getPriorityColor(ticket.priority)}`}>
                  {getPriorityIcon(ticket.priority)}
                  {ticket.priority.toUpperCase()}
                </span>
                <span className="text-sm text-gray-600">{getCategoryDisplayName(ticket.category)}</span>
              </div>
            </div>
          </div>

          {/* Content */}
          <div className="max-h-[calc(100vh-240px)] overflow-y-auto">
            {/* Ticket Info Grid */}
            <div className="px-8 py-6 grid grid-cols-3 gap-4 bg-gray-50 border-b border-gray-200">
              <div className="bg-white p-4 rounded-lg shadow-sm">
                <div className="text-xs font-medium text-gray-500 uppercase mb-1">Created</div>
                <div className="text-sm font-semibold text-gray-900">{new Date(ticket.createdAt).toLocaleString()}</div>
              </div>
              <div className="bg-white p-4 rounded-lg shadow-sm">
                <div className="text-xs font-medium text-gray-500 uppercase mb-1">Last Updated</div>
                <div className="text-sm font-semibold text-gray-900">{new Date(ticket.updatedAt).toLocaleString()}</div>
              </div>
              <div className="bg-white p-4 rounded-lg shadow-sm">
                <div className="text-xs font-medium text-gray-500 uppercase mb-1">Messages</div>
                <div className="text-sm font-semibold text-gray-900">{ticket.messages.length} messages</div>
              </div>
            </div>

            {/* Description */}
            <div className="px-8 py-6 border-b border-gray-200">
              <h4 className="text-sm font-semibold text-gray-700 uppercase mb-3">Description</h4>
              <p className="text-gray-900 leading-relaxed">{ticket.description}</p>
            </div>

            {/* Status Update */}
            <div className="px-8 py-4 border-b border-gray-200 bg-gray-50">
              <div className="flex items-center gap-4">
                <label className="text-sm font-semibold text-gray-700">Update Status:</label>
                <select
                  value={ticket.status}
                  onChange={(e) => handleStatusUpdate(e.target.value)}
                  disabled={updatingStatus}
                  className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm font-medium disabled:opacity-50"
                >
                  <option value="open">Open</option>
                  <option value="in_progress">In Progress</option>
                  <option value="resolved">Resolved</option>
                  <option value="closed">Closed</option>
                  <option value="on_hold">On Hold</option>
                </select>
              </div>
            </div>

            {/* Messages */}
            <div className="px-8 py-6">
              <h4 className="text-sm font-semibold text-gray-700 uppercase mb-4 flex items-center gap-2">
                <ChatBubbleLeftRightIcon className="h-5 w-5" />
                Conversation
              </h4>
              <div className="space-y-4 max-h-96 overflow-y-auto">
                {ticket.messages.map((msg: any, idx: number) => (
                  <div
                    key={idx}
                    className={`flex ${msg.senderType === 'agent' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[70%] rounded-2xl px-5 py-3 shadow-sm ${
                        msg.senderType === 'agent'
                          ? 'bg-gradient-to-br from-blue-500 to-blue-600 text-white'
                          : 'bg-white border border-gray-200 text-gray-900'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className={`text-xs font-semibold ${msg.senderType === 'agent' ? 'text-blue-100' : 'text-gray-600'}`}>
                          {msg.senderType === 'agent' ? '🎫 Support Agent' : '👤 User'}
                        </span>
                        <span className={`text-xs ${msg.senderType === 'agent' ? 'text-blue-100' : 'text-gray-500'}`}>
                          {new Date(msg.sentAt).toLocaleString()}
                        </span>
                      </div>
                      <p className="text-sm whitespace-pre-wrap leading-relaxed">{msg.message}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Send Message */}
            <div className="px-8 py-6 border-t border-gray-200 bg-gray-50">
              {error && (
                <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg flex items-center gap-2">
                  <ExclamationCircleIcon className="h-5 w-5 flex-shrink-0" />
                  {error}
                </div>
              )}
              <div className="flex gap-3">
                <textarea
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Type your response..."
                  className="flex-1 p-4 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm resize-none"
                  rows={3}
                  disabled={sending}
                />
                <button
                  type="button"
                  onClick={handleSendMessage}
                  disabled={sending || !newMessage.trim()}
                  className="px-6 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl hover:from-blue-700 hover:to-blue-800 disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed font-medium transition-all shadow-md hover:shadow-lg"
                >
                  {sending ? 'Sending...' : 'Send'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="flex items-center justify-center h-[calc(100vh-200px)]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600 font-medium">Loading support tickets...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border-2 border-red-200 rounded-xl p-6 shadow-sm">
          <div className="flex items-start gap-4">
            <ExclamationCircleIcon className="h-6 w-6 text-red-600 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-red-900 mb-2">Error Loading Tickets</h3>
              <p className="text-red-700 mb-4">{error}</p>
              <button
                onClick={fetchTickets}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium transition-colors"
              >
                Try Again
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Calculate stats if not available from API
  const calculatedStats = stats || {
    total: tickets.length,
    open: tickets.filter(t => t.status === 'open').length,
    inProgress: tickets.filter(t => t.status === 'in_progress').length,
    resolved: tickets.filter(t => t.status === 'resolved').length,
    closed: tickets.filter(t => t.status === 'closed').length,
    byPriority: {},
    byCategory: {},
  };

  // Calculate urgent/high priority tickets
  const urgentTickets = tickets.filter(t => 
    (t.priority === 'urgent' || t.priority === 'high') && 
    (t.status === 'open' || t.status === 'in_progress')
  ).length;

  const statCards = [
    {
      name: 'Total Tickets',
      value: calculatedStats.total,
      icon: TicketIcon,
      bgColor: 'bg-blue-50',
      iconColor: 'text-blue-600',
    },
    {
      name: 'Open Tickets',
      value: calculatedStats.open,
      icon: ClockIcon,
      bgColor: 'bg-yellow-50',
      iconColor: 'text-yellow-600',
    },
    {
      name: 'In Progress',
      value: calculatedStats.inProgress,
      icon: SparklesIcon,
      bgColor: 'bg-indigo-50',
      iconColor: 'text-indigo-600',
    },
    {
      name: 'Resolved',
      value: calculatedStats.resolved,
      icon: CheckCircleIcon,
      bgColor: 'bg-green-50',
      iconColor: 'text-green-600',
    },
    {
      name: 'High Priority',
      value: urgentTickets,
      icon: ExclamationCircleIcon,
      bgColor: 'bg-red-50',
      iconColor: 'text-red-600',
    },
  ];

  return (
    <div className="p-6">
      {selectedTicket && (
        <TicketDetailModal
          ticket={selectedTicket}
          onClose={() => setSelectedTicket(null)}
        />
      )}
      
      <div className="space-y-6">
        {/* Page Header */}
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl shadow-xl p-8 text-white">
          <div className="flex items-center gap-3 mb-2">
            <ChatBubbleLeftRightIcon className="h-10 w-10" />
            <h1 className="text-4xl font-bold">Support Tickets</h1>
          </div>
          <p className="text-blue-100 text-lg">Manage and respond to user support requests</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-6">
          {statCards.map((stat) => (
            <div
              key={stat.name}
              className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100"
            >
              <div className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className={`p-3 rounded-xl ${stat.bgColor}`}>
                    <stat.icon className={`h-7 w-7 ${stat.iconColor}`} />
                  </div>
                  <div className="text-right">
                    <p className="text-3xl font-bold text-gray-900">
                      {stat.value}
                    </p>
                  </div>
                </div>
                <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">
                  {stat.name}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Filters and Search */}
        <div className="bg-white rounded-xl shadow-md p-6 border border-gray-100">
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Search */}
            <div className="flex-1 relative">
              <MagnifyingGlassIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search tickets by title, description, or user ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
              />
            </div>
            
            {/* Status Filter */}
            <div className="relative">
              <FunnelIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400 pointer-events-none" />
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm font-medium appearance-none bg-white cursor-pointer min-w-[180px]"
              >
                <option value="">All Statuses</option>
                <option value="open">Open</option>
                <option value="in_progress">In Progress</option>
                <option value="resolved">Resolved</option>
                <option value="closed">Closed</option>
                <option value="on_hold">On Hold</option>
              </select>
            </div>
            
            {/* Category Filter */}
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm font-medium appearance-none bg-white cursor-pointer min-w-[220px]"
            >
              <option value="">All Categories</option>
              <option value="authentication">🔐 Authentication</option>
              <option value="app_technical">📱 App Technical</option>
              <option value="drop_creation">🏠 Drop Creation</option>
              <option value="collection_navigation">🚚 Collection & Navigation</option>
              <option value="collector_application">👤 Collector Application</option>
              <option value="payment_rewards">💰 Payment & Rewards</option>
              <option value="statistics_history">📊 Statistics & History</option>
              <option value="role_switching">🔄 Role Switching</option>
              <option value="communication">📞 Communication</option>
              <option value="general_support">🛠️ General Support</option>
            </select>
          </div>
        </div>

        {/* Tickets List */}
        {filteredTickets.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md border border-gray-100">
            <div className="px-6 py-16">
              <div className="text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gray-100 mb-4">
                  <TicketIcon className="h-8 w-8 text-gray-400" />
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">No tickets found</h3>
                <p className="text-gray-600">
                  {searchQuery || selectedStatus || selectedCategory
                    ? 'Try adjusting your filters or search query.'
                    : 'No support tickets have been created yet.'}
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {filteredTickets.map((ticket) => (
              <div
                key={ticket.id || ticket._id}
                className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 border border-gray-100 overflow-hidden group"
              >
                <div className="p-6">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 min-w-0">
                      {/* Title and Badges */}
                      <div className="flex items-start gap-3 mb-3">
                        <h3 className="text-lg font-bold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-2 flex-1">
                          {ticket.title}
                        </h3>
                        <div className="flex gap-2 flex-shrink-0">
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(ticket.status)}`}>
                            {ticket.status.replace('_', ' ').toUpperCase()}
                          </span>
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getPriorityColor(ticket.priority)}`}>
                            {getPriorityIcon(ticket.priority)}{ticket.priority.toUpperCase()}
                          </span>
                        </div>
                      </div>
                      
                      {/* Meta Info */}
                      <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-gray-600 mb-3">
                        <span className="flex items-center gap-1.5 font-medium">
                          {getCategoryDisplayName(ticket.category)}
                        </span>
                        <span className="text-gray-400">•</span>
                        <span className="flex items-center gap-1.5">
                          <ClockIcon className="h-4 w-4" />
                          {new Date(ticket.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                        </span>
                        <span className="text-gray-400">•</span>
                        <span className="flex items-center gap-1.5">
                          <ChatBubbleLeftRightIcon className="h-4 w-4" />
                          {ticket.messages.length} message{ticket.messages.length !== 1 ? 's' : ''}
                        </span>
                        {ticket.assignedTo && (
                          <>
                            <span className="text-gray-400">•</span>
                            <span className="flex items-center gap-1.5">
                              👤 Assigned to: {ticket.assignedTo}
                            </span>
                          </>
                        )}
                      </div>
                      
                      {/* Description Preview */}
                      <p className="text-gray-700 line-clamp-2 leading-relaxed">
                        {ticket.description}
                      </p>
                    </div>
                    
                    {/* View Button */}
                    <button
                      onClick={() => setSelectedTicket(ticket)}
                      className="flex-shrink-0 px-6 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl hover:from-blue-700 hover:to-blue-800 font-semibold transition-all shadow-md hover:shadow-lg transform hover:-translate-y-0.5"
                    >
                      View Details
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
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