'use client';

import { useState, useEffect } from 'react';
import { applicationsAPI } from '@/lib/api';
import { CollectorApplication } from '@/types';

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

export default function ApplicationsPage() {
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
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [selectedApplication, setSelectedApplication] = useState<CollectorApplication | null>(null);
  const [selectedRejectionReason, setSelectedRejectionReason] = useState('');

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
      console.log('🔍 First application details:', response.data.applications[0]);
      console.log('🔍 First application status:', response.data.applications[0]?.status);
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

  const handleApprove = async (applicationId: string) => {
    try {
      console.log('🔍 handleApprove called with applicationId:', applicationId);
      console.log('🔍 selectedApplication:', selectedApplication);
      
      if (!applicationId) {
        console.error('❌ applicationId is undefined or empty');
        return;
      }
      
      // No notes needed for approval
      await applicationsAPI.approveApplication(applicationId);
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error approving application:', error);
    }
  };

  const handleReject = async (applicationId: string, rejectionReason: string) => {
    try {
      // Use predefined rejection reason
      await applicationsAPI.rejectApplication(applicationId, rejectionReason);
      setShowReviewModal(false);
      setSelectedApplication(null);
      setSelectedRejectionReason('');
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error rejecting application:', error);
    }
  };

  const handleReverseApproval = async (applicationId: string) => {
    try {
      await applicationsAPI.reverseApproval(applicationId);
      setShowReviewModal(false);
      setSelectedApplication(null);
      setSelectedRejectionReason('');
      loadApplications();
      loadStats();
    } catch (error) {
      console.error('Error reversing application approval:', error);
    }
  };

  const openReviewModal = (application: CollectorApplication) => {
    console.log('🔍 Opening review modal for application:', application);
    console.log('🔍 Application status:', application.status);
    console.log('🔍 Application status type:', typeof application.status);
    setSelectedApplication(application);
    setSelectedRejectionReason('');
    setShowReviewModal(true);
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

  // Import centralized date utilities
  const { formatDateTime, formatDateOnly, formatRelativeTime } = require('../../lib/dateUtils');

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
                {applications.map((application) => {
                  console.log('🔍 Rendering application:', application);
                  return (
                  <tr key={application.id} className="hover:bg-gray-50">
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
                      {formatDateTime(application.appliedAt)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {application.reviewedAt ? formatDateTime(application.reviewedAt) : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => {
                          console.log('🔍 View Details button clicked!');
                          console.log('🔍 Application being opened:', application);
                          alert(`Opening modal for application with status: ${application.status}`);
                          openReviewModal(application);
                        }}
                        className="text-blue-600 hover:text-blue-900 bg-blue-50 hover:bg-blue-100 px-3 py-1 rounded-md text-xs font-medium"
                      >
                        View Details (Status: {application.status})
                      </button>
                    </td>
                  </tr>
                );
                })}
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

      {/* Review Modal */}
      {showReviewModal && selectedApplication && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Review Application
              </h3>
              <p className="text-sm text-gray-500 mb-4">
                {selectedApplication.status === 'pending' 
                  ? 'Select a reason for rejecting this application or approve it:'
                  : 'Application has already been reviewed.'}
              </p>
              
              {/* Debug info */}
              <div className="mb-4 p-2 bg-gray-100 rounded text-xs">
                <p><strong>Debug Info:</strong></p>
                <p>Status: "{selectedApplication.status}"</p>
                <p>Status type: {typeof selectedApplication.status}</p>
                <p>Status length: {selectedApplication.status?.length}</p>
                <p>Is pending: {selectedApplication.status === 'pending' ? 'true' : 'false'}</p>
                <p>Is approved: {selectedApplication.status === 'approved' ? 'true' : 'false'}</p>
                <p>Is rejected: {selectedApplication.status === 'rejected' ? 'true' : 'false'}</p>
                <p>Status toLowerCase: "{selectedApplication.status?.toLowerCase()}"</p>
                <p>Status includes 'approve': {selectedApplication.status?.includes('approve') ? 'true' : 'false'}</p>
              </div>
              
              {selectedApplication.status === 'pending' && (
                <>
                  <div className="space-y-3 mb-6">
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

                  <div className="flex justify-end space-x-3">
                    <button
                      onClick={() => {
                        setShowReviewModal(false);
                        setSelectedApplication(null);
                        setSelectedRejectionReason('');
                      }}
                      className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => {
                        console.log('🔍 Approve button clicked');
                        console.log('🔍 selectedApplication.id:', selectedApplication.id);
                        console.log('🔍 selectedApplication:', selectedApplication);
                        handleApprove(selectedApplication.id);
                      }}
                      className="px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700"
                    >
                      Approve Application
                    </button>
                    <button
                      onClick={() => {
                        if (selectedRejectionReason) {
                          const reason = REJECTION_REASONS.find(r => r.id === selectedRejectionReason);
                          handleReject(selectedApplication.id, reason?.label || selectedRejectionReason);
                        }
                      }}
                      disabled={!selectedRejectionReason}
                      className="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Reject Application
                    </button>
                  </div>
                </>
              )}

              {/* Test section - always show for debugging */}
              <div className="mb-4 p-2 bg-yellow-100 rounded text-xs">
                <p><strong>Condition Test:</strong></p>
                <p>Status === 'approved': {selectedApplication.status === 'approved' ? 'TRUE' : 'false'}</p>
                <p>Status toLowerCase === 'approved': {selectedApplication.status?.toLowerCase() === 'approved' ? 'TRUE' : 'false'}</p>
                <p>Status includes 'approve': {selectedApplication.status?.toLowerCase().includes('approve') ? 'TRUE' : 'false'}</p>
              </div>

              {/* Force show approved section for testing */}
              <div className="mb-4 p-2 bg-red-100 rounded text-xs">
                <p><strong>FORCED APPROVED SECTION (TESTING):</strong></p>
                <p>This should always show the reverse approval button</p>
                <button
                  onClick={() => handleReverseApproval(selectedApplication.id)}
                  className="mt-2 px-4 py-2 text-sm font-medium text-white bg-orange-600 border border-transparent rounded-md hover:bg-orange-700"
                >
                  Reverse Approval (FORCED)
                </button>
              </div>

              {(selectedApplication.status === 'approved' || 
                selectedApplication.status?.toLowerCase() === 'approved' ||
                selectedApplication.status?.toLowerCase().includes('approve')) && (
                <div className="space-y-4">
                  <div className="bg-green-50 border border-green-200 rounded-md p-4">
                    <div className="flex">
                      <div className="flex-shrink-0">
                        <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                      </div>
                      <div className="ml-3">
                        <h3 className="text-sm font-medium text-green-800">Application Approved</h3>
                        <div className="mt-2 text-sm text-green-700">
                          <p>This application has been approved. You can reverse the approval if needed.</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-end space-x-3">
                    <button
                      onClick={() => {
                        setShowReviewModal(false);
                        setSelectedApplication(null);
                        setSelectedRejectionReason('');
                      }}
                      className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                    >
                      Close
                    </button>
                    <button
                      onClick={() => handleReverseApproval(selectedApplication.id)}
                      className="px-4 py-2 text-sm font-medium text-white bg-orange-600 border border-transparent rounded-md hover:bg-orange-700"
                    >
                      Reverse Approval
                    </button>
                  </div>
                </div>
              )}

              {selectedApplication.status === 'rejected' && (
                <div className="space-y-4">
                  <div className="bg-red-50 border border-red-200 rounded-md p-4">
                    <div className="flex">
                      <div className="flex-shrink-0">
                        <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                        </svg>
                      </div>
                      <div className="ml-3">
                        <h3 className="text-sm font-medium text-red-800">Application Rejected</h3>
                        <div className="mt-2 text-sm text-red-700">
                          <p>This application has been rejected and cannot be modified.</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-end">
                    <button
                      onClick={() => {
                        setShowReviewModal(false);
                        setSelectedApplication(null);
                        setSelectedRejectionReason('');
                      }}
                      className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200"
                    >
                      Close
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
} 