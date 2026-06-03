import React from "react";

const ComponenteEsqueleto = () => {
  // Criamos um array de 5 itens apenas para renderizar 5 linhas de esqueleto
  const rows = Array.from({ length: 5 });

  return (
    <div className="skeleton-container" style={{ width: "100%" }}>
      {/* Header Fake */}
      <div className="task-row-header" style={{ opacity: 0.5 }}>
        <div className="task-cell task-name">Loading...</div>
        <div className="task-cell">...</div>
        <div className="task-cell">...</div>
        <div className="task-cell task-cell-connection">...</div>
        <div className="task-cell task-cell-restart">...</div>
      </div>

      {/* Linhas Fake */}
      {rows.map((_, index) => (
        <div key={index} className="task-row" style={{ animation: "pulse 1.5s infinite" }}>
          {/* Coluna Nome */}
          <div className="task-cell task-name">
            <div style={{ height: "20px", width: "70%", backgroundColor: "#e0e0e0", borderRadius: "4px" }}></div>
          </div>

          {/* Coluna Status */}
          <div className="task-cell">
            <div style={{ height: "24px", width: "80px", backgroundColor: "#e0e0e0", borderRadius: "12px", margin: "0 auto" }}></div>
          </div>

          {/* Coluna Recovery */}
          <div className="task-cell">
             <div style={{ height: "20px", width: "60%", backgroundColor: "#e0e0e0", borderRadius: "4px", margin: "0 auto" }}></div>
          </div>

          {/* Coluna Test Connection */}
          <div className="task-cell task-cell-connection">
            <div style={{ height: "35px", width: "100%", backgroundColor: "#e0e0e0", borderRadius: "20px" }}></div>
          </div>

          {/* Coluna Restart */}
          <div className="task-cell task-cell-restart">
            <div style={{ height: "35px", width: "100%", backgroundColor: "#e0e0e0", borderRadius: "20px" }}></div>
          </div>
        </div>
      ))}
      
      <style>{`
        @keyframes pulse {
          0% { opacity: 1; }
          50% { opacity: 0.5; }
          100% { opacity: 1; }
        }
      `}</style>
    </div>
  );
};

export default ComponenteEsqueleto;