import { useState, useEffect } from "react";
import { useAuth } from "react-oidc-context";
import { cognitoAuthConfig } from "../cognitoConfig";
import "./DashBoard.css";

// Componentes
import TaskStatusModal from "../components/TaskStatusModal";
import ConfirmationModal from "../components/ConfirmationModal";
import FilterControls from "../components/FilterControls";
import TaskListHeader from "../components/TaskListHeader";
import TaskRow from "../components/TaskRow";
import Pagination from "../components/Pagination";
import SearchAndUpdateControls from "../components/SearchAndUpdateControls";
import LoadingSpinner from "../components/ui/LoadingSpinner";
import TaskErrorDisplay from "../components/ui/TaskErrorDisplay";
import EmptyTasksMessage from "../components/ui/EmptyTasksMessage";

// Hooks personalizados
import { useDarkMode } from "../hooks/useDarkMode";
import { useTaskManagement } from "../hooks/useTaskManagement";
import { useConnectionTest } from "../hooks/useConnectionTest";
import { useStepFunctionManagement } from "../hooks/useStepFunctionManagement";
import { useTaskFiltering } from "../hooks/useTaskFiltering";

// Utils
import { getStatusStyle, getPageNumbers } from "../utils/taskStatusUtils";

function DashBoard() {
  const auth = useAuth();
  const [darkMode, setDarkMode] = useDarkMode();
  
  const [showRestartModal, setShowRestartModal] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [selectedTaskIndex, setSelectedTaskIndex] = useState(null);

  const { tasks, tasksRef, loading, error, fetchTasks, updateTask } = useTaskManagement(auth);
  const { statusModal, setStatusModal, testConnection } = useConnectionTest(tasks, updateTask, auth);
  const { checkStepFunctionStatus, invokeStepFunction } = useStepFunctionManagement(
    tasks, tasksRef, updateTask, auth
  );
  
const { 
    searchTerm, setSearchTerm, 
    currentPage, setCurrentPage, 
    currentTasks, filteredTasks, 
    totalPages, indexOfFirstTask,
    activeCategory,  
    setActiveCategory,  
    activeStatus,     
    setActiveStatus,    
  } = useTaskFiltering(tasks);

  useEffect(() => {
    if (auth && auth.user) {
      const interval = setInterval(() => {
        checkStepFunctionStatus();
      }, 5000);
      
      return () => clearInterval(interval);
    }
  }, [checkStepFunctionStatus, auth]); 

  const openRestartModal = (taskIndex) => {
    const task = tasks[taskIndex];
    setSelectedTask(task);
    setSelectedTaskIndex(taskIndex);
    setShowRestartModal(true);
  };


// feedback visual dos botões destivados

  const handleRestartConfirmation = async () => {
    setShowRestartModal(false);
    const task = selectedTask;
    const taskIndex = selectedTaskIndex;

    if (!task || taskIndex === null) return;

    // desabilita botões e atualiza status na UI imediatamente.
    updateTask(taskIndex, {
      restartDisabled: true,
      connectionDisabled: true, 
      stepFunctionStatus: "Iniciando..."
    });

    try {
      // nome do usuário diretamente do contexto de autenticação
      const userName = auth.user?.profile?.name || auth.user?.profile?.email;
      await invokeStepFunction(task.TaskIdentifier, userName, taskIndex);
    } catch (error) {
      console.error("Erro ao reiniciar a task:", error);
      // em caso de erro, reverte a UI para o estado anterior.
      updateTask(taskIndex, {
        restartDisabled: false,
        connectionDisabled: false,
        stepFunctionStatus: 'Falha ao iniciar'
      });
      alert(`Erro ao reiniciar a task: ${error.message}`);
    }
  };

  const handleSignOut = async () => {
    try {
      await auth.signoutRedirect({ client_id: cognitoAuthConfig.client_id });
    } catch (error) {
      console.error("Erro durante o signout:", error);
      alert("Falha ao efetuar logout. Por favor, tente novamente.");
    }
  };

  return (
    <div className={`container ${darkMode ? "dark-mode" : ""}`}>
      <header className="header" role="banner">
        <img className="logo" src="/image.png" alt="Logotipo Flowhub" />
        <h1>Status das Tasks Flowhub</h1>
        <img
          className="perfil"
          src="/perfil.png"
          alt="Imagem do perfil"
          onClick={handleSignOut}
          title="Clique para sair"
        />
      </header>
      
      <SearchAndUpdateControls
        searchTerm={searchTerm}
        setSearchTerm={setSearchTerm}
        fetchTasks={fetchTasks}
        darkMode={darkMode}
        setDarkMode={setDarkMode}
        setCurrentPage={setCurrentPage}
      />
      <FilterControls 
        activeCategory={activeCategory}
        setActiveCategory={setActiveCategory}
        activeStatus={activeStatus}
        setActiveStatus={setActiveStatus}
      />
      <div className="task-list">
        {loading ? (
          <LoadingSpinner />
        ) : error ? (
          <TaskErrorDisplay error={error} onRetry={fetchTasks} />
        ) : filteredTasks.length === 0 ? (
          <EmptyTasksMessage searchTerm={searchTerm} />
        ) : (
          <>
            <TaskListHeader />
            
            {statusModal.isOpen && (
              <TaskStatusModal
                task={statusModal.task}
                currentMessage={statusModal.currentMessage}
                isError={statusModal.isError}
                onClose={() => setStatusModal({ isOpen: false, currentMessage: "", task: null, isError: false })}
              />
            )}
            
            {currentTasks.map((task, index) => (
              <TaskRow
                key={task.TaskIdentifier || index}
                task={task}
                index={index + indexOfFirstTask}
                testConnection={testConnection}
                invokeStepFunction={openRestartModal}
                getStatusStyle={getStatusStyle}
              />
            ))}
          </>
        )}
      </div>
      
      {!loading && !error && filteredTasks.length > 0 && (
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={setCurrentPage}
          getPageNumbers={getPageNumbers}
        />
      )}
      
      {showRestartModal && selectedTask && (
        <ConfirmationModal
          isOpen={showRestartModal}
          onClose={() => setShowRestartModal(false)}
          onConfirm={handleRestartConfirmation}
          taskIdentifier={selectedTask?.TaskIdentifier}
        />
      )}
    </div>
  );
}

export default DashBoard;