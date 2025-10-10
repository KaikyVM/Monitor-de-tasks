import { MdOutlineKeyboardDoubleArrowLeft, MdOutlineKeyboardDoubleArrowRight } from "react-icons/md";
import PropTypes from "prop-types";

const Pagination = ({ currentPage, totalPages, onPageChange, getPageNumbers }) => (
  <div className="pagination-container">
    <button
      className="arrow-button"
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage === 1}
      aria-label="Página anterior"
    >
      <MdOutlineKeyboardDoubleArrowLeft size={12} />
    </button>
    {getPageNumbers(currentPage, totalPages).map((page, index) =>
      page === "..." ? (
        <span key={`ellipsis-${index}`} className="ellipsis" aria-hidden="true">
          {page}
        </span>
      ) : (
        <button
          key={page}
          onClick={() => onPageChange(page)}
          className={currentPage === page ? "active-page" : ""}
          aria-label={`Ir para página ${page}`}
        >
          {page}
        </button>
      )
    )}
    <button
      className="arrow-button"
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage === totalPages}
      aria-label="Próxima página"
    >
      <MdOutlineKeyboardDoubleArrowRight size={12} />
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