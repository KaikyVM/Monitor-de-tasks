import PropTypes from 'prop-types';

function TaskErrorDisplay({ error, onRetry }) {
    return (
      <div className="error-message" style={{ padding: "20px", textAlign: "center", color: "red" }}>
        {error}
        <button 
          onClick={onRetry} 
          style={{ marginLeft: "10px", padding: "5px 10px" }}
        >
          Tentar novamente
        </button>
      </div>
    );
  }
  
TaskErrorDisplay.propTypes = {
    error: PropTypes.string.isRequired,
    onRetry: PropTypes.func.isRequired,
};

export default TaskErrorDisplay;