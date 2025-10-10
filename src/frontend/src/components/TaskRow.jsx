import PropTypes from 'prop-types';

// função para formatara  data
const formatTimestamp = (isoString) => {
  if (!isoString) return '';
  try {
    const date = new Date(isoString);
    // o formato fica = DD/MM/AAAA HH:MM
    return date.toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch (error) {
    return ''; // return vazio se a data for inválida
  }
};

const TaskRow = ({ task, index, testConnection, invokeStepFunction, getStatusStyle }) => {

  const dmsStatus = (task.Status || '').toLowerCase();
  const sfnStatus = (task.stepFunctionStatus || '').toLowerCase();

  // verifica running
  const isStepFunctionProcessing = sfnStatus === 'running' || sfnStatus === 'iniciando...';

  // verifica condições restart.
  const isReadyForRestart = dmsStatus === 'failed' && task.connectionText === 'Conexão (OK)';
  
  const restartShouldBeDisabled = isStepFunctionProcessing || !isReadyForRestart;
  //formata a data q vem da api
  const formattedFinishDate = formatTimestamp(task.sfn_finished_at);

  return (
    <div className="task-row">
      <div className="task-cell task-namee">{task.TaskIdentifier}</div>
      <div className="task-cell" style={getStatusStyle(task)}>
        {task.Status}
      </div>
      <div className="task-cell-connection">
        <button
          onClick={() => testConnection(index)}
          disabled={task.connectionDisabled}
          className={task.connectionClass}
          aria-label={`Testar conexão para a task ${task.TaskIdentifier}`}
        >
          {task.connectionText || "Conexão"}
        </button>
      </div>
      <div className="task-cell-restart">
        <button
          onClick={() => invokeStepFunction(index)}
          disabled={restartShouldBeDisabled}
          aria-label={`Reiniciar task ${task.TaskIdentifier}`}
        >
          Restart
        </button>
      </div>
      <div
        className="task-cell-updated"
        title={`Última atualização em: ${task.last_update || "Data desconhecida"}`}
      >
        {task.updated_by || "N/A"}
      </div>
      <div className="task-stepFunction">
        <span>{task.stepFunctionStatus}</span>
        {formattedFinishDate && (
          <span className="timestamp">{formattedFinishDate}</span>
        )}
        </div>
    </div>
  );
};

TaskRow.propTypes = {
  task: PropTypes.shape({
    TaskIdentifier: PropTypes.string.isRequired,
    Status: PropTypes.string,
    connectionDisabled: PropTypes.bool,
    connectionClass: PropTypes.string,
    connectionText: PropTypes.string,
    restartDisabled: PropTypes.bool,
    last_update: PropTypes.string,
    updated_by: PropTypes.string,
    stepFunctionStatus: PropTypes.string,
  }).isRequired,
  index: PropTypes.number.isRequired,
  testConnection: PropTypes.func.isRequired,
  invokeStepFunction: PropTypes.func.isRequired,
  getStatusStyle: PropTypes.func.isRequired,
};
 
export default TaskRow;