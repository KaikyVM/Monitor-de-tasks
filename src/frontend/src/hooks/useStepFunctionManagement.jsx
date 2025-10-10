import { useCallback } from "react";
import { checkStepFunctionExecution, invokeStepFunction as apiInvokeStepFunction } from "../services/api";

// 'auth' como um parâmetro para manter o padrão.
export function useStepFunctionManagement(tasks, tasksRef, updateTask, auth) {

  const checkStepFunctionStatus = useCallback(async () => {
    // Verifica se o auth está pronto
    if (!auth || !auth.user) return;

    const currentTasks = tasksRef.current;
    if (!Array.isArray(currentTasks) || currentTasks.length === 0) return;
    
    for (let i = 0; i < currentTasks.length; i++) {
      const task = currentTasks[i];
      if (!task.executionArn) continue;
      
      try {
        //Passa 'auth' para a chamada da API
        const data = await checkStepFunctionExecution(
          task.executionArn, 
          task.TaskIdentifier, 
          task.updated_by,
          auth
        );
        
        if (data.status) {
          const statusLower = (data.status || "").toLowerCase();
          const currentStatusLower = (task.stepFunctionStatus || "").toLowerCase();
          
          if (statusLower !== currentStatusLower) {
            updateTask(i, { stepFunctionStatus: data.status });
          }
          
          if (statusLower === "succeeded" || statusLower === "failed" || statusLower === "aborted") {
            updateTask(i, { restartDisabled: false });
          } else {
            updateTask(i, { restartDisabled: true });
          }
        }
      } catch (error) {
        console.error(`Erro ao verificar status da SFN para ${task.TaskIdentifier}:`, error);
      }
    }
  }, [tasksRef, updateTask, auth]); // add 'auth' às dependências

  const invokeStepFunction = async (taskIdentifier, username, taskIndex) => {
    try {
      if (!username || username.trim() === "") throw new Error("Nome de usuário não fornecido");
      
      // passa 'auth' para a chamada da API
      const data = await apiInvokeStepFunction(taskIdentifier, username, auth);
      
      if (!data || !data.executionArn) throw new Error("Resposta inválida ao invocar Step Function");
      
      updateTask(taskIndex, {
        stepFunctionStatus: "Executando",
        executionArn: data.executionArn,
        updated_by: username,
        restartDisabled: true,
      });

      return data;
      
    } catch (error) {
      console.error("Erro ao invocar a Step Function:", error);
      updateTask(taskIndex, {
        restartDisabled: false,
        stepFunctionStatus: "Erro: " + error.message
      });
      throw error;
    }
  };
  
  return {
    checkStepFunctionStatus,
    invokeStepFunction
  };
}
