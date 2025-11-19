import { Sun, Moon, Search } from "lucide-react";
import PropTypes from "prop-types";

const SearchAndUpdateControls = ({ searchTerm, setSearchTerm, fetchTasks, darkMode, setDarkMode, setCurrentPage }) => (
  <div className="search-update-container flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto">
    <div className="search-input-wrapper relative w-full sm:w-64">
      <span className="search-icon absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" aria-hidden="true">
        <Search size={18} />
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
        className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
      />
    </div>
    
    <div className="flex gap-2 w-full sm:w-auto">
      <button 
        id="update-button" 
        onClick={fetchTasks} 
        aria-label="Atualizar status das tasks"
        className="flex-1 sm:flex-none px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors text-sm font-medium"
      >
        Atualizar Status
      </button>
      
      <button
        className="theme-toggle p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
        onClick={() => setDarkMode(!darkMode)}
        aria-label={`Alternar para modo ${darkMode ? "claro" : "escuro"}`}
        aria-pressed={darkMode}
      >
        {darkMode ? <Sun size={20} className="text-yellow-400" /> : <Moon size={20} className="text-gray-600" />}
      </button>
    </div>
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