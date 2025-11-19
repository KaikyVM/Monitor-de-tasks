import React from 'react';
import PropTypes from 'prop-types';
import './FilterControls.css'; 

// Filtros de status agora são o foco principal
const STATUS_FILTERS = [
  { label: "Todos os Status", value: "" },
  { label: "Em Execução", value: "running" },
  { label: "Com Falha", value: "failed" },
  { label: "Parado", value: "stopped" },
];

const FilterControls = ({ activeStatus, setActiveStatus }) => {
  return (
    <div className="filter-controls-container">
      <span>Filtrar por Status:</span>
      <div className="chips-wrapper">
        {STATUS_FILTERS.map(filter => (
          <button
            key={filter.label}
            className={`filter-chip ${activeStatus === filter.value ? 'active' : ''}`}
            onClick={() => setActiveStatus(filter.value)}
          >
            {filter.label}
          </button>
        ))}
      </div>
    </div>
  );
};

FilterControls.propTypes = {
  activeStatus: PropTypes.string.isRequired,
  setActiveStatus: PropTypes.func.isRequired,
};

export default FilterControls;