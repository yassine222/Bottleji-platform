'use client';

import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
} from 'recharts';

// Users Growth Chart
export function UsersGrowthChart({ data }: { data: any[] }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Users Growth</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="count" stroke="#00695C" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

// Drops Activity Chart
export function DropsActivityChart({ data }: { data: any[] }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Drops Activity</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="count" stroke="#00695C" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

// Collector Interactions Chart
export function CollectorInteractionsChart({ data }: { data: any[] }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Collector Interactions</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="interactions" stroke="#00695C" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

// Drop Status Pie Chart
export function Co2SavingsChart({ data }: { data?: { date: string; co2: number }[] }) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const formatLabel = (dateStr: string) => {
    const date = new Date(`${dateStr}T00:00:00`);
    date.setHours(0, 0, 0, 0);
    const diffMs = today.getTime() - date.getTime();
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays === 2) return '2 days ago';
    if (diffDays === 3) return '3 days ago';
    if (diffDays === 4) return '4 days ago';
    if (diffDays === 5) return '5 days ago';
    if (diffDays === 6) return '6 days ago';
    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  };

  const fallbackData = Array.from({ length: 7 }).map((_, idx) => {
    const date = new Date();
    date.setDate(date.getDate() - (6 - idx));
    date.setHours(0, 0, 0, 0);
    const base = 50 + Math.random() * 150; // 50-200 kg baseline
    const variability = Math.sin((idx / 6) * Math.PI) * 40; // gentle mid-week bump
    const noise = (Math.random() - 0.5) * 20; // ±10 kg noise
    const value = base + variability + noise;
    return {
      date: date.toISOString().split('T')[0],
      co2: Math.max(0, Math.round(value * 100) / 100),
    };
  });

  const sourceData = fallbackData;

  const chartData = sourceData.map((item) => ({
    label: formatLabel(item.date),
    co2: Number((item.co2 || 0).toFixed(2)),
  }));

  const totalCo2 = chartData.reduce((sum, entry) => sum + entry.co2, 0);

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">CO₂ Saved (Last 7 Days)</h3>
        <span className="text-sm text-gray-500">Total: {totalCo2.toFixed(2)} kg</span>
      </div>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={chartData}
            margin={{ top: 8, right: 12, left: 8, bottom: 8 }}
            barCategoryGap="25%"
          >
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="label" tick={{ fontSize: 12 }} interval={0} />
            <YAxis tickFormatter={(value) => `${value} kg`} />
            <Tooltip formatter={(value: number) => [`${value.toFixed(2)} kg`, 'CO₂ Saved']} />
            <Bar dataKey="co2" fill="#00695C" radius={[8, 8, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

export function TicketsByCategory({ data }: { data: any }) {
  const COLORS = ['#00695C', '#4CAF50', '#FF9800', '#F44336', '#9C27B0'];
  
  const barData = Object.entries(data).map(([key, value], index) => ({
    name: key,
    value: value,
    color: COLORS[index % COLORS.length]
  }));

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Tickets by Category</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={barData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="value" fill="#00695C" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
