import React, { useMemo, useState } from 'react';
import { Activity, PlayCircle, ArrowUpDown, ArrowUp, ArrowDown } from 'lucide-react';
import { Tooltip } from 'react-tooltip';
import Badge from './Badge';

const columnMapping = {
  task_identifier: 'Identificador',
  status: 'Status DMS',
  migration_progress: 'Progresso',
  sfn_status: 'Status Recuperação',
  sfn_finished_at: 'Última Execução',
};

const Table = ({
  data,
  onEditDocument, 
  onViewDocument, 
}) => {
  const [sortConfig, setSortConfig] = useState({
    key: '',
    direction: 'asc',
  });

  const handleSort = (column) => {
    let direction = 'asc';
    if (sortConfig.key === column && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key: column, direction });
  };

  const content = data?.content || [];

  const sortedData = useMemo(() => {
    if (!sortConfig.key) return content;
    return [...content].sort((a, b) => {
      const aValue = a[sortConfig.key] || '';
      const bValue = b[sortConfig.key] || '';
      
      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [content, sortConfig]);

  const columns = content.length > 0
    ? Object.keys(content[0]).filter(col => !['id', 'raw'].includes(col))
    : [];

  const renderCellContent = (colKey, value) => {
    if (colKey === 'status' || colKey === 'sfn_status') {
      return <Badge text={String(value)} />;
    }
    if (colKey === 'migration_progress') {
        return <span className="font-mono text-xs font-bold bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">{value}%</span>
    }
    return <span className="text-gray-700 dark:text-gray-300 text-sm">{value}</span>;
  };

  const getSortIcon = (col) => {
    if (sortConfig.key !== col) return <ArrowUpDown size={14} className="text-gray-400" />;
    if (sortConfig.direction === 'asc') return <ArrowUp size={14} className="text-indigo-600 dark:text-indigo-400" />;
    return <ArrowDown size={14} className="text-indigo-600 dark:text-indigo-400" />;
  };

  return (
    <div className="w-full overflow-hidden rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
      <div className="overflow-x-auto">
        <table className="w-full whitespace-nowrap">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-700/50 border-b border-gray-200 dark:border-gray-700 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              {columns.map((col) => (
                <th key={col} className="px-6 py-3 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors select-none" onClick={() => handleSort(col)}>
                  <div className="flex items-center gap-2">
                    {columnMapping[col] || col}
                    {getSortIcon(col)}
                  </div>
                </th>
              ))}
              <th className="px-6 py-3 text-center">Ações</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            {sortedData.map((row, index) => (
              <tr key={`${row.id}-${index}`} className="hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors">
                {columns.map((col) => (
                  <td key={col} className="px-6 py-4">
                    {renderCellContent(col, row[col])}
                  </td>
                ))}
                <td className="px-6 py-4 text-center">
                  <div className="flex items-center justify-center gap-3">
                    <button
                      onClick={() => onViewDocument?.(row.raw)}
                      className="p-2 rounded-md text-blue-600 hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-900/20 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                      data-tooltip-id="test-conn"
                      data-tooltip-content="Testar Conexão"
                      disabled={row.raw.connectionDisabled}
                    >
                      <Activity size={18} />
                    </button>

                    <button
                      onClick={() => onEditDocument?.(row.raw)}
                      className="p-2 rounded-md text-amber-600 hover:bg-amber-50 dark:text-amber-400 dark:hover:bg-amber-900/20 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                      data-tooltip-id="restart"
                      data-tooltip-content="Reiniciar Task"
                      disabled={row.raw.restartDisabled}
                    >
                      <PlayCircle size={18} />
                    </button>
                    <Tooltip id="test-conn" className="z-50 text-xs" />
                    <Tooltip id="restart" className="z-50 text-xs" />
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {content.length === 0 && (
        <div className="p-12 text-center text-gray-500 dark:text-gray-400 flex flex-col items-center">
          <p>Nenhuma task encontrada.</p>
        </div>
      )}
    </div>
  );
};

export default Table;