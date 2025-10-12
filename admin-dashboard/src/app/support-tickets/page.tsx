'use client';

import { useState, useEffect } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { supportTicketsAPI } from '@/lib/api';
import {
  TicketIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationCircleIcon,
  FunnelIcon,
  MagnifyingGlassIcon,
  SparklesIcon,
  ChatBubbleLeftRightIcon,
} from '@heroicons/react/24/outline';

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

interface TicketStats {
  totalTickets: number;
  openTickets: number;
  inProgressTickets: number;
  resolvedTickets: number;
  closedTickets: number;
  urgentTickets: number;
  responseTime: number;
}

interface TicketDetailModalProps {
  ticket: SupportTicket;
  onClose: () => void;
  onMessageSent: () => void;
  onStatusChange: () => void;
}

function TicketDetailModal({ ticket, onClose, onMessageSent, onStatusChange }: TicketDetailModalProps) {
  const [newMessage, setNewMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [updatingStatus, setUpdatingStatus] = useState(false);

  const handleSendMessage = async () => {
    if (!newMessage.trim()) return;

    try {
      setSending(true);
      setError(null);
      
      await supportTicketsAPI.addMessage(ticket.id, newMessage, false);
      
      setNewMessage('');
      onMessageSent();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send message');
    } finally {
      setSending(false);
    }
  };

  const handleStatusChange = async (newStatus: string) => {
    try {
      setUpdatingStatus(true);
      await supportTicketsAPI.updateTicketStatus(ticket.id, newStatus);
      onStatusChange();
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
                onChange={(e) => handleStatusChange(e.target.value)}
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
              {ticket.messages.map((msg, idx) => (
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
}

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

export default function SupportTicketsPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [stats, setStats] = useState<TicketStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);

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
      
      // Fetch stats
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
        const response = await supportTicketsAPI.getTicketById(selectedTicket.id);
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

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-[calc(100vh-200px)]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600 font-medium">Loading support tickets...</p>
          </div>
        </div>
      </AdminLayout>
    );
  }

  if (error) {
    return (
      <AdminLayout>
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
      </AdminLayout>
    );
  }

  // Calculate stats if not available from API
  const calculatedStats = stats || {
    totalTickets: tickets.length,
    openTickets: tickets.filter(t => t.status === 'open').length,
    inProgressTickets: tickets.filter(t => t.status === 'in_progress').length,
    resolvedTickets: tickets.filter(t => t.status === 'resolved').length,
    closedTickets: tickets.filter(t => t.status === 'closed').length,
    urgentTickets: tickets.filter(t => t.priority === 'urgent' || t.priority === 'high').length,
    responseTime: 0,
  };

  const statCards = [
    {
      name: 'Total Tickets',
      value: calculatedStats.totalTickets,
      icon: TicketIcon,
      color: 'from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50',
      iconColor: 'text-blue-600',
    },
    {
      name: 'Open Tickets',
      value: calculatedStats.openTickets,
      icon: ClockIcon,
      color: 'from-yellow-500 to-yellow-600',
      bgColor: 'bg-yellow-50',
      iconColor: 'text-yellow-600',
    },
    {
      name: 'In Progress',
      value: calculatedStats.inProgressTickets,
      icon: SparklesIcon,
      color: 'from-indigo-500 to-indigo-600',
      bgColor: 'bg-indigo-50',
      iconColor: 'text-indigo-600',
    },
    {
      name: 'Resolved',
      value: calculatedStats.resolvedTickets,
      icon: CheckCircleIcon,
      color: 'from-green-500 to-green-600',
      bgColor: 'bg-green-50',
      iconColor: 'text-green-600',
    },
  ];

  return (
    <AdminLayout>
      {selectedTicket && (
        <TicketDetailModal
          ticket={selectedTicket}
          onClose={() => setSelectedTicket(null)}
          onMessageSent={handleMessageSent}
          onStatusChange={handleStatusChange}
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
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
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
                key={ticket.id}
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
    </AdminLayout>
  );
}
