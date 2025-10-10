const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;

// Monta as URLs completas dos endpoints dinamicamente.
const testConnectionLambdaUrl = `${API_BASE_URL}/dms/test-connection`;
const stepFunctionUrl = `${API_BASE_URL}/dms/invoke`;
const flowhubUrl = `${API_BASE_URL}/dms/get_flowhub_task_status`;

function getAuthHeaders(auth) {
  if (!auth || !auth.user || !auth.user.id_token) {
    // Adiciona um log de erro para facilitar a depuração
    console.error("ERRO FATAL: Objeto 'auth' ou 'id_token' está em falta na função getAuthHeaders!", auth);
    throw new Error("Usuário não autenticado ou token inválido.");
  }
  return {
    "Content-Type": "application/json",
    "Authorization": auth.user.id_token,
  };
}

 export async function fetchTasks(auth) {
   try {
     const response = await fetch(flowhubUrl, {
       method: "POST",
       headers: getAuthHeaders(auth), 
       body: JSON.stringify({ action: "listar_status" }),
     });




    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`Erro ao buscar tasks: ${response.status} - ${errorData}`);
    }

    const data = await response.json();
    return data || [];
  } catch (error) {
    console.error("Erro em fetchTasks:", error);
    throw new Error(`Falha ao buscar tasks: ${error.message}`);
  }
}

/**
 * Obtém os detalhes completos de uma task (incluindo ARNs).
 */
export async function getTaskDetails(taskArn, auth) {
  if (!taskArn) throw new Error("taskArn é obrigatório");
 
  try {
    const response = await fetch(flowhubUrl, {
      method: "POST",
      headers: getAuthHeaders(auth),
      body: JSON.stringify({ 
        action: "detalhes_task",
        replication_task_arn: taskArn 
      }),
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro ao obter detalhes da task: ${response.status} - ${errorText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error("Erro em getTaskDetails:", error);
    throw new Error(`Falha ao obter detalhes da task: ${error.message}`);
  }
}

/**
 * Inicia o teste de conexão para um endpoint específico.
 */
export async function startConnectionTest(replicationInstanceArn, endpointArn, auth) {
  if (!replicationInstanceArn || !endpointArn) {
    throw new Error("replicationInstanceArn e endpointArn são obrigatórios");
  }
 
  try {
    const payload = {
      action: "start-test",
      ReplicationInstanceArn: replicationInstanceArn,
      endpoint_arn: endpointArn,
    };
    
    const response = await fetch(testConnectionLambdaUrl, {
      method: "POST",
      headers: getAuthHeaders(auth),
      body: JSON.stringify(payload),
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro ao iniciar o teste de conexão: ${response.status} - ${errorText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error("Erro em startConnectionTest:", error);
    throw new Error(`Falha ao iniciar teste de conexão: ${error.message}`);
  }
}

/**
 * Verifica o status de um teste de conexão em andamento.
 */
export async function checkConnectionTest(replicationInstanceArn, endpointArn, auth) {
  if (!replicationInstanceArn || !endpointArn) {
    throw new Error("replicationInstanceArn e endpointArn são obrigatórios");
  }

  try {
    const payload = {
      action: "check-test",
      ReplicationInstanceArn: replicationInstanceArn,
      endpoint_arn: endpointArn,
    };

    const response = await fetch(testConnectionLambdaUrl, {
      method: "POST",
      headers: getAuthHeaders(auth),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro ao verificar o teste de conexão: ${response.status} - ${errorText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error("Erro em checkConnectionTest:", error);
    throw new Error(`Falha ao verificar teste de conexão: ${error.message}`);
  }
}

/**
 * Invoca a Step Function para reiniciar (recovery) uma task.
 */
export async function invokeStepFunction(taskIdentifier, username, auth) {
  console.log("--- DEBUG: DENTRO DE invokeStepFunction ---"); // <-- DEBUG
  if (!taskIdentifier) throw new Error("taskIdentifier é obrigatório");
  if (!username) throw new Error("username é obrigatório");
 
  try {
    const headers = getAuthHeaders(auth);
    console.log("Cabeçalhos a serem enviados para /invoke:", headers); // <-- DEBUG

    const payload = {
      task_identifier: taskIdentifier,
      updated_by: username,
    };
    
    const response = await fetch(stepFunctionUrl, {
      method: "POST",
      headers: headers,
      body: JSON.stringify(payload),
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro ao invocar a Step Function: ${response.status} - ${errorText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error("Erro em invokeStepFunction:", error);
    throw new Error(`Falha ao invocar Step Function: ${error.message}`);
  }
}

/**
 * Verifica o status de uma execução específica da Step Function.
 */
export async function checkStepFunctionExecution(executionArn, taskIdentifier, updatedBy, auth) {
  if (!executionArn || !taskIdentifier) {
    throw new Error("executionArn e taskIdentifier são obrigatórios");
  }
 
  try {
    const payload = {
      executionArn,
      task_identifier: taskIdentifier,
      updated_by: updatedBy || "N/A",
    };
    
    const response = await fetch(stepFunctionUrl, {
      method: "POST",
      headers: getAuthHeaders(auth),
      body: JSON.stringify(payload),
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro ao verificar status da Step Function: ${response.status} - ${errorText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error("Erro em checkStepFunctionExecution:", error);
    throw new Error(`Falha ao verificar status da execução: ${error.message}`);
  }
}
