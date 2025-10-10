import { WebStorageStateStore } from "oidc-client";
// se for rodar local precisa criar um .env.local 

export const cognitoAuthConfig = {
  // import.meta.env para o vite conseguir ler
  authority: import.meta.env.VITE_COGNITO_AUTHORITY,
  client_id: import.meta.env.VITE_COGNITO_CLIENT_ID,
  redirect_uri: import.meta.env.VITE_REDIRECT_URI,
  post_logout_redirect_uri: import.meta.env.VITE_LOGOUT_URI,
  response_type: "code",
  scope: "openid email phone",
  userStore: new WebStorageStateStore({ store: window.localStorage }),
};