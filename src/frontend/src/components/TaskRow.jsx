import PropTypes from 'prop-types';

// Função para formatar a data (já está ótima, mantida como está)
const formatTimestamp = (isoString) => {
  if (!isoString) return '';
  try {
    const date = new Date(isoString);
    return date.toLocaleString('pt-BR', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  } catch (error) {
    return '';
  }
};

const TaskRow = ({ task, index, testConnection, invokeStepFunction, getStatusStyle }) => {
  const dmsStatus = (task.Status || '').toLowerCase();
  const sfnStatus = (task.stepFunctionStatus || '').toLowerCase();
  const isStepFunctionProcessing = sfnStatus === 'running' || sfnStatus === 'iniciando...';
  
  // Condição de restart simplificada para o novo layout
  const restartShouldBeDisabled = isStepFunctionProcessing || dmsStatus !== 'failed';
  
  const formattedFinishDate = formatTimestamp(task.sfn_finished_at);

  return (
    // A div principal da linha
    <div className="task-row">
      
      {/* Coluna 1: Task Name */}
      <div className="task-cell task-name" data-label="Task Name">
        {task.TaskIdentifier}
      </div>

      {/* Coluna 2: Status (com a pílula) */}
      <div className="task-cell" data-label="Status">
        <span style={getStatusStyle(task)}>
          {task.Status}
        </span>
      </div>

      {/* Coluna 3: Recovery Status */}
      <div className="task-cell" data-label="Recovery Status">
        <div className="task-stepFunction">
            <span>{task.stepFunctionStatus || "N/A"}</span>
            {formattedFinishDate && (
              <span className="timestamp">{formattedFinishDate}</span>
            )}
        </div>
      </div>
      
      {/* Coluna 4: Test Connection */}
      <div className="task-cell task-cell-connection" data-label="Test Connection">
        <button
          onClick={() => testConnection(index)}
          disabled={task.connectionDisabled || isStepFunctionProcessing}
          aria-label={`Testar conexão para a task ${task.TaskIdentifier}`}
        >
          {task.connectionText || "Testar"}
        </button>
      </div>

      {/* Coluna 5: Actions (Restart) */}
      <div className="task-cell task-cell-restart" data-label="Actions">
        <button
          onClick={() => invokeStepFunction(index)}
          disabled={restartShouldBeDisabled}
          aria-label={`Reiniciar task ${task.TaskIdentifier}`}
        >
          Restart
        </button>
      </div>

    </div>
  );
};

// PropTypes mantidos, são ótimas práticas!
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
    sfn_finished_at: PropTypes.string, // Adicionado para a data formatada
  }).isRequired,
  index: PropTypes.number.isRequired,
  testConnection: PropTypes.func.isRequired,
  invokeStepFunction: PropTypes.func.isRequired,
  getStatusStyle: PropTypes.func.isRequired,
};

export default TaskRow;