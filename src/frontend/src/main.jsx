import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.jsx";
import { AuthProvider } from "react-oidc-context";
import { cognitoAuthConfig } from "./cognitoConfig";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    {/* Agora, sem o bloco 'metadata', o AuthProvider vai usar 
      o 'authority' dinâmico que vem do cognitoAuthConfig.
    */}
    <AuthProvider
      {...cognitoAuthConfig}
      loadUserInfo={true}
      automaticSilentRenew={true}
    >
      <App />
    </AuthProvider>
  </StrictMode>
);