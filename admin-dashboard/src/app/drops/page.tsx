'use client';

import { useState, useEffect } from 'react';
import axios from 'axios';
import AdminLayout from '@/components/layout/AdminLayout';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { 
  TrendingUp, 
  TrendingDown, 
  MapPin, 
  Clock, 
  Package, 
  AlertTriangle,
  CheckCircle,
  XCircle,
  Trophy,
  Users,
  Calendar,
  Filter,
  Search,
  Download,
  Eye,
  EyeOff,
  BarChart3,
  ClipboardList,
  GraduationCap,
  MessageCircle,
  Settings,
  Flag,
  Shield,
  Ban
} from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://172.20.10.12:3000/api';

interface DropsStats {
  totalDrops: number;
  activeDrops: number;
  completedDrops: number;
  flaggedDrops: number;
  oldDrops: number;
  reportedDrops: number;
  collectedDrops: number;
  censoredDrops: number;
  dropsByStatus: Record<string, number>;
  dropsLast7Days: number;
  dropsLast30Days: number;
}

interface TimeBasedStats {
  thisWeek: number;
  lastWeek: number;
  weekChange: number;
  thisMonth: number;
  lastMonth: number;
  monthChange: number;
}

interface SuccessRateStats {
  total: number;
  collected: number;
  cancelled: number;
  expired: number;
  successRate: number;
  cancellationRate: number;
  expirationRate: number;
}

interface CollectorLeaderboard {
  collectorId: string;
  collectorName: string;
  collectorEmail: string;
  totalCollections: number;
  averageDuration: number;
}

interface HouseholdRanking {
  userId: string;
  userName: string;
  userEmail: string;
  totalDrops: number;
  collectedDrops: number;
  successRate: number;
}

interface OldDrop {
  _id: string;
  userId: { name: string; email: string };
  location: { latitude: number; longitude: number };
  status: string;
  createdAt: string;
  ageInDays: number;
  reason: string;
  notes?: string;
  numberOfBottles: number;
  numberOfCans: number;
}

const COLORS = {
  primary: '#00695C',
  success: '#4CAF50',
  warning: '#FF9800',
  error: '#F44336',
  info: '#2196F3',
  pending: '#FFC107',
  collected: '#4CAF50',
  cancelled: '#9E9E9E',
  expired: '#FF5722',
  stale: '#795548',
};

