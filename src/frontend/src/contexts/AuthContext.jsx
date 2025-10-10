import { createContext, useContext, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { UserManager } from 'oidc-client';
import { cognitoAuthConfig } from '../cognitoConfig';

// Cria o Contexto
const AuthContext = createContext(null);

// Cria o "provedor" do contexto, que vai gerenciar a lógica
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Cria uma instância do gerenciador de usuários com sua configuração
  const userManager = new UserManager(cognitoAuthConfig);

  useEffect(() => {
    // Tenta pegar o usuário da sessão quando o app carrega
    const loadUser = async () => {
      const userFromStorage = await userManager.getUser();
      if (userFromStorage && !userFromStorage.expired) {
        setUser(userFromStorage);
      }
      setIsLoading(false);
    };
    loadUser();
  }, []);

  const login = () => {
    return userManager.signinRedirect();
  };

  const logout = () => {
    setUser(null);
    return userManager.signoutRedirect();
  };

  // O "value" é o que será compartilhado com todos os componentes filhos
  const value = { user, login, logout, isLoading };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

AuthProvider.propTypes = {
  children: PropTypes.node.isRequired,
};

// Hook customizado para facilitar o uso do contexto
export const useAuth = () => {
  return useContext(AuthContext);
};