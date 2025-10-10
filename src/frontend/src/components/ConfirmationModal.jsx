import PropTypes from 'prop-types';
import { useAuth } from 'react-oidc-context'; 
import './ConfirmationModal.css';

const ConfirmationModal = ({ isOpen, onClose, onConfirm, taskIdentifier }) => {
  const auth = useAuth();

  // extrair o nome do usuário do perfil, se não houver nome, usar o email
  const userName = auth.user?.profile?.name || auth.user?.profile?.email || 'Usuário';

  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <h3>Confirmar Restart para {taskIdentifier}</h3>
        
        {}
        <p className="modal-user-info">
          Ação será executada por: <strong>{userName}</strong>
        </p>

        <div className="modal-buttons">
          <button onClick={onClose} className="modal-btn btn-cancel-red">
            Cancelar
          </button>
          {}
          <button 
            onClick={onConfirm}
            className="modal-btn btn-confirm-green"
          >
            Confirmar
          </button>
        </div>
      </div>
    </div>
  );
};

ConfirmationModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  onConfirm: PropTypes.func.isRequired,
  taskIdentifier: PropTypes.string.isRequired,
};

export default ConfirmationModal;