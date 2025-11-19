export const getStatusStyle = (task) => {
  if (!task || !task.Status) {
    return {};
  }

  // Base style para todas as pills
  const baseStyle = {
    color: "white",
    fontWeight: "bold",
    borderRadius: "9999px", // Truque para fazer uma pílula perfeita
    padding: "4px 12px",   // Padding vertical e horizontal
    fontSize: "0.8rem",
    textAlign: "center",
    display: "inline-block", // Importante para o padding funcionar bem
    minWidth: "80px", // Garante uma largura mínima
  };

  let statusStyle = {};
  const status = task.Status.toLowerCase(); // Normaliza o status

  if (status === "running" && task.MigrationProgress === 100) {
    statusStyle = { background: "#28a745" }; // Verde "Done"
  } else if (status === "failed" || status === "error") {
    statusStyle = { background: "#dc3545" }; // Vermelho "Pending/Failed"
  } else if (status === "running" || status === "starting" || status === "replicating") {
    statusStyle = { background: "#007bff" }; // Azul "Progress"
  } else if (status === "ready" || status === "stopped") {
    statusStyle = { background: "#6c757d", color: "white" }; // Cinza "Stopped"
  } else {
     statusStyle = { background: "#ffc107", color: "black" }; // Amarelo para outros status
  }

  return { ...baseStyle, ...statusStyle };
};
  
  export const getPageNumbers = (currentPage, totalPages, maxVisible = 7) => {
    let pages = [];
    
    if (!totalPages || totalPages <= 0) {
      return [1];
    }
    
    if (totalPages <= maxVisible) {
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      if (currentPage <= 4) {
        pages = [1, 2, 3, 4, 5, "...", totalPages];
      } else if (currentPage >= totalPages - 3) {
        pages = [1, "...", totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
      } else {
        pages = [1, "...", currentPage - 1, currentPage, currentPage + 1, "...", totalPages];
      }
    }
    return pages;
  };