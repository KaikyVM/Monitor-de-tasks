import React, { useState, useEffect } from "react";
import { useAuth } from "react-oidc-context";
import { LogOut, RefreshCw } from "lucide-react"; 

import Table from "../components/Table"; 
import ComponenteEsqueleto from "../components/ComponenteEsqueleto";
import TaskStatusModal from "../components/TaskStatusModal";
import ConfirmationModal from "../components/ConfirmationModal";
import Pagination from "../components/Pagination";
import SearchAndUpdateControls from "../components/SearchAndUpdateControls";
import FilterControls from "../components/FilterControls";
import TaskErrorDisplay from "../components/ui/TaskErrorDisplay";

import { useDarkMode } from "../hooks/useDarkMode";
import { useTaskManagement } from "../hooks/useTaskManagement";
import { useConnectionTest } from "../hooks/useConnectionTest";
import { useStepFunctionManagement } from "../hooks/useStepFunctionManagement";
import { useTaskFiltering } from "../hooks/useTaskFiltering";
import { cognitoAuthConfig } from "../cognitoConfig";
import { getPageNumbers } from "../utils/taskStatusUtils";

function DashBoard() {
  const auth = useAuth();
  const [darkMode, setDarkMode] = useDarkMode();
  
  const [showRestartModal, setShowRestartModal] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [selectedTaskIndex, setSelectedTaskIndex] = useState(null);

  const { tasks, tasksRef, loading, error, fetchTasks, updateTask } = useTaskManagement(auth);
  const { statusModal, setStatusModal, testConnection } = useConnectionTest(tasks, updateTask, auth);
  const { checkStepFunctionStatus, invokeStepFunction } = useStepFunctionManagement(tasks, tasksRef, updateTask, auth);

  const {
    searchTerm, setSearchTerm,
    currentPage, setCurrentPage,
    currentTasks, 
    totalPages,
    activeCategory, setActiveCategory,
    activeStatus, setActiveStatus,
  } = useTaskFiltering(tasks);

  useEffect(() => {
    if (auth && auth.user) {
      const interval = setInterval(() => checkStepFunctionStatus(), 5000);
      return () => clearInterval(interval);
    }
  }, [checkStepFunctionStatus, auth]);

  const handleSignOut = () => auth.signoutRedirect({ client_id: cognitoAuthConfig.client_id });

  const openRestartModal = (taskRaw) => {
    const index = tasks.findIndex(t => t.TaskIdentifier === taskRaw.TaskIdentifier);
    setSelectedTask(taskRaw);
    setSelectedTaskIndex(index);
    setShowRestartModal(true);
  };

  const handleRestartConfirmation = async () => {
    setShowRestartModal(false);
    if (!selectedTask || selectedTaskIndex === null) return;

    updateTask(selectedTaskIndex, {
      restartDisabled: true,
      connectionDisabled: true,
      stepFunctionStatus: "Iniciando..."
    });

    try {
      const userName = auth.user?.profile?.name || auth.user?.profile?.email;
      await invokeStepFunction(selectedTask.TaskIdentifier, userName, selectedTaskIndex);
    } catch (error) {
      console.error("Erro ao reiniciar:", error);
      updateTask(selectedTaskIndex, {
        restartDisabled: false,
        connectionDisabled: false,
        stepFunctionStatus: 'Falha'
      });
      alert(`Erro: ${error.message}`);
    }
  };

  const handleTestConnection = (taskRaw) => {
     const index = tasks.findIndex(t => t.TaskIdentifier === taskRaw.TaskIdentifier);
     testConnection(index);
  }

  const tableData = {
    content: currentTasks.map(task => ({
      id: task.TaskIdentifier,
      task_identifier: task.TaskIdentifier,
      status: task.Status,
      sfn_status: task.stepFunctionStatus,
      migration_progress: task.MigrationProgress,
      sfn_finished_at: task.sfn_finished_at ? new Date(task.sfn_finished_at).toLocaleString() : '-',
      raw: task 
    }))
  };

  return (
    <div className={`min-h-screen transition-colors duration-300 ${darkMode ? "bg-slate-900 text-slate-100" : "bg-gray-50 text-gray-900"}`}>
      
      <header className="bg-white dark:bg-slate-800 shadow-sm border-b border-gray-200 dark:border-slate-700 sticky top-0 z-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-indigo-600 p-1.5 rounded-lg shadow-lg shadow-indigo-500/30">
                <RefreshCw className="text-white w-5 h-5" />
            </div>
            <h1 className="text-lg font-bold tracking-tight text-gray-900 dark:text-white">
              DMS-TASK-MONITOR
            </h1>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleSignOut}
              className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-md transition-colors"
            >
              <LogOut size={16} />
              <span className="hidden sm:inline">Sair</span>
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        <div className="mb-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
            <div>
                <h2 className="text-2xl font-bold tracking-tight">Monitoramento</h2>
                <p className="text-sm text-gray-500 dark:text-gray-400">Gerencie suas tasks de replicação.</p>
            </div>
            
            <SearchAndUpdateControls 
                searchTerm={searchTerm}
                setSearchTerm={setSearchTerm}
                fetchTasks={fetchTasks}
                darkMode={darkMode}
                setDarkMode={setDarkMode}
                setCurrentPage={setCurrentPage}
            />
        </div>

        <div className="mb-6">
             <FilterControls 
                activeCategory={activeCategory}
                setActiveCategory={setActiveCategory}
                activeStatus={activeStatus}
                setActiveStatus={setActiveStatus}
             />
        </div>

        <div className="space-y-4">
            {error ? (
                 <TaskErrorDisplay error={error} onRetry={fetchTasks} />
            ) : loading ? (
                 <div className="bg-white dark:bg-slate-800 p-6 rounded-lg border border-gray-200 dark:border-slate-700">
                    <ComponenteEsqueleto loading={true} numRows={8} />
                 </div>
            ) : (
                 <>
                    <Table 
                        data={tableData} 
                        onEditDocument={openRestartModal} 
                        onViewDocument={handleTestConnection} 
                    />
                    
                    {currentTasks.length > 0 && (
                        <div className="flex justify-center mt-6">
                            <Pagination
                                currentPage={currentPage}
                                totalPages={totalPages}
                                onPageChange={setCurrentPage}
                                getPageNumbers={getPageNumbers}
                            />
                        </div>
                    )}
                 </>
            )}
        </div>
      </main>

      {statusModal.isOpen && (
        <TaskStatusModal
          task={statusModal.task}
          currentMessage={statusModal.currentMessage}
          onClose={() => setStatusModal({ isOpen: false, currentMessage: "", task: null, isError: false })}
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