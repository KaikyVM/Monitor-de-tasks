// Em TaskListHeader.jsx
function TaskListHeader() {
  return (
    <div className="task-row-header">
      <div className="task-cell task-name">Task Name</div>
      <div className="task-cell">Status</div>
      <div className="task-cell">Recovery Status</div>
      <div className="task-cell task-cell-connection">Test Connection</div>
      <div className="task-cell task-cell-restart">Actions</div>
    </div>
  );
}