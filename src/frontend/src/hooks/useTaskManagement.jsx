import { useState, useRef, useCallback, useEffect } from "react";
import { fetchTasks as apiFetchTasks } from "../services/api";

export function useTaskManagement(auth) {
  const [tasks, setTasks] = useState([]);
  const tasksRef = useRef([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    tasksRef.current = tasks;
  }, [tasks]);

  const fetchTasksHandler = useCallback(async () => {
    // Verifica se o objeto auth está pronto antes de fazer a chamada
    if (!auth || !auth.user) {
      // Se não estiver pronto, não faz nada. O hook useAuth vai recarregar o componente quando estiver.
      return;
    }

    setLoading(true);
    setError(null);
    try {
      // 2. Passe o objeto 'auth' para a chamada da API.
      // A sua Lambda `get_DMS_task_monitor_task_status` já retorna todos os dados combinados.
      const tasksData = await apiFetchTasks(auth);

      if (!Array.isArray(tasksData)) {
        throw new Error("Formato de dados inválido ao buscar tasks");
      }

      // Processa os dados que já recebemos para definir o estado inicial dos botões
      const processedTasks = tasksData.map(task => {
        const status = (task.Status || "").toLowerCase();
        const DMS_task_monitorStatus = (task.DMS_task_monitorStatus || "").toLowerCase();
        
        // O botão de restart fica habilitado se o status do DMS for 'failed' ou 'stopped',
        // ou se o status da Step Function (DMS_task_monitorStatus) for 'succeeded' ou 'failed'.
        const restartDisabled = !(status === "failed" || status === "stopped" || DMS_task_monitorStatus === "succeeded" || DMS_task_monitorStatus === "failed");

        return {
          ...task,
          connectionDisabled: false,
          connectionClass: "btn-gray",
          connectionText: "Conexão",
          restartDisabled: restartDisabled,
          stepFunctionStatus: task.DMS_task_monitorStatus || "Desconhecido",
        };
      });

      setTasks(processedTasks);
    } catch (error) {
      console.error("Erro ao buscar as tasks:", error);
      setError("Falha ao carregar as tarefas. Por favor, tente novamente.");
    } finally {
      setLoading(false);
    }
    // add 'auth' à lista de dependências do useCallback
  }, [auth]);

  useEffect(() => {
    fetchTasksHandler();
  }, [fetchTasksHandler]);

  const updateTask = (index, newProps) => {
    if (index < 0 || index >= tasksRef.current.length) {
      console.error("Índice de task inválido em updateTask:", index);
      return;
    }
    setTasks(prevTasks => {
      const newTasks = [...prevTasks];
      newTasks[index] = { ...newTasks[index], ...newProps };
      return newTasks;
    });
  };

  return {
    tasks,
    tasksRef,
    loading,
    error,
    fetchTasks: fetchTasksHandler,
    updateTask,
  };
}