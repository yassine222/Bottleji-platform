'use client';

import { useState } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { 
  AcademicCapIcon,
  PlayIcon,
  DocumentTextIcon,
  ChartBarIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  UsersIcon,
  BookOpenIcon,
  TrophyIcon
} from '@heroicons/react/24/outline';

export default function TrainingPage() {
  const [selectedModule, setSelectedModule] = useState<string | null>(null);

  // Mock training data
  const trainingModules = [
    {
      id: '1',
      title: 'Collection Basics',
      description: 'Learn the fundamentals of bottle and can collection',
      duration: '15 min',
      status: 'completed',
      progress: 100,
      icon: BookOpenIcon,
      color: 'bg-green-500'
    },
    {
      id: '2',
      title: 'Safety Protocols',
      description: 'Important safety guidelines for collectors',
      duration: '20 min',
      status: 'in_progress',
      progress: 60,
      icon: ExclamationTriangleIcon,
      color: 'bg-orange-500'
    },
    {
      id: '3',
      title: 'Customer Service',
      description: 'Best practices for interacting with households',
      duration: '25 min',
      status: 'pending',
      progress: 0,
      icon: UsersIcon,
      color: 'bg-blue-500'
    },
    {
      id: '4',
      title: 'App Navigation',
      description: 'How to use the Bottleji collector app effectively',
      duration: '10 min',
      status: 'pending',
      progress: 0,
      icon: PlayIcon,
      color: 'bg-purple-500'
    }
  ];

  const trainingStats = {
    totalModules: 4,
    completedModules: 1,
    inProgressModules: 1,
    pendingModules: 2,
    totalTimeSpent: '35 min',
    averageScore: 85
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'text-green-600 bg-green-100';
      case 'in_progress': return 'text-orange-600 bg-orange-100';
      case 'pending': return 'text-gray-600 bg-gray-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'completed': return 'Completed';
      case 'in_progress': return 'In Progress';
      case 'pending': return 'Pending';
      default: return 'Unknown';
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header Section */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className="p-2 bg-blue-100 rounded-lg">
                <AcademicCapIcon className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Training Management</h1>
                <p className="text-gray-600">Manage training modules and track collector progress</p>
              </div>
            </div>
          </div>
        </div>

        {/* Training Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-center">
              <div className="p-2 bg-blue-100 rounded-lg">
                <BookOpenIcon className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Modules</p>
                <p className="text-2xl font-bold text-gray-900">{trainingStats.totalModules}</p>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-center">
              <div className="p-2 bg-green-100 rounded-lg">
                <CheckCircleIcon className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Completed</p>
                <p className="text-2xl font-bold text-gray-900">{trainingStats.completedModules}</p>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-center">
              <div className="p-2 bg-orange-100 rounded-lg">
                <ClockIcon className="h-6 w-6 text-orange-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">In Progress</p>
                <p className="text-2xl font-bold text-gray-900">{trainingStats.inProgressModules}</p>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-center">
              <div className="p-2 bg-purple-100 rounded-lg">
                <TrophyIcon className="h-6 w-6 text-purple-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Avg Score</p>
                <p className="text-2xl font-bold text-gray-900">{trainingStats.averageScore}%</p>
              </div>
            </div>
          </div>
        </div>

        {/* Training Modules */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">Training Modules</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {trainingModules.map((module) => (
                <div
                  key={module.id}
                  className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer"
                  onClick={() => setSelectedModule(module.id)}
                >
                  <div className="flex items-start space-x-4">
                    <div className={`p-3 rounded-lg ${module.color}`}>
                      <module.icon className="h-6 w-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-lg font-medium text-gray-900 mb-2">{module.title}</h3>
                      <p className="text-gray-600 mb-3">{module.description}</p>
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-sm text-gray-500">{module.duration}</span>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(module.status)}`}>
                          {getStatusText(module.status)}
                        </span>
                      </div>
                      {module.progress > 0 && (
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <div
                            className={`h-2 rounded-full ${module.color}`}
                            style={{ width: `${module.progress}%` }}
                          ></div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Training Actions */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">Training Actions</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button className="flex items-center justify-center px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                <DocumentTextIcon className="h-5 w-5 text-gray-600 mr-2" />
                <span className="text-sm font-medium text-gray-700">Create New Module</span>
              </button>
              <button className="flex items-center justify-center px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                <ChartBarIcon className="h-5 w-5 text-gray-600 mr-2" />
                <span className="text-sm font-medium text-gray-700">View Progress Reports</span>
              </button>
              <button className="flex items-center justify-center px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                <UsersIcon className="h-5 w-5 text-gray-600 mr-2" />
                <span className="text-sm font-medium text-gray-700">Manage Collectors</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
} 