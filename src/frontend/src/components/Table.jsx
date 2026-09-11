import { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { PlayCircle, ArrowUpDown, ArrowUp, ArrowDown, Wifi } from 'lucide-react';
import { Tooltip } from 'react-tooltip';
import Badge from './Badge';

// Formata data ISO para dd/mm/aaaa hh:mm
const formatTimestamp = (isoString) => {
  if (!isoString || isoString === '-') return '-';
  try {
    return new Date(isoString).toLocaleString('pt-BR', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  } catch { return '-'; }
};

const SortIcon = ({ col, sortConfig }) => {
  if (sortConfig.key !== col) return <ArrowUpDown size={12} className="text-gray-500 opacity-50" />;
  return sortConfig.direction === 'asc'
    ? <ArrowUp size={12} className="text-indigo-400" />
    : <ArrowDown size={12} className="text-indigo-400" />;
};

SortIcon.propTypes = {
  col: PropTypes.string.isRequired,
  sortConfig: PropTypes.shape({
    key: PropTypes.string.isRequired,
    direction: PropTypes.oneOf(['asc', 'desc']).isRequired,
  }).isRequired,
};

// Badge de Step Function
const SfnBadge = ({ status }) => {
  const s = (status || '').toLowerCase();
  const isRunning = ['running', 'iniciando...', 'executando'].includes(s);
  const isSuccess = s === 'succeeded';
  const isFailed = ['failed', 'falha'].includes(s);

  let cls = 'text-gray-400 dark:text-gray-500';
  if (isRunning) cls = 'text-blue-400 animate-pulse';
  else if (isSuccess) cls = 'text-emerald-400';
  else if (isFailed) cls = 'text-red-400';

  return (
    <span className={`text-xs font-semibold uppercase tracking-wider ${cls}`}>
      {status || 'INATIVO'}
    </span>
  );
};

SfnBadge.propTypes = {
  status: PropTypes.string,
};

const Table = ({ data, onEditDocument, onViewDocument }) => {
  const [sortConfig, setSortConfig] = useState({ key: '', direction: 'asc' });

  const handleSort = (key) => {
    setSortConfig(prev => ({
      key,
      direction: prev.key === key && prev.direction === 'asc' ? 'desc' : 'asc',
    }));
  };

  const content = useMemo(() => data?.content ?? [], [data?.content]);

  const sortedData = useMemo(() => {
    if (!sortConfig.key) return content;
    return [...content].sort((a, b) => {
      const av = a[sortConfig.key] || '';
      const bv = b[sortConfig.key] || '';
      if (av < bv) return sortConfig.direction === 'asc' ? -1 : 1;
      if (av > bv) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [content, sortConfig]);

  const headers = [
    { key: 'task_identifier', label: 'TASK IDENTIFIER', align: 'left' },
    { key: 'status',          label: 'STATUS DMS',      align: 'center' },
    { key: null,              label: 'CONEXÃO',          align: 'center' },
    { key: null,              label: 'RECOVERY',         align: 'center' },
    { key: 'sfn_status',      label: 'STEP FUNCTION',   align: 'center' },
    { key: 'sfn_finished_at', label: 'ÚLTIMA ATUALIZAÇÃO', align: 'right' },
  ];

  return (
    <div className="w-full overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700/60 shadow-sm bg-white dark:bg-gray-900">
      <div className="overflow-x-auto">
        <table className="w-full">
          {/* ── HEADER ── */}
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-700/60 bg-gray-50 dark:bg-gray-800/80">
              {headers.map((h, i) => (
                <th
                  key={i}
                  onClick={() => h.key && handleSort(h.key)}
                  className={`
                    px-5 py-3 text-xs font-semibold tracking-widest text-gray-500 dark:text-gray-400 uppercase
                    ${h.align === 'center' ? 'text-center' : h.align === 'right' ? 'text-right' : 'text-left'}
                    ${h.key ? 'cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none' : ''}
                    transition-colors
                  `}
                >
                  <div className={`inline-flex items-center gap-1.5 ${h.align === 'center' ? 'justify-center' : h.align === 'right' ? 'justify-end' : ''}`}>
                    {h.label}
                    {h.key && <SortIcon col={h.key} sortConfig={sortConfig} />}
                  </div>
                </th>
              ))}
            </tr>
          </thead>

          {/* ── BODY ── */}
          <tbody>
            {sortedData.map((row, idx) => {
              const task = row.raw;
              const sfnStatus = (row.sfn_status || '').toLowerCase();
              const isProcessing = ['running', 'iniciando...', 'executando'].includes(sfnStatus);

              return (
                <tr
                  key={`${row.id}-${idx}`}
                  className="group border-b border-gray-100 dark:border-gray-700/40 hover:bg-indigo-50/30 dark:hover:bg-indigo-900/10 transition-colors"
                >
                  {/* TASK IDENTIFIER */}
                  <td className="px-5 py-3.5 text-sm font-mono font-medium text-indigo-600 dark:text-indigo-400 max-w-xs truncate">
                    <span title={row.task_identifier}>{row.task_identifier}</span>
                  </td>

                  {/* STATUS DMS */}
                  <td className="px-5 py-3.5 text-center">
                    <Badge text={String(row.status || '-')} />
                  </td>

                  {/* CONEXÃO */}
                  <td className="px-5 py-3.5 text-center">
                    <button
                      onClick={() => onViewDocument?.(task)}
                      disabled={task?.connectionDisabled}
                      data-tooltip-id="tt-conn"
                      data-tooltip-content="Testar Conexão"
                      className={`
                        inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border
                        disabled:opacity-30 disabled:cursor-not-allowed transition-all
                        ${
                          task?.connectionText === "Conexão (OK)"
                            ? "bg-green-50 text-green-700 border-green-300 dark:bg-green-900/30 dark:text-green-400 dark:border-green-800"
                            : task?.connectionText?.includes("Erro") || task?.connectionText?.includes("Falha")
                            ? "bg-red-50 text-red-700 border-red-300 dark:bg-red-900/30 dark:text-red-400 dark:border-red-800"
                            : "border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:border-blue-400 hover:text-blue-600 dark:hover:text-blue-400"
                        }
                      `}
                    >
                      <Wifi size={12} />
                      {task?.connectionText || "Testar"}
                    </button>
                  </td>

                  {/* RECOVERY (Restart) */}
                  <td className="px-5 py-3.5 text-center">
                    <button
                      onClick={() => onEditDocument?.(task)}
                      disabled={
                        task?.restartDisabled ||
                        isProcessing ||
                        task?.connectionText !== "Conexão (OK)" ||
                        !['failed', 'stopped'].includes(String(task?.Status || '').toLowerCase())
                      }
                      data-tooltip-id="tt-restart"
                      data-tooltip-content={
                        !['failed', 'stopped'].includes(String(task?.Status || '').toLowerCase())
                          ? "Task DMS não está parada ou com falha"
                          : task?.connectionText !== "Conexão (OK)"
                          ? "Teste a conexão primeiro"
                          : "Reiniciar Task"
                      }
                      className="
                        inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border
                        border-amber-400 dark:border-amber-500 text-amber-600 dark:text-amber-400
                        hover:bg-amber-50 dark:hover:bg-amber-900/20
                        disabled:opacity-30 disabled:cursor-not-allowed
                        transition-all
                      "
                    >
                      <PlayCircle size={12} />
                      Restart
                    </button>
                  </td>

                  {/* STEP FUNCTION */}
                  <td className="px-5 py-3.5 text-center">
                    <SfnBadge status={row.sfn_status} />
                  </td>

                  {/* ÚLTIMA ATUALIZAÇÃO */}
                  <td className="px-5 py-3.5 text-right">
                    <div className="flex flex-col items-end gap-0.5">
                      {task?.updated_by && (
                        <span className="text-xs font-semibold text-gray-700 dark:text-gray-300 truncate max-w-[180px]">
                          {task.updated_by}
                        </span>
                      )}
                      <span className="text-xs text-gray-400 dark:text-gray-500">
                        {formatTimestamp(task?.sfn_finished_at)}
                      </span>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {content.length === 0 && (
        <div className="p-12 text-center text-gray-400 dark:text-gray-500 text-sm">
          Nenhuma task encontrada.
        </div>
      )}

      <Tooltip id="tt-conn" className="z-50 text-xs" />
      <Tooltip id="tt-restart" className="z-50 text-xs" />
    </div>
  );
};

const taskRowShape = PropTypes.shape({
  id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  task_identifier: PropTypes.string,
  status: PropTypes.string,
  sfn_status: PropTypes.string,
  sfn_finished_at: PropTypes.string,
  raw: PropTypes.shape({
    Status: PropTypes.string,
    connectionDisabled: PropTypes.bool,
    connectionText: PropTypes.string,
    restartDisabled: PropTypes.bool,
    sfn_finished_at: PropTypes.string,
    updated_by: PropTypes.string,
  }),
});

Table.propTypes = {
  data: PropTypes.shape({
    content: PropTypes.arrayOf(taskRowShape),
  }),
  onEditDocument: PropTypes.func,
  onViewDocument: PropTypes.func,
};

export default Table;


