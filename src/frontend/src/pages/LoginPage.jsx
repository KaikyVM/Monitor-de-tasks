// src/pages/LoginPage.jsx

import React from 'react';
import { useAuth } from 'react-oidc-context';
import './LoginPage.css';

function LoginPage() {
  const auth = useAuth();

  return (
    <div className="login-container">
      <div className="login-box">
        {/* adicionar o logo aqui no futuro */}
        {/* <img src="/logo-flowhub.png" alt="Logo" /> */}

        <h2>Acesse sua Conta</h2>
        <p>Bem-vindo ao painel do Flowhub.</p>
        
        <button className="login-button" onClick={() => auth.signinRedirect()}>
          Entrar
        </button>
      </div>
    </div>
  );
}

export default LoginPage;