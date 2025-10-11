'use client';

import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const COLORS = {
  primary: '#00695C',
  secondary: '#0288D1',
  success: '#4CAF50',
  warning: '#FF9800',
  error: '#F44336',
  purple: '#9C27B0',
  pink: '#E91E63',
  teal: '#009688',
};

const PIE_COLORS = ['#00695C', '#0288D1', '#4CAF50', '#FF9800', '#F44336', '#9C27B0'];

interface UsersGrowthChartProps {
  data: Array<{ date: string; count: number }>;
}

export function UsersGrowthChart({ data }: UsersGrowthChartProps) {
  // Calculate cumulative users
  const cumulativeData = data.reduce((acc, curr, index) => {
    const previousCount = index > 0 ? acc[index - 1].total : 0;
    acc.push({
      date: new Date(curr.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      new: curr.count,
      total: previousCount + curr.count
    });
    return acc;
  }, [] as Array<{ date: string; new: number; total: number }>);

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">User Growth (Last 30 Days)</h3>
      <ResponsiveContainer width="100%" height={300}>
        <AreaChart data={cumulativeData}>
          <defs>
            <linearGradient id="colorTotal" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={COLORS.primary} stopOpacity={0.8}/>
              <stop offset="95%" stopColor={COLORS.primary} stopOpacity={0.1}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Area type="monotone" dataKey="total" stroke={COLORS.primary} fillOpacity={1} fill="url(#colorTotal)" name="Total Users" />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

interface DropsActivityChartProps {
  data: Array<{ date: string; count: number }>;
}

export function DropsActivityChart({ data }: DropsActivityChartProps) {
  const formattedData = data.map(item => ({
    date: new Date(item.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    drops: item.count
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Drops Activity (Last 30 Days)</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={formattedData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="drops" fill={COLORS.secondary} name="Drops Created" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

interface CollectorInteractionsChartProps {
  data: Array<{ date: string; accepted: number; collected: number; cancelled: number; expired: number }>;
}

export function CollectorInteractionsChart({ data }: CollectorInteractionsChartProps) {
  const formattedData = data.map(item => ({
    date: new Date(item.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    Accepted: item.accepted,
    Collected: item.collected,
    Cancelled: item.cancelled,
    Expired: item.expired
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Collector Interactions (Last 30 Days)</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={formattedData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="Accepted" stroke={COLORS.success} strokeWidth={2} />
          <Line type="monotone" dataKey="Collected" stroke={COLORS.primary} strokeWidth={2} />
          <Line type="monotone" dataKey="Cancelled" stroke={COLORS.error} strokeWidth={2} />
          <Line type="monotone" dataKey="Expired" stroke={COLORS.warning} strokeWidth={2} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

interface DropStatusPieChartProps {
  data: Record<string, number>;
}

export function DropStatusPieChart({ data }: DropStatusPieChartProps) {
  const chartData = Object.entries(data).map(([status, count]) => ({
    name: status.charAt(0).toUpperCase() + status.slice(1),
    value: count
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Drops by Status</h3>
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
            ))}
          </Pie>
          <Tooltip />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}

interface BottleTypeDistributionProps {
  data: Record<string, number>;
}

export function BottleTypeDistribution({ data }: BottleTypeDistributionProps) {
  const chartData = Object.entries(data).map(([type, count]) => ({
    name: type.charAt(0).toUpperCase() + type.slice(1),
    value: count
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Bottle Type Distribution</h3>
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
            ))}
          </Pie>
          <Tooltip />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}

interface TicketsByCategoryProps {
  data: Record<string, number>;
}

export function TicketsByCategory({ data }: TicketsByCategoryProps) {
  const chartData = Object.entries(data).map(([category, count]) => ({
    category: category.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' '),
    count
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Support Tickets by Category</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={chartData} layout="vertical">
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis type="number" />
          <YAxis dataKey="category" type="category" width={150} />
          <Tooltip />
          <Bar dataKey="count" fill={COLORS.purple} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

interface ApplicationsStatusProps {
  data: Record<string, number>;
}

export function ApplicationsStatus({ data }: ApplicationsStatusProps) {
  const chartData = Object.entries(data).map(([status, count]) => ({
    name: status.charAt(0).toUpperCase() + status.slice(1),
    value: count
  }));

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'pending': return COLORS.warning;
      case 'approved': return COLORS.success;
      case 'rejected': return COLORS.error;
      default: return COLORS.primary;
    }
  };

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Collector Applications Status</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Bar dataKey="value" name="Applications">
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={getStatusColor(entry.name)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

