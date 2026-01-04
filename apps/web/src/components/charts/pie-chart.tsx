'use client';

import { Cell, Pie, PieChart as RechartsPieChart, ResponsiveContainer, Tooltip, Legend } from 'recharts';

interface PieChartProps {
  data: { name: string; value: number }[];
  colors?: string[];
  height?: number;
  showLegend?: boolean;
  innerRadius?: number;
}

const DEFAULT_COLORS = ['#0066cc', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

export function PieChart({
  data,
  colors = DEFAULT_COLORS,
  height = 300,
  showLegend = true,
  innerRadius = 0,
}: PieChartProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <RechartsPieChart>
        <Pie
          data={data}
          dataKey="value"
          nameKey="name"
          cx="50%"
          cy="50%"
          outerRadius={80}
          innerRadius={innerRadius}
          paddingAngle={2}
          label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
          labelLine={false}
        >
          {data.map((_, index) => (
            <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            backgroundColor: 'white',
            border: '1px solid #e5e7eb',
            borderRadius: '8px',
            boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
          }}
        />
        {showLegend && <Legend />}
      </RechartsPieChart>
    </ResponsiveContainer>
  );
}
