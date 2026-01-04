'use client';

import {
  Bar,
  BarChart as RechartsBarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

interface BarChartProps {
  data: { name: string; value: number }[];
  color?: string;
  height?: number;
  horizontal?: boolean;
  formatValue?: (value: number) => string;
}

export function BarChart({
  data,
  color = '#0066cc',
  height = 300,
  horizontal = false,
  formatValue = (v) => v.toString(),
}: BarChartProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <RechartsBarChart
        data={data}
        layout={horizontal ? 'vertical' : 'horizontal'}
        margin={{ top: 10, right: 10, left: horizontal ? 80 : 0, bottom: 0 }}
      >
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
        {horizontal ? (
          <>
            <XAxis type="number" tick={{ fontSize: 12 }} tickFormatter={formatValue} />
            <YAxis type="category" dataKey="name" tick={{ fontSize: 12 }} width={70} />
          </>
        ) : (
          <>
            <XAxis dataKey="name" tick={{ fontSize: 12 }} tickLine={false} />
            <YAxis tick={{ fontSize: 12 }} tickFormatter={formatValue} />
          </>
        )}
        <Tooltip
          contentStyle={{
            backgroundColor: 'white',
            border: '1px solid #e5e7eb',
            borderRadius: '8px',
            boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
          }}
          formatter={(value: number) => [formatValue(value), 'Value']}
        />
        <Bar dataKey="value" fill={color} radius={[4, 4, 0, 0]} />
      </RechartsBarChart>
    </ResponsiveContainer>
  );
}
