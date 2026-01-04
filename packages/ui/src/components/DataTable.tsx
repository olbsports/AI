'use client';

import * as React from 'react';
import {
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
} from 'lucide-react';

import { cn } from '../utils/cn';
import { Button } from './Button';

// Table components
const Table = React.forwardRef<
  HTMLTableElement,
  React.HTMLAttributes<HTMLTableElement>
>(({ className, ...props }, ref) => (
  <div className="relative w-full overflow-auto">
    <table
      ref={ref}
      className={cn('w-full caption-bottom text-sm', className)}
      {...props}
    />
  </div>
));
Table.displayName = 'Table';

const TableHeader = React.forwardRef<
  HTMLTableSectionElement,
  React.HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <thead ref={ref} className={cn('[&_tr]:border-b', className)} {...props} />
));
TableHeader.displayName = 'TableHeader';

const TableBody = React.forwardRef<
  HTMLTableSectionElement,
  React.HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <tbody
    ref={ref}
    className={cn('[&_tr:last-child]:border-0', className)}
    {...props}
  />
));
TableBody.displayName = 'TableBody';

const TableFooter = React.forwardRef<
  HTMLTableSectionElement,
  React.HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <tfoot
    ref={ref}
    className={cn(
      'border-t bg-muted/50 font-medium [&>tr]:last:border-b-0',
      className
    )}
    {...props}
  />
));
TableFooter.displayName = 'TableFooter';

const TableRow = React.forwardRef<
  HTMLTableRowElement,
  React.HTMLAttributes<HTMLTableRowElement>
>(({ className, ...props }, ref) => (
  <tr
    ref={ref}
    className={cn(
      'border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted',
      className
    )}
    {...props}
  />
));
TableRow.displayName = 'TableRow';

const TableHead = React.forwardRef<
  HTMLTableCellElement,
  React.ThHTMLAttributes<HTMLTableCellElement>
>(({ className, ...props }, ref) => (
  <th
    ref={ref}
    className={cn(
      'h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0',
      className
    )}
    {...props}
  />
));
TableHead.displayName = 'TableHead';

const TableCell = React.forwardRef<
  HTMLTableCellElement,
  React.TdHTMLAttributes<HTMLTableCellElement>
>(({ className, ...props }, ref) => (
  <td
    ref={ref}
    className={cn('p-4 align-middle [&:has([role=checkbox])]:pr-0', className)}
    {...props}
  />
));
TableCell.displayName = 'TableCell';

const TableCaption = React.forwardRef<
  HTMLTableCaptionElement,
  React.HTMLAttributes<HTMLTableCaptionElement>
>(({ className, ...props }, ref) => (
  <caption
    ref={ref}
    className={cn('mt-4 text-sm text-muted-foreground', className)}
    {...props}
  />
));
TableCaption.displayName = 'TableCaption';

// Column definition type
export interface ColumnDef<T> {
  id: string;
  header: string | React.ReactNode;
  accessorKey?: keyof T;
  accessorFn?: (row: T) => React.ReactNode;
  cell?: (props: { row: T; value: unknown }) => React.ReactNode;
  sortable?: boolean;
  className?: string;
}

// Sort direction type
type SortDirection = 'asc' | 'desc' | null;

// DataTable props
interface DataTableProps<T> {
  data: T[];
  columns: ColumnDef<T>[];
  pageSize?: number;
  showPagination?: boolean;
  onRowClick?: (row: T) => void;
  isLoading?: boolean;
  emptyMessage?: string;
  className?: string;
}

