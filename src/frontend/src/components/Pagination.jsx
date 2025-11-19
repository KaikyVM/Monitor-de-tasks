import { ChevronsLeft, ChevronsRight } from "lucide-react";
import PropTypes from "prop-types";

const Pagination = ({ currentPage, totalPages, onPageChange, getPageNumbers }) => (
  <div className="pagination-container flex items-center justify-center gap-1 mt-6">
    <button
      className="p-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage === 1}
      aria-label="Página anterior"
    >
      <ChevronsLeft size={16} />
    </button>
    
    {getPageNumbers(currentPage, totalPages).map((page, index) =>
      page === "..." ? (
        <span key={`ellipsis-${index}`} className="px-3 py-1 text-gray-500" aria-hidden="true">
          {page}
        </span>
      ) : (
        <button
          key={page}
          onClick={() => onPageChange(page)}
          className={`px-3 py-1 min-w-[32px] rounded-md text-sm font-medium transition-colors ${
            currentPage === page 
              ? "bg-indigo-600 text-white border border-indigo-600" 
              : "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
          }`}
          aria-label={`Ir para página ${page}`}
        >
          {page}
        </button>
      )
    )}
    
    <button
      className="p-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage === totalPages}
      aria-label="Próxima página"
    >
      <ChevronsRight size={16} />
    </button>
  </div>
);

Pagination.propTypes = {
  currentPage: PropTypes.number.isRequired,
  totalPages: PropTypes.number.isRequired,
  onPageChange: PropTypes.func.isRequired,
  getPageNumbers: PropTypes.func.isRequired,
};

export default Pagination;