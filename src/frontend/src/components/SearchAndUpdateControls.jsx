import { FiSun, FiMoon } from "react-icons/fi";
import PropTypes from "prop-types";

const SearchAndUpdateControls = ({ searchTerm, setSearchTerm, fetchTasks, darkMode, setDarkMode, setCurrentPage }) => (
  <div className="search-update-container">
    <div className="search-input-wrapper">
      <span className="search-icon" aria-hidden="true">
        <img src="/search.png" alt="Pesquisar" />
      </span>
      <input
        type="text"
        placeholder="Pesquisar task..."
        aria-label="Pesquisar task"
        value={searchTerm}
        onChange={(e) => {
          setSearchTerm(e.target.value);
          setCurrentPage(1);
        }}
      />
    </div>
    <button id="update-button" onClick={fetchTasks} aria-label="Atualizar status das tasks">
      Atualizar Status
    </button>
    <button
      className="theme-toggle"
      onClick={() => setDarkMode(!darkMode)}
      aria-label={`Alternar para modo ${darkMode ? "claro" : "escuro"}`}
      aria-pressed={darkMode}
    >
      {darkMode ? <FiSun size={20} color="#fff" /> : <FiMoon size={20} color="#000" />}
    </button>
  </div>
);
SearchAndUpdateControls.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  setSearchTerm: PropTypes.func.isRequired,
  fetchTasks: PropTypes.func.isRequired,
  darkMode: PropTypes.bool.isRequired,
  setDarkMode: PropTypes.func.isRequired,
  setCurrentPage: PropTypes.func.isRequired,
};

export default SearchAndUpdateControls;