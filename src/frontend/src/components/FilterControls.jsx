import React from 'react';
import PropTypes from 'prop-types';
import './FilterControls.css'; 


const CATEGORY_FILTERS = [
  { label: "Todos", value: "" },
  { label: "TASY", value: "TASY" },
  { label: "WPD", value: "WPD" },
  { label: "Flowhub", value: "FLOWHUB" },
];

const STATUS_FILTERS = [
  { label: "Qualquer Status", value: "" },
  { label: "Em Execução", value: "running" },
  { label: "Com Falha", value: "failed" },
];

const FilterControls = ({ activeCategory, setActiveCategory, activeStatus, setActiveStatus }) => {
  return (
    <>
      <div className="filter-controls">
        <span>Filtrar por Categoria:</span>
        {CATEGORY_FILTERS.map(filter => (
          <button
            key={filter.label}
            className={`filter-chip ${activeCategory === filter.value ? 'active' : ''}`}
            onClick={() => setActiveCategory(filter.value)}
          >
            {filter.label}
          </button>
        ))}
      </div>
      <div className="filter-controls" style={{ marginTop: '10px' }}>
        <span>Filtrar por Status:</span>
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
    </>
  );
};

FilterControls.propTypes = {
  activeCategory: PropTypes.string.isRequired,
  setActiveCategory: PropTypes.func.isRequired,
  activeStatus: PropTypes.string.isRequired,
  setActiveStatus: PropTypes.func.isRequired,
};

export default FilterControls;
