'use client';

import { useState, useEffect, useRef } from 'react';
import axios from 'axios';
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

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://172.20.10.12:3000/api';

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
  const [showAddWarningModal, setShowAddWarningModal] = useState(false);
  const [newWarningReason, setNewWarningReason] = useState('');
  const [editingWarning, setEditingWarning] = useState<{ index: number; reason: string; date: string } | null>(null);

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
      console.log('📊 Frontend received activities:', response.data);
      const activities = response.data.activities || response.data || [];
      console.log('📊 Total activities:', activities.length);
      console.log('📊 Collection activities:', activities.filter((a: any) => a.type?.startsWith('collector_')).length);
      setUserActivities(activities);
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

  const handleReportedDropAction = async (reportId: string, dropId: string, action: 'approve' | 'censor' | 'delete') => {
    const actionMessages = {
      approve: 'Approve this drop? This will dismiss the report and keep the drop active.',
      censor: 'Censor this drop? This will hide it from public view but keep it in the system.',
      delete: 'Delete this drop? This will permanently remove it from the system.'
    };

    const confirmed = window.confirm(actionMessages[action]);
    
    if (confirmed) {
      try {
        const response = await fetch(`/api/admin/drops-management/reports/${reportId}/action/${dropId}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
          },
          body: JSON.stringify({ action })
        });

        if (!response.ok) {
          throw new Error('Failed to process action');
        }

        // Reload reported drops to reflect the change
        await fetchReportedDrops();
        
        // Show success message
        alert(`Drop ${action}d successfully!`);
      } catch (err: any) {
        console.error(`Error ${action}ing drop:`, err);
        alert(`Failed to ${action} drop. Please try again.`);
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

  const collectorsCount = users.filter(u => u.roles?.includes('collector')).length;
  const activeUsersCount = users.filter(u => !u.isAccountLocked || (u.accountLockedUntil && new Date(u.accountLockedUntil) <= new Date())).length;
  const lockedUsersCount = users.filter(u => u.isAccountLocked && (!u.accountLockedUntil || new Date(u.accountLockedUntil) > new Date())).length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-600 to-cyan-600 rounded-2xl shadow-xl p-8 text-white">
        <div className="flex items-center gap-3 mb-2">
          <UsersIcon className="h-10 w-10" />
          <h1 className="text-4xl font-bold">User Management</h1>
        </div>
        <p className="text-teal-100 text-lg">Manage users, roles, and permissions</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-blue-50">
                <UsersIcon className="h-7 w-7 text-blue-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{totalUsers}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Total Users</p>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-purple-50">
                <UserGroupIcon className="h-7 w-7 text-purple-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{collectorsCount}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Collectors</p>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-green-50">
                <CheckCircleIcon className="h-7 w-7 text-green-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{activeUsersCount}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Active Users</p>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-red-50">
                <ExclamationCircleIcon className="h-7 w-7 text-red-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{lockedUsersCount}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Locked Users</p>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-xl shadow-md p-6 border border-gray-100">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <MagnifyingGlassIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent text-sm"
            />
          </div>
          
          {/* Status Filter */}
          <div className="flex items-center gap-3">
            <FunnelIcon className="h-5 w-5 text-gray-400" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent font-medium min-w-[180px]"
            >
              <option value="all">All Users</option>
              <option value="users">🏠 Household</option>
              <option value="collectors">👷 Collectors</option>
              <option value="active">✅ Active</option>
              <option value="locked">🔒 Locked</option>
            </select>
          </div>

          {/* Include Deleted Toggle */}
          <div className="flex items-center gap-3 px-4 py-3 bg-gray-50 rounded-xl border border-gray-200">
            <input
              type="checkbox"
              id="includeDeleted"
              checked={includeDeleted}
              onChange={(e) => {
                setIncludeDeleted(e.target.checked);
                loadUsers(1);
              }}
              className="h-4 w-4 text-teal-600 focus:ring-teal-500 border-gray-300 rounded"
            />
            <label htmlFor="includeDeleted" className="text-sm font-medium text-gray-700 cursor-pointer">
              Show Deleted
            </label>
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
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-6xl bg-white rounded-2xl shadow-2xl">
            {/* Header with Gradient and Profile */}
            <div className="relative px-8 py-6 border-b border-gray-200 bg-gradient-to-r from-teal-50 to-cyan-50">
              <button
                onClick={() => setShowUserModal(false)}
                className="absolute top-6 right-6 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              <div className="flex items-center gap-6 pr-12">
                <div className="flex-shrink-0">
                  {selectedUser.profilePhoto ? (
                    <img
                      className="h-24 w-24 rounded-full object-cover ring-4 ring-white shadow-lg"
                      src={selectedUser.profilePhoto}
                      alt={selectedUser.name || 'User'}
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                        target.nextElementSibling?.classList.remove('hidden');
                      }}
                    />
                  ) : null}
                  <div className={`h-24 w-24 rounded-full bg-gradient-to-br from-teal-500 to-cyan-500 flex items-center justify-center ring-4 ring-white shadow-lg ${selectedUser.profilePhoto ? 'hidden' : ''}`}>
                    <span className="text-white text-3xl font-bold">
                      {selectedUser.name?.charAt(0)?.toUpperCase() || selectedUser.email?.charAt(0)?.toUpperCase() || 'U'}
                    </span>
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-3xl font-bold text-gray-900 mb-2">{selectedUser.name || 'No Name'}</h3>
                  <p className="text-gray-600 mb-3">{selectedUser.email}</p>
                  <div className="flex items-center gap-2">
                    {getStatusBadge(selectedUser)}
                    {selectedUser.roles?.map((role: string) => (
                      <span key={role} className="px-3 py-1 text-xs font-semibold bg-gray-100 text-gray-700 rounded-full border border-gray-300">
                        {role === 'household' ? '🏠 Household' : role === 'collector' ? '👷 Collector' : role}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Content */}
            <div className="max-h-[calc(100vh-240px)] overflow-y-auto p-8">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-gradient-to-br from-teal-50 to-cyan-50 rounded-xl p-6 border border-teal-100">
                  <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <UsersIcon className="h-5 w-5 text-teal-600" />
                    Personal Information
                  </h4>
                  <div className="space-y-2 text-sm">
                    <div><span className="font-medium">Name:</span> {selectedUser.name || 'Not provided'}</div>
                    <div><span className="font-medium">Email:</span> {selectedUser.email}</div>
                    <div><span className="font-medium">Phone:</span> {selectedUser.phoneNumber || 'Not provided'}</div>
                    <div><span className="font-medium">Address:</span> {selectedUser.address || 'Not provided'}</div>
                  </div>
                </div>
                
                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-6 border border-blue-100">
                  <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <svg className="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    Account Information
                  </h4>
                  <div className="space-y-3 text-sm">
                    <div className="flex justify-between items-center">
                      <span className="font-semibold text-gray-700">Status:</span>
                      {getStatusBadge(selectedUser)}
                    </div>
                    <div className="flex justify-between">
                      <span className="font-semibold text-gray-700">Verified:</span>
                      <span className={selectedUser.isVerified ? 'text-green-600 font-medium' : 'text-orange-600 font-medium'}>
                        {selectedUser.isVerified ? '✅ Yes' : '⚠️ No'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-semibold text-gray-700">Profile Complete:</span>
                      <span className={selectedUser.isProfileComplete ? 'text-green-600 font-medium' : 'text-orange-600 font-medium'}>
                        {selectedUser.isProfileComplete ? '✅ Yes' : '⚠️ No'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-semibold text-gray-700">Joined:</span>
                      <span className="text-gray-900">{formatDate(selectedUser.createdAt)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-semibold text-gray-700">Last Updated:</span>
                      <span className="text-gray-900">{formatDate(selectedUser.updatedAt)}</span>
                    </div>
                    {selectedUser.isAccountLocked && selectedUser.accountLockedUntil && (
                      <div className="flex justify-between">
                        <span className="font-semibold text-gray-700">Lock Expires:</span>
                        <span className="text-red-600 font-medium">{formatDate(selectedUser.accountLockedUntil)}</span>
                      </div>
                    )}
                  </div>
                </div>
                
                {selectedUser.collectorApplication && (
                  <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-6 border border-purple-100">
                    <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                      <ClipboardDocumentListIcon className="h-5 w-5 text-purple-600" />
                      Collector Application
                    </h4>
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between items-center">
                        <span className="font-semibold text-gray-700">Status:</span>
                        <span className="font-medium">{selectedUser.collectorApplication.status}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold text-gray-700">Applied:</span>
                        <span className="text-gray-900">{formatDate(selectedUser.collectorApplication.appliedAt)}</span>
                      </div>
                      {selectedUser.collectorApplication.reviewedAt && (
                        <div className="flex justify-between">
                          <span className="font-semibold text-gray-700">Reviewed:</span>
                          <span className="text-gray-900">{formatDate(selectedUser.collectorApplication.reviewedAt)}</span>
                        </div>
                      )}
                      {selectedUser.collectorApplication.rejectionReason && (
                        <div className="flex justify-between">
                          <span className="font-semibold text-gray-700">Rejection Reason:</span>
                          <span className="text-red-600 font-medium">{selectedUser.collectorApplication.rejectionReason}</span>
                        </div>
                      )}
                    </div>
                  </div>
                )}
                
              </div>

              {/* Warnings Management Section - Full Width */}
              <div className="mt-6 bg-gradient-to-br from-red-50 to-orange-50 rounded-xl p-6 border-2 border-red-200">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <ExclamationCircleIcon className="h-6 w-6 text-red-600" />
                    <div>
                      <h4 className="text-xl font-bold text-gray-900">Warnings Management</h4>
                      <p className="text-sm text-gray-600">Track and manage user violations</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <div className="text-3xl font-bold text-red-600">{selectedUser.warningCount || 0}/5</div>
                      <div className="text-xs text-gray-600 font-medium">Warnings</div>
                    </div>
                  </div>
                </div>

                {/* Warning Progress Bar */}
                <div className="mb-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-semibold text-gray-700">Warning Level</span>
                    <span className="text-sm font-medium text-gray-600">
                      {selectedUser.warningCount >= 5 ? '🔒 Account Locked' : 
                       selectedUser.warningCount >= 4 ? '⚠️ Critical' : 
                       selectedUser.warningCount >= 3 ? '⚠️ High' : 
                       selectedUser.warningCount >= 2 ? '⚡ Medium' : 
                       selectedUser.warningCount >= 1 ? '💬 Low' : '✅ Clean'}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
                    <div 
                      className={`h-full transition-all duration-500 ${
                        selectedUser.warningCount >= 5 ? 'bg-red-600' :
                        selectedUser.warningCount >= 4 ? 'bg-orange-500' :
                        selectedUser.warningCount >= 3 ? 'bg-yellow-500' :
                        'bg-green-500'
                      }`}
                      style={{ width: `${Math.min((selectedUser.warningCount || 0) / 5 * 100, 100)}%` }}
                    ></div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex gap-3 mb-6">
                  <button
                    onClick={() => setShowAddWarningModal(true)}
                    className="flex-1 bg-gradient-to-r from-orange-600 to-red-600 text-white px-4 py-3 rounded-xl hover:from-orange-700 hover:to-red-700 font-semibold transition-all shadow-md hover:shadow-lg flex items-center justify-center gap-2"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.732 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    Add Warning
                  </button>
                  <button
                    onClick={async () => {
                      if (window.confirm('Are you sure you want to reset all warnings for this user? This action cannot be undone.')) {
                        try {
                          setLoading(true);
                          await usersAPI.resetUserWarnings(selectedUser.id);
                          
                          // Update the selected user data
                          setSelectedUser({
                            ...selectedUser,
                            warningCount: 0,
                            warnings: [],
                            isAccountLocked: false,
                            accountLockedUntil: null,
                          });
                          
                          // Refresh the users list to show updated data
                          await loadUsers(currentPage);
                          
                          alert('All warnings have been reset successfully!');
                        } catch (error: any) {
                          console.error('Error resetting warnings:', error);
                          alert('Failed to reset warnings: ' + (error.response?.data?.message || error.message));
                        } finally {
                          setLoading(false);
                        }
                      }
                    }}
                    disabled={!selectedUser.warnings || selectedUser.warnings.length === 0}
                    className="flex-1 bg-gradient-to-r from-blue-600 to-cyan-600 text-white px-4 py-3 rounded-xl hover:from-blue-700 hover:to-cyan-700 font-semibold transition-all shadow-md hover:shadow-lg disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                    Reset All Warnings
                  </button>
                </div>

                {/* Warnings List */}
                {selectedUser.warnings && selectedUser.warnings.length > 0 ? (
                  <div className="space-y-3">
                    {selectedUser.warnings.map((warning: any, index: number) => (
                      <div key={index} className="bg-white rounded-xl p-4 border-2 border-red-200 shadow-sm hover:shadow-md transition-all">
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2">
                              <span className="px-2 py-1 bg-red-100 text-red-800 text-xs font-bold rounded-full">
                                Warning #{index + 1}
                              </span>
                              <span className="text-xs text-gray-500">
                                {formatDate(warning.date || warning.timestamp || new Date().toISOString())}
                              </span>
                            </div>
                            <p className="text-sm font-semibold text-gray-900">{warning.reason}</p>
                          </div>
                          <div className="flex gap-2 flex-shrink-0">
                            <button
                              onClick={() => setEditingWarning({ index, reason: warning.reason, date: warning.date })}
                              className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                              title="Edit Warning"
                            >
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                              </svg>
                            </button>
                            <button
                              onClick={() => {
                                if (window.confirm(`Are you sure you want to remove warning #${index + 1}?`)) {
                                  // TODO: Call API to remove warning
                                  alert('Remove warning functionality will be implemented');
                                }
                              }}
                              className="p-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                              title="Remove Warning"
                            >
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="bg-white/50 rounded-xl p-8 text-center border-2 border-dashed border-gray-300">
                    <CheckCircleIcon className="h-12 w-12 text-green-500 mx-auto mb-3" />
                    <p className="text-gray-600 font-medium">No warnings issued</p>
                    <p className="text-sm text-gray-500 mt-1">This user has a clean record</p>
                  </div>
                )}
              </div>

              {/* Add Warning Modal */}
              {showAddWarningModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[70] flex items-center justify-center p-4">
                  <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
                    <div className="p-6 border-b border-gray-200">
                      <h3 className="text-xl font-bold text-gray-900">Add New Warning</h3>
                      <p className="text-sm text-gray-600 mt-1">Issue a warning to this user</p>
                    </div>
                    <div className="p-6">
                      <label className="block text-sm font-semibold text-gray-700 mb-2">
                        Warning Reason
                      </label>
                      <textarea
                        value={newWarningReason}
                        onChange={(e) => setNewWarningReason(e.target.value)}
                        placeholder="Enter the reason for this warning..."
                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-500 text-sm resize-none"
                        rows={4}
                      />
                      <p className="text-xs text-gray-500 mt-2">
                        ⚠️ Warning {(selectedUser.warningCount || 0) + 1} of 5 - Account will be locked after 5 warnings
                      </p>
                    </div>
                    <div className="p-6 border-t border-gray-200 flex gap-3">
                      <button
                        onClick={() => {
                          setShowAddWarningModal(false);
                          setNewWarningReason('');
                        }}
                        className="flex-1 px-4 py-3 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 font-semibold transition-colors"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => {
                          if (newWarningReason.trim()) {
                            // TODO: Call API to add warning
                            alert('Add warning functionality will be implemented');
                            setShowAddWarningModal(false);
                            setNewWarningReason('');
                          }
                        }}
                        disabled={!newWarningReason.trim()}
                        className="flex-1 px-4 py-3 bg-gradient-to-r from-red-600 to-orange-600 text-white rounded-xl hover:from-red-700 hover:to-orange-700 font-semibold transition-all shadow-md hover:shadow-lg disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed"
                      >
                        Add Warning
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Edit Warning Modal */}
              {editingWarning && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[70] flex items-center justify-center p-4">
                  <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
                    <div className="p-6 border-b border-gray-200">
                      <h3 className="text-xl font-bold text-gray-900">Edit Warning #{editingWarning.index + 1}</h3>
                      <p className="text-sm text-gray-600 mt-1">Modify the warning details</p>
                    </div>
                    <div className="p-6">
                      <label className="block text-sm font-semibold text-gray-700 mb-2">
                        Warning Reason
                      </label>
                      <textarea
                        value={editingWarning.reason}
                        onChange={(e) => setEditingWarning({ ...editingWarning, reason: e.target.value })}
                        placeholder="Enter the reason for this warning..."
                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm resize-none"
                        rows={4}
                      />
                      <p className="text-xs text-gray-500 mt-2">
                        Issued on: {formatDate(editingWarning.date)}
                      </p>
                    </div>
                    <div className="p-6 border-t border-gray-200 flex gap-3">
                      <button
                        onClick={() => setEditingWarning(null)}
                        className="flex-1 px-4 py-3 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 font-semibold transition-colors"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => {
                          if (editingWarning.reason.trim()) {
                            // TODO: Call API to update warning
                            alert('Edit warning functionality will be implemented');
                            setEditingWarning(null);
                          }
                        }}
                        disabled={!editingWarning.reason.trim()}
                        className="flex-1 px-4 py-3 bg-gradient-to-r from-blue-600 to-cyan-600 text-white rounded-xl hover:from-blue-700 hover:to-cyan-700 font-semibold transition-all shadow-md hover:shadow-lg disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed"
                      >
                        Save Changes
                      </button>
                    </div>
                  </div>
                </div>
              )}
              
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
                        <div className="space-y-4">
                          {filteredActivities.map((activity) => {
                            // For collection history with grouped interactions, show timeline card
                            if (activeActivityTab === 'collection-history' && activity.interactions && activity.interactions.length > 0) {
                              return (
                                <div key={activity.id} className={`rounded-xl border-2 p-5 shadow-sm ${
                                  activity.interactionType === 'collected' ? 'bg-green-50 border-green-300' :
                                  activity.interactionType === 'cancelled' ? 'bg-red-50 border-red-300' :
                                  activity.interactionType === 'expired' ? 'bg-orange-50 border-orange-300' :
                                  'bg-blue-50 border-blue-300'
                                }`}>
                                  {/* Header with final status */}
                                  <div className="flex items-center justify-between mb-4">
                                    <h5 className="text-base font-bold text-gray-900">{activity.title}</h5>
                                    <span className="text-sm text-gray-600 font-medium">{activity.numberOfBottles} bottles, {activity.numberOfCans} cans</span>
                                  </div>
                                  
                                  {/* Timeline of interactions inside the card */}
                                  <div className="space-y-3 pl-4 border-l-4 border-gray-300">
                                    {activity.interactions.map((interaction: any, idx: number) => (
                                      <div key={idx} className="relative pl-6">
                                        {/* Timeline dot */}
                                        <div className={`absolute left-0 top-1.5 -translate-x-1/2 w-3 h-3 rounded-full border-2 border-white shadow-sm ${
                                          interaction.type === 'accepted' ? 'bg-blue-500' :
                                          interaction.type === 'collected' ? 'bg-green-500' :
                                          interaction.type === 'cancelled' ? 'bg-red-500' :
                                          interaction.type === 'expired' ? 'bg-orange-500' :
                                          'bg-gray-500'
                                        }`}></div>
                                        
                                        <div className="bg-white/80 rounded-lg p-3 shadow-sm">
                                          <div className="flex items-center justify-between mb-1">
                                            <span className="text-sm font-semibold text-gray-900">
                                              {interaction.type === 'accepted' ? '📋 Accepted' :
                                               interaction.type === 'collected' ? '✅ Collected' :
                                               interaction.type === 'cancelled' ? '❌ Cancelled' :
                                               interaction.type === 'expired' ? '⏰ Expired' : interaction.type}
                                            </span>
                                            <span className="text-xs text-gray-600">{formatDate(interaction.time)}</span>
                                          </div>
                                          {interaction.reason && (
                                            <p className="text-xs text-red-700 font-medium mt-1">Reason: {interaction.reason}</p>
                                          )}
                                          {interaction.notes && (
                                            <p className="text-xs text-gray-600 mt-1">{interaction.notes}</p>
                                          )}
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              );
                            }
                            
                            // For drops created or simple activities, show simple timeline
                            return (
                              <div key={activity.id} className="flex items-start space-x-3 p-3 bg-surface rounded-lg">
                                <div className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center">
                                  <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                                    <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                                    </svg>
                                  </div>
                                </div>
                                <div className="flex-1 min-w-0">
                                  <div className="flex items-center justify-between">
                                    <p className="text-sm font-medium text-text-primary">{activity.title}</p>
                                    <span className="text-xs text-text-secondary">{formatDate(activity.timestamp)}</span>
                                  </div>
                                  <p className="text-xs text-text-secondary mt-1">{activity.description}</p>
                                  
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
                                </div>
                              </div>
                            );
                          })}
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
  const [stats, setStats] = useState<any>(null);
  const [timeBasedStats, setTimeBasedStats] = useState<any>(null);
  const [successRate, setSuccessRate] = useState<any>(null);
  const [collectorLeaderboard, setCollectorLeaderboard] = useState<any[]>([]);
  const [householdRankings, setHouseholdRankings] = useState<any[]>([]);
  const [oldDrops, setOldDrops] = useState<any[]>([]);
  const [selectedOldDrops, setSelectedOldDrops] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [showOldDropsModal, setShowOldDropsModal] = useState(false);
  
  // Drops list state
  const [dropsList, setDropsList] = useState<any[]>([]);
  const [dropsLoading, setDropsLoading] = useState(false);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [showWithAttempts, setShowWithAttempts] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [dropsActiveTab, setDropsActiveTab] = useState('all-drops');
  const [reportedDrops, setReportedDrops] = useState([]);
  const [loadingReportedDrops, setLoadingReportedDrops] = useState(false);
  const [flaggedDrops, setFlaggedDrops] = useState([]);
  const [loadingFlaggedDrops, setLoadingFlaggedDrops] = useState(false);
  const [collectedDrops, setCollectedDrops] = useState([]);
  const [loadingCollectedDrops, setLoadingCollectedDrops] = useState(false);
  const [staleDrops, setStaleDrops] = useState([]);
  const [loadingStaleDrops, setLoadingStaleDrops] = useState(false);
  const [censoredDrops, setCensoredDrops] = useState([]);
  const [loadingCensoredDrops, setLoadingCensoredDrops] = useState(false);
  const [showCensorModal, setShowCensorModal] = useState(false);
  const [censorTargetDropId, setCensorTargetDropId] = useState<string | null>(null);
  const [selectedCensorReason, setSelectedCensorReason] = useState<string>('inappropriate_image');
  const [censorNotes, setCensorNotes] = useState<string>('');
  
  // Drop details modal state
  const [selectedDrop, setSelectedDrop] = useState<any>(null);
  const [showDropDetails, setShowDropDetails] = useState(false);
  const [dropDetailsLoading, setDropDetailsLoading] = useState(false);
  const [dropDetailsContext, setDropDetailsContext] = useState<'default' | 'flagged'>('default');

  useEffect(() => {
    fetchAllData();
    fetchDropsList();
    // Load counts for all tabs on initial load
    fetchReportedDrops();
    fetchFlaggedDrops();
    fetchCollectedDrops();
    fetchStaleDrops();
    fetchCensoredDrops();
  }, []);

  useEffect(() => {
    fetchDropsList();
  }, [selectedStatus, searchQuery, showWithAttempts, currentPage]);

  useEffect(() => {
    if (dropsActiveTab === 'reported-drops') {
      fetchReportedDrops();
    }
    if (dropsActiveTab === 'flagged-drops') {
      fetchFlaggedDrops();
    }
    if (dropsActiveTab === 'collected-drops') {
      fetchCollectedDrops();
    }
    if (dropsActiveTab === 'stale-drops') {
      fetchStaleDrops();
    }
    if (dropsActiveTab === 'censored-drops') {
      fetchCensoredDrops();
    }
  }, [dropsActiveTab]);

  // Reset to page 1 when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedStatus, searchQuery, showWithAttempts]);

  const fetchDropsList = async () => {
    try {
      setDropsLoading(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      
      const params = new URLSearchParams();
      if (selectedStatus) params.append('status', selectedStatus);
      if (searchQuery) params.append('search', searchQuery);
      if (showWithAttempts) params.append('hasAttempts', 'true');
      params.append('page', currentPage.toString());
      params.append('limit', '10');
      
      console.log('📋 Fetching drops list with params:', params.toString());
      
      const response = await axios.get(
        `${API_URL}/admin/drops-management/list?${params.toString()}`,
        config
      );
      
      console.log('📋 Drops list response:', response.data);
      console.log('📋 First drop sample:', response.data.drops?.[0]);
      console.log('📋 Total drops returned:', response.data.drops?.length);
      
      setDropsList(response.data.drops || []);
      setTotalPages(response.data.totalPages || 1);
    } catch (error: any) {
      console.error('❌ Error fetching drops list:', error);
      console.error('❌ Error response:', error.response?.data);
      console.error('❌ Error status:', error.response?.status);
    } finally {
      setDropsLoading(false);
    }
  };

  const fetchReportedDrops = async () => {
    try {
      setLoadingReportedDrops(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      
      console.log('📋 Fetching reported drops...');
      
      const response = await axios.get(
        `${API_URL}/admin/drops-management/reported`,
        config
      );
      
      console.log('📋 Reported drops response:', response.data);
      console.log('📋 Total reported drops:', response.data.reports?.length);
      
      setReportedDrops(response.data.reports || []);
    } catch (error: any) {
      console.error('❌ Error fetching reported drops:', error);
      console.error('❌ Error details:', error.response?.data);
    } finally {
      setLoadingReportedDrops(false);
    }
  };

  const fetchFlaggedDrops = async () => {
    try {
      setLoadingFlaggedDrops(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      console.log('📋 Fetching flagged drops...');

      const response = await axios.get(
        `${API_URL}/admin/drops-management/flagged`,
        config
      );

      console.log('📋 Flagged drops response:', response.data);
      console.log('📋 Total flagged drops:', response.data.drops?.length);

      setFlaggedDrops(response.data.drops || []);
    } catch (error: any) {
      console.error('❌ Error fetching flagged drops:', error);
      console.error('❌ Error details:', error.response?.data);
    } finally {
      setLoadingFlaggedDrops(false);
    }
  };

  const fetchCollectedDrops = async () => {
    try {
      setLoadingCollectedDrops(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      console.log('📋 Fetching collected drops...');

      const response = await axios.get(
        `${API_URL}/admin/drops?status=collected&limit=1000`,
        config
      );

      console.log('📋 Collected drops response:', response.data);
      console.log('📋 Total collected drops:', response.data.drops?.length);
      
      // Debug: Check the first drop's data structure
      if (response.data.drops && response.data.drops.length > 0) {
        const firstDrop = response.data.drops[0];
        console.log('📋 First collected drop data:', {
          id: firstDrop._id,
          userId: firstDrop.userId,
          collectedBy: firstDrop.collectedBy,
          status: firstDrop.status,
          collectedAt: firstDrop.collectedAt
        });
      }

      setCollectedDrops(response.data.drops || []);
    } catch (error: any) {
      console.error('❌ Error fetching collected drops:', error);
      console.error('❌ Error details:', error.response?.data);
    } finally {
      setLoadingCollectedDrops(false);
    }
  };

  const fetchStaleDrops = async () => {
    try {
      setLoadingStaleDrops(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      console.log('📋 Fetching stale drops...');

      const response = await axios.get(
        `${API_URL}/admin/drops-management/stale?limit=1000`,
        config
      );

      console.log('📋 Stale drops response:', response.data);
      console.log('📋 Total stale drops:', response.data.drops?.length);

      setStaleDrops(response.data.drops || []);
    } catch (error: any) {
      console.error('❌ Error fetching stale drops:', error);
      console.error('❌ Error details:', error.response?.data);
    } finally {
      setLoadingStaleDrops(false);
    }
  };

  const fetchCensoredDrops = async () => {
    try {
      setLoadingCensoredDrops(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      console.log('📋 Fetching censored drops...');

      const response = await axios.get(
        `${API_URL}/admin/drops?isCensored=true&limit=1000`,
        config
      );

      console.log('📋 Censored drops response:', response.data);
      console.log('📋 Total censored drops:', response.data.drops?.length);

      setCensoredDrops(response.data.drops || []);
    } catch (error: any) {
      console.error('❌ Error fetching censored drops:', error);
      console.error('❌ Error details:', error.response?.data);
    } finally {
      setLoadingCensoredDrops(false);
    }
  };

  const fetchAllData = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      const [
        statsRes,
        timeRes,
        successRes,
        collectorRes,
        householdRes,
      ] = await Promise.all([
        axios.get(`${API_URL}/admin/drops-management/stats`, config),
        axios.get(`${API_URL}/admin/drops-management/analytics/time-based`, config),
        axios.get(`${API_URL}/admin/drops-management/analytics/success-rate`, config),
        axios.get(`${API_URL}/admin/drops-management/performance/collector-leaderboard?limit=5`, config),
        axios.get(`${API_URL}/admin/drops-management/performance/household-rankings?limit=5`, config),
      ]);

      setStats(statsRes.data.stats);
      setTimeBasedStats(timeRes.data.stats);
      setSuccessRate(successRes.data.stats);
      setCollectorLeaderboard(collectorRes.data.leaderboard);
      setHouseholdRankings(householdRes.data.rankings);
    } catch (error) {
      console.error('Error fetching drops data:', error);
    } finally {
      setLoading(false);
    }
  };

  const analyzeOldDrops = async () => {
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      const response = await axios.get(`${API_URL}/admin/drops-management/analyze-old`, config);
      setOldDrops(response.data.drops);
      setShowOldDropsModal(true);
    } catch (error) {
      console.error('Error analyzing old drops:', error);
    }
  };

  const hideSelectedDrops = async () => {
    if (selectedOldDrops.length === 0) return;
    
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      await axios.post(`${API_URL}/admin/drops-management/hide-old`, 
        { dropIds: selectedOldDrops }, 
        config
      );
      
      alert(`${selectedOldDrops.length} drops hidden successfully and users notified!`);
      setShowOldDropsModal(false);
      setSelectedOldDrops([]);
      fetchAllData();
    } catch (error) {
      console.error('Error hiding drops:', error);
      alert('Error hiding drops');
    }
  };

  const viewDropDetails = async (dropId: string) => {
    try {
      setDropDetailsLoading(true);
      setShowDropDetails(true);
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      const response = await axios.get(`${API_URL}/admin/drops-management/details/${dropId}`, config);
      console.log('🔍 Drop details response:', response.data);
      console.log('🔍 Image URL from drop:', response.data.drop?.imageUrl);
      console.log('🔍 Collection attempts:', response.data.collectionAttempts);
      console.log('🔍 First attempt dropSnapshot:', response.data.collectionAttempts?.[0]?.dropSnapshot);
      console.log('🔍 Image URL from snapshot:', response.data.collectionAttempts?.[0]?.dropSnapshot?.imageUrl);
      console.log('🔍 Full drop object:', response.data.drop);
      console.log('🔍 Drop keys:', Object.keys(response.data.drop || {}));
      setSelectedDrop(response.data);
    } catch (error) {
      console.error('Error fetching drop details:', error);
      alert('Unable to load drop details. This drop may have been deleted or is no longer available.');
      setShowDropDetails(false);
    } finally {
      setDropDetailsLoading(false);
    }
  };

  const flagDrop = async (dropId: string) => {
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      await axios.put(`${API_URL}/admin/drops-management/flag/${dropId}`, { reason: 'Flagged by admin' }, config);
      alert('Drop flagged successfully!');
      setShowDropDetails(false);
      fetchDropsList();
      fetchAllData();
    } catch (error) {
      console.error('Error flagging drop:', error);
      alert('Error flagging drop');
    }
  };

  const unflagDrop = async (dropId: string) => {
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      await axios.put(`${API_URL}/admin/drops-management/unflag/${dropId}`, {}, config);
      alert('Flag removed successfully!');
      setShowDropDetails(false);
      fetchDropsList();
      fetchAllData();
    } catch (error) {
      console.error('Error unflagging drop:', error);
      alert('Error unflagging drop');
    }
  };

  const openCensorModal = (dropId: string) => {
    setCensorTargetDropId(dropId);
    setSelectedCensorReason('inappropriate_image');
    setCensorNotes('');
    setShowCensorModal(true);
  };

  const submitCensor = async () => {
    if (!censorTargetDropId) return;
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      const reasonPayload = censorNotes?.trim()
        ? `${selectedCensorReason}: ${censorNotes.trim()}`
        : selectedCensorReason;
      await axios.put(`${API_URL}/admin/drops-management/censor/${censorTargetDropId}`, { reason: reasonPayload }, config);
      setShowCensorModal(false);
      setCensorTargetDropId(null);
      alert('Drop image censored, user notified, and warning added!');
      setShowDropDetails(false);
      fetchDropsList();
      fetchAllData();
    } catch (error) {
      console.error('Error censoring drop:', error);
      alert('Error censoring drop');
    }
  };

  const deleteDrop = async (dropId: string) => {
    if (!confirm('Are you sure you want to permanently delete this drop? This action cannot be undone.')) return;
    
    try {
      const token = localStorage.getItem('admin_token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      await axios.put(`${API_URL}/admin/drops-management/delete/${dropId}`, {}, config);
      alert('Drop deleted successfully and user notified!');
      setShowDropDetails(false);
      fetchDropsList();
      fetchAllData();
    } catch (error) {
      console.error('Error deleting drop:', error);
      alert('Error deleting drop');
    }
  };

  if (loading || !stats) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  const COLORS = {
    pending: '#FFC107',
    collected: '#4CAF50',
    cancelled: '#9E9E9E',
    expired: '#FF5722',
  };

  const statusData = [
    { name: 'Pending', value: stats.dropsByStatus['pending'] || 0, color: COLORS.pending },
    { name: 'Collected', value: stats.dropsByStatus['collected'] || 0, color: COLORS.collected },
    { name: 'Cancelled', value: stats.dropsByStatus['cancelled'] || 0, color: COLORS.cancelled },
    { name: 'Expired', value: stats.dropsByStatus['expired'] || 0, color: COLORS.expired },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Drops Management</h2>
        <p className="text-gray-600">Monitor, analyze, and manage all drops in the system</p>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setDropsActiveTab('all-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'all-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            All Drops
          </button>
          <button
            onClick={() => setDropsActiveTab('reported-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'reported-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Reported Drops ({reportedDrops.length})
          </button>
          <button
            onClick={() => setDropsActiveTab('flagged-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'flagged-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Flagged Drops ({flaggedDrops.length})
          </button>
          <button
            onClick={() => setDropsActiveTab('collected-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'collected-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Collected Drops ({collectedDrops.length})
          </button>
          <button
            onClick={() => setDropsActiveTab('stale-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'stale-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Stale Drops ({staleDrops.length})
          </button>
          <button
            onClick={() => setDropsActiveTab('censored-drops')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              dropsActiveTab === 'censored-drops'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Censored Drops ({censoredDrops.length})
          </button>
        </nav>
      </div>

      {/* Tab Content */}
      {dropsActiveTab === 'all-drops' && (
        <>
          {/* Stats Overview Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Total Drops */}
        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-blue-500 p-3 rounded-lg text-white">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
              </svg>
            </div>
            {timeBasedStats && (
              <div className={`flex items-center gap-1 text-sm ${timeBasedStats.weekChange > 0 ? 'text-green-600' : 'text-red-600'}`}>
                {timeBasedStats.weekChange > 0 ? '↑' : '↓'}
                {Math.abs(timeBasedStats.weekChange).toFixed(1)}%
              </div>
            )}
          </div>
          <h3 className="text-gray-600 text-sm font-medium mb-1">Total Drops</h3>
          <p className="text-3xl font-bold text-gray-900">{stats.totalDrops.toLocaleString()}</p>
        </div>

        {/* Active Drops */}
        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-green-500 p-3 rounded-lg text-white">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>
          <h3 className="text-gray-600 text-sm font-medium mb-1">Active Drops</h3>
          <p className="text-3xl font-bold text-gray-900">{stats.activeDrops.toLocaleString()}</p>
        </div>

        {/* Flagged Drops */}
        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-orange-500 p-3 rounded-lg text-white">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
          </div>
          <h3 className="text-gray-600 text-sm font-medium mb-1">Flagged Drops</h3>
          <p className="text-3xl font-bold text-gray-900">{stats.flaggedDrops.toLocaleString()}</p>
        </div>

        {/* Old Drops */}
        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-red-500 p-3 rounded-lg text-white">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          </div>
          <h3 className="text-gray-600 text-sm font-medium mb-1">Old Drops (&gt;3 days)</h3>
          <p className="text-3xl font-bold text-gray-900">{stats.oldDrops.toLocaleString()}</p>
          <button
            onClick={analyzeOldDrops}
            className="mt-3 w-full bg-white text-red-600 border border-red-600 px-4 py-2 rounded-lg hover:bg-red-50 transition-colors text-sm font-medium"
          >
            Analyze Old Drops
          </button>
        </div>
      </div>

      {/* Success Rate & Status Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Success Rate */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <h3 className="text-xl font-semibold mb-4 text-gray-900">Drop Success Rate</h3>
          {successRate && (
            <div className="space-y-4">
              <div className="flex justify-around">
                <div className="text-center">
                  <p className="text-3xl font-bold text-green-600">{successRate.successRate.toFixed(1)}%</p>
                  <p className="text-sm text-gray-600">Collected</p>
                </div>
                <div className="text-center">
                  <p className="text-3xl font-bold text-gray-600">{successRate.cancellationRate.toFixed(1)}%</p>
                  <p className="text-sm text-gray-600">Cancelled</p>
                </div>
                <div className="text-center">
                  <p className="text-3xl font-bold text-orange-600">{successRate.expirationRate.toFixed(1)}%</p>
                  <p className="text-sm text-gray-600">Expired</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Status Distribution */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <h3 className="text-xl font-semibold mb-4 text-gray-900">Status Distribution</h3>
          <div className="space-y-2">
            {statusData.map((status) => (
              <div key={status.name} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 rounded" style={{ backgroundColor: status.color }}></div>
                  <span className="text-sm text-gray-700">{status.name}</span>
                </div>
                <span className="text-sm font-semibold text-gray-900">{status.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Leaderboards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Collector Leaderboard */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
              🏆 Top Collectors
            </h3>
          </div>
          <div className="space-y-3">
            {collectorLeaderboard.map((collector: any, index: number) => (
              <div key={collector.collectorId} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-white ${
                    index === 0 ? 'bg-yellow-500' : index === 1 ? 'bg-gray-400' : index === 2 ? 'bg-orange-600' : 'bg-gray-300'
                  }`}>
                    {index + 1}
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{collector.collectorName}</p>
                    <p className="text-sm text-gray-500">{collector.collectorEmail}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-green-600">{collector.totalCollections}</p>
                  <p className="text-xs text-gray-500">collections</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Household Rankings */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
              👥 Top Households
            </h3>
          </div>
          <div className="space-y-3">
            {householdRankings.map((household: any, index: number) => (
              <div key={household.userId} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-white ${
                    index === 0 ? 'bg-yellow-500' : index === 1 ? 'bg-gray-400' : index === 2 ? 'bg-orange-600' : 'bg-gray-300'
                  }`}>
                    {index + 1}
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{household.userName}</p>
                    <p className="text-sm text-gray-500">{household.totalDrops} drops</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-green-600">{household.successRate}%</p>
                  <p className="text-xs text-gray-500">success rate</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Drops List Table */}
      <div className="bg-white rounded-xl shadow-md p-6">
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-xl font-semibold text-gray-900">All Drops</h3>
            <div className="flex gap-3">
              {/* Status Filter */}
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              >
                <option value="">All Statuses</option>
                <option value="pending">Pending</option>
                <option value="accepted">Accepted</option>
                <option value="collected">Collected</option>
                <option value="cancelled">Cancelled</option>
                <option value="expired">Expired</option>
              </select>
              
              {/* Search */}
              <input
                type="text"
                placeholder="Search by ID or notes..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent w-64"
              />
            </div>
          </div>
          
          {/* Additional Filters */}
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
              <input
                type="checkbox"
                checked={showWithAttempts}
                onChange={(e) => setShowWithAttempts(e.target.checked)}
                className="w-4 h-4 text-primary rounded focus:ring-primary"
              />
              <span>Only show drops with collection attempts</span>
            </label>
          </div>
        </div>

        {dropsLoading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Items</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Age</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {dropsList.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="px-6 py-12 text-center text-gray-500">
                        No drops found
                      </td>
                    </tr>
                  ) : (
                    dropsList.map((drop: any, index: number) => (
                      <tr key={drop.id || drop._id || `drop-${index}`} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                          {(drop.id || drop._id)?.substring(0, 8) || 'N/A'}...
                        </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">
                          {typeof drop.userId === 'object' ? drop.userId?.name : 'User ID: ' + (drop.userId?.substring(0, 8) || 'Unknown')}
                        </div>
                        <div className="text-sm text-gray-500">
                          {typeof drop.userId === 'object' ? drop.userId?.email : ''}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        📍 {drop.location?.latitude?.toFixed(2)}, {drop.location?.longitude?.toFixed(2)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <div className="flex items-center gap-3">
                          <div className="flex items-center gap-1">
                            <img src="/water-bottle.png" alt="Bottles" className="w-4 h-4" />
                            <span>{drop.numberOfBottles}</span>
                          </div>
                          <span>•</span>
                          <div className="flex items-center gap-1">
                            <img src="/can.png" alt="Cans" className="w-4 h-4" />
                            <span>{drop.numberOfCans}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          drop.status === 'collected' ? 'bg-green-100 text-green-800' :
                          drop.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                          drop.status === 'accepted' ? 'bg-blue-100 text-blue-800' :
                          drop.status === 'cancelled' ? 'bg-gray-100 text-gray-800' :
                          'bg-orange-100 text-orange-800'
                        }`}>
                          {drop.status}
                        </span>
                        {drop.isSuspicious && (
                          <span className="ml-2 px-2 py-1 bg-red-100 text-red-800 text-xs rounded-full">⚠️ Flagged</span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(drop.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {(() => {
                          const created = new Date(drop.createdAt);
                          const now = new Date();
                          const days = Math.floor((now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24));
                          return days === 0 ? 'Today' : `${days}d ago`;
                        })()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                          onClick={() => { setDropDetailsContext('default'); viewDropDetails(drop.id || drop._id); }}
                          className="text-primary hover:text-primary-dark font-medium"
                        >
                          View Details →
                        </button>
                      </td>
                    </tr>
                  )))}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between mt-6 pt-4 border-t border-gray-200">
              <p className="text-sm text-gray-700">
                Page {currentPage} of {totalPages}
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                  disabled={currentPage === 1}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Previous
                </button>
                <button
                  onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                  disabled={currentPage === totalPages}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                </button>
              </div>
            </div>
          </>
        )}
      </div>
        </>
      )}

      {/* Reported Drops Tab */}
      {dropsActiveTab === 'reported-drops' && (
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="mb-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Reported Drops</h3>
            <p className="text-gray-600">Review and take action on reported drops</p>
          </div>

          {loadingReportedDrops ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : reportedDrops.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-gray-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Reported Drops</h3>
              <p className="text-gray-500">All reports have been reviewed or there are no pending reports.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Report ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Drop Info</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reporter</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Details</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reported At</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {reportedDrops.map((report: any, index: number) => (
                    <tr key={report._id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                        {report._id?.substring(0, 8)}...
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {report.drop?.imageUrl && (
                            <img
                              className="h-10 w-10 rounded-lg object-cover mr-3"
                              src={report.drop.imageUrl}
                              alt="Drop image"
                            />
                          )}
                          <div>
                            <div className="text-sm font-medium text-gray-900">
                              {report.drop?.numberOfBottles || 0} bottles, {report.drop?.numberOfCans || 0} cans
                            </div>
                            <div className="text-sm text-gray-500">
                              Status: {report.drop?.status || 'Unknown'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">
                          {report.reporter?.name || 'Unknown'}
                        </div>
                        <div className="text-sm text-gray-500">
                          {report.reporter?.email || 'N/A'}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          {report.reason?.replace('_', ' ').toUpperCase() || 'Unknown'}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900 max-w-xs truncate">
                          {report.details || 'No additional details'}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(report.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                          onClick={() => { setDropDetailsContext('default'); viewDropDetails(report.dropId); }}
                          className="text-primary hover:text-primary-dark"
                        >
                          View Drop
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Flagged Drops Tab */}
      {dropsActiveTab === 'flagged-drops' && (
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="mb-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Flagged Drops</h3>
            <p className="text-gray-600">Drops marked as suspicious (e.g., cancelled by 3 different collectors)</p>
          </div>

          {loadingFlaggedDrops ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : flaggedDrops.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-gray-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Flagged Drops</h3>
              <p className="text-gray-500">There are currently no flagged drops.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cancels</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {flaggedDrops.map((drop: any, index: number) => (
                    <tr key={drop._id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                        {(drop._id?.toString?.() || drop.id || '').toString().slice(0, 8)}...
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{drop.userId?.name || 'Unknown'}</div>
                        <div className="text-sm text-gray-500">{drop.userId?.email || 'N/A'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                          {drop.suspiciousReason || 'Flagged'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {drop.status}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {drop.cancellationCount || 0}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {drop.createdAt ? new Date(drop.createdAt).toLocaleDateString() : '—'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                          onClick={() => { setDropDetailsContext('flagged'); viewDropDetails(drop._id || drop.id); }}
                          className="text-primary hover:text-primary-dark"
                        >
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Collected Drops Tab */}
      {dropsActiveTab === 'collected-drops' && (
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="mb-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Collected Drops</h3>
            <p className="text-gray-600">Drops that have been successfully collected by collectors</p>
          </div>

          {loadingCollectedDrops ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : collectedDrops.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-gray-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Collected Drops</h3>
              <p className="text-gray-500">There are currently no collected drops.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Image</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Items</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Collected By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Collected At</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {collectedDrops.map((drop: any, index: number) => (
                    <tr key={drop._id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                        {(drop._id?.toString?.() || drop.id || '').toString().slice(0, 8)}...
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{drop.userId?.name || 'Unknown'}</div>
                        <div className="text-sm text-gray-500">{drop.userId?.email || 'N/A'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {drop.imageUrl ? (
                          <img
                            className="h-10 w-10 rounded-lg object-cover"
                            src={drop.imageUrl}
                            alt="Drop image"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="%23e5e7eb" width="100" height="100"/><text x="50%" y="50%" fill="%236b7280" text-anchor="middle" font-size="12">No Image</text></svg>';
                            }}
                          />
                        ) : (
                          <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                            <span className="text-xs text-gray-500">No Image</span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{drop.numberOfBottles || 0} bottles, {drop.numberOfCans || 0} cans</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{drop.collectedBy?.name || 'Unknown'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(drop.collectedAt || drop.updatedAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => {
                            setDropDetailsContext('default');
                            viewDropDetails(drop._id || drop.id);
                          }}
                          className="text-primary hover:text-primary-dark"
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
      )}

      {/* Stale Drops Tab */}
      {dropsActiveTab === 'stale-drops' && (
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="mb-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Stale Drops</h3>
            <p className="text-gray-600">Drops that have expired and are no longer available for collection</p>
          </div>

          {loadingStaleDrops ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : staleDrops.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-gray-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Stale Drops</h3>
              <p className="text-gray-500">There are currently no stale drops.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Image</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Items</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expired</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {staleDrops.map((drop: any, index: number) => (
                    <tr key={drop._id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                        {(drop._id?.toString?.() || drop.id || '').toString().slice(0, 8)}...
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{drop.userId?.name || 'Unknown'}</div>
                        <div className="text-sm text-gray-500">{drop.userId?.email || 'N/A'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {drop.imageUrl ? (
                          <img
                            className="h-10 w-10 rounded-lg object-cover"
                            src={drop.imageUrl}
                            alt="Drop image"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="%23e5e7eb" width="100" height="100"/><text x="50%" y="50%" fill="%236b7280" text-anchor="middle" font-size="12">No Image</text></svg>';
                            }}
                          />
                        ) : (
                          <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                            <span className="text-xs text-gray-500">No Image</span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{drop.numberOfBottles || 0} bottles, {drop.numberOfCans || 0} cans</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(drop.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(drop.updatedAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => {
                            setDropDetailsContext('default');
                            viewDropDetails(drop._id || drop.id);
                          }}
                          className="text-primary hover:text-primary-dark"
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
      )}

      {/* Censored Drops Tab */}
      {dropsActiveTab === 'censored-drops' && (
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="mb-6">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Censored Drops</h3>
            <p className="text-gray-600">Drops that have been censored due to inappropriate content</p>
          </div>

          {loadingCensoredDrops ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : censoredDrops.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-gray-400 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L18.364 5.636" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Censored Drops</h3>
              <p className="text-gray-500">There are currently no censored drops.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Image</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Censored By</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Censored At</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {censoredDrops.map((drop: any, index: number) => (
                    <tr key={drop._id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">
                        {(drop._id?.toString?.() || drop.id || '').toString().slice(0, 8)}...
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{drop.userId?.name || 'Unknown'}</div>
                        <div className="text-sm text-gray-500">{drop.userId?.email || 'N/A'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {drop.imageUrl ? (
                          <img
                            className="h-10 w-10 rounded-lg object-cover"
                            src={drop.imageUrl}
                            alt="Drop image"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="%23e5e7eb" width="100" height="100"/><text x="50%" y="50%" fill="%236b7280" text-anchor="middle" font-size="12">No Image</text></svg>';
                            }}
                          />
                        ) : (
                          <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                            <span className="text-xs text-gray-500">No Image</span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          {drop.censorReason || 'Inappropriate Content'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{drop.censoredBy?.name || 'Admin'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(drop.censoredAt || drop.updatedAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => {
                            setDropDetailsContext('default');
                            viewDropDetails(drop._id || drop.id);
                          }}
                          className="text-primary hover:text-primary-dark"
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
      )}

      {/* Old Drops Modal */}
      {showOldDropsModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-6xl w-full max-h-[90vh] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900">Old Drops Analysis (&gt;3 days)</h2>
                <button
                  onClick={() => setShowOldDropsModal(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
              <p className="text-gray-600 mt-2">Found {oldDrops.length} drops older than 3 days that have not been collected</p>
            </div>
            
            <div className="flex-1 overflow-auto p-6">
              <div className="space-y-3">
                {oldDrops.map((drop: any) => (
                  <div key={drop._id} className="flex items-center gap-4 p-4 border border-gray-200 rounded-lg hover:border-red-300 transition-colors">
                    <input
                      type="checkbox"
                      checked={selectedOldDrops.includes(drop._id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedOldDrops([...selectedOldDrops, drop._id]);
                        } else {
                          setSelectedOldDrops(selectedOldDrops.filter(id => id !== drop._id));
                        }
                      }}
                      className="w-5 h-5 text-red-600 rounded"
                    />
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-2">
                        <p className="font-medium text-gray-900">{drop.userId?.name || 'Unknown User'}</p>
                        <span className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm font-medium">
                          {drop.ageInDays} days old
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mb-2">{drop.userId?.email}</p>
                      <p className="text-sm text-gray-500 flex items-center gap-2">
                        <span>📍 {drop.location?.latitude?.toFixed(4)}, {drop.location?.longitude?.toFixed(4)}</span>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <img src="/water-bottle.png" alt="Bottles" className="w-4 h-4 inline" />
                          {drop.numberOfBottles} bottles
                        </span>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <img src="/can.png" alt="Cans" className="w-4 h-4 inline" />
                          {drop.numberOfCans} cans
                        </span>
                      </p>
                      {drop.notes && <p className="text-sm text-gray-500 mt-1">Note: {drop.notes}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 bg-gray-50">
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-600">
                  {selectedOldDrops.length} of {oldDrops.length} selected
                </p>
                <div className="flex gap-3">
                  <button
                    onClick={() => setSelectedOldDrops(oldDrops.map((d: any) => d._id))}
                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    Select All
                  </button>
                  <button
                    onClick={() => setSelectedOldDrops([])}
                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    Clear
                  </button>
                  <button
                    onClick={hideSelectedDrops}
                    disabled={selectedOldDrops.length === 0}
                    className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-medium"
                  >
                    Hide Selected & Notify Users
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Censor Reason Modal */}
      {showCensorModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Censor Image</h3>
              <button onClick={() => setShowCensorModal(false)} className="h-8 w-8 inline-flex items-center justify-center rounded-full bg-gray-100 text-gray-700 hover:bg-gray-200 hover:text-gray-900">
                ✕
              </button>
            </div>
            <div className="px-6 py-4 space-y-4">
              <p className="text-sm text-gray-600">Select a reason for censoring this drop image. This will hide the drop from collectors and add a warning to the user's account.</p>
              <div className="space-y-2">
                <label className="flex items-center gap-3">
                  <input
                    type="radio"
                    className="h-4 w-4 text-primary"
                    checked={selectedCensorReason === 'inappropriate_image'}
                    onChange={() => setSelectedCensorReason('inappropriate_image')}
                  />
                  <span className="text-sm text-gray-800">Inappropriate image</span>
                </label>
                <label className="flex items-center gap-3">
                  <input
                    type="radio"
                    className="h-4 w-4 text-primary"
                    checked={selectedCensorReason === 'fake_drop'}
                    onChange={() => setSelectedCensorReason('fake_drop')}
                  />
                  <span className="text-sm text-gray-800">Fake drop</span>
                </label>
                <label className="flex items-center gap-3">
                  <input
                    type="radio"
                    className="h-4 w-4 text-primary"
                    checked={selectedCensorReason === 'amount_mismatch'}
                    onChange={() => setSelectedCensorReason('amount_mismatch')}
                  />
                  <span className="text-sm text-gray-800">Amount of bottles does not match</span>
                </label>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Notes (optional)</label>
                <textarea
                  value={censorNotes}
                  onChange={(e) => setCensorNotes(e.target.value)}
                  rows={3}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                  placeholder="Add more context for the user..."
                />
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
              <button
                onClick={() => setShowCensorModal(false)}
                className="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={submitCensor}
                className="px-4 py-2 rounded-lg bg-purple-600 text-white hover:bg-purple-700"
              >
                Censor Image
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Drop Details Modal */}
      {showDropDetails && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-40 p-4 overflow-y-auto">
          <div className="bg-white rounded-xl shadow-2xl max-w-6xl w-full my-8 relative">
            {/* Header */}
            <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-primary to-primary-dark">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-white">Drop Details</h2>
                <button
                  onClick={() => setShowDropDetails(false)}
                  className="h-9 w-9 inline-flex items-center justify-center rounded-full bg-white/20 text-white hover:bg-white/30"
                  aria-label="Close"
                >
                  ✕
                </button>
              </div>
            </div>

            {dropDetailsLoading ? (
              <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
              </div>
            ) : selectedDrop ? (
              <div className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
                {/* Drop Information Grid */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {/* Left Column */}
                  <div className="space-y-6">
                    {/* Drop Image */}
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="font-semibold text-gray-900 mb-3">Drop Image</h3>
                      {(() => {
                        // Use collection attempt's dropSnapshot if available, otherwise fall back to direct drop data
                        const imageUrl = selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.imageUrl || selectedDrop.drop?.imageUrl;
                        console.log('🔍 Image source check:', {
                          fromSnapshot: selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.imageUrl,
                          fromDrop: selectedDrop.drop?.imageUrl,
                          finalImageUrl: imageUrl,
                          hasCollectionAttempts: selectedDrop.collectionAttempts?.length > 0,
                          collectionAttemptsLength: selectedDrop.collectionAttempts?.length || 0
                        });
                        
                        return imageUrl ? (
                          <img 
                            src={imageUrl} 
                            alt="Drop" 
                            className="w-full h-64 object-cover rounded-lg"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300"><rect fill="%23e5e7eb" width="400" height="300"/><text x="50%" y="50%" fill="%236b7280" text-anchor="middle" font-size="20">Image Failed to Load</text></svg>';
                            }}
                          />
                        ) : (
                          <div className="w-full h-64 bg-gray-200 rounded-lg flex items-center justify-center">
                            <div className="text-center">
                              <div className="text-gray-500 text-lg mb-2">📷</div>
                              <div className="text-gray-500">No image available</div>
                            </div>
                          </div>
                        );
                      })()}
                    </div>

                    {/* Drop Details */}
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="font-semibold text-gray-900 mb-3">Drop Information</h3>
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Drop ID:</span>
                          <span className="font-mono font-medium text-xs">{selectedDrop.drop?.id || selectedDrop.drop?._id}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Status:</span>
                          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                            selectedDrop.drop?.status === 'collected' ? 'bg-green-100 text-green-800' :
                            selectedDrop.drop?.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                            selectedDrop.drop?.status === 'accepted' ? 'bg-blue-100 text-blue-800' :
                            'bg-gray-100 text-gray-800'
                          }`}>
                            {selectedDrop.drop?.status}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Bottles:</span>
                          <span className="font-medium flex items-center gap-2">
                            <img src="/water-bottle.png" alt="Bottles" className="w-5 h-5" />
                            {selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.numberOfBottles || selectedDrop.drop?.numberOfBottles}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Cans:</span>
                          <span className="font-medium flex items-center gap-2">
                            <img src="/can.png" alt="Cans" className="w-5 h-5" />
                            {selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.numberOfCans || selectedDrop.drop?.numberOfCans}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Bottle Type:</span>
                          <span className="font-medium capitalize flex items-center gap-2">
                            <img 
                              src={(selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.bottleType || selectedDrop.drop?.bottleType) === 'mixed' ? '/mixed.png' : '/water-bottle.png'} 
                              alt={selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.bottleType || selectedDrop.drop?.bottleType} 
                              className="w-5 h-5" 
                            />
                            {selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.bottleType || selectedDrop.drop?.bottleType}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Leave Outside:</span>
                          <span className="font-medium">{selectedDrop.drop?.leaveOutside ? 'Yes' : 'No'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Created:</span>
                          <span className="font-medium text-xs">{new Date(selectedDrop.drop?.createdAt).toLocaleString()}</span>
                        </div>
                        {selectedDrop.drop?.isSuspicious && (
                          <div className="pt-2 border-t border-red-200 bg-red-50 -mx-4 -mb-4 p-4 mt-3">
                            <span className="text-red-800 font-medium">⚠️ Flagged as Suspicious</span>
                            {selectedDrop.drop?.suspiciousReason && (
                              <p className="text-xs text-red-700 mt-1">{selectedDrop.drop.suspiciousReason}</p>
                            )}
                          </div>
                        )}
                        {(selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.notes || selectedDrop.drop?.notes) && (
                          <div className="pt-2 border-t border-gray-200">
                            <span className="text-gray-600">Notes:</span>
                            <p className="mt-1 text-gray-900">{selectedDrop.collectionAttempts?.[0]?.dropSnapshot?.notes || selectedDrop.drop?.notes}</p>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Flagged-specific Attempt Stats (only when opened from Flagged tab) */}
                    {dropDetailsContext === 'flagged' && selectedDrop.drop?.isSuspicious && (
                      <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-200">
                        <h3 className="font-semibold text-yellow-900 mb-3">Flagged Attempt Stats</h3>
                        <div className="space-y-2 text-sm text-yellow-900">
                          <div className="flex justify-between">
                            <span className="text-yellow-800">Suspicious:</span>
                            <span className="font-medium">{String(selectedDrop.drop?.isSuspicious)}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-yellow-800">Reason:</span>
                            <span className="font-medium">{selectedDrop.drop?.suspiciousReason || '—'}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-yellow-800">Cancellation Count:</span>
                            <span className="font-medium">{selectedDrop.drop?.cancellationCount || 0}</span>
                          </div>
                          <div>
                            <span className="text-yellow-800">Cancelled By (distinct collectors):</span>
                            <div className="mt-1 text-xs text-yellow-900 break-all">
                              {(selectedDrop.drop?.cancelledByCollectorIds || []).length > 0
                                ? (selectedDrop.drop.cancelledByCollectorIds).join(', ')
                                : '—'}
                            </div>
                          </div>
                          <div>
                            <span className="text-yellow-800">Cancellation History:</span>
                            <div className="mt-2 space-y-1">
                              {(selectedDrop.drop?.cancellationHistory || []).length > 0 ? (
                                selectedDrop.drop.cancellationHistory.map((entry: any, idx: number) => (
                                  <div key={idx} className="text-xs flex justify-between">
                                    <span className="text-yellow-800">{entry.collectorId}</span>
                                    <span className="text-yellow-900">{entry.reason}</span>
                                    <span className="text-yellow-700">{entry.cancelledAt ? new Date(entry.cancelledAt).toLocaleString() : ''}</span>
                                  </div>
                                ))
                              ) : (
                                <div className="text-xs text-yellow-700">No history</div>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* User Information */}
                    <div className="bg-blue-50 rounded-lg p-4">
                      <h3 className="font-semibold text-gray-900 mb-3">Household User</h3>
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Name:</span>
                          <span className="font-medium">{selectedDrop.drop?.user?.name || 'Unknown'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Email:</span>
                          <span className="font-medium">{selectedDrop.drop?.user?.email || 'N/A'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Phone:</span>
                          <span className="font-medium">{selectedDrop.drop?.user?.phoneNumber || 'N/A'}</span>
                        </div>
                        {selectedDrop.drop?.user?.address && (
                          <div className="pt-2 border-t border-gray-200">
                            <span className="text-gray-600">Address:</span>
                            <p className="mt-1 text-gray-900 text-xs">{selectedDrop.drop.user.address}</p>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Right Column */}
                  <div className="space-y-6">
                    {/* Location Map */}
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="font-semibold text-gray-900 mb-3">📍 Drop Location</h3>
                      <div className="space-y-3">
                        {/* Map */}
                        <div className="w-full h-64 rounded-lg overflow-hidden border-2 border-gray-300">
                          <iframe
                            width="100%"
                            height="100%"
                            frameBorder="0"
                            style={{ border: 0 }}
                            src={`https://www.google.com/maps/embed/v1/place?key=AIzaSyBFw0Qbyq9zTFTd-tUY6dZWTgaQzuU17R8&q=${selectedDrop.drop?.location?.coordinates?.[1]},${selectedDrop.drop?.location?.coordinates?.[0]}&zoom=15`}
                            allowFullScreen
                          />
                        </div>
                        
                        {/* Coordinates */}
                        <div className="bg-white rounded-lg p-3 space-y-2 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600">Latitude:</span>
                            <span className="font-mono font-medium">{selectedDrop.drop?.location?.coordinates?.[1]?.toFixed(6)}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Longitude:</span>
                            <span className="font-mono font-medium">{selectedDrop.drop?.location?.coordinates?.[0]?.toFixed(6)}</span>
                          </div>
                        </div>
                        
                        {/* Open in Maps Button */}
                        <a
                          href={`https://www.google.com/maps?q=${selectedDrop.drop?.location?.coordinates?.[1]},${selectedDrop.drop?.location?.coordinates?.[0]}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="block w-full bg-primary text-white text-center py-3 rounded-lg hover:bg-primary-dark transition-colors font-medium"
                        >
                          🗺️ Open in Google Maps
                        </a>
                      </div>
                    </div>

                    {/* Complete Drop Timeline (Flagged tab uses dropoff history; others use attempts) */}
                    {dropDetailsContext === 'flagged' ? (
                      <div className="bg-gray-50 rounded-lg p-4">
                        <h3 className="font-semibold text-gray-900 mb-4">📜 Complete Drop Timeline</h3>
                        <div className="space-y-4 max-h-96 overflow-y-auto">
                          {/* Created */}
                          <div className="flex gap-3">
                            <div className="flex flex-col items-center">
                              <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">📦</div>
                              {(selectedDrop.drop?.cancellationHistory?.length || 0) > 0 && (
                                <div className="w-0.5 h-full bg-gray-300 mt-2"></div>
                              )}
                            </div>
                            <div className="flex-1 pb-4">
                              <div className="bg-white rounded-lg p-3 shadow-sm">
                                <p className="font-semibold text-gray-900">Drop Created</p>
                                <p className="text-sm text-gray-600">by {selectedDrop.drop?.user?.name || 'Unknown'}</p>
                                <p className="text-xs text-gray-500 mt-1">{new Date(selectedDrop.drop?.createdAt).toLocaleString()}</p>
                              </div>
                            </div>
                          </div>

                          {/* Cancellations from drop.cancellationHistory */}
                          {(selectedDrop.drop?.cancellationHistory || []).map((entry: any, index: number) => (
                            <div key={entry._id || index} className="flex gap-3">
                              <div className="flex flex-col items-center">
                                <div className="w-10 h-10 rounded-full bg-gray-500 flex items-center justify-center text-white font-bold">✕</div>
                                {index < (selectedDrop.drop?.cancellationHistory?.length || 0) - 1 && (
                                  <div className="w-0.5 h-full bg-gray-300 mt-2"></div>
                                )}
                              </div>
                              <div className="flex-1 pb-4">
                                <div className="bg-white rounded-lg p-3 shadow-sm">
                                  <p className="font-semibold text-gray-900">Collection Cancelled</p>
                                  <p className="text-xs text-gray-600">collectorId: {entry.collectorId}</p>
                                  <p className="text-xs text-gray-600">reason: {entry.reason}</p>
                                  <p className="text-xs text-gray-500 mt-1">{entry.cancelledAt ? new Date(entry.cancelledAt).toLocaleString() : ''}</p>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ) : (
                      <div className="bg-gray-50 rounded-lg p-4">
                        <h3 className="font-semibold text-gray-900 mb-4">📜 Complete Drop Timeline</h3>
                        <div className="space-y-4 max-h-96 overflow-y-auto">
                          {/* Created */}
                          <div className="flex gap-3">
                            <div className="flex flex-col items-center">
                              <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">📦</div>
                              {(selectedDrop.collectionAttempts && selectedDrop.collectionAttempts.length > 0) && (
                                <div className="w-0.5 h-full bg-gray-300 mt-2"></div>
                              )}
                            </div>
                            <div className="flex-1 pb-4">
                              <div className="bg-white rounded-lg p-3 shadow-sm">
                                <p className="font-semibold text-gray-900">Drop Created</p>
                                <p className="text-sm text-gray-600">by {selectedDrop.drop?.user?.name || 'Unknown'}</p>
                                <p className="text-xs text-gray-500 mt-1">{new Date(selectedDrop.drop?.createdAt).toLocaleString()}</p>
                              </div>
                            </div>
                          </div>
                          {/* Attempts */}
                          {selectedDrop.collectionAttempts && selectedDrop.collectionAttempts.length > 0 ? (
                            selectedDrop.collectionAttempts.map((attempt: any, index: number) => (
                              <div key={attempt._id || index}>
                                <div className="flex gap-3">
                                  <div className="flex flex-col items-center">
                                    <div className="w-10 h-10 rounded-full bg-green-500 flex items-center justify-center text-white font-bold">✓</div>
                                    <div className="w-0.5 h-full bg-gray-300 mt-2"></div>
                                  </div>
                                  <div className="flex-1 pb-4">
                                    <div className="bg-white rounded-lg p-3 shadow-sm">
                                      <p className="font-semibold text-gray-900">Accepted for Collection</p>
                                      <p className="text-sm text-gray-600">by {attempt.collector?.name || 'Unknown Collector'}</p>
                                      <p className="text-xs text-gray-500">{attempt.collector?.email}</p>
                                      <p className="text-xs text-gray-500 mt-1">{new Date(attempt.acceptedAt).toLocaleString()}</p>
                                    </div>
                                  </div>
                                </div>
                                {attempt.completedAt && (
                                  <div className="flex gap-3">
                                    <div className="flex flex-col items-center">
                                      <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold ${attempt.outcome === 'collected' ? 'bg-green-600' : attempt.outcome === 'cancelled' ? 'bg-gray-500' : 'bg-orange-500'}`}>{attempt.outcome === 'collected' ? '✓' : attempt.outcome === 'cancelled' ? '✕' : '⏱'}</div>
                                      {index < selectedDrop.collectionAttempts.length - 1 && (<div className="w-0.5 h-full bg-gray-300 mt-2"></div>)}
                                    </div>
                                    <div className="flex-1 pb-4">
                                      <div className={`rounded-lg p-3 shadow-sm ${attempt.outcome === 'collected' ? 'bg-green-50 border border-green-200' : attempt.outcome === 'cancelled' ? 'bg-gray-50 border border-gray-200' : 'bg-orange-50 border border-orange-200'}`}>
                                        <p className="font-semibold text-gray-900 capitalize">{attempt.outcome === 'collected' ? '✓ Successfully Collected' : attempt.outcome === 'cancelled' ? '✕ Collection Cancelled' : '⏱ Collection Expired'}</p>
                                        <p className="text-sm text-gray-600">by {attempt.collector?.name || 'Unknown Collector'}</p>
                                        <p className="text-xs text-gray-500 mt-1">{new Date(attempt.completedAt).toLocaleString()}{attempt.durationMinutes !== undefined && ` • Duration: ${attempt.durationMinutes} min`}</p>
                                      </div>
                                    </div>
                                  </div>
                                )}
                              </div>
                            ))
                          ) : (
                            <p className="text-gray-500 text-sm text-center py-4">No collection attempts yet</p>
                          )}
                        </div>
                      </div>
                    )}

                    {/* Statistics: flagged uses drop fields; others use attempts summary */}
                    {dropDetailsContext === 'flagged' ? (
                      <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-200">
                        <h3 className="font-semibold text-yellow-900 mb-3">Flagged Attempt Stats</h3>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div className="bg-white rounded-lg p-3 border">
                            <p className="text-xs text-gray-600">Cancellation Count</p>
                            <p className="text-xl font-bold text-yellow-800">{selectedDrop.drop?.cancellationCount || 0}</p>
                          </div>
                          <div className="bg-white rounded-lg p-3 border">
                            <p className="text-xs text-gray-600">Distinct Cancellers</p>
                            <p className="text-xl font-bold text-yellow-800">{(selectedDrop.drop?.cancelledByCollectorIds || []).length}</p>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div className="bg-gradient-to-br from-primary/10 to-primary/5 rounded-lg p-4">
                        <h3 className="font-semibold text-gray-900 mb-3">Attempt Statistics</h3>
                        <div className="grid grid-cols-3 gap-3 text-center">
                          <div className="bg-white rounded-lg p-3">
                            <p className="text-2xl font-bold text-green-600">{selectedDrop.successfulCollections || 0}</p>
                            <p className="text-xs text-gray-600">Collected</p>
                          </div>
                          <div className="bg-white rounded-lg p-3">
                            <p className="text-2xl font-bold text-gray-600">{selectedDrop.cancelledAttempts || 0}</p>
                            <p className="text-xs text-gray-600">Cancelled</p>
                          </div>
                          <div className="bg-white rounded-lg p-3">
                            <p className="text-2xl font-bold text-orange-600">{selectedDrop.expiredAttempts || 0}</p>
                            <p className="text-xs text-gray-600">Expired</p>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="border-t border-gray-200 pt-6">
                  <h3 className="font-semibold text-gray-900 mb-4">Admin Actions</h3>
                  <div className="flex flex-wrap gap-3">
                    {/* Censor Image Button */}
                    {!selectedDrop.drop?.isCensored && (
                      <button
                        onClick={() => openCensorModal(selectedDrop.drop.id || selectedDrop.drop._id)}
                        className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium shadow-md hover:shadow-lg"
                      >
                        🚫 Censor Image
                      </button>
                    )}
                    
                    {/* Flag/Unflag Button */}
                    {selectedDrop.drop?.isSuspicious ? (
                      <button
                        onClick={() => unflagDrop(selectedDrop.drop.id || selectedDrop.drop._id)}
                        className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium shadow-md hover:shadow-lg"
                      >
                        ✓ Remove Flag
                      </button>
                    ) : (
                      <button
                        onClick={() => flagDrop(selectedDrop.drop.id || selectedDrop.drop._id)}
                        className="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-medium shadow-md hover:shadow-lg"
                      >
                        ⚠️ Flag as Suspicious
                      </button>
                    )}
                    
                    {/* Contact User Button */}
                    <button
                      onClick={() => {
                        const email = selectedDrop.drop?.user?.email;
                        if (email) window.location.href = `mailto:${email}`;
                      }}
                      className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium shadow-md hover:shadow-lg"
                    >
                      ✉️ Contact User
                    </button>
                    
                    {/* Delete Button */}
                    <button
                      onClick={() => deleteDrop(selectedDrop.drop.id || selectedDrop.drop._id)}
                      className="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium shadow-md hover:shadow-lg"
                    >
                      🗑️ Delete Drop
                    </button>
                  </div>
                  
                  {/* Censored Warning */}
                  {selectedDrop.drop?.isCensored && (
                    <div className="mt-4 p-4 bg-purple-50 border border-purple-200 rounded-lg">
                      <p className="text-purple-900 font-semibold">🚫 This drop image has been censored</p>
                      <p className="text-sm text-purple-700 mt-1">Reason: {selectedDrop.drop.censorReason}</p>
                      <p className="text-xs text-purple-600 mt-1">
                        Censored on: {new Date(selectedDrop.drop.censoredAt).toLocaleString()}
                      </p>
                    </div>
                  )}

                  {/* Flagged Warning */}
                  {selectedDrop.drop?.isSuspicious && (
                    <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                      <p className="text-yellow-900 font-semibold">⚠️ This drop is flagged as suspicious</p>
                      <p className="text-sm text-yellow-700 mt-1">Reason: {selectedDrop.drop.suspiciousReason || 'No reason provided'}</p>
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="p-6 text-center text-gray-500">
                Failed to load drop details
              </div>
            )}
          </div>
        </div>
      )}
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
  const [inspectingImage, setInspectingImage] = useState<{ url: string; title: string } | null>(null);
  const [imageZoom, setImageZoom] = useState(1);
  const [imagePan, setImagePan] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [searchQuery, setSearchQuery] = useState('');

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

  // Keyboard shortcuts for image inspector
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!inspectingImage) return;
      
      if (e.key === 'Escape') {
        handleCloseInspector();
      } else if (e.key === '+' || e.key === '=') {
        handleZoomIn();
      } else if (e.key === '-') {
        handleZoomOut();
      } else if (e.key === '0') {
        handleResetZoom();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [inspectingImage, imageZoom]);

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

  const handleInspectImage = (url: string, title: string) => {
    setInspectingImage({ url, title });
    setImageZoom(1);
    setImagePan({ x: 0, y: 0 });
  };

  const handleCloseInspector = () => {
    setInspectingImage(null);
    setImageZoom(1);
    setImagePan({ x: 0, y: 0 });
  };

  const handleZoomIn = () => {
    setImageZoom(prev => Math.min(prev + 0.5, 5));
  };

  const handleZoomOut = () => {
    setImageZoom(prev => Math.max(prev - 0.5, 0.5));
  };

  const handleResetZoom = () => {
    setImageZoom(1);
    setImagePan({ x: 0, y: 0 });
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    if (imageZoom > 1) {
      setIsDragging(true);
      setDragStart({ x: e.clientX - imagePan.x, y: e.clientY - imagePan.y });
    }
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (isDragging && imageZoom > 1) {
      setImagePan({
        x: e.clientX - dragStart.x,
        y: e.clientY - dragStart.y,
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    if (e.deltaY < 0) {
      handleZoomIn();
    } else {
      handleZoomOut();
    }
  };

  const getStatusBadge = (status: string) => {
    const statusClasses = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-300',
      approved: 'bg-green-100 text-green-800 border-green-300',
      rejected: 'bg-red-100 text-red-800 border-red-300',
    };
    
    const statusIcons = {
      pending: '⏳ ',
      approved: '✅ ',
      rejected: '❌ ',
    };
    
    return (
      <span className={`inline-flex items-center px-3 py-1 text-xs font-semibold rounded-full border ${statusClasses[status as keyof typeof statusClasses] || statusClasses.pending}`}>
        {statusIcons[status as keyof typeof statusIcons]}{status.charAt(0).toUpperCase() + status.slice(1).toUpperCase()}
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
      {/* Image Inspector Modal */}
      {inspectingImage && (
        <div className="fixed inset-0 bg-black/95 z-[60] flex items-center justify-center">
          {/* Controls Bar */}
          <div className="absolute top-0 left-0 right-0 bg-black/80 backdrop-blur-sm p-4 flex items-center justify-between border-b border-gray-700">
            <div className="flex items-center gap-4">
              <h3 className="text-white font-semibold text-lg">{inspectingImage.title}</h3>
              <span className="text-gray-400 text-sm">Zoom: {Math.round(imageZoom * 100)}%</span>
            </div>
            <div className="flex items-center gap-3">
              {/* Zoom Controls */}
              <button
                onClick={handleZoomOut}
                className="p-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors"
                title="Zoom Out"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM13 10H7" />
                </svg>
              </button>
              <button
                onClick={handleResetZoom}
                className="px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors text-sm font-medium"
                title="Reset Zoom"
              >
                Reset
              </button>
              <button
                onClick={handleZoomIn}
                className="p-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors"
                title="Zoom In"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                </svg>
              </button>
              <div className="w-px h-8 bg-gray-600"></div>
              <button
                onClick={handleCloseInspector}
                className="p-2 bg-red-500/80 hover:bg-red-600 text-white rounded-lg transition-colors"
                title="Close"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          {/* Image Container */}
          <div 
            className="w-full h-full flex items-center justify-center overflow-hidden cursor-move"
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
            onWheel={handleWheel}
          >
            <img
              src={inspectingImage.url}
              alt={inspectingImage.title}
              className="max-w-none select-none"
              style={{
                transform: `scale(${imageZoom}) translate(${imagePan.x / imageZoom}px, ${imagePan.y / imageZoom}px)`,
                transition: isDragging ? 'none' : 'transform 0.2s ease-out',
                cursor: imageZoom > 1 ? (isDragging ? 'grabbing' : 'grab') : 'default',
              }}
              draggable={false}
            />
          </div>

          {/* Instructions */}
          <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 bg-black/80 backdrop-blur-sm px-6 py-3 rounded-full text-white text-sm">
            <span className="flex items-center gap-4">
              <span>🖱️ Scroll to zoom</span>
              <span className="text-gray-400">•</span>
              <span>🖐️ Drag to pan</span>
              <span className="text-gray-400">•</span>
              <span>ESC to close</span>
            </span>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="bg-gradient-to-r from-purple-600 to-indigo-600 rounded-2xl shadow-xl p-8 text-white">
        <div className="flex items-center gap-3 mb-2">
          <ClipboardDocumentListIcon className="h-10 w-10" />
          <h1 className="text-4xl font-bold">Collector Applications</h1>
        </div>
        <p className="text-purple-100 text-lg">Review and manage collector applications</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-blue-50">
                <ClipboardDocumentListIcon className="h-7 w-7 text-blue-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{stats.total}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Total Applications</p>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-yellow-50">
                <ClockIcon className="h-7 w-7 text-yellow-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{stats.pending}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Pending Review</p>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-green-50">
                <CheckCircleIcon className="h-7 w-7 text-green-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{stats.approved}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Approved</p>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 rounded-xl bg-red-50">
                <ExclamationCircleIcon className="h-7 w-7 text-red-600" />
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-gray-900">{stats.rejected}</p>
              </div>
            </div>
            <p className="text-sm font-semibold text-gray-600 uppercase tracking-wide">Rejected</p>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-xl shadow-md p-6 border border-gray-100">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <MagnifyingGlassIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name, email, or application ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent text-sm"
            />
          </div>
          
          {/* Status Filter */}
          <div className="flex items-center gap-3">
            <FunnelIcon className="h-5 w-5 text-gray-400" />
            <label className="text-sm font-semibold text-gray-700">Status:</label>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent font-medium min-w-[180px]"
            >
              <option value="">All Statuses</option>
              <option value="pending">⏳ Pending</option>
              <option value="approved">✅ Approved</option>
              <option value="rejected">❌ Rejected</option>
            </select>
          </div>
        </div>
      </div>

      {/* Applications Cards */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-purple-600 mx-auto"></div>
            <p className="mt-4 text-gray-600 font-medium">Loading applications...</p>
          </div>
        </div>
      ) : applications.length === 0 ? (
        <div className="bg-white rounded-xl shadow-md border border-gray-100">
          <div className="px-6 py-16">
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gray-100 mb-4">
                <ClipboardDocumentListIcon className="h-8 w-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">No applications found</h3>
              <p className="text-gray-600">
                {searchQuery || selectedStatus 
                  ? 'Try adjusting your search or filters.' 
                  : 'No collector applications have been submitted yet.'}
              </p>
            </div>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4">
          {applications
            .filter(application => {
              if (!searchQuery) return true;
              
              const query = searchQuery.toLowerCase();
              const name = typeof application.userId === 'object' && application.userId?.name 
                ? application.userId.name.toLowerCase() 
                : '';
              const email = typeof application.userId === 'object' && application.userId?.email 
                ? application.userId.email.toLowerCase() 
                : '';
              const id = application.id.toLowerCase();
              
              return name.includes(query) || email.includes(query) || id.includes(query);
            })
            .map((application, index) => (
            <div
              key={`${application.id}-${index}`}
              className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 border border-gray-100 overflow-hidden group"
            >
              <div className="p-6">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    {/* Applicant Info */}
                    <div className="flex items-center gap-4 mb-3">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-indigo-500 flex items-center justify-center text-white font-bold text-lg flex-shrink-0">
                        {typeof application.userId === 'object' && application.userId?.name 
                          ? application.userId.name[0].toUpperCase() 
                          : '?'}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="text-lg font-bold text-gray-900 group-hover:text-purple-600 transition-colors truncate">
                          {typeof application.userId === 'object' && application.userId?.name 
                            ? application.userId.name 
                            : 'Unknown Applicant'}
                        </h3>
                        <p className="text-sm text-gray-600 truncate">
                          {typeof application.userId === 'object' && application.userId?.email 
                            ? application.userId.email 
                            : `ID: ${application.id}`}
                        </p>
                      </div>
                      <div className="flex-shrink-0">
                        {getStatusBadge(application.status)}
                      </div>
                    </div>
                    
                    {/* Meta Info */}
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-gray-600">
                      <span className="flex items-center gap-1.5">
                        <ClockIcon className="h-4 w-4" />
                        Applied: {new Date(application.appliedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                      </span>
                      {application.reviewedAt && (
                        <>
                          <span className="text-gray-400">•</span>
                          <span className="flex items-center gap-1.5">
                            <CheckCircleIcon className="h-4 w-4" />
                            Reviewed: {new Date(application.reviewedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                          </span>
                        </>
                      )}
                      {application.idCardType && (
                        <>
                          <span className="text-gray-400">•</span>
                          <span className="flex items-center gap-1.5">
                            🆔 {application.idCardType}
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                  
                  {/* View Button */}
                  <button
                    onClick={() => handleViewApplication(application)}
                    className="flex-shrink-0 px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl hover:from-purple-700 hover:to-indigo-700 font-semibold transition-all shadow-md hover:shadow-lg transform hover:-translate-y-0.5"
                  >
                    Review
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

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
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-6xl bg-white rounded-2xl shadow-2xl">
            {/* Header with Gradient */}
            <div className="relative px-8 py-6 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-indigo-50">
              <button
                onClick={() => setShowApplicationModal(false)}
                className="absolute top-6 right-6 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              <div className="pr-12">
                <div className="flex items-center gap-3 mb-3">
                  <ClipboardDocumentListIcon className="h-8 w-8 text-purple-600" />
                  <h3 className="text-3xl font-bold text-gray-900">Application Review</h3>
                </div>
                <div className="flex items-center gap-3">
                  {getStatusBadge(selectedApplication.status)}
                  <span className="text-sm text-gray-600">
                    Submitted on {new Date(selectedApplication.appliedAt).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                  </span>
                </div>
              </div>
            </div>

            {/* Content */}
            <div className="max-h-[calc(100vh-200px)] overflow-y-auto p-8">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Left Column - User Information */}
                <div className="space-y-6">
                  {/* User Details */}
                  <div className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-xl p-6 border border-purple-100">
                    <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                      <UsersIcon className="h-5 w-5 text-purple-600" />
                      Applicant Information
                    </h4>
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
                  <div className="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl p-6 border border-blue-100">
                    <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                      <svg className="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                      </svg>
                      ID Card Information
                    </h4>
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
                    <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl p-6 border border-amber-200">
                      <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                        <SparklesIcon className="h-5 w-5 text-amber-600" />
                        Review Actions
                      </h4>
                      
                      {/* Rejection Reason Selection */}
                      <div className="mb-6">
                        <label className="block text-sm font-semibold text-gray-700 mb-3">
                          Rejection Reason (Required for rejection)
                        </label>
                        <div className="space-y-2">
                          {REJECTION_REASONS.map((reason) => (
                            <label key={reason.id} className="flex items-start space-x-3 cursor-pointer p-3 rounded-lg hover:bg-white/50 transition-colors">
                              <input
                                type="radio"
                                name="rejectionReason"
                                value={reason.id}
                                checked={selectedRejectionReason === reason.id}
                                onChange={(e) => setSelectedRejectionReason(e.target.value)}
                                className="mt-1 h-4 w-4 text-purple-600 border-gray-300 focus:ring-purple-500"
                              />
                              <div className="flex-1">
                                <div className="text-sm font-semibold text-gray-900">{reason.label}</div>
                                <div className="text-xs text-gray-600">{reason.description}</div>
                              </div>
                            </label>
                          ))}
                        </div>
                      </div>

                      {/* Action Buttons */}
                      <div className="flex gap-3">
                        <button
                          onClick={handleApprove}
                          className="flex-1 bg-gradient-to-r from-green-600 to-green-700 text-white px-6 py-3 rounded-xl hover:from-green-700 hover:to-green-800 transition-all font-semibold shadow-md hover:shadow-lg"
                        >
                          ✅ Approve Application
                        </button>
                        <button
                          onClick={handleReject}
                          disabled={!selectedRejectionReason}
                          className="flex-1 bg-gradient-to-r from-red-600 to-red-700 text-white px-6 py-3 rounded-xl hover:from-red-700 hover:to-red-800 transition-all font-semibold shadow-md hover:shadow-lg disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed"
                        >
                          ❌ Reject Application
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Approved Application Actions */}
                  {selectedApplication.status === 'approved' && (
                    <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl p-6 border border-green-200">
                      <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                        <CheckCircleIcon className="h-6 w-6 text-green-600" />
                        Application Approved
                      </h4>
                      <div className="mb-4">
                        <div className="flex items-start gap-3 p-4 bg-white/50 rounded-lg">
                          <CheckCircleIcon className="h-6 w-6 text-green-600 flex-shrink-0 mt-0.5" />
                          <div>
                            <p className="text-sm font-medium text-green-900 mb-1">
                              This application has been approved
                            </p>
                            <p className="text-xs text-green-700">
                              You can reverse the approval if needed.
                            </p>
                          </div>
                        </div>
                      </div>
                      
                      {/* Reverse Approval Button */}
                      <button
                        onClick={handleReverseApproval}
                        className="w-full bg-gradient-to-r from-orange-600 to-orange-700 text-white px-6 py-3 rounded-xl hover:from-orange-700 hover:to-orange-800 transition-all font-semibold shadow-md hover:shadow-lg"
                      >
                        🔄 Reverse Approval
                      </button>
                    </div>
                  )}
                </div>

                {/* Right Column - Image Comparison */}
                <div className="space-y-6">
                  <h4 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                    <svg className="h-6 w-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    Identity Verification
                  </h4>
                  
                  {selectedApplication.idCardType === 'Passport' ? (
                    // Passport Photos
                    <div className="bg-gradient-to-br from-gray-50 to-slate-50 rounded-xl p-5 border border-gray-200 shadow-sm">
                      <h5 className="text-md font-semibold text-gray-900 mb-3 flex items-center gap-2">
                        <svg className="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        Passport Main Page
                      </h5>
                      <div 
                        className="aspect-video bg-white rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden shadow-inner cursor-pointer hover:border-purple-400 transition-colors group/img"
                        onClick={() => selectedApplication.passportMainPagePhoto && handleInspectImage(selectedApplication.passportMainPagePhoto, 'Passport Main Page')}
                      >
                        {selectedApplication.passportMainPagePhoto ? (
                          <>
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
                            <div className="absolute inset-0 bg-black/0 group-hover/img:bg-black/10 transition-all flex items-center justify-center">
                              <div className="bg-purple-600 rounded-full p-3 opacity-0 group-hover/img:opacity-100 transition-opacity shadow-lg">
                                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                                </svg>
                              </div>
                            </div>
                          </>
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
                      <div className="bg-gradient-to-br from-gray-50 to-slate-50 rounded-xl p-5 border border-gray-200 shadow-sm">
                        <h5 className="text-md font-semibold text-gray-900 mb-3 flex items-center gap-2">
                          <svg className="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                          </svg>
                          ID Card Front
                        </h5>
                        <div 
                          className="aspect-video bg-white rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden shadow-inner cursor-pointer hover:border-purple-400 transition-colors group/img relative"
                          onClick={() => selectedApplication.idCardPhoto && handleInspectImage(selectedApplication.idCardPhoto, 'ID Card Front')}
                        >
                          {selectedApplication.idCardPhoto ? (
                            <>
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
                              <div className="absolute inset-0 bg-black/0 group-hover/img:bg-black/10 transition-all flex items-center justify-center">
                                <div className="bg-purple-600 rounded-full p-3 opacity-0 group-hover/img:opacity-100 transition-opacity shadow-lg">
                                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                                  </svg>
                                </div>
                              </div>
                            </>
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
                      <div className="bg-gradient-to-br from-gray-50 to-slate-50 rounded-xl p-5 border border-gray-200 shadow-sm">
                        <h5 className="text-md font-semibold text-gray-900 mb-3 flex items-center gap-2">
                          <svg className="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                          </svg>
                          ID Card Back
                        </h5>
                        <div 
                          className="aspect-video bg-white rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden shadow-inner cursor-pointer hover:border-purple-400 transition-colors group/img relative"
                          onClick={() => selectedApplication.idCardBackPhoto && handleInspectImage(selectedApplication.idCardBackPhoto, 'ID Card Back')}
                        >
                          {selectedApplication.idCardBackPhoto ? (
                            <>
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
                              <div className="absolute inset-0 bg-black/0 group-hover/img:bg-black/10 transition-all flex items-center justify-center">
                                <div className="bg-purple-600 rounded-full p-3 opacity-0 group-hover/img:opacity-100 transition-opacity shadow-lg">
                                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                                  </svg>
                                </div>
                              </div>
                            </>
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
                  <div className="bg-gradient-to-br from-gray-50 to-slate-50 rounded-xl p-5 border border-gray-200 shadow-sm">
                    <h5 className="text-md font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <svg className="h-5 w-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                      </svg>
                      Selfie with ID
                    </h5>
                    <div 
                      className="aspect-video bg-white rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden shadow-inner cursor-pointer hover:border-purple-400 transition-colors group/img relative"
                      onClick={() => selectedApplication.selfieWithIdPhoto && handleInspectImage(selectedApplication.selfieWithIdPhoto, 'Selfie with ID')}
                    >
                      {selectedApplication.selfieWithIdPhoto ? (
                        <>
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
                          <div className="absolute inset-0 bg-black/0 group-hover/img:bg-black/10 transition-all flex items-center justify-center">
                            <div className="bg-purple-600 rounded-full p-3 opacity-0 group-hover/img:opacity-100 transition-opacity shadow-lg">
                              <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                              </svg>
                            </div>
                          </div>
                        </>
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredContent.map((content) => (
            <div key={content._id} className="bg-white border border-gray-200 rounded-xl overflow-hidden hover:shadow-lg transition-all duration-300 flex flex-col h-full">
              {/* Card Header - Fixed height */}
              <div className="p-4 border-b border-gray-100 flex-shrink-0">
                <div className="flex items-start justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-2xl flex-shrink-0">
                        {contentTypes.find(t => t.value === content.type)?.icon || '📄'}
                      </span>
                      <h3 className="text-lg font-bold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-1">
                        {content.title}
                      </h3>
                    </div>
                    
                    <p className="text-sm text-gray-600 line-clamp-2 leading-relaxed h-10">{content.description}</p>
                  </div>
                  
                  {/* Action Buttons */}
                  <div className="flex gap-2 ml-3 flex-shrink-0">
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

              {/* Card Body - Media - Fixed height */}
              <div className="p-3 bg-gray-50 flex-1 flex flex-col">
                {content.type === 'video' && content.mediaUrl && (
                  <div className="relative group/video cursor-pointer flex-1 flex flex-col" onClick={() => handlePlayVideo(content.mediaUrl, content.thumbnailUrl, content.title)}>
                    <div className="relative w-full h-56 bg-black rounded-lg overflow-hidden flex-shrink-0">
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
                  <div className="relative group/image w-full h-56 flex-shrink-0">
                    <img
                      src={content.mediaUrl}
                      alt={content.title}
                      className="w-full h-full object-cover rounded-lg shadow-md"
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
                  <div className="bg-white p-4 rounded-lg border border-gray-200 w-full h-56 flex-shrink-0 flex flex-col">
                    <div className="flex items-center text-gray-500 mb-3">
                      <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                      <span className="text-xs font-medium">Story Content</span>
                    </div>
                    <div className="flex-1 overflow-hidden">
                      <p className="text-sm text-gray-600 leading-relaxed h-full overflow-y-auto">{content.content}</p>
                    </div>
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
  const [chatConnecting, setChatConnecting] = useState<boolean>(false);
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
    // Note: connection is now manual via the Connect to Chat button in the modal

    // Auto-scroll to bottom when opening ticket
    setTimeout(() => {
      scrollToBottom();
    }, 100);
  };

  const handleConnectToChat = async () => {
    if (!selectedTicket || chatConnecting) return;
    try {
      setChatConnecting(true);
      const token = typeof window !== 'undefined' ? localStorage.getItem('admin_token') : null;
      if (!token) {
        console.error('❌ Admin Dashboard: No admin token found');
        return;
      }

      // If already connected, just join the room
      let activeSocket = socket;
      if (!activeSocket || !activeSocket.connected) {
        const { io } = await import('socket.io-client');
        activeSocket = io('http://localhost:3000/chat', {
          auth: { token },
          transports: ['websocket'],
          timeout: 10000,
          forceNew: true,
          reconnection: true,
          reconnectionAttempts: 3,
          reconnectionDelay: 1000,
          reconnectionDelayMax: 5000,
        });

        await new Promise<void>((resolve, reject) => {
          const t = setTimeout(() => reject(new Error('Connection timeout')), 10000);
          activeSocket.on('connect', () => { clearTimeout(t); resolve(); });
          activeSocket.on('connect_error', (err: any) => { clearTimeout(t); reject(err); });
        });
        setSocket(activeSocket);
      }

      const ticketId = selectedTicket._id || selectedTicket.id;
      activeSocket.emit('join_ticket', { ticketId, senderType: 'agent' });
      activeSocket.emit('presence_indicator', { ticketId, isPresent: true, senderType: 'agent' });
      console.log('👤 Admin Dashboard: Joined ticket room via manual connect:', ticketId);
    } catch (err) {
      console.error('❌ Admin Dashboard: Failed to connect/join chat:', err);
    } finally {
      setChatConnecting(false);
    }
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

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'bg-red-100 text-red-800 border-red-300';
      case 'high':
        return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'low':
        return 'bg-green-100 text-green-800 border-green-300';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
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

  // Calculate stats if not available from API
  const calculatedStats = stats || {
    total: tickets.length,
    open: tickets.filter((t: any) => t.status === 'open').length,
    inProgress: tickets.filter((t: any) => t.status === 'in_progress').length,
    resolved: tickets.filter((t: any) => t.status === 'resolved').length,
    closed: tickets.filter((t: any) => t.status === 'closed').length,
  };

  // Calculate urgent/high priority tickets
  const urgentTickets = tickets.filter((t: any) => 
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

        {/* Filters */}
        <div className="flex justify-between items-center">
          <div className="flex space-x-4">
            <button
              onClick={() => {
                fetchTickets();
                fetchStats();
              }}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors shadow-sm"
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

        {tickets.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md border border-gray-100">
            <div className="px-6 py-16">
              <div className="text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gray-100 mb-4">
                  <TicketIcon className="h-8 w-8 text-gray-400" />
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">No tickets found</h3>
                <p className="text-gray-600">
                  {selectedStatus || selectedCategory
                    ? 'Try adjusting your filters or search query.'
                    : 'No support tickets have been created yet.'}
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {tickets.map((ticket) => (
              <div
                key={ticket._id || ticket.id}
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
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getStatusColor(ticket.status)}`}>
                            {ticket.status.replace('_', ' ').toUpperCase()}
                          </span>
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getPriorityColor(ticket.priority)}`}>
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
                          {ticket.messages?.length || 0} message{(ticket.messages?.length || 0) !== 1 ? 's' : ''}
                        </span>
                        {ticket.userId && (
                          <>
                            <span className="text-gray-400">•</span>
                            <span className="flex items-center gap-1.5">
                              👤 {ticket.userId.name || 'User'}
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
                      onClick={() => handleViewTicket(ticket)}
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
                                        <img src="/water-bottle.png" alt="Bottles" className="w-5 h-5" />
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
                                        <img src="/can.png" alt="Cans" className="w-5 h-5" />
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
                      
                      {/* Collection Issue - Show CollectionAttempt timeline */}
                      {selectedTicket.relatedCollectionId && (
                        <div className="p-4 bg-green-50 rounded-lg border border-green-200">
                          <h4 className="font-medium text-green-900 mb-3">Collection Attempt Details</h4>
                          
                          {/* Collection Attempt Info */}
                          <div className="grid grid-cols-2 gap-3 mb-4">
                            <div className="bg-white rounded-lg p-3 border border-green-200">
                              <p className="text-xs text-gray-600">Status</p>
                              <p className="font-semibold text-green-900 capitalize">{selectedTicket.relatedCollectionId.status}</p>
                            </div>
                            <div className="bg-white rounded-lg p-3 border border-green-200">
                              <p className="text-xs text-gray-600">Outcome</p>
                              <p className="font-semibold text-green-900 capitalize">{selectedTicket.relatedCollectionId.outcome || 'In Progress'}</p>
                            </div>
                            {selectedTicket.relatedCollectionId.durationMinutes && (
                              <div className="bg-white rounded-lg p-3 border border-green-200">
                                <p className="text-xs text-gray-600">Duration</p>
                                <p className="font-semibold text-green-900">{selectedTicket.relatedCollectionId.durationMinutes} min</p>
                              </div>
                            )}
                          </div>

                          {/* Collection Attempt Timeline */}
                          {selectedTicket.relatedCollectionId.timeline && selectedTicket.relatedCollectionId.timeline.length > 0 && (
                            <div className="mt-4 pt-4 border-t border-green-200">
                              <h4 className="font-medium text-green-900 mb-3">Collection Attempt Timeline</h4>
                              
                              <div className="space-y-4 max-h-96 overflow-y-auto">
                                {selectedTicket.relatedCollectionId.timeline.map((event: any, index: number) => {
                                  const getEventIcon = (eventType: string) => {
                                    switch (eventType.toLowerCase()) {
                                      case 'accepted':
                                        return '✓';
                                      case 'collected':
                                        return '📦';
                                      case 'cancelled':
                                        return '✗';
                                      case 'expired':
                                        return '⏰';
                                      default:
                                        return '•';
                                    }
                                  };

                                  const getEventColor = (eventType: string) => {
                                    switch (eventType.toLowerCase()) {
                                      case 'accepted':
                                        return 'bg-green-100 text-green-800 border-green-200';
                                      case 'collected':
                                        return 'bg-blue-100 text-blue-800 border-blue-200';
                                      case 'cancelled':
                                        return 'bg-red-100 text-red-800 border-red-200';
                                      case 'expired':
                                        return 'bg-orange-100 text-orange-800 border-orange-200';
                                      default:
                                        return 'bg-gray-100 text-gray-800 border-gray-200';
                                    }
                                  };

                                  const getEventTitle = (eventType: string) => {
                                    switch (eventType.toLowerCase()) {
                                      case 'accepted':
                                        return 'Collector Accepted Drop';
                                      case 'collected':
                                        return 'Drop Collected Successfully';
                                      case 'cancelled':
                                        return 'Collection Cancelled';
                                      case 'expired':
                                        return 'Collection Expired';
                                      default:
                                        return eventType.charAt(0).toUpperCase() + eventType.slice(1);
                                    }
                                  };

                                  return (
                                    <div key={index} className="relative flex items-start space-x-4">
                                      <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium border-2 ${getEventColor(event.event)}`}>
                                        {getEventIcon(event.event)}
                                      </div>
                                      <div className="flex-1 min-w-0 bg-white rounded-lg border border-gray-200 p-3">
                                        <div className="flex items-center justify-between">
                                          <h5 className="text-sm font-medium text-gray-900">{getEventTitle(event.event)}</h5>
                                          <span className="text-xs text-gray-500">
                                            {new Date(event.timestamp).toLocaleString()}
                                          </span>
                                        </div>
                                        {event.collector && (
                                          <p className="mt-1 text-sm text-gray-600">
                                            <strong>Collector:</strong> {event.collector.name} ({event.collector.email})
                                          </p>
                                        )}
                                        {event.details?.reason && (
                                          <p className="mt-1 text-sm text-gray-600">
                                            <strong>Reason:</strong> {event.details.reason}
                                          </p>
                                        )}
                                        {event.details?.notes && (
                                          <p className="mt-1 text-sm text-gray-600">
                                            <strong>Notes:</strong> {event.details.notes}
                                          </p>
                                        )}
                                      </div>
                                    </div>
                                  );
                                })}
                              </div>
                            </div>
                          )}
                          
                          {/* Show message when no timeline found */}
                          {(!selectedTicket.relatedCollectionId.timeline || selectedTicket.relatedCollectionId.timeline.length === 0) && (
                            <div className="mt-4 pt-4 border-t border-green-200">
                              <h4 className="font-medium text-green-900 mb-3">Collection Attempt Timeline</h4>
                              <div className="text-center py-4 text-gray-500">
                                <p>No timeline found for this collection attempt.</p>
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
                      <div className={`w-2 h-2 rounded-full ${socket && socket.connected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                      {socket && socket.connected ? (
                        <span className="text-xs text-gray-500">Connected</span>
                      ) : (
                        <button
                          type="button"
                          onClick={handleConnectToChat}
                          disabled={chatConnecting}
                          className={`px-3 py-1.5 rounded-md text-xs font-semibold text-white ${chatConnecting ? 'bg-gray-400' : 'bg-blue-600 hover:bg-blue-700'}`}
                        >
                          {chatConnecting ? 'Connecting…' : 'Connect to Chat'}
                        </button>
                      )}
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