export default function DropsManagementPage() {
  const [stats, setStats] = useState<DropsStats | null>(null);
  const [timeBasedStats, setTimeBasedStats] = useState<TimeBasedStats | null>(null);
  const [successRate, setSuccessRate] = useState<SuccessRateStats | null>(null);
  const [collectorLeaderboard, setCollectorLeaderboard] = useState<CollectorLeaderboard[]>([]);
  const [householdRankings, setHouseholdRankings] = useState<HouseholdRanking[]>([]);
  const [oldDrops, setOldDrops] = useState<OldDrop[]>([]);
  const [selectedOldDrops, setSelectedOldDrops] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [showOldDropsModal, setShowOldDropsModal] = useState(false);

  useEffect(() => {
    fetchAllData();
  }, []);

  const fetchAllData = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('token');
      const config = { headers: { Authorization: `Bearer ${token}` } };

      const [
        statsRes,
        timeRes,
        successRes,
        collectorRes,
        householdRes,
      ] = await Promise.all([
        axios.get(`${API_URL}/admin/drops/stats`, config),
        axios.get(`${API_URL}/admin/drops/analytics/time-based`, config),
        axios.get(`${API_URL}/admin/drops/analytics/success-rate`, config),
        axios.get(`${API_URL}/admin/drops/performance/collector-leaderboard?limit=5`, config),
        axios.get(`${API_URL}/admin/drops/performance/household-rankings?limit=5`, config),
      ]);

      setStats(statsRes.data.stats);
      setTimeBasedStats(timeRes.data.stats);
      setSuccessRate(successRes.data.stats);
      setCollectorLeaderboard(collectorRes.data.leaderboard);
      setHouseholdRankings(householdRes.data.rankings);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const analyzeOldDrops = async () => {
    try {
      const token = localStorage.getItem('token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      const response = await axios.get(`${API_URL}/admin/drops/analyze-old`, config);
      setOldDrops(response.data.drops);
      setShowOldDropsModal(true);
    } catch (error) {
      console.error('Error analyzing old drops:', error);
    }
  };

  const hideSelectedDrops = async () => {
    if (selectedOldDrops.length === 0) return;
    
    try {
      const token = localStorage.getItem('token');
      const config = { headers: { Authorization: `Bearer ${token}` } };
      await axios.post(`${API_URL}/admin/drops/hide-old`, 
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

  if (loading || !stats) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Prepare status pie chart data
  const statusData = [
    { name: 'Pending', value: stats.dropsByStatus['pending'] || 0, color: COLORS.pending },
    { name: 'Collected', value: stats.dropsByStatus['collected'] || 0, color: COLORS.collected },
    { name: 'Cancelled', value: stats.dropsByStatus['cancelled'] || 0, color: COLORS.cancelled },
    { name: 'Expired', value: stats.dropsByStatus['expired'] || 0, color: COLORS.expired },
    { name: 'Stale', value: stats.dropsByStatus['stale'] || 0, color: COLORS.stale },
  ];

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header Section */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-green-100 rounded-lg">
                <Package className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Drops Management</h1>
                <p className="text-gray-600">Monitor, analyze, and manage all drops in the system</p>
              </div>
            </div>
          </div>
        </div>

      {/* Stats Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Total Drops"
          value={stats.totalDrops}
          icon={<Package className="w-6 h-6" />}
          color="bg-blue-500"
          trend={timeBasedStats ? `${timeBasedStats.weekChange > 0 ? '+' : ''}${timeBasedStats.weekChange.toFixed(1)}% this week` : ''}
          trendUp={timeBasedStats ? timeBasedStats.weekChange > 0 : false}
        />
        <StatCard
          title="Active Drops"
          value={stats.activeDrops}
          icon={<Clock className="w-6 h-6" />}
          color="bg-green-500"
        />
        <StatCard
          title="Flagged Drops"
          value={stats.flaggedDrops}
          icon={<AlertTriangle className="w-6 h-6" />}
          color="bg-orange-500"
        />
        <StatCard
          title="Old Drops (&gt;3 days)"
          value={stats.oldDrops}
          icon={<XCircle className="w-6 h-6" />}
          color="bg-red-500"
          action={
            <button
              onClick={analyzeOldDrops}
              className="mt-3 w-full bg-white text-red-600 border border-red-600 px-4 py-2 rounded-lg hover:bg-red-50 transition-colors text-sm font-medium"
            >
              Analyze Old Drops
            </button>
          }
        />
      </div>

      {/* Additional Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <StatCard
          title="Reported Drops"
          value={stats.reportedDrops || 0}
          icon={<Flag className="w-6 h-6" />}
          color="bg-red-500"
          description="Drops reported by users for issues"
          action={
            <button className="mt-3 w-full bg-red-50 text-red-600 border border-red-200 px-4 py-2 rounded-lg hover:bg-red-100 transition-colors text-sm font-medium">
              View Reports
            </button>
          }
        />
        <StatCard
          title="Collected Drops"
          value={stats.collectedDrops || 0}
          icon={<CheckCircle className="w-6 h-6" />}
          color="bg-green-500"
          description="Successfully collected drops"
          action={
            <button className="mt-3 w-full bg-green-50 text-green-600 border border-green-200 px-4 py-2 rounded-lg hover:bg-green-100 transition-colors text-sm font-medium">
              View Collections
            </button>
          }
        />
        <StatCard
          title="Censored Drops"
          value={stats.censoredDrops || 0}
          icon={<Ban className="w-6 h-6" />}
          color="bg-purple-500"
          description="Drops that have been censored"
          action={
            <button className="mt-3 w-full bg-purple-50 text-purple-600 border border-purple-200 px-4 py-2 rounded-lg hover:bg-purple-100 transition-colors text-sm font-medium">
              Manage Censorship
            </button>
          }
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Success Rate Chart */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4 text-gray-900">Drop Success Rate</h2>
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
              <div className="pt-4">
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={[
                        { name: 'Collected', value: successRate.collected },
                        { name: 'Cancelled', value: successRate.cancelled },
                        { name: 'Expired', value: successRate.expired },
                      ]}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      <Cell fill={COLORS.collected} />
                      <Cell fill={COLORS.cancelled} />
                      <Cell fill={COLORS.expired} />
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </div>

        {/* Status Distribution */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4 text-gray-900">Status Distribution</h2>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie
                data={statusData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name}: ${((percent || 0) * 100).toFixed(0)}%`}
                outerRadius={80}
                dataKey="value"
              >
                {statusData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Leaderboards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Collector Leaderboard */}
        <div className="bg-white rounded-xl shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
              <Trophy className="w-6 h-6 text-yellow-500" />
              Top Collectors
            </h2>
          </div>
          <div className="space-y-3">
            {collectorLeaderboard.map((collector, index) => (
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
            <h2 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
              <Users className="w-6 h-6 text-blue-500" />
              Top Households
            </h2>
          </div>
          <div className="space-y-3">
            {householdRankings.map((household, index) => (
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
                  <XCircle className="w-6 h-6" />
                </button>
              </div>
              <p className="text-gray-600 mt-2">Found {oldDrops.length} drops older than 3 days that have not been collected</p>
            </div>
            
            <div className="flex-1 overflow-auto p-6">
              <div className="space-y-3">
                {oldDrops.map((drop) => (
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
                      <p className="text-sm text-gray-500">
                        📍 {drop.location.latitude.toFixed(4)}, {drop.location.longitude.toFixed(4)} • 
                        🍾 {drop.numberOfBottles} bottles • 🥫 {drop.numberOfCans} cans
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
                    onClick={() => setSelectedOldDrops(oldDrops.map(d => d._id))}
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
      </div>
    </AdminLayout>
  );
} 

function StatCard({ 
  title, 
  value, 
  icon, 
  color, 
  trend, 
  trendUp, 
  action,
  description
}: { 
  title: string; 
  value: number; 
  icon: React.ReactNode; 
  color: string; 
  trend?: string; 
  trendUp?: boolean;
  action?: React.ReactNode;
  description?: string;
}) {
  return (
    <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-center justify-between mb-4">
        <div className={`${color} p-3 rounded-lg text-white`}>
          {icon}
        </div>
        {trend && (
          <div className={`flex items-center gap-1 text-sm ${trendUp ? 'text-green-600' : 'text-red-600'}`}>
            {trendUp ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
            {trend}
          </div>
        )}
      </div>
      <h3 className="text-gray-600 text-sm font-medium mb-1">{title}</h3>
      <p className="text-3xl font-bold text-gray-900">{value.toLocaleString()}</p>
      {description && (
        <p className="text-xs text-gray-500 mt-2">{description}</p>
      )}
      {action && action}
    </div>
  );
}