// Main DataTable component
function DataTable<T extends { id: string | number }>({
  data,
  columns,
  pageSize = 10,
  showPagination = true,
  onRowClick,
  isLoading = false,
  emptyMessage = 'Aucune donnée disponible',
  className,
}: DataTableProps<T>) {
  const [currentPage, setCurrentPage] = React.useState(1);
  const [sortColumn, setSortColumn] = React.useState<string | null>(null);
  const [sortDirection, setSortDirection] = React.useState<SortDirection>(null);

  // Sort data
  const sortedData = React.useMemo(() => {
    if (!sortColumn || !sortDirection) return data;

    const column = columns.find((col) => col.id === sortColumn);
    if (!column) return data;

    return [...data].sort((a, b) => {
      let aValue: unknown;
      let bValue: unknown;

      if (column.accessorFn) {
        aValue = column.accessorFn(a);
        bValue = column.accessorFn(b);
      } else if (column.accessorKey) {
        aValue = a[column.accessorKey];
        bValue = b[column.accessorKey];
      }

      if (aValue === bValue) return 0;
      if (aValue === null || aValue === undefined) return 1;
      if (bValue === null || bValue === undefined) return -1;

      const comparison = aValue < bValue ? -1 : 1;
      return sortDirection === 'asc' ? comparison : -comparison;
    });
  }, [data, sortColumn, sortDirection, columns]);

  // Paginate data
  const totalPages = Math.ceil(sortedData.length / pageSize);
  const paginatedData = showPagination
    ? sortedData.slice((currentPage - 1) * pageSize, currentPage * pageSize)
    : sortedData;

  // Handle sort
  const handleSort = (columnId: string) => {
    if (sortColumn === columnId) {
      if (sortDirection === 'asc') {
        setSortDirection('desc');
      } else if (sortDirection === 'desc') {
        setSortColumn(null);
        setSortDirection(null);
      }
    } else {
      setSortColumn(columnId);
      setSortDirection('asc');
    }
  };

  // Get cell value
  const getCellValue = (row: T, column: ColumnDef<T>): React.ReactNode => {
    let value: unknown;

    if (column.accessorFn) {
      value = column.accessorFn(row);
    } else if (column.accessorKey) {
      value = row[column.accessorKey];
    }

    if (column.cell) {
      return column.cell({ row, value });
    }

    return value as React.ReactNode;
  };

  // Render sort icon
  const renderSortIcon = (columnId: string) => {
    if (sortColumn !== columnId) {
      return <ArrowUpDown className="ml-2 h-4 w-4" />;
    }
    if (sortDirection === 'asc') {
      return <ArrowUp className="ml-2 h-4 w-4" />;
    }
    return <ArrowDown className="ml-2 h-4 w-4" />;
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-10">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className={cn('space-y-4', className)}>
      <Table>
        <TableHeader>
          <TableRow>
            {columns.map((column) => (
              <TableHead key={column.id} className={column.className}>
                {column.sortable ? (
                  <button
                    className="flex items-center hover:text-foreground transition-colors"
                    onClick={() => handleSort(column.id)}
                  >
                    {column.header}
                    {renderSortIcon(column.id)}
                  </button>
                ) : (
                  column.header
                )}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {paginatedData.length === 0 ? (
            <TableRow>
              <TableCell
                colSpan={columns.length}
                className="h-24 text-center text-muted-foreground"
              >
                {emptyMessage}
              </TableCell>
            </TableRow>
          ) : (
            paginatedData.map((row) => (
              <TableRow
                key={row.id}
                onClick={() => onRowClick?.(row)}
                className={onRowClick ? 'cursor-pointer' : undefined}
              >
                {columns.map((column) => (
                  <TableCell key={column.id} className={column.className}>
                    {getCellValue(row, column)}
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      {showPagination && totalPages > 1 && (
        <div className="flex items-center justify-between px-2">
          <p className="text-sm text-muted-foreground">
            {(currentPage - 1) * pageSize + 1} -{' '}
            {Math.min(currentPage * pageSize, sortedData.length)} sur{' '}
            {sortedData.length} résultats
          </p>
          <div className="flex items-center space-x-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(1)}
              disabled={currentPage === 1}
            >
              <ChevronsLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="text-sm">
              Page {currentPage} sur {totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(totalPages)}
              disabled={currentPage === totalPages}
            >
              <ChevronsRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

export {
  DataTable,
  Table,
  TableHeader,
  TableBody,
  TableFooter,
  TableHead,
  TableRow,
  TableCell,
  TableCaption,
  type ColumnDef,
};
