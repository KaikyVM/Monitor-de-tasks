import { useState } from "react";
import { getTaskDetails, startConnectionTest, checkConnectionTest } from "../services/api";

// agora aceita 'auth' como um terceiro parâmetro, vindo do DashBoard.js
export function useConnectionTest(tasks, updateTask, auth) {
  const [statusModal, setStatusModal] = useState({
    isOpen: false,
    currentMessage: "",
    task: null,
    isError: false
  });

  const testConnection = async (taskIndex) => {
    if (taskIndex < 0 || taskIndex >= tasks.length) {
      console.error("Índice de task inválido:", taskIndex);
      return;
    }
    
    // Verifica se o auth está pronto antes de continuar
    if (!auth || !auth.user) {
        alert("Erro de autenticação. Por favor, recarregue a página.");
        return;
    }
    
    const task = tasks[taskIndex];
    
    setStatusModal({
      isOpen: true,
      currentMessage: `Buscando detalhes para iniciar o teste da task...`,
      task,
      isError: false
    });
    
    try {
      // Passa o objeto 'auth' para a chamada da API getTaskDetails.
      const taskDetails = await getTaskDetails(task.TaskArn, auth);
      
      if (!taskDetails) throw new Error("Dados detalhados da task não foram encontrados.");
      
      const replicationInstanceArn = taskDetails.ReplicationInstanceArn;
      const endpointArn = taskDetails.SourceEndpointArn;
      
      if (!replicationInstanceArn || !endpointArn) {
        throw new Error("ARNs necessários não encontrados nos detalhes da task.");
      }

      setStatusModal(prev => ({ ...prev, currentMessage: "Iniciando teste de conexão..." }));

      // Passa o objeto 'auth' para a chamada da API startConnectionTest.
      await startConnectionTest(replicationInstanceArn, endpointArn, auth);
      
      updateTask(taskIndex, { connectionDisabled: true, connectionText: "Testando..." });
      
      // Passa o objeto 'auth' para a chamada da API de verificação.
      await checkConnectionStatus(task, taskIndex, replicationInstanceArn, endpointArn);

    } catch (error) {
      console.error("Erro no processo de teste de conexão:", error);
      setStatusModal(prev => ({ ...prev, currentMessage: `Erro: ${error.message}`, isError: true }));
      updateTask(taskIndex, { connectionDisabled: false, connectionClass: "btn-red", connectionText: "Conexão (Erro)" });
    }
  };

  const checkConnectionStatus = async (task, taskIndex, replicationInstanceArn, endpointArn) => {
    let status = "testing";
    let attempts = 0;
    const maxAttempts = 30;
    
    try {
      while (status === "testing" && attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 10000));
        attempts++;
        
        setStatusModal(prev => ({ ...prev, currentMessage: `Verificando... Tentativa ${attempts}/${maxAttempts}` }));
        
        // Passa objeto 'auth' para a chamada da API de verificação.
        const result = await checkConnectionTest(replicationInstanceArn, endpointArn, auth);
        status = result.status || "unknown";
      }
      
      if (attempts >= maxAttempts && status === "testing") {
        throw new Error("Timeout ao verificar status de conexão.");
      }
      
      setStatusModal(prev => ({ ...prev, currentMessage: `Teste finalizado: ${status}` }));
      updateConnectionStatus(taskIndex, status);

    } catch (error) {
      console.error("Erro ao verificar status de conexão:", error);
      setStatusModal(prev => ({ ...prev, currentMessage: `Erro ao verificar status: ${error.message}`, isError: true }));
      updateTask(taskIndex, { connectionDisabled: false, connectionClass: "btn-red", connectionText: "Conexão (Erro)" });
    }
  };

  const updateConnectionStatus = (taskIndex, status) => {
    if (taskIndex < 0 || taskIndex >= tasks.length) return;

    const normalizedStatus = (status || "").toLowerCase().trim();
    const currentTask = tasks[taskIndex];
    const newProps = { connectionDisabled: false };
    
    if (normalizedStatus === "successful") {
      newProps.connectionClass = "btn-green";
      newProps.connectionText = "Conexão (OK)";
      
      if (currentTask.Status === "failed" || currentTask.Status === "stopped") {
        newProps.restartDisabled = false;
      } else if (currentTask.Status === "running") {
        newProps.restartDisabled = true;
      }
    } else if (normalizedStatus === "failed") {
      newProps.connectionClass = "btn-red";
      newProps.connectionText = "Conexão (Falha)";
      newProps.restartDisabled = true;
    }
    
    updateTask(taskIndex, newProps);
  };

  return { 
    statusModal, 
    setStatusModal, 
    testConnection 
  };
}
