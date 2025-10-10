import PropTypes from "prop-types";

function EmptyTasksMessage({ searchTerm }) {
  return (
    <div style={{ padding: "20px", textAlign: "center" }}>
      Nenhuma task encontrada{searchTerm ? ` para "${searchTerm}"` : ""}.
    </div>
  );
}
EmptyTasksMessage.propTypes = {
  searchTerm: PropTypes.string,
};

export default EmptyTasksMessage;
