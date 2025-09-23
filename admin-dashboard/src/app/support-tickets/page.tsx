'use client';

import { useState, useEffect } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { supportTicketsAPI } from '@/lib/api';

interface SupportTicket {
  id: string;
  userId: string;
  title: string;
  description: string;
  category: string;
  priority: string;
  status: string;
  assignedTo?: string;
  createdAt: string;
  updatedAt: string;
  messages: Array<{
    message: string;
    senderId: string;
    senderType: string;
    sentAt: string;
    isInternal: boolean;
  }>;
}

export default function SupportTicketsPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');

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
      
      // The backend returns { success: true, tickets: [...], total: ..., page: ..., totalPages: ... }
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

  useEffect(() => {
    console.log('🔍 useEffect triggered - fetching tickets');
    fetchTickets();
  }, [selectedStatus, selectedCategory]);

  // Add a test button to manually fetch tickets
  const testFetch = () => {
    console.log('🧪 Manual test fetch triggered');
    fetchTickets();
  };

  // Test API client directly
  const testAPIClient = async () => {
    try {
      console.log('🧪 Testing API client directly...');
      const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
      console.log('🧪 Token found:', token ? token.substring(0, 20) + '...' : 'No token');
      
      const response = await fetch('http://localhost:3000/api/admin/support-tickets', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      const data = await response.json();
      console.log('🧪 Direct API response:', data);
      console.log('🧪 Tickets count:', data.tickets?.length || 0);
    } catch (error) {
      console.error('🧪 Direct API test failed:', error);
    }
  };

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
        return 'bg-orange-100 text-orange-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'bg-red-100 text-red-800';
      case 'high':
        return 'bg-orange-100 text-orange-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
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
      case 'collection_navigation':
        return '🚚 Collection & Navigation';
      case 'collector_application':
        return '👤 Collector Application';
      case 'payment_rewards':
        return '💰 Payment & Rewards';
      case 'statistics_history':
        return '📊 Statistics & History';
      case 'role_switching':
        return '🔄 Role Switching';
      case 'communication':
        return '📞 Communication';
      case 'general_support':
        return '🛠️ General Support';
      default:
        return category;
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </AdminLayout>
    );
  }

  if (error) {
    return (
      <AdminLayout>
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
      </AdminLayout>
    );
  }

  // Debug logging
  console.log('🔍 Support Tickets Page Render - Current State:', {
    loading,
    error,
    ticketsCount: tickets.length,
    tickets: tickets,
    selectedStatus,
    selectedCategory
  });

  return (
    <AdminLayout>
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
          <h1 className="text-2xl font-bold text-gray-900">Support Tickets</h1>
          <div className="flex space-x-4">
            <button
              onClick={testFetch}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 text-sm"
            >
              Test Fetch
            </button>
            <button
              onClick={testAPIClient}
              className="px-4 py-2 bg-green-500 text-white rounded-md hover:bg-green-600 text-sm"
            >
              Test API Direct
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
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="text-center">
                <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <h3 className="mt-2 text-sm font-medium text-gray-900">No support tickets</h3>
                <p className="mt-1 text-sm text-gray-500">
                  {selectedStatus || selectedCategory 
                    ? 'No tickets match the current filters.' 
                    : 'No support tickets have been created yet.'}
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {tickets.map((ticket) => (
                <li key={ticket.id}>
                  <div className="px-4 py-4 sm:px-6 hover:bg-gray-50">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3">
                          <h3 className="text-sm font-medium text-gray-900 truncate">
                            {ticket.title}
                          </h3>
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(ticket.status)}`}>
                            {ticket.status.replace('_', ' ')}
                          </span>
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(ticket.priority)}`}>
                            {ticket.priority}
                          </span>
                        </div>
                        <div className="mt-1 flex items-center space-x-4 text-sm text-gray-500">
                          <span>{getCategoryDisplayName(ticket.category)}</span>
                          <span>•</span>
                          <span>User ID: {ticket.userId}</span>
                          <span>•</span>
                          <span>Created: {new Date(ticket.createdAt).toLocaleDateString()}</span>
                          {ticket.assignedTo && (
                            <>
                              <span>•</span>
                              <span>Assigned to: {ticket.assignedTo}</span>
                            </>
                          )}
                        </div>
                        <div className="mt-2">
                          <p className="text-sm text-gray-600 line-clamp-2">
                            {ticket.description}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className="text-sm text-gray-500">
                          {ticket.messages.length} message{ticket.messages.length !== 1 ? 's' : ''}
                        </span>
                        <button className="text-blue-600 hover:text-blue-900 text-sm font-medium">
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
    </AdminLayout>
  );
}